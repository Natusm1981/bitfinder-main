import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/key_search_types.dart';
import '../models/pool_models.dart';

class PoolServerService extends ChangeNotifier with WidgetsBindingObserver {
  static const int defaultPort = 40404;
  static const int defaultBatchSize = 2000000;
  static const String _storageKey = 'pool_server_completed_ranges';

  ServerSocket? _serverSocket;
  PoolServerConfig? _config;
  BigInt _nextSequenceIndex = BigInt.zero;
  int _nextRangeId = 0;
  String? _hostAddress;
  String? _errorMessage;
  bool _isStarting = false;
  String? _appVersion;

  final Map<String, Socket> _sockets = {};
  final Map<String, StreamSubscription<String>> _subscriptions = {};
  final Map<String, PoolClientInfo> _clients = {};
  final Map<String, PoolRangeInfo> _ranges = {};

  PoolServerService() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isRunning => _serverSocket != null;
  bool get isStarting => _isStarting;
  String? get hostAddress => _hostAddress;
  String? get errorMessage => _errorMessage;
  PoolServerConfig? get config => _config;
  List<PoolClientInfo> get clients =>
      _clients.values
          .where((client) => client.status != PoolClientStatus.disconnected)
          .toList(growable: false);
  List<PoolRangeInfo> get ranges => _ranges.values.toList(growable: false);

  BigInt get completedKeys {
    return _ranges.values
        .where((range) => range.status == PoolRangeStatus.completed)
        .fold(BigInt.zero, (sum, range) => sum + range.totalKeys);
  }

  BigInt get liveKeysChecked {
    return _ranges.values.fold(
      completedKeys,
      (sum, range) =>
          range.status == PoolRangeStatus.assigned ? sum + range.keysChecked : sum,
    );
  }

  double get completedPercent {
    final total = _config?.totalKeys ?? BigInt.zero;
    if (total == BigInt.zero) return 0;
    return _ratio(completedKeys, total);
  }

  double get livePercent {
    final total = _config?.totalKeys ?? BigInt.zero;
    if (total == BigInt.zero) return 0;
    return _ratio(liveKeysChecked, total);
  }

  double get totalSpeed {
    return _clients.values.fold(0, (sum, client) => sum + client.speed);
  }

  int get completedRangeCount =>
      _ranges.values.where((range) => range.status == PoolRangeStatus.completed).length;

  int get assignedRangeCount =>
      _ranges.values.where((range) => range.status == PoolRangeStatus.assigned).length;

  Future<void> startFromSearchConfig(KeySearchConfig searchConfig) async {
    final config = PoolServerConfig(
      startKey: searchConfig.startKey,
      endKey: searchConfig.endKey,
      stride: searchConfig.stride,
      compressionIndex: searchConfig.compression.index,
      targets: searchConfig.targets.map((target) => target.address).toList(),
      port: defaultPort,
      batchSize: defaultBatchSize,
    );
    await start(config);
  }

  Future<void> start(PoolServerConfig config) async {
    if (isRunning || _isStarting) return;

    _isStarting = true;
    _errorMessage = null;
    _config = config;
    _appVersion = await _loadAppVersion();
    _nextSequenceIndex = BigInt.zero;
    _nextRangeId = 0;
    _ranges.clear();
    notifyListeners();

    try {
      await _restoreCompletedRanges(config);
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        config.port,
        shared: true,
      );
      _hostAddress = await _resolveHostAddress();
      _serverSocket!.listen(_handleSocket, onError: _handleServerError);
      await WakelockPlus.enable();
    } catch (error) {
      _errorMessage = error.toString();
      await stop();
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    for (final socket in _sockets.values) {
      socket.destroy();
    }
    await _serverSocket?.close();
    _serverSocket = null;
    _subscriptions.clear();
    _sockets.clear();
    _clients.clear();
    _hostAddress = null;
    await WakelockPlus.disable();
    notifyListeners();
  }

  void _handleSocket(Socket socket) {
    final clientId = 'client-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final address = socket.remoteAddress.address;
    _sockets[clientId] = socket;
    _clients[clientId] = PoolClientInfo(
      id: clientId,
      deviceName: address,
      address: address,
      status: PoolClientStatus.connected,
      keysChecked: BigInt.zero,
      speed: 0,
      connectedAt: now,
      lastSeenAt: now,
    );
    notifyListeners();

    _send(socket, {
      'type': 'welcome',
      'clientId': clientId,
      'appVersion': _appVersion,
      'config': _config?.toJson(),
    });

    _subscriptions[clientId] = utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen(
          (line) => _handleMessage(clientId, line),
          onError: (_) => _disconnectClient(clientId),
          onDone: () => _disconnectClient(clientId),
          cancelOnError: true,
        );
  }

  void _handleMessage(String clientId, String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'] as String?;

      switch (type) {
        case 'hello':
          _handleHello(clientId, decoded);
        case 'assign_request':
          _assignNextRange(clientId);
        case 'progress':
          _handleProgress(clientId, decoded);
        case 'work_completed':
          unawaited(_handleCompleted(clientId, decoded));
        case 'heartbeat':
          _touchClient(clientId);
        case 'found':
          _handleFound(clientId, decoded);
      }
    } catch (error) {
      debugPrint('Invalid pool message: $error');
    }
  }

  void _handleHello(String clientId, Map<String, dynamic> message) {
    final client = _clients[clientId];
    if (client == null) return;
    _clients[clientId] = client.copyWith(
      deviceName: message['deviceName'] as String? ?? client.deviceName,
      status: PoolClientStatus.idle,
      lastSeenAt: DateTime.now(),
    );
    final clientVersion = message['appVersion'] as String?;
    if (clientVersion != null &&
        _appVersion != null &&
        clientVersion != _appVersion) {
      _send(_sockets[clientId]!, {
        'type': 'version_mismatch',
        'hostVersion': _appVersion,
        'clientVersion': clientVersion,
      });
      _disconnectClient(clientId);
      return;
    }
    notifyListeners();
  }

  void _handleProgress(String clientId, Map<String, dynamic> message) {
    final client = _clients[clientId];
    if (client == null) return;
    final rangeId = message['rangeId'] as String? ?? client.currentRangeId;
    final keysChecked = BigInt.tryParse(message['keysChecked']?.toString() ?? '0') ?? BigInt.zero;
    final speed = (message['speed'] as num?)?.toDouble() ?? client.speed;

    if (rangeId != null && _ranges.containsKey(rangeId)) {
      final range = _ranges[rangeId]!;
      _ranges[rangeId] = range.copyWith(keysChecked: keysChecked);
    }

    _clients[clientId] = client.copyWith(
      status: PoolClientStatus.searching,
      currentRangeId: rangeId,
      keysChecked: keysChecked,
      speed: speed,
      lastSeenAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> _handleCompleted(
    String clientId,
    Map<String, dynamic> message,
  ) async {
    final client = _clients[clientId];
    if (client == null) return;
    final rangeId = message['rangeId'] as String? ?? client.currentRangeId;
    if (rangeId == null || !_ranges.containsKey(rangeId)) return;

    final range = _ranges[rangeId]!;
    _ranges[rangeId] = range.copyWith(
      status: PoolRangeStatus.completed,
      keysChecked: range.totalKeys,
      completedAt: DateTime.now(),
    );
    _clients[clientId] = client.copyWith(
      status: PoolClientStatus.idle,
      clearCurrentRangeId: true,
      keysChecked: BigInt.zero,
      speed: 0,
      lastSeenAt: DateTime.now(),
    );
    await _persistCompletedRanges();
    notifyListeners();
  }

  void _handleFound(String clientId, Map<String, dynamic> message) {
    _touchClient(clientId);
    _sendToAll({
      'type': 'stop',
      'reason': 'found',
      'result': message['result'],
    });
  }

  void _touchClient(String clientId) {
    final client = _clients[clientId];
    if (client == null) return;
    _clients[clientId] = client.copyWith(lastSeenAt: DateTime.now());
    notifyListeners();
  }

  void _assignNextRange(String clientId) {
    final client = _clients[clientId];
    final socket = _sockets[clientId];
    final config = _config;
    if (client == null || socket == null || config == null) return;

    final range = _allocateRange(config, clientId);
    if (range == null) {
      _send(socket, {'type': 'no_work'});
      _clients[clientId] = client.copyWith(
        status: PoolClientStatus.idle,
        clearCurrentRangeId: true,
        lastSeenAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    _ranges[range.id] = range;
    _clients[clientId] = client.copyWith(
      status: PoolClientStatus.searching,
      currentRangeId: range.id,
      keysChecked: BigInt.zero,
      speed: 0,
      lastSeenAt: DateTime.now(),
    );
    _send(socket, {
      'type': 'work_assigned',
      'range': {
        'id': range.id,
        'startKey': range.startKey.toString(),
        'endKey': range.endKey.toString(),
      },
    });
    notifyListeners();
  }

  PoolRangeInfo? _allocateRange(PoolServerConfig config, String clientId) {
    final total = config.totalKeys;
    while (_nextSequenceIndex < total) {
      final sequenceStart = _nextSequenceIndex;
      final remaining = total - sequenceStart;
      final count =
          remaining > BigInt.from(config.batchSize)
              ? config.batchSize
              : remaining.toInt();
      _nextSequenceIndex += BigInt.from(count);
      final startKey = config.startKey + sequenceStart * config.stride;
      final endKey = startKey + BigInt.from(count - 1) * config.stride;
      final id = 'range-${_nextRangeId++}';
      final alreadyCompleted = _ranges.values.any(
        (range) =>
            range.status == PoolRangeStatus.completed &&
            range.startKey == startKey &&
            range.endKey == endKey,
      );
      if (alreadyCompleted) continue;
      return PoolRangeInfo(
        id: id,
        startKey: startKey,
        endKey: endKey,
        keyCount: BigInt.from(count),
        status: PoolRangeStatus.assigned,
        assignedClientId: clientId,
        keysChecked: BigInt.zero,
        createdAt: DateTime.now(),
        assignedAt: DateTime.now(),
      );
    }
    return null;
  }

  void _disconnectClient(String clientId) {
    _subscriptions.remove(clientId)?.cancel();
    _sockets.remove(clientId)?.destroy();
    final client = _clients[clientId];
    if (client != null) {
      _clients[clientId] = client.copyWith(
        status: PoolClientStatus.disconnected,
        speed: 0,
        lastSeenAt: DateTime.now(),
      );
    }

    final rangeId = client?.currentRangeId;
    if (rangeId != null && _ranges.containsKey(rangeId)) {
      final range = _ranges[rangeId]!;
      if (range.status == PoolRangeStatus.assigned) {
        _ranges[rangeId] = range.copyWith(
          status: PoolRangeStatus.failed,
          completedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  void _handleServerError(Object error) {
    _errorMessage = error.toString();
    notifyListeners();
  }

  void _send(Socket socket, Map<String, dynamic> message) {
    socket.writeln(jsonEncode(message));
  }

  void _sendToAll(Map<String, dynamic> message) {
    for (final socket in _sockets.values) {
      _send(socket, message);
    }
  }

  Future<void> _restoreCompletedRanges(PoolServerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    if (decoded['signature'] != config.signature) return;
    final ranges = decoded['ranges'];
    if (ranges is! List) return;

    for (final item in ranges) {
      if (item is! Map<String, dynamic>) continue;
      final range = PoolRangeInfo.fromJson(item);
      if (range.status == PoolRangeStatus.completed) {
        _ranges[range.id] = range;
      }
    }
  }

  Future<void> _persistCompletedRanges() async {
    final config = _config;
    if (config == null) return;
    final completed =
        _ranges.values
            .where((range) => range.status == PoolRangeStatus.completed)
            .map((range) => range.toJson())
            .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({'signature': config.signature, 'ranges': completed}),
    );
  }

  Future<String?> _resolveHostAddress() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) return address.address;
      }
    }
    return null;
  }

  Future<String> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  double _ratio(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero || numerator <= BigInt.zero) return 0;
    if (numerator >= denominator) return 1;
    final shift = denominator.bitLength > 52 ? denominator.bitLength - 52 : 0;
    final scaledDenominator = denominator >> shift;
    final scaledNumerator = numerator >> shift;
    if (scaledNumerator == BigInt.zero) return 0;
    return (scaledNumerator.toDouble() / scaledDenominator.toDouble()).clamp(0, 1);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(stop());
    super.dispose();
  }
}
