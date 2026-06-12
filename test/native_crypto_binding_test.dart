import 'package:bit_finder/utils/native_crypto_binding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('32-byte BigInt conversion round-trips', () {
    final values = [
      BigInt.zero,
      BigInt.one,
      BigInt.parse(
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140',
        radix: 16,
      ),
    ];

    for (final value in values) {
      expect(
        NativeCryptoBinding.bytesToBigInt(
          NativeCryptoBinding.bigIntToBytes(value),
        ),
        value,
      );
    }
  });
}
