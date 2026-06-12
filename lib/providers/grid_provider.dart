import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/keyspace_grid.dart';

class GridProvider with ChangeNotifier {
  KeyspaceGrid? _currentGrid;
  static const String _storageKey = 'keyspace_grids';

  KeyspaceGrid? get currentGrid => _currentGrid;

  // Inicializa um novo grid para uma busca
  void initializeGrid({
    required BigInt rangeStart,
    required BigInt rangeEnd,
    String? challengeId,
  }) {
    _currentGrid = KeyspaceGrid(
      gridSize: 200,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    notifyListeners();
  }

  // Marca uma chave como testada
  void markKeyTested(BigInt key) {
    if (_currentGrid != null) {
      _currentGrid!.markKeyTested(key);

      // Atualiza a cada 1000 chaves para não sobrecarregar
      if (_currentGrid!.testedCount % 1000 == 0) {
        notifyListeners();
        _saveGrid();
      }
    }
  }

  // Salva o grid atual
  Future<void> _saveGrid() async {
    if (_currentGrid == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_currentGrid!.toJson());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('Erro ao salvar grid: $e');
    }
  }

  // Carrega o grid salvo
  Future<void> loadGrid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _currentGrid = KeyspaceGrid.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar grid: $e');
    }
  }

  // Reseta o grid atual
  void resetGrid() {
    _currentGrid?.reset();
    notifyListeners();
    _saveGrid();
  }

  // Limpa o grid
  void clearGrid() {
    _currentGrid = null;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_storageKey);
    });
  }
}
