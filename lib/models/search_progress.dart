import 'dart:convert';

/// Representa o progresso de busca em um keyspace dividido em blocos
class SearchProgress {
  final String keyspaceId; // Identificador único do keyspace (ex: "8:F")
  final BigInt startKey;
  final BigInt endKey;
  final BigInt nextKey;
  final int totalBlocks; // Total de blocos (ex: 40000 para grid 200x200)
  final Set<int> testedBlocks; // Índices dos blocos já testados
  final DateTime createdAt;
  final DateTime lastUpdated;

  SearchProgress({
    required this.keyspaceId,
    required this.startKey,
    required this.endKey,
    BigInt? nextKey,
    required this.totalBlocks,
    Set<int>? testedBlocks,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) : nextKey = nextKey ?? startKey,
       testedBlocks = testedBlocks ?? {},
       createdAt = createdAt ?? DateTime.now(),
       lastUpdated = lastUpdated ?? DateTime.now();

  /// Calcula o índice do bloco para uma chave específica
  int getBlockIndex(BigInt key) {
    if (key < startKey || key > endKey) return -1;

    final range = endKey - startKey;
    if (range == BigInt.zero) return 0;
    final keyOffset = key - startKey;
    final blockIndex =
        ((keyOffset * BigInt.from(totalBlocks)) ~/ range).toInt();

    return blockIndex.clamp(0, totalBlocks - 1);
  }

  /// Marca um bloco como testado
  SearchProgress markBlockTested(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= totalBlocks) return this;

    final newTested = Set<int>.from(testedBlocks)..add(blockIndex);
    return copyWith(testedBlocks: newTested, lastUpdated: DateTime.now());
  }

  /// Marca múltiplos blocos como testados
  SearchProgress markBlocksTested(Set<int> blocks) {
    final validBlocks = blocks.where((b) => b >= 0 && b < totalBlocks);
    final newTested = Set<int>.from(testedBlocks)..addAll(validBlocks);
    return copyWith(testedBlocks: newTested, lastUpdated: DateTime.now());
  }

  SearchProgress markRangeTested(BigInt firstKey, BigInt lastKey) {
    final first = getBlockIndex(firstKey);
    final last = getBlockIndex(lastKey);
    if (first < 0 || last < 0) return this;

    final from = first < last ? first : last;
    final to = first < last ? last : first;
    final newTested = Set<int>.from(testedBlocks);
    for (var block = from; block <= to; block++) {
      newTested.add(block);
    }
    if (newTested.length == testedBlocks.length) return this;
    return copyWith(testedBlocks: newTested, lastUpdated: DateTime.now());
  }

  SearchProgress updateCheckpoint(BigInt value) {
    final bounded = value < startKey ? startKey : value;
    if (bounded <= nextKey) return this;
    return copyWith(nextKey: bounded, lastUpdated: DateTime.now());
  }

  /// Calcula a porcentagem de progresso
  double get progressPercentage {
    if (totalBlocks == 0) return 0.0;
    return (testedBlocks.length / totalBlocks) * 100;
  }

  /// Verifica se um bloco foi testado
  bool isBlockTested(int blockIndex) {
    return testedBlocks.contains(blockIndex);
  }

  SearchProgress copyWith({
    String? keyspaceId,
    BigInt? startKey,
    BigInt? endKey,
    BigInt? nextKey,
    int? totalBlocks,
    Set<int>? testedBlocks,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return SearchProgress(
      keyspaceId: keyspaceId ?? this.keyspaceId,
      startKey: startKey ?? this.startKey,
      endKey: endKey ?? this.endKey,
      nextKey: nextKey ?? this.nextKey,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      testedBlocks: testedBlocks ?? this.testedBlocks,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyspaceId': keyspaceId,
      'startKey': startKey.toString(),
      'endKey': endKey.toString(),
      'nextKey': nextKey.toString(),
      'totalBlocks': totalBlocks,
      'testedBlocks': testedBlocks.toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SearchProgress.fromJson(Map<String, dynamic> json) {
    return SearchProgress(
      keyspaceId: json['keyspaceId'] as String,
      startKey: BigInt.parse(json['startKey'] as String),
      endKey: BigInt.parse(json['endKey'] as String),
      nextKey: BigInt.parse(
        (json['nextKey'] as String?) ?? json['startKey'] as String,
      ),
      totalBlocks: json['totalBlocks'] as int,
      testedBlocks:
          (json['testedBlocks'] as List<dynamic>).map((e) => e as int).toSet(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SearchProgress.fromJsonString(String jsonString) {
    return SearchProgress.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
