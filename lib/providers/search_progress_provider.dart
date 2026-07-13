import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_progress.dart';

class SearchProgressProvider extends ChangeNotifier {
  static const _checkpointSaveInterval = Duration(seconds: 30);

  late final Future<void> _loadFuture;
  SearchProgress? _currentProgress;
  final Map<String, SearchProgress> _savedProgresses = {};
  int _changesSinceSave = 0;
  DateTime? _lastCheckpointSave;

  SearchProgress? get currentProgress => _currentProgress;
  Map<String, SearchProgress> get savedProgresses =>
      Map.unmodifiable(_savedProgresses);

  SearchProgressProvider() {
    _loadFuture = _loadProgresses();
  }

  /// Carrega os progressos salvos
  Future<void> _loadProgresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('progress_'));

      _savedProgresses.clear();
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final progress = SearchProgress.fromJsonString(jsonString);
            _savedProgresses[progress.keyspaceId] = progress;
          } catch (e) {
            debugPrint('Error loading progress $key: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progresses: $e');
    }
  }

  /// Inicia um novo progresso ou carrega existente
  Future<SearchProgress> startProgress({
    required String keyspaceId,
    required BigInt startKey,
    required BigInt endKey,
    int gridSize = 200,
  }) async {
    await _loadFuture;
    final totalBlocks = gridSize * gridSize;

    // Verifica se já existe progresso salvo para este keyspace
    if (_savedProgresses.containsKey(keyspaceId)) {
      _currentProgress = _savedProgresses[keyspaceId];
    } else {
      _currentProgress = SearchProgress(
        keyspaceId: keyspaceId,
        startKey: startKey,
        endKey: endKey,
        totalBlocks: totalBlocks,
      );
    }

    notifyListeners();
    return _currentProgress!;
  }

  /// Atualiza o progresso com uma chave testada
  Future<void> updateProgress(BigInt testedKey) async {
    if (_currentProgress == null) return;

    final blockIndex = _currentProgress!.getBlockIndex(testedKey);
    if (blockIndex < 0) return;

    // Só atualiza se o bloco ainda não foi testado
    if (!_currentProgress!.isBlockTested(blockIndex)) {
      _currentProgress = _currentProgress!.markBlockTested(blockIndex);
      notifyListeners();

      // Salva a cada 100 blocos testados para não sobrecarregar
      _changesSinceSave++;
      if (_changesSinceSave >= 100) {
        await _saveProgress();
      }
    }
  }

  Future<void> updateProgressRange(BigInt firstKey, BigInt lastKey) async {
    if (_currentProgress == null) return;
    final before = _currentProgress!.testedBlocks.length;
    final updated = _currentProgress!.markRangeTested(firstKey, lastKey);
    final added = updated.testedBlocks.length - before;
    if (added == 0) return;

    _currentProgress = updated;
    _changesSinceSave += added;
    notifyListeners();
    if (_changesSinceSave >= 100) {
      await _saveProgress();
    }
  }

  Future<void> updateCheckpoint(BigInt nextKey) async {
    if (_currentProgress == null) return;
    _currentProgress = _currentProgress!.updateCheckpoint(nextKey);

    final now = DateTime.now();
    if (_lastCheckpointSave == null ||
        now.difference(_lastCheckpointSave!) >= _checkpointSaveInterval) {
      _lastCheckpointSave = now;
      await _saveProgress();
    }
  }

  /// Atualiza múltiplos blocos de uma vez (otimização)
  Future<void> updateProgressBatch(Set<int> blockIndices) async {
    if (_currentProgress == null) return;

    _currentProgress = _currentProgress!.markBlocksTested(blockIndices);
    notifyListeners();
    await _saveProgress();
  }

  /// Salva o progresso atual
  Future<void> _saveProgress() async {
    if (_currentProgress == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progress_${_currentProgress!.keyspaceId}';
      await prefs.setString(key, _currentProgress!.toJsonString());

      _savedProgresses[_currentProgress!.keyspaceId] = _currentProgress!;
      _changesSinceSave = 0;
      _lastCheckpointSave = DateTime.now();
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  /// Para o progresso atual e salva
  Future<void> stopProgress() async {
    if (_currentProgress != null) {
      await _saveProgress();
    }
    _currentProgress = null;
    notifyListeners();
  }

  Future<void> saveCurrentProgress() => _saveProgress();

  /// Limpa o progresso de um keyspace específico
  Future<void> clearProgress(String keyspaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('progress_$keyspaceId');

      _savedProgresses.remove(keyspaceId);
      if (_currentProgress?.keyspaceId == keyspaceId) {
        _currentProgress = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing progress: $e');
    }
  }

  /// Limpa todos os progressos
  Future<void> clearAllProgresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('progress_'));

      for (final key in keys) {
        await prefs.remove(key);
      }

      _savedProgresses.clear();
      _currentProgress = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all progresses: $e');
    }
  }

  /// Carrega um progresso específico como atual
  void loadProgress(String keyspaceId) {
    if (_savedProgresses.containsKey(keyspaceId)) {
      _currentProgress = _savedProgresses[keyspaceId];
      notifyListeners();
    }
  }
}
