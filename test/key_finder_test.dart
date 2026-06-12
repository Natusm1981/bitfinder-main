import 'dart:async';

import 'package:bit_finder/models/key_search_types.dart';
import 'package:bit_finder/services/key_finder.dart';
import 'package:bit_finder/utils/address_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dart fallback finds a known puzzle key and stops', () async {
    final address = '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH';
    final hash = AddressUtil.addressToHash160(address);
    final config = KeySearchConfig(
      startKey: BigInt.one,
      nextKey: BigInt.one,
      endKey: BigInt.from(4),
      numThreads: 2,
      targets: [
        KeySearchTarget(
          address: address,
          hash160: [
            for (var i = 0; i < hash.length; i += 4)
              (hash[i] << 24) |
                  (hash[i + 1] << 16) |
                  (hash[i + 2] << 8) |
                  hash[i + 3],
          ],
        ),
      ],
    );
    final finder = KeyFinder(config);
    final result = Completer<KeySearchResult>();
    finder.onResult = (value) {
      if (!result.isCompleted) result.complete(value);
      finder.stop();
    };
    finder.onError = result.completeError;

    await finder.start();
    final found = await result.future.timeout(const Duration(seconds: 10));

    expect(found.privateKey, BigInt.one);
    expect(found.address, address);
    finder.dispose();
  });

  test('finite search reports completion', () async {
    final address = '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH';
    final config = KeySearchConfig(
      startKey: BigInt.from(2),
      nextKey: BigInt.from(2),
      endKey: BigInt.from(5),
      numThreads: 2,
      targets: [
        KeySearchTarget(address: address, hash160: List<int>.filled(5, 0)),
      ],
    );
    final finder = KeyFinder(config);
    final completed = Completer<void>();
    finder.onCompleted = completed.complete;
    finder.onError = completed.completeError;

    await finder.start();
    await completed.future.timeout(const Duration(seconds: 10));

    expect(finder.isRunning, isFalse);
    expect(config.nextKey, lessThanOrEqualTo(config.endKey + BigInt.one));
    finder.dispose();
  });
}
