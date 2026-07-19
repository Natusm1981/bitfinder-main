import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/key_search_types.dart';
import '../models/wallet_challenge.dart';
import '../services/background_search_service.dart';
import '../services/key_finder.dart';
import '../utils/address_util.dart';
import 'history_provider.dart';
import 'search_progress_provider.dart';
import 'performance_provider.dart';
import 'workload_provider.dart';

class KeyFinderProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _lastConfigKey = 'last_search_config_v1';
  static const _checkpointPersistInterval = Duration(seconds: 30);

  late final Future<void> _initialization;
  Future<void> _pendingPersist = Future<void>.value();
  DateTime? _lastCheckpointPersist;
  HistoryProvider? _historyProvider;
  SearchProgressProvider? _progressProvider;
  PerformanceProvider? _performanceProvider;
  WorkloadProvider? _workloadProvider;

  void setHistoryProvider(HistoryProvider provider) {
    _historyProvider = provider;
  }

  void setProgressProvider(SearchProgressProvider provider) {
    _progressProvider = provider;
  }

  void setPerformanceProvider(PerformanceProvider provider) {
    _performanceProvider = provider;
  }

  void setWorkloadProvider(WorkloadProvider provider) {
    _workloadProvider = provider;
  }

  KeySearchConfig _config = KeySearchConfig();
  KeyFinder? _keyFinder;

  KeySearchStatus? _currentStatus;
  final List<TemperatureSample> _temperatureHistory = [];
  final List<KeySearchResult> _results = [];
  String? _errorMessage;

  KeyFinderProvider() {
    _initialization = _restoreConfiguration();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> get initialized => _initialization;

  bool get isRunning => _config.isRunning;
  KeySearchStatus? get currentStatus => _currentStatus;
  List<TemperatureSample> get temperatureHistory =>
      List.unmodifiable(_temperatureHistory);
  List<KeySearchResult> get results => List.unmodifiable(_results);
  String? get errorMessage => _errorMessage;
  KeySearchConfig get config => _config;
  bool get canStartSearch =>
      _config.targets.isNotEmpty &&
      _config.startKey <= _config.endKey &&
      _config.nextKey <= _config.endKey &&
      _config.stride > BigInt.zero;

  /// Start the key search
  Future<void> startSearch() async {
    if (_config.isRunning || !canStartSearch) return;
    if (_workloadProvider?.acquire(WorkloadActivity.localSearch) == false) {
      _errorMessage = 'Another search is already running';
      notifyListeners();
      return;
    }

    _errorMessage = null;

    // Ativar wakelock para manter tela ligada
    await WakelockPlus.enable();

    // Aplicar configurações de performance
    final numThreads = _performanceProvider?.numThreads ?? 1;
    _config = _config.copyWith(isRunning: true, numThreads: numThreads);
    notifyListeners();

    // Inicializar progresso apenas para modo Sequential
    if (_config.searchMode == SearchMode.sequential) {
      final progress = await _progressProvider?.startProgress(
        keyspaceId: _progressId,
        startKey: _config.startKey,
        endKey: _config.endKey,
      );
      if (progress != null) {
        _config = _config.copyWith(nextKey: progress.nextKey);
        unawaited(_persistConfiguration());
      }
    }

    _keyFinder = KeyFinder(_config);

    _keyFinder!.onStatus = (status) {
      _currentStatus = status;
      final temperature = status.batteryTemperatureCelsius;
      if (temperature != null) {
        _temperatureHistory.add(
          TemperatureSample(
            celsius: temperature,
            timestamp: status.timestamp,
          ),
        );
        if (_temperatureHistory.length > 120) {
          _temperatureHistory.removeRange(
            0,
            _temperatureHistory.length - 120,
          );
        }
      }
      notifyListeners();
    };

    _keyFinder!.onProgress = (start, end) {
      if (_config.searchMode == SearchMode.sequential) {
        _progressProvider?.updateProgressRange(start, end);
      }
    };

    _keyFinder!.onCheckpoint = (nextKey) {
      if (_config.searchMode == SearchMode.sequential) {
        _config.nextKey = nextKey;
        unawaited(_saveCheckpointSnapshot(nextKey));
      }
    };

    _keyFinder!.onResult = (result) {
      _results.add(result);
      // Salvar no histórico
      _historyProvider?.addToHistory(result);
      stopSearch(clearResults: false); // Para a busca mas mantém resultado
      notifyListeners();
    };

    _keyFinder!.onError = (error) {
      _errorMessage = error;
      unawaited(stopSearch(clearResults: false));
    };

    _keyFinder!.onCompleted = () {
      _config = _config.copyWith(isRunning: false);
      _workloadProvider?.release(WorkloadActivity.localSearch);
      WakelockPlus.disable();
      unawaited(_progressProvider?.stopProgress());
      unawaited(_persistConfiguration());
      notifyListeners();
    };

    await _keyFinder!.start();
  }

  /// Stop the key search
  Future<void> stopSearch({bool clearResults = false}) async {
    final finder = _keyFinder;
    if (finder != null) {
      await finder.stop();
    }
    _keyFinder = null;
    _workloadProvider?.release(WorkloadActivity.localSearch);
    _config = _config.copyWith(isRunning: false);
    _temperatureHistory.clear();

    // Desativar wakelock
    await WakelockPlus.disable();
    await BackgroundSearchService.stop();
    if (_config.searchMode == SearchMode.sequential) {
      await _progressProvider?.updateCheckpoint(_config.nextKey);
      await _progressProvider?.stopProgress();
    }
    // Limpar resultados e configuração quando parar (exceto se encontrou chave)
    if (clearResults) {
      _results.clear();
      _config = _config.copyWith(
        targets: [],
        startKey: BigInt.one,
        nextKey: BigInt.one,
        endKey: BigInt.parse(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
          radix: 16,
        ),
        challengeId: null,
        clearChallengeId: true,
      );
      _currentStatus = null;
    }

    await _persistConfiguration();
    notifyListeners();
  }

  String get _progressId {
    final targets =
        _config.targets.map((target) => target.address).toList()..sort();
    final owner = _config.challengeId?.toString() ?? targets.join(',');
    return 'v2|$owner|${_config.startKey.toRadixString(16)}:'
        '${_config.endKey.toRadixString(16)}|${_config.stride.toRadixString(16)}|'
        '${_config.compression.index}';
  }

  /// Update configuration
  void updateConfig(KeySearchConfig newConfig) {
    if (_config.isRunning) return;
    _config = newConfig;
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  /// Add target address
  void addTarget(String address) {
    if (_config.isRunning) return;

    if (!AddressUtil.verifyAddress(address)) {
      _errorMessage = 'Invalid Bitcoin address: $address';
      notifyListeners();
      return;
    }

    try {
      final hash160Bytes = AddressUtil.addressToHash160(address);
      final hash160List = <int>[];

      // Convert bytes to list of 32-bit integers
      for (int i = 0; i < hash160Bytes.length; i += 4) {
        int value = 0;
        for (int j = 0; j < 4 && i + j < hash160Bytes.length; j++) {
          value = (value << 8) | hash160Bytes[i + j];
        }
        hash160List.add(value);
      }

      final target = KeySearchTarget(address: address, hash160: hash160List);

      final newTargets =
          List<KeySearchTarget>.from(_config.targets)
            ..removeWhere((existing) => existing.address == target.address)
            ..add(target);
      _config = _config.copyWith(targets: newTargets);
      unawaited(_persistConfiguration());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to process address: $e';
      notifyListeners();
    }
  }

  /// Remove target address
  void removeTarget(int index) {
    if (_config.isRunning) return;

    final newTargets = List<KeySearchTarget>.from(_config.targets)
      ..removeAt(index);
    _config = _config.copyWith(targets: newTargets);
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  /// Clear all targets
  void clearTargets() {
    if (_config.isRunning) return;

    _config = _config.copyWith(targets: [], clearChallengeId: true);
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  /// Set keyspace
  void setKeyspace(String keyspaceStr) {
    if (_config.isRunning) return;

    try {
      final keyspace = KeyspaceUtil.parseKeyspace(keyspaceStr);
      _config = _config.copyWith(
        startKey: keyspace.start,
        nextKey: keyspace.start,
        endKey: keyspace.end,
      );
      unawaited(_persistConfiguration());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Invalid keyspace: $e';
      notifyListeners();
    }
  }

  /// Set compression mode
  void setCompressionMode(PointCompressionType mode) {
    if (_config.isRunning) return;

    _config = _config.copyWith(compression: mode);
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  /// Set stride
  void setStride(String strideStr) {
    if (_config.isRunning) return;

    try {
      final stride = BigInt.parse(strideStr, radix: 16);
      final curveOrder = BigInt.parse(
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
        radix: 16,
      );
      if (stride <= BigInt.zero || stride >= curveOrder) {
        throw const FormatException('Stride must be between 1 and n-1');
      }
      _config = _config.copyWith(stride: stride);
      unawaited(_persistConfiguration());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Invalid stride: $e';
      notifyListeners();
    }
  }

  /// Set search mode
  void setSearchMode(SearchMode mode) {
    if (_config.isRunning) return;

    _config = _config.copyWith(searchMode: mode);
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    unawaited(_persistConfiguration());
    notifyListeners();
  }

  Future<void> _restoreConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_lastConfigKey);
      if (encoded == null) return;
      _config = KeySearchConfig.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      ).copyWith(isRunning: false);
      notifyListeners();
    } catch (error) {
      debugPrint('Error restoring last search configuration: $error');
    }
  }

  Future<void> _persistConfiguration() {
    final encoded = jsonEncode(_config.toJson());
    _pendingPersist = _pendingPersist.then((_) => _writeConfiguration(encoded));
    return _pendingPersist;
  }

  Future<void> _writeConfiguration(String encoded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConfigKey, encoded);
    } catch (error) {
      debugPrint('Error saving last search configuration: $error');
    }
  }

  Future<void> persistSession() async {
    await _initialization;
    if (_config.searchMode == SearchMode.sequential) {
      await _progressProvider?.updateCheckpoint(_config.nextKey);
      await _progressProvider?.saveCurrentProgress();
    }
    await _persistConfiguration();
  }

  Future<void> _saveCheckpointSnapshot(BigInt nextKey) async {
    await _progressProvider?.updateCheckpoint(nextKey);
    final now = DateTime.now();
    if (_lastCheckpointPersist != null &&
        now.difference(_lastCheckpointPersist!) < _checkpointPersistInterval) {
      return;
    }
    _lastCheckpointPersist = now;
    await _persistConfiguration();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(persistSession());
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_activateBackgroundSearch());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(BackgroundSearchService.stop());
    }
  }

  Future<void> _activateBackgroundSearch() async {
    await _initialization;
    if (!_config.isRunning && canStartSearch) {
      await startSearch();
    }
    if (_config.isRunning) {
      await WakelockPlus.enable();
      await BackgroundSearchService.start();
    }
  }

  /// Clear results
  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  /// Load challenge configuration
  void loadChallenge(WalletChallenge challenge) {
    if (_config.isRunning) return;

    // Clear existing targets
    _config = _config.copyWith(targets: [], challengeId: challenge.id);

    // Add challenge address
    addTarget(challenge.btcAddress);

    // Set keyspace
    setKeyspace(challenge.keyspace);

    // Set compression mode
    final compression =
        challenge.compressed
            ? PointCompressionType.compressed
            : PointCompressionType.uncompressed;
    setCompressionMode(compression);

    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(persistSession());
    unawaited(BackgroundSearchService.stop());
    _keyFinder?.dispose();
    super.dispose();
  }
}
