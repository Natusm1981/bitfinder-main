import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceProvider extends ChangeNotifier {
  int _numThreads = 1;
  late int _maxThreads;

  int get numThreads => _numThreads;
  int get maxThreads => _maxThreads;

  PerformanceProvider() {
    _maxThreads = Platform.numberOfProcessors;
    _loadSettings();
  }

  /// Retorna o número recomendado de threads (N-1)
  int get recommendedThreads => _maxThreads > 1 ? _maxThreads - 1 : 1;

  /// Carrega as configurações salvas
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Padrão: N-1 threads
      _numThreads = prefs.getInt('num_threads') ?? recommendedThreads;

      // Garantir que não exceda o máximo
      if (_numThreads > _maxThreads) {
        _numThreads = _maxThreads;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading performance settings: $e');
    }
  }

  /// Define o número de threads
  Future<void> setNumThreads(int threads) async {
    if (threads < 1 || threads > _maxThreads) return;

    _numThreads = threads;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('num_threads', threads);
    } catch (e) {
      debugPrint('Error saving num_threads: $e');
    }
  }

  /// Reseta para o padrão (N-1 threads recomendados)
  Future<void> resetToDefault() async {
    await setNumThreads(recommendedThreads);
  }

  /// Verifica se está usando todas as threads (pode travar)
  bool get isUsingMaxThreads => _numThreads == _maxThreads && _maxThreads > 1;
}
