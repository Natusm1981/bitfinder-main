import 'dart:math';

class KeyspaceGrid {
  final int gridSize; // 200x200 = 40,000 blocos
  final BigInt rangeStart;
  final BigInt rangeEnd;
  final BigInt blockSize; // Quantas chaves por bloco
  final List<bool> testedBlocks; // true = testado (vermelho)

  KeyspaceGrid({
    required this.gridSize,
    required this.rangeStart,
    required this.rangeEnd,
  }) : blockSize = (rangeEnd - rangeStart) ~/ BigInt.from(gridSize * gridSize),
       testedBlocks = List.filled(gridSize * gridSize, false);

  // Marca um bloco como testado baseado na chave
  void markKeyTested(BigInt key) {
    final blockIndex = _getBlockIndex(key);
    if (blockIndex >= 0 && blockIndex < testedBlocks.length) {
      testedBlocks[blockIndex] = true;
    }
  }

  // Calcula o índice do bloco baseado na chave
  int _getBlockIndex(BigInt key) {
    if (key < rangeStart || key > rangeEnd) return -1;

    final offset = key - rangeStart;
    final totalBlocks = BigInt.from(gridSize * gridSize);
    final totalRange = rangeEnd - rangeStart;

    if (totalRange == BigInt.zero) return 0;

    final blockIndex = (offset * totalBlocks) ~/ totalRange;
    return min(blockIndex.toInt(), testedBlocks.length - 1);
  }

  // Retorna a porcentagem de blocos testados
  double get progress {
    final tested = testedBlocks.where((b) => b).length;
    return tested / testedBlocks.length;
  }

  // Retorna quantos blocos foram testados
  int get testedCount => testedBlocks.where((b) => b).length;

  // Serialização para persistência
  Map<String, dynamic> toJson() {
    return {
      'gridSize': gridSize,
      'rangeStart': rangeStart.toString(),
      'rangeEnd': rangeEnd.toString(),
      'testedBlocks': testedBlocks.map((b) => b ? 1 : 0).toList(),
    };
  }

  factory KeyspaceGrid.fromJson(Map<String, dynamic> json) {
    final grid = KeyspaceGrid(
      gridSize: json['gridSize'] as int,
      rangeStart: BigInt.parse(json['rangeStart'] as String),
      rangeEnd: BigInt.parse(json['rangeEnd'] as String),
    );

    final blocks = (json['testedBlocks'] as List).cast<int>();
    for (int i = 0; i < blocks.length && i < grid.testedBlocks.length; i++) {
      grid.testedBlocks[i] = blocks[i] == 1;
    }

    return grid;
  }

  // Reseta o grid
  void reset() {
    for (int i = 0; i < testedBlocks.length; i++) {
      testedBlocks[i] = false;
    }
  }
}
