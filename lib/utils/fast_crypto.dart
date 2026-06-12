import 'native_crypto_binding.dart';

/// Compatibility facade used by app startup and diagnostics.
class FastCrypto {
  static Future<void> initialize() => NativeCryptoBinding.initialize();

  static bool get isNativeAvailable => NativeCryptoBinding.isAvailable;
  static bool get isUsingNative => NativeCryptoBinding.isAvailable;

  static String getEngineName() {
    return isUsingNative ? 'libsecp256k1 (native)' : 'PointyCastle (Dart)';
  }

  static String getEngineIcon() => isUsingNative ? 'N' : 'D';
}
