import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Utility class for Bitcoin address operations
class AddressUtil {
  static final ECDomainParameters _secp256k1Params = ECDomainParameters(
    'secp256k1',
  );

  /// Verify if a string is a valid Bitcoin address
  static bool verifyAddress(String address) {
    if (address.isEmpty) return false;

    // Basic validation - should start with 1, 3, or bc1
    if (!address.startsWith('1') &&
        !address.startsWith('3') &&
        !address.startsWith('bc1')) {
      return false;
    }

    // Length check
    if (address.length < 26 || address.length > 62) {
      return false;
    }

    return true; // Simplified validation for demo
  }

  /// Convert a Bitcoin address to hash160
  static Uint8List addressToHash160(String address) {
    // This is a simplified implementation
    // In production, you'd need full Base58 decoding
    try {
      final decoded = _base58Decode(address);
      if (decoded.length < 25) {
        throw Exception('Invalid address length');
      }
      // Skip version byte and checksum (last 4 bytes)
      return Uint8List.fromList(decoded.sublist(1, 21));
    } catch (e) {
      throw Exception('Failed to decode address: $e');
    }
  }

  /// Convert hash160 to Bitcoin address
  static String hash160ToAddress(Uint8List hash160, {bool testnet = false}) {
    final version = testnet ? 0x6F : 0x00;
    final payload = Uint8List(21);
    payload[0] = version;
    payload.setRange(1, 21, hash160);

    final checksum = _hash256(payload).sublist(0, 4);
    final fullPayload = Uint8List(25);
    fullPayload.setRange(0, 21, payload);
    fullPayload.setRange(21, 25, checksum);

    return _base58Encode(fullPayload);
  }

  /// Generate public key from private key
  static ECPoint publicKeyFromPrivate(BigInt privateKey) {
    final d = privateKey;
    final point = _secp256k1Params.G * d;
    if (point == null) {
      throw Exception('Failed to generate public key');
    }
    return point;
  }

  /// Get compressed public key bytes
  static Uint8List compressedPublicKey(ECPoint point) {
    final x = point.x!.toBigInteger()!;
    final y = point.y!.toBigInteger()!;

    final prefix = y.isEven ? 0x02 : 0x03;
    final xBytes = _bigIntToBytes(x);

    final result = Uint8List(33);
    result[0] = prefix;
    result.setRange(1, 33, xBytes);

    return result;
  }

  /// Get uncompressed public key bytes
  static Uint8List uncompressedPublicKey(ECPoint point) {
    final x = point.x!.toBigInteger()!;
    final y = point.y!.toBigInteger()!;

    final xBytes = _bigIntToBytes(x);
    final yBytes = _bigIntToBytes(y);

    final result = Uint8List(65);
    result[0] = 0x04;
    result.setRange(1, 33, xBytes);
    result.setRange(33, 65, yBytes);

    return result;
  }

  /// Convert public key to hash160
  static Uint8List publicKeyToHash160(Uint8List publicKey) {
    // SHA-256 hash
    final sha256Hash = sha256.convert(publicKey).bytes;

    // RIPEMD-160 hash
    final ripemd160Digest = RIPEMD160Digest();
    final hash160 = Uint8List(20);
    ripemd160Digest.update(
      Uint8List.fromList(sha256Hash),
      0,
      sha256Hash.length,
    );
    ripemd160Digest.doFinal(hash160, 0);

    return hash160;
  }

  /// Generate Bitcoin address from private key
  static String privateKeyToAddress(
    BigInt privateKey, {
    bool compressed = true,
  }) {
    final publicKey = publicKeyFromPrivate(privateKey);
    return publicPointToAddress(publicKey, compressed: compressed);
  }

  /// Generate an address from an already computed public point.
  static String publicPointToAddress(
    ECPoint publicKey, {
    bool compressed = true,
  }) {
    final publicKeyBytes =
        compressed
            ? compressedPublicKey(publicKey)
            : uncompressedPublicKey(publicKey);
    final hash160 = publicKeyToHash160(publicKeyBytes);
    return hash160ToAddress(hash160);
  }

  // Helper methods
  static Uint8List _bigIntToBytes(BigInt number) {
    final bytes = Uint8List(32);
    var n = number;
    for (int i = 31; i >= 0; i--) {
      bytes[i] = (n & BigInt.from(0xff)).toInt();
      n = n >> 8;
    }
    return bytes;
  }

  static Uint8List _hash256(Uint8List data) {
    final hash1 = sha256.convert(data).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    return Uint8List.fromList(hash2);
  }

  static const String _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String _base58Encode(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    // Count leading zeros
    int zeros = 0;
    while (zeros < bytes.length && bytes[zeros] == 0) {
      zeros++;
    }

    // Convert to base58
    var num = BigInt.zero;
    for (var byte in bytes) {
      num = num * BigInt.from(256) + BigInt.from(byte);
    }

    var encoded = '';
    while (num > BigInt.zero) {
      final remainder = num % BigInt.from(58);
      num = num ~/ BigInt.from(58);
      encoded = _base58Alphabet[remainder.toInt()] + encoded;
    }

    // Add leading '1's for leading zeros
    encoded = '1' * zeros + encoded;

    return encoded;
  }

  static Uint8List _base58Decode(String input) {
    if (input.isEmpty) return Uint8List(0);

    // Count leading '1's
    int zeros = 0;
    while (zeros < input.length && input[zeros] == '1') {
      zeros++;
    }

    // Convert from base58
    var num = BigInt.zero;
    for (int i = 0; i < input.length; i++) {
      final digit = _base58Alphabet.indexOf(input[i]);
      if (digit < 0) {
        throw Exception('Invalid base58 character: ${input[i]}');
      }
      num = num * BigInt.from(58) + BigInt.from(digit);
    }

    // Convert to bytes
    final bytes = <int>[];
    while (num > BigInt.zero) {
      bytes.insert(0, (num % BigInt.from(256)).toInt());
      num = num ~/ BigInt.from(256);
    }

    // Add leading zeros
    final result = Uint8List(zeros + bytes.length);
    result.setRange(zeros, result.length, bytes);

    return result;
  }

  /// Convert private key to WIF (Wallet Import Format)
  static String privateKeyToWIF(
    BigInt privateKey, {
    bool compressed = true,
    bool testnet = false,
  }) {
    // Version byte: 0x80 for mainnet, 0xEF for testnet
    final version = testnet ? 0xEF : 0x80;

    // Private key as 32 bytes
    final privateKeyBytes = _bigIntToBytes(privateKey);

    // Build the payload
    final payloadLength = compressed ? 34 : 33;
    final payload = Uint8List(payloadLength);

    payload[0] = version;
    payload.setRange(1, 33, privateKeyBytes);

    // Add compression flag if needed
    if (compressed) {
      payload[33] = 0x01;
    }

    // Calculate checksum (double SHA-256, first 4 bytes)
    final checksum = _hash256(payload).sublist(0, 4);

    // Combine payload and checksum
    final fullPayload = Uint8List(payloadLength + 4);
    fullPayload.setRange(0, payloadLength, payload);
    fullPayload.setRange(payloadLength, payloadLength + 4, checksum);

    // Encode to Base58
    return _base58Encode(fullPayload);
  }
}

/// Utility class for parsing and formatting
class KeyspaceUtil {
  /// Parse keyspace string (START:END, START:+COUNT, etc.)
  static ({BigInt start, BigInt end}) parseKeyspace(String keyspace) {
    final parts = keyspace.split(':');

    BigInt start;
    BigInt end;

    if (parts.length == 1) {
      // Just START
      start = BigInt.parse(parts[0], radix: 16);
      end = _secp256k1N() - BigInt.one;
    } else if (parts.length == 2) {
      // START:END or START:+COUNT or :END or :+COUNT
      if (parts[0].isEmpty) {
        start = BigInt.one;
      } else {
        start = BigInt.parse(parts[0], radix: 16);
      }

      if (parts[1].startsWith('+')) {
        final count = BigInt.parse(parts[1].substring(1), radix: 16);
        end = start + count;
      } else {
        end = BigInt.parse(parts[1], radix: 16);
      }
    } else {
      throw Exception('Invalid keyspace format');
    }

    // Validate
    if (start <= BigInt.zero || start >= _secp256k1N()) {
      throw Exception('Start key out of range');
    }
    if (end <= BigInt.zero || end >= _secp256k1N()) {
      throw Exception('End key out of range');
    }
    if (start >= end) {
      throw Exception('Start key must be less than end key');
    }

    return (start: start, end: end);
  }

  static BigInt _secp256k1N() {
    return BigInt.parse(
      'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
      radix: 16,
    );
  }

  /// Format number with thousand separators
  static String formatThousands(BigInt number) {
    final str = number.toString();
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Format seconds to HH:MM:SS
  static String formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
