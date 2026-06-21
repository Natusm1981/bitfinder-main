import 'package:bit_finder/models/search_progress.dart';
import 'package:bit_finder/providers/search_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('exact checkpoint survives provider recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final firstProvider = SearchProgressProvider();
    await firstProvider.startProgress(
      keyspaceId: 'resume-test',
      startKey: BigInt.one,
      endKey: BigInt.from(1000),
    );
    await firstProvider.updateCheckpoint(BigInt.from(321));
    await firstProvider.stopProgress();

    final secondProvider = SearchProgressProvider();
    final restored = await secondProvider.startProgress(
      keyspaceId: 'resume-test',
      startKey: BigInt.one,
      endKey: BigInt.from(1000),
    );

    expect(restored.nextKey, BigInt.from(321));
  });
}
