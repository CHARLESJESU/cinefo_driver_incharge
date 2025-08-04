import 'package:flutter/services.dart';

class NfcHelper {
  static const MethodChannel _channel = MethodChannel('nfc_settings');

  static Future<void> openNfcSettings() async {
    try {
      await _channel.invokeMethod('openNfcSettings');
    } on PlatformException catch (e) {
      print("Failed to open NFC settings: ${e.message}");
    }
  }
}
