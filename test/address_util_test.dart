import 'package:bit_finder/utils/address_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bitcoin address vectors', () {
    test('private key 1 produces the known compressed address', () {
      expect(
        AddressUtil.privateKeyToAddress(BigInt.one),
        '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
      );
    });

    test('private key 1 produces the known uncompressed address', () {
      expect(
        AddressUtil.privateKeyToAddress(BigInt.one, compressed: false),
        '1EHNa6Q4Jz2uvNExL497mE43ikXhwF6kZm',
      );
    });

    test('address decoding returns the known HASH160', () {
      expect(
        AddressUtil.addressToHash160('1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH'),
        [
          0x75,
          0x1e,
          0x76,
          0xe8,
          0x19,
          0x91,
          0x96,
          0xd4,
          0x54,
          0x94,
          0x1c,
          0x45,
          0xd1,
          0xb3,
          0xa3,
          0x23,
          0xf1,
          0x43,
          0x3b,
          0xd6,
        ],
      );
    });
  });
}
