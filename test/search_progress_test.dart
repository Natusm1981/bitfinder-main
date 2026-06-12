import 'package:bit_finder/models/search_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('markRangeTested marks every block crossed by a batch', () {
    final progress = SearchProgress(
      keyspaceId: 'range',
      startKey: BigInt.zero,
      endKey: BigInt.from(999),
      totalBlocks: 10,
    );

    final updated = progress.markRangeTested(
      BigInt.from(150),
      BigInt.from(449),
    );

    expect(updated.testedBlocks, {1, 2, 3, 4});
  });
}
