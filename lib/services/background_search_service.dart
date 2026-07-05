import 'package:flutter/services.dart';

class BackgroundSearchService {
  static const MethodChannel _channel = MethodChannel('background_search');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } on MissingPluginException {
      // Non-Android platforms and widget tests do not provide this channel.
    } on PlatformException {
      // The search itself must keep running even if Android rejects the service.
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Non-Android platforms and widget tests do not provide this channel.
    } on PlatformException {
      // Nothing else to do; the service is best-effort process protection.
    }
  }
}
