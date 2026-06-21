import 'package:bit_finder/models/key_search_types.dart';
import 'package:bit_finder/providers/key_finder_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('last search configuration survives provider recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final expected = KeySearchConfig(
      startKey: BigInt.from(100),
      nextKey: BigInt.from(321),
      endKey: BigInt.from(1000),
      stride: BigInt.from(3),
      compression: PointCompressionType.both,
      searchMode: SearchMode.random,
      challengeId: 71,
      targets: [
        KeySearchTarget(
          address: '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
          hash160: [1, 2, 3, 4, 5],
        ),
      ],
    );

    final firstProvider = KeyFinderProvider();
    await firstProvider.initialized;
    firstProvider.updateConfig(expected);
    await firstProvider.persistSession();

    final secondProvider = KeyFinderProvider();
    await secondProvider.initialized;
    final restored = secondProvider.config;

    expect(restored.startKey, expected.startKey);
    expect(restored.nextKey, expected.nextKey);
    expect(restored.endKey, expected.endKey);
    expect(restored.stride, expected.stride);
    expect(restored.compression, expected.compression);
    expect(restored.searchMode, expected.searchMode);
    expect(restored.challengeId, expected.challengeId);
    expect(restored.targets, expected.targets);

    firstProvider.dispose();
    secondProvider.dispose();
  });
}
