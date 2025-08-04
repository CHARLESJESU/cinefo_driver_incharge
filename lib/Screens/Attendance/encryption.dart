import 'dart:convert';
import 'package:encrypt/encrypt.dart';

bool isBase64(String str) {
  try {
    base64Decode(str);
    return true;
  } catch (_) {
    return false;
  }
}

String decryptAES(String encryptedText, String encryptionKey, IV iv) {
  if (!isBase64(encryptedText)) {
    throw ArgumentError("Invalid base64 input for AES decryption.");
  }

  try {
    final key = Key.fromUtf8(encryptionKey);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  } catch (e) {
    throw ArgumentError("Decryption failed: ${e.toString()}");
  }
}
