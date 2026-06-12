import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/key_search_types.dart';
import '../models/wallet_challenge.dart';
import '../services/key_finder.dart';
import '../utils/address_util.dart';
import 'history_provider.dart';
import 'search_progress_provider.dart';
import 'performance_provider.dart';

class KeyFinderProvider extends ChangeNotifier {
  HistoryProvider? _historyProvider;
  SearchProgressProvider? _progressProvider;
  PerformanceProvider? _performanceProvider;

  void setHistoryProvider(HistoryProvider provider) {
    _historyProvider = provider;
  }

  void setProgressProvider(SearchProgressProvider provider) {
    _progressProvider = provider;
  }

  void setPerformanceProvider(PerformanceProvider provider) {
    _performanceProvider = provider;
  }

  KeySearchConfig _config = KeySearchConfig();
  KeyFinder? _keyFinder;

  KeySearchStatus? _currentStatus;
  final List<KeySearchResult> _results = [];
  String? _errorMessage;

  bool get isRunning => _config.isRunning;
  KeySearchStatus? get currentStatus => _currentStatus;
  List<KeySearchResult> get results => List.unmodifiable(_results);
  String? get errorMessage => _errorMessage;
  KeySearchConfig get config => _config;

  /// Start the key search
  Future<void> startSearch() async {
    if (_config.isRunning) return;

    _errorMessage = null;

    // Ativar wakelock para manter tela ligada
    await WakelockPlus.enable();

    // Aplicar configurações de performance
    final numThreads = _performanceProvider?.numThreads ?? 1;
    _config = _config.copyWith(isRunning: true, numThreads: numThreads);
    notifyListeners();

    // Inicializar progresso apenas para modo Sequential
    if (_config.searchMode == SearchMode.sequential) {
      final keyspaceId =
          '${_config.startKey.toRadixString(16)}:${_config.endKey.toRadixString(16)}';
      await _progressProvider?.startProgress(
        keyspaceId: keyspaceId,
        startKey: _config.startKey,
        endKey: _config.endKey,
      );
    }

    _keyFinder = KeyFinder(_config);

    _keyFinder!.onStatus = (status) {
      _currentStatus = status;
      notifyListeners();
    };

    _keyFinder!.onProgress = (start, end) {
      if (_config.searchMode == SearchMode.sequential) {
        _progressProvider?.updateProgressRange(start, end);
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
      stopSearch(clearResults: true);
    };

    _keyFinder!.onCompleted = () {
      _config = _config.copyWith(isRunning: false);
      WakelockPlus.disable();
      _progressProvider?.stopProgress();
      notifyListeners();
    };

    await _keyFinder!.start();
  }

  /// Stop the key search
  void stopSearch({bool clearResults = true}) {
    _keyFinder?.stop();
    _keyFinder = null;
    _config = _config.copyWith(isRunning: false);

    // Desativar wakelock
    WakelockPlus.disable();
    _progressProvider?.stopProgress();

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
      );
      _currentStatus = null;
    }

    notifyListeners();
  }

  /// Update configuration
  void updateConfig(KeySearchConfig newConfig) {
    if (_config.isRunning) return;
    _config = newConfig;
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

      final newTargets = List<KeySearchTarget>.from(_config.targets)
        ..add(target);
      _config = _config.copyWith(targets: newTargets);
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
    notifyListeners();
  }

  /// Clear all targets
  void clearTargets() {
    if (_config.isRunning) return;

    _config = _config.copyWith(targets: [], challengeId: null);
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
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
    _keyFinder?.dispose();
    super.dispose();
  }
}
