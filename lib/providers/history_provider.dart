import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/key_search_types.dart';

class HistoryProvider extends ChangeNotifier {
  List<KeySearchResult> _history = [];

  List<KeySearchResult> get history => List.unmodifiable(_history);
  int get historyCount => _history.length;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('search_history') ?? [];

      _history =
          historyJson.map((jsonStr) {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            return KeySearchResult.fromJson(json);
          }).toList();

      // Sort by date (most recent first)
      _history.sort((a, b) => b.foundAt.compareTo(a.foundAt));

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> addToHistory(KeySearchResult result) async {
    try {
      // Check if already exists (avoid duplicates)
      final exists = _history.any(
        (item) =>
            item.address == result.address &&
            item.privateKey == result.privateKey,
      );

      if (!exists) {
        _history.insert(0, result); // Add to beginning

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final historyJson =
            _history.map((item) => jsonEncode(item.toJson())).toList();
        await prefs.setStringList('search_history', historyJson);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  Future<void> removeFromHistory(int index) async {
    try {
      if (index >= 0 && index < _history.length) {
        _history.removeAt(index);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final historyJson =
            _history.map((item) => jsonEncode(item.toJson())).toList();
        await prefs.setStringList('search_history', historyJson);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing from history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _history.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> exportHistory() async {
    // This method can be extended to export to file
    return;
  }
}
