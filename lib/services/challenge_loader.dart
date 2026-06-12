import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/wallet_challenge.dart';

class ChallengeLoader {
  static const String _assetPath = 'assets/wallet_challenges.json';

  /// Load wallet challenges from JSON asset
  static Future<WalletChallengeCollection> loadChallenges() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return WalletChallengeCollection.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load wallet challenges: $e');
    }
  }

  /// Get challenges filtered by solved status
  static Future<List<WalletChallenge>> getChallengesBySolvedStatus({
    required bool solved,
  }) async {
    final collection = await loadChallenges();
    return collection.challenges.where((c) => c.solved == solved).toList();
  }

  /// Get challenge by ID
  static Future<WalletChallenge?> getChallengeById(int id) async {
    final collection = await loadChallenges();
    try {
      return collection.challenges.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get challenges by difficulty range (bits)
  static Future<List<WalletChallenge>> getChallengesByBitsRange({
    required int minBits,
    required int maxBits,
  }) async {
    final collection = await loadChallenges();
    return collection.challenges
        .where((c) => c.bits >= minBits && c.bits <= maxBits)
        .toList();
  }
}
