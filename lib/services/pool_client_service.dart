import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/key_search_types.dart';
import '../models/pool_models.dart';
import '../services/key_finder.dart';
import '../utils/address_util.dart';

class PoolClientService extends ChangeNotifier {
  static const String _lastHostKey = 'pool_client_last_host';
  static const String _lastPortKey = 'pool_client_last_port';

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  Timer? _heartbeatTimer;
  KeyFinder? _keyFinder;
  PoolServerConfig? _serverConfig;
  PoolWorkerStatus _status = PoolWorkerStatus.disconnected;
  String? _clientId;
  String? _host;
  int? _port;
  int _numThreads = 1;
  String? _currentRangeId;
  BigInt? _currentRangeStart;
  BigInt? _currentRangeEnd;
  BigInt _rangeKeysChecked = BigInt.zero;
  BigInt _totalKeysChecked = BigInt.zero;
  double _speed = 0;
  String? _errorMessage;
  String? _appVersion;
  String? _hostVersion;

  PoolWorkerStatus get status => _status;
  bool get isConnected => _socket != null;
  bool get isSearching => _status == PoolWorkerStatus.searching;
  String? get clientId => _clientId;
  String? get host => _host;
  int? get port => _port;
  int get numThreads => _numThreads;
  String? get currentRangeId => _currentRangeId;
  BigInt? get currentRangeStart => _currentRangeStart;
  BigInt? get currentRangeEnd => _currentRangeEnd;
  BigInt get rangeKeysChecked => _rangeKeysChecked;
  BigInt get totalKeysChecked => _totalKeysChecked;
  double get speed => _speed;
  String? get errorMessage => _errorMessage;
  String? get appVersion => _appVersion;
  String? get hostVersion => _hostVersion;

  Future<void> connect({
    required String host,
    required int port,
    required int numThreads,
    String? deviceName,
  }) async {
    if (_socket != null || _status == PoolWorkerStatus.connecting) return;

    _host = host.trim();
    _port = port;
    _numThreads = numThreads;
    _appVersion = await _loadAppVersion();
    _status = PoolWorkerStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final socket = await Socket.connect(_host, port, timeout: const Duration(seconds: 8));
      _socket = socket;
      await _saveLastEndpoint(_host!, port);
      _status = PoolWorkerStatus.connected;
      _subscription = utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: (error) => _handleDisconnect(error.toString()),
            onDone: () => _handleDisconnect(null),
            cancelOnError: true,
          );
      _send({
        'type': 'hello',
        'appVersion': _appVersion,
        'deviceName': deviceName?.trim().isNotEmpty == true
            ? deviceName!.trim()
            : Platform.localHostname,
      });
      _startHeartbeat();
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _status = PoolWorkerStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _stopCurrentRange();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;
    _clientId = null;
    _serverConfig = null;
    _currentRangeId = null;
    _currentRangeStart = null;
    _currentRangeEnd = null;
    _rangeKeysChecked = BigInt.zero;
    _speed = 0;
    _status = PoolWorkerStatus.disconnected;
    notifyListeners();
  }

  void requestWork() {
    if (_socket == null || _status == PoolWorkerStatus.searching) return;
    _send({'type': 'assign_request'});
  }

  Future<({String? host, int? port})> loadLastEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      host: prefs.getString(_lastHostKey),
      port: prefs.getInt(_lastPortKey),
    );
  }

  void _handleLine(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'] as String?;
      switch (type) {
        case 'welcome':
          _handleWelcome(decoded);
        case 'version_mismatch':
          _handleVersionMismatch(decoded);
        case 'work_assigned':
          unawaited(_handleWorkAssigned(decoded));
        case 'no_work':
          _status = PoolWorkerStatus.completed;
          notifyListeners();
        case 'stop':
          unawaited(_stopCurrentRange());
      }
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _handleWelcome(Map<String, dynamic> message) {
    _clientId = message['clientId'] as String?;
    _hostVersion = message['appVersion'] as String?;
    if (_hostVersion != null &&
        _appVersion != null &&
        _hostVersion != _appVersion) {
      _errorMessage = 'Version mismatch: host $_hostVersion, client $_appVersion';
      unawaited(disconnect());
      return;
    }
    final configJson = message['config'];
    if (configJson is Map<String, dynamic>) {
      _serverConfig = PoolServerConfig.fromJson(configJson);
    }
    _status = PoolWorkerStatus.idle;
    notifyListeners();
    requestWork();
  }

  void _handleVersionMismatch(Map<String, dynamic> message) {
    _hostVersion = message['hostVersion'] as String?;
    final clientVersion = message['clientVersion'] as String? ?? _appVersion;
    _errorMessage = 'Version mismatch: host $_hostVersion, client $clientVersion';
    unawaited(disconnect());
  }

  Future<void> _handleWorkAssigned(Map<String, dynamic> message) async {
    final config = _serverConfig;
    final range = message['range'];
    if (config == null || range is! Map<String, dynamic>) return;

    await _stopCurrentRange();
    _currentRangeId = range['id'] as String?;
    _currentRangeStart = BigInt.parse(range['startKey'] as String);
    _currentRangeEnd = BigInt.parse(range['endKey'] as String);
    _rangeKeysChecked = BigInt.zero;
    _speed = 0;
    _status = PoolWorkerStatus.searching;
    notifyListeners();

    final searchConfig = _buildSearchConfig(config);
    _keyFinder = KeyFinder(searchConfig);
    _keyFinder!.onStatus = (status) {
      _speed = status.speed * 1000000;
      _sendProgress();
      notifyListeners();
    };
    _keyFinder!.onProgress = (start, end) {
      final stride = searchConfig.stride;
      final checked =
          end >= start ? ((end - start) ~/ stride) + BigInt.one : BigInt.zero;
      _rangeKeysChecked += checked;
      _totalKeysChecked += checked;
      _sendProgress();
      notifyListeners();
    };
    _keyFinder!.onResult = (result) {
      _send({'type': 'found', 'result': result.toJson()});
      unawaited(disconnect());
    };
    _keyFinder!.onError = (error) {
      _errorMessage = error;
      _sendProgress();
      unawaited(_stopCurrentRange());
      notifyListeners();
    };
    _keyFinder!.onCompleted = () {
      _send({
        'type': 'work_completed',
        'rangeId': _currentRangeId,
        'keysChecked': _rangeKeysChecked.toString(),
      });
      _status = PoolWorkerStatus.idle;
      _currentRangeId = null;
      _currentRangeStart = null;
      _currentRangeEnd = null;
      _rangeKeysChecked = BigInt.zero;
      _speed = 0;
      _keyFinder = null;
      notifyListeners();
      requestWork();
    };

    await _keyFinder!.start();
  }

  KeySearchConfig _buildSearchConfig(PoolServerConfig config) {
    final start = _currentRangeStart!;
    final end = _currentRangeEnd!;
    final compressionIndex = config.compressionIndex.clamp(
      0,
      PointCompressionType.values.length - 1,
    );
    final targets =
        config.targets.map((address) {
          final hash160Bytes = AddressUtil.addressToHash160(address);
          final hash160 = <int>[];
          for (var i = 0; i < hash160Bytes.length; i += 4) {
            var value = 0;
            for (var j = 0; j < 4 && i + j < hash160Bytes.length; j++) {
              value = (value << 8) | hash160Bytes[i + j];
            }
            hash160.add(value);
          }
          return KeySearchTarget(address: address, hash160: hash160);
        }).toList();

    return KeySearchConfig(
      startKey: start,
      nextKey: start,
      endKey: end,
      stride: config.stride,
      compression: PointCompressionType.values[compressionIndex],
      searchMode: SearchMode.sequential,
      targets: targets,
      numThreads: Platform.numberOfProcessors > 1
          ? _numThreads.clamp(1, Platform.numberOfProcessors)
          : 1,
    );
  }

  Future<void> _stopCurrentRange() async {
    final finder = _keyFinder;
    _keyFinder = null;
    if (finder != null) {
      await finder.stop();
    }
  }

  void _sendProgress() {
    if (_currentRangeId == null) return;
    _send({
      'type': 'progress',
      'rangeId': _currentRangeId,
      'keysChecked': _rangeKeysChecked.toString(),
      'speed': _speed,
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _send({
        'type': 'heartbeat',
        'rangeId': _currentRangeId,
        'speed': _speed,
      });
    });
  }

  void _send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null) return;
    socket.writeln(jsonEncode(message));
  }

  void _handleDisconnect(String? error) {
    _errorMessage = error;
    unawaited(disconnect());
  }

  Future<void> _saveLastEndpoint(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastHostKey, host);
    await prefs.setInt(_lastPortKey, port);
  }

  Future<String> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  @override
  void dispose() {
    unawaited(disconnect());
    super.dispose();
  }
}
