import 'package:flutter/services.dart';

class NativeSearchBatchResult {
  final int checked;
  final BigInt nextKey;
  final BigInt? foundKey;
  final bool? foundCompressed;

  const NativeSearchBatchResult({
    required this.checked,
    required this.nextKey,
    required this.foundKey,
    required this.foundCompressed,
  });
}

class NativeThermalInfo {
  final int thermalStatus;
  final double? batteryTemperatureCelsius;

  const NativeThermalInfo({
    required this.thermalStatus,
    required this.batteryTemperatureCelsius,
  });
}

/// Thin, typed contract for the Android libsecp256k1 engine.
class NativeCryptoBinding {
  static const MethodChannel _channel = MethodChannel('native_crypto');
  static bool _isAvailable = false;
  static bool _initialized = false;

  static bool get isAvailable => _isAvailable;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _isAvailable = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _isAvailable = false;
    } on MissingPluginException {
      _isAvailable = false;
    }
  }

  static Future<NativeSearchBatchResult> searchBatch({
    required BigInt startKey,
    required int count,
    required BigInt stride,
    required int compressionMode,
    required List<Uint8List> targetHashes,
  }) async {
    if (!_isAvailable) {
      throw StateError('Native crypto engine is not available');
    }

    final raw = await _channel.invokeMapMethod<String, dynamic>('searchBatch', {
      'startKey': bigIntToBytes(startKey),
      'count': count,
      'stride': bigIntToBytes(stride),
      'compressionMode': compressionMode,
      'targetHashes': targetHashes,
    });
    if (raw == null) {
      throw StateError('Native crypto engine returned no result');
    }

    final nextKeyBytes = raw['nextKey'] as Uint8List;
    final foundKeyBytes = raw['foundKey'] as Uint8List?;
    return NativeSearchBatchResult(
      checked: raw['checked'] as int,
      nextKey: bytesToBigInt(nextKeyBytes),
      foundKey: foundKeyBytes == null ? null : bytesToBigInt(foundKeyBytes),
      foundCompressed: raw['foundCompressed'] as bool?,
    );
  }

  static Future<int> getThermalStatus() async {
    final info = await getThermalInfo();
    return info.thermalStatus;
  }

  static Future<NativeThermalInfo> getThermalInfo() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getThermalInfo',
      );
      if (raw == null) {
        return const NativeThermalInfo(
          thermalStatus: 0,
          batteryTemperatureCelsius: null,
        );
      }
      final temperature = raw['batteryTemperatureCelsius'];
      return NativeThermalInfo(
        thermalStatus: raw['thermalStatus'] as int? ?? 0,
        batteryTemperatureCelsius:
            temperature is num ? temperature.toDouble() : null,
      );
    } on PlatformException {
      return const NativeThermalInfo(
        thermalStatus: 0,
        batteryTemperatureCelsius: null,
      );
    } on MissingPluginException {
      return const NativeThermalInfo(
        thermalStatus: 0,
        batteryTemperatureCelsius: null,
      );
    }
  }

  static Uint8List bigIntToBytes(BigInt number, {int length = 32}) {
    if (number < BigInt.zero) {
      throw ArgumentError.value(number, 'number', 'Must not be negative');
    }
    final bytes = Uint8List(length);
    var remaining = number;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    if (remaining != BigInt.zero) {
      throw ArgumentError.value(
        number,
        'number',
        'Does not fit in $length bytes',
      );
    }
    return bytes;
  }

  static BigInt bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}
