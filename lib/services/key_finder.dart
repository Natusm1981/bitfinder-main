import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../models/key_search_types.dart';
import '../utils/address_util.dart';
import '../utils/native_crypto_binding.dart';

class KeyFinder {
  static const int _nativeBatchSize = 8192;
  static const int _dartBatchSize = 256;

  final KeySearchConfig config;

  Timer? _statusTimer;
  Timer? _thermalTimer;
  final List<Isolate> _searchIsolates = [];
  ReceivePort? _receivePort;
  DateTime? _startTime;
  DateTime? _lastCheckTime;
  BigInt _keysChecked = BigInt.zero;
  BigInt _lastKeysChecked = BigInt.zero;
  final Map<int, BigInt> _threadKeysChecked = {};
  final Map<int, BigInt> _threadNextKeys = {};
  int _completedWorkers = 0;
  int _runId = 0;

  BigInt _nextSequenceIndex = BigInt.zero;
  int _nextBatchId = 0;
  int _contiguousBatchId = 0;
  final Map<int, BigInt> _completedBatchEnds = {};
  List<Uint8List> _nativeTargetHashes = const [];
  int _activeNativeWorkers = 1;
  int _activeNativeBatches = 0;
  bool _stopRequested = false;
  Completer<void>? _stopCompleter;

  void Function(KeySearchResult)? onResult;
  void Function(KeySearchStatus)? onStatus;
  void Function(BigInt start, BigInt end)? onProgress;
  void Function(BigInt nextKey)? onCheckpoint;
  void Function()? onCompleted;
  void Function(String)? onError;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  KeyFinder(this.config);

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _runId++;
    _startTime = DateTime.now();
    _lastCheckTime = _startTime;
    _keysChecked = BigInt.zero;
    _lastKeysChecked = BigInt.zero;
    _threadKeysChecked.clear();
    _threadNextKeys.clear();
    _completedWorkers = 0;
    _nextSequenceIndex = _initialSequenceIndex();
    _nextBatchId = 0;
    _contiguousBatchId = 0;
    _completedBatchEnds.clear();
    _activeNativeBatches = 0;
    _stopRequested = false;
    _stopCompleter = null;
    _nativeTargetHashes = config.targets
        .map((target) => AddressUtil.addressToHash160(target.address))
        .toList(growable: false);
    _activeNativeWorkers = config.numThreads;

    _reportInitialStatus();
    _statusTimer = Timer.periodic(
      Duration(milliseconds: config.statusInterval.clamp(500, 10000)),
      (_) => _reportStatus(),
    );

    try {
      if (NativeCryptoBinding.isAvailable) {
        final runId = _runId;
        _thermalTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => unawaited(_refreshThermalLimit()),
        );
        for (var workerId = 0; workerId < config.numThreads; workerId++) {
          unawaited(_runNativeWorker(workerId, runId));
        }
      } else {
        await _startDartWorkers();
      }
    } catch (error) {
      _fail('Failed to start search: $error');
    }
  }

  Future<void> stop({bool graceful = true}) async {
    if (!_isRunning && _searchIsolates.isEmpty) return;

    if (graceful &&
        NativeCryptoBinding.isAvailable &&
        _searchIsolates.isEmpty &&
        _activeNativeBatches > 0) {
      _stopRequested = true;
      _statusTimer?.cancel();
      _statusTimer = null;
      _thermalTimer?.cancel();
      _thermalTimer = null;
      _stopCompleter ??= Completer<void>();
      return _stopCompleter!.future;
    }

    _finishStop(killIsolates: true);
  }

  void _finishStop({required bool killIsolates}) {
    if (!_isRunning && _searchIsolates.isEmpty) {
      _completeStopRequest();
      return;
    }
    _isRunning = false;
    _stopRequested = false;
    _runId++;
    _statusTimer?.cancel();
    _statusTimer = null;
    _thermalTimer?.cancel();
    _thermalTimer = null;
    if (killIsolates) {
      for (final isolate in _searchIsolates) {
        isolate.kill(priority: Isolate.immediate);
      }
      _searchIsolates.clear();
      _receivePort?.close();
      _receivePort = null;
    }
    _completeStopRequest();
  }

  void _completeStopRequest() {
    final completer = _stopCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _stopCompleter = null;
  }

  Future<void> _runNativeWorker(int workerId, int runId) async {
    var batchInFlight = false;
    try {
      while (_isRunning && runId == _runId) {
        if (_stopRequested) break;
        if (workerId >= _activeNativeWorkers) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }
        final batch = _allocateNativeBatch();
        if (batch == null) break;

        _activeNativeBatches++;
        batchInFlight = true;
        final result = await NativeCryptoBinding.searchBatch(
          startKey: batch.startKey,
          count: batch.count,
          stride: config.stride,
          compressionMode: config.compression.index,
          targetHashes: _nativeTargetHashes,
        );
        _activeNativeBatches--;
        batchInFlight = false;
        if (runId != _runId) return;
        if (!_isRunning && !_stopRequested) return;

        _keysChecked += BigInt.from(result.checked);
        _threadKeysChecked[workerId] =
            (_threadKeysChecked[workerId] ?? BigInt.zero) +
            BigInt.from(result.checked);
        _threadNextKeys[workerId] = result.nextKey;

        if (result.checked > 0) {
          final lastKey =
              batch.startKey + config.stride * BigInt.from(result.checked - 1);
          onProgress?.call(batch.startKey, lastKey);
        }

        if (config.searchMode == SearchMode.sequential) {
          _completedBatchEnds[batch.id] =
              batch.sequenceStart + BigInt.from(result.checked);
          _advanceCheckpoint();
        } else {
          config.nextKey = result.nextKey;
        }

        if (result.foundKey != null && result.foundCompressed != null) {
          unawaited(stop(graceful: false));
          onResult?.call(
            _buildResult(result.foundKey!, result.foundCompressed!),
          );
          return;
        }

        if (_stopRequested) break;
      }
    } catch (error) {
      if (batchInFlight && _activeNativeBatches > 0) {
        _activeNativeBatches--;
      }
      if (_isRunning && runId == _runId) {
        _fail('Native search failed: $error');
      }
      return;
    }

    if (_isRunning && runId == _runId) {
      if (_stopRequested) {
        _completedWorkers++;
        if (_activeNativeBatches == 0) {
          _reportStatus();
          _finishStop(killIsolates: false);
        }
        return;
      }
      _completedWorkers++;
      if (_completedWorkers == config.numThreads) {
        _finish();
      }
    }
  }

  _NativeBatch? _allocateNativeBatch() {
    if (config.searchMode == SearchMode.random) {
      final start = _generateRandomBatchStart(
        config.startKey,
        config.endKey,
        config.stride,
        _nativeBatchSize,
      );
      final available =
          ((config.endKey - start) ~/ config.stride + BigInt.one).toInt();
      return _NativeBatch(
        id: _nextBatchId++,
        sequenceStart: BigInt.zero,
        startKey: start,
        count: min(_nativeBatchSize, available),
      );
    }

    final total =
        (config.endKey - config.startKey) ~/ config.stride + BigInt.one;
    if (_nextSequenceIndex >= total) return null;

    final remaining = total - _nextSequenceIndex;
    final count =
        remaining > BigInt.from(_nativeBatchSize)
            ? _nativeBatchSize
            : remaining.toInt();
    final sequenceStart = _nextSequenceIndex;
    _nextSequenceIndex += BigInt.from(count);
    return _NativeBatch(
      id: _nextBatchId++,
      sequenceStart: sequenceStart,
      startKey: config.startKey + sequenceStart * config.stride,
      count: count,
    );
  }

  BigInt _initialSequenceIndex() {
    if (config.searchMode != SearchMode.sequential ||
        config.nextKey <= config.startKey) {
      return BigInt.zero;
    }
    final index = (config.nextKey - config.startKey) ~/ config.stride;
    final alignedKey = config.startKey + index * config.stride;
    return alignedKey < config.nextKey ? index + BigInt.one : index;
  }

  void _advanceCheckpoint() {
    while (_completedBatchEnds.containsKey(_contiguousBatchId)) {
      final sequenceEnd = _completedBatchEnds.remove(_contiguousBatchId)!;
      config.nextKey = config.startKey + sequenceEnd * config.stride;
      onCheckpoint?.call(config.nextKey);
      _contiguousBatchId++;
    }
  }

  Future<void> _startDartWorkers() async {
    _receivePort = ReceivePort();
    _receivePort!.listen(_handleDartMessage);

    final resumeKey =
        config.nextKey < config.startKey ? config.startKey : config.nextKey;
    if (resumeKey > config.endKey) {
      _finish();
      return;
    }
    final keyCount = (config.endKey - resumeKey) ~/ config.stride + BigInt.one;
    final perWorker =
        (keyCount + BigInt.from(config.numThreads - 1)) ~/
        BigInt.from(config.numThreads);

    for (var workerId = 0; workerId < config.numThreads; workerId++) {
      final startIndex = perWorker * BigInt.from(workerId);
      if (startIndex >= keyCount) {
        _completedWorkers++;
        continue;
      }
      final endIndex = minBigInt(keyCount, startIndex + perWorker) - BigInt.one;
      final workerConfig = config.copyWith(
        startKey: resumeKey + startIndex * config.stride,
        nextKey: resumeKey + startIndex * config.stride,
        endKey: resumeKey + endIndex * config.stride,
      );
      _threadKeysChecked[workerId] = BigInt.zero;
      _threadNextKeys[workerId] = workerConfig.startKey;
      _searchIsolates.add(
        await Isolate.spawn(
          _searchWorker,
          _SearchParams(
            sendPort: _receivePort!.sendPort,
            config: workerConfig,
            threadId: workerId,
          ),
        ),
      );
    }
  }

  void _handleDartMessage(dynamic message) {
    if (message is KeySearchResult) {
      unawaited(stop(graceful: false));
      onResult?.call(message);
      return;
    }
    if (message is! Map) return;

    final type = message['type'];
    if (type == 'error') {
      _fail(message['message'] as String);
    } else if (type == 'status') {
      final workerId = message['threadId'] as int;
      _threadKeysChecked[workerId] = message['keysChecked'] as BigInt;
      _threadNextKeys[workerId] = message['nextKey'] as BigInt;
      _keysChecked = _threadKeysChecked.values.fold(
        BigInt.zero,
        (sum, value) => sum + value,
      );
      config.nextKey = _threadNextKeys.values.reduce(minBigInt);
      onCheckpoint?.call(config.nextKey);
      onProgress?.call(
        message['batchStart'] as BigInt,
        message['batchEnd'] as BigInt,
      );
    } else if (type == 'completed') {
      _completedWorkers++;
      if (_completedWorkers == config.numThreads) _finish();
    }
  }

  static void _searchWorker(_SearchParams params) {
    final config = params.config;
    final targets = config.targets.map((target) => target.address).toSet();
    final random = Random.secure();
    var currentKey = config.nextKey;
    var checked = BigInt.zero;

    try {
      final stridePoint = AddressUtil.publicKeyFromPrivate(config.stride);
      while (config.searchMode == SearchMode.random ||
          currentKey <= config.endKey) {
        final batchStart =
            config.searchMode == SearchMode.random
                ? _generateRandomBatchStart(
                  config.startKey,
                  config.endKey,
                  config.stride,
                  _dartBatchSize,
                  random: random,
                )
                : currentKey;
        currentKey = batchStart;
        ECPoint? point = AddressUtil.publicKeyFromPrivate(currentKey);
        var processed = 0;

        while (processed < _dartBatchSize && currentKey <= config.endKey) {
          final compressedMatch =
              config.compression != PointCompressionType.uncompressed &&
              targets.contains(
                AddressUtil.publicPointToAddress(point!, compressed: true),
              );
          final uncompressedMatch =
              !compressedMatch &&
              config.compression != PointCompressionType.compressed &&
              targets.contains(
                AddressUtil.publicPointToAddress(point!, compressed: false),
              );
          if (compressedMatch || uncompressedMatch) {
            params.sendPort.send(
              _buildStaticResult(config, currentKey, compressedMatch, point),
            );
            return;
          }

          currentKey += config.stride;
          point = point! + stridePoint;
          processed++;
          checked += BigInt.one;
        }

        params.sendPort.send({
          'type': 'status',
          'threadId': params.threadId,
          'keysChecked': checked,
          'nextKey': currentKey,
          'batchStart': batchStart,
          'batchEnd': currentKey - config.stride,
        });
      }
      params.sendPort.send({'type': 'completed', 'threadId': params.threadId});
    } catch (error) {
      params.sendPort.send({'type': 'error', 'message': error.toString()});
    }
  }

  KeySearchResult _buildResult(BigInt privateKey, bool compressed) {
    final point = AddressUtil.publicKeyFromPrivate(privateKey);
    return _buildStaticResult(config, privateKey, compressed, point);
  }

  static KeySearchResult _buildStaticResult(
    KeySearchConfig config,
    BigInt privateKey,
    bool compressed,
    ECPoint point,
  ) {
    return KeySearchResult(
      address: AddressUtil.publicPointToAddress(point, compressed: compressed),
      privateKey: privateKey,
      publicKeyX: point.x!.toBigInteger()!.toRadixString(16),
      publicKeyY: point.y!.toBigInteger()!.toRadixString(16),
      compressed: compressed,
      privateKeyWIF: AddressUtil.privateKeyToWIF(
        privateKey,
        compressed: compressed,
      ),
      challengeId: config.challengeId,
    );
  }

  void _reportInitialStatus() {
    onStatus?.call(
      KeySearchStatus(
        speed: 0,
        total: BigInt.zero,
        totalTime: 0,
        deviceName: _deviceName,
        targets: config.targets.length,
        nextKey: config.nextKey,
      ),
    );
  }

  void _reportStatus() {
    if (!_isRunning || _startTime == null || _lastCheckTime == null) return;
    final now = DateTime.now();
    final interval = now.difference(_lastCheckTime!).inMicroseconds;
    final delta = _keysChecked - _lastKeysChecked;
    final speed = interval <= 0 ? 0.0 : delta.toDouble() / interval.toDouble();
    _lastKeysChecked = _keysChecked;
    _lastCheckTime = now;
    onStatus?.call(
      KeySearchStatus(
        speed: speed,
        total: _keysChecked,
        totalTime: now.difference(_startTime!).inMilliseconds,
        deviceName: _deviceName,
        targets: config.targets.length,
        nextKey: config.nextKey,
      ),
    );
  }

  Future<void> _refreshThermalLimit() async {
    if (!_isRunning || !NativeCryptoBinding.isAvailable) return;
    try {
      final thermalStatus = await NativeCryptoBinding.getThermalStatus();
      if (thermalStatus >= 4) {
        _activeNativeWorkers = 1;
      } else if (thermalStatus >= 3) {
        _activeNativeWorkers = max(1, config.numThreads ~/ 2);
      } else {
        _activeNativeWorkers = config.numThreads;
      }
    } catch (_) {
      _activeNativeWorkers = config.numThreads;
    }
  }

  String get _deviceName {
    final engine = NativeCryptoBinding.isAvailable ? 'libsecp256k1' : 'Dart';
    return '$engine (${config.numThreads} workers)';
  }

  void _finish() {
    if (!_isRunning) return;
    _reportStatus();
    unawaited(stop(graceful: false));
    onCompleted?.call();
  }

  void _fail(String message) {
    if (!_isRunning) return;
    unawaited(stop(graceful: false));
    onError?.call(message);
  }

  void dispose() {
    unawaited(stop(graceful: false));
  }

  static BigInt _generateRandomBatchStart(
    BigInt start,
    BigInt end,
    BigInt stride,
    int batchSize, {
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final total = (end - start) ~/ stride + BigInt.one;
    final availableStarts =
        total > BigInt.from(batchSize)
            ? total - BigInt.from(batchSize) + BigInt.one
            : BigInt.one;
    return start + _randomBelow(rng, availableStarts) * stride;
  }

  static BigInt _randomBelow(Random random, BigInt upperExclusive) {
    if (upperExclusive <= BigInt.one) return BigInt.zero;
    final byteCount = (upperExclusive.bitLength + 7) ~/ 8;
    while (true) {
      var value = BigInt.zero;
      for (var i = 0; i < byteCount; i++) {
        value = (value << 8) | BigInt.from(random.nextInt(256));
      }
      if (value < upperExclusive) return value;
    }
  }
}

BigInt minBigInt(BigInt a, BigInt b) => a < b ? a : b;

class _NativeBatch {
  final int id;
  final BigInt sequenceStart;
  final BigInt startKey;
  final int count;

  const _NativeBatch({
    required this.id,
    required this.sequenceStart,
    required this.startKey,
    required this.count,
  });
}

class _SearchParams {
  final SendPort sendPort;
  final KeySearchConfig config;
  final int threadId;

  const _SearchParams({
    required this.sendPort,
    required this.config,
    required this.threadId,
  });
}
