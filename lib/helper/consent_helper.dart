import 'package:flutter/services.dart';

class ConsentHelper {
  static const MethodChannel _channel = MethodChannel('com.app.bqfreshdriver/consent');

  static Future<bool> hasAccepted() async {
    try {
      final bool result = await _channel.invokeMethod('hasAccepted');
      return result;
    } catch (_) {
      return false;
    }
  }
}
