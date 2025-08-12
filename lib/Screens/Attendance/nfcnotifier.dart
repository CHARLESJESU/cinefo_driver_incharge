import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:production/Screens/Attendance/encryption.dart';

class NFCNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void clearNfcData() {
    _message = "";
    _vcid = null;
    safeNotifyListeners();
  }

  bool _isProcessing = false;
  String _message = "";
  bool get isProcessing => _isProcessing;
  String get message => _message;
  String? decrypt1;
  bool _hasStarted = false;
  bool get hasStarted => _hasStarted;
  String? _vcid;
  String? get vcid => _vcid;

  Future<void> startNFCOperation(
      {required NFCOperation nfcOperation, String dataType = ""}) async {
    try {
      _isProcessing = true;
      _hasStarted = true;
      safeNotifyListeners();
      bool isAvail = await NfcManager.instance.isAvailable();
      if (isAvail) {
        if (nfcOperation == NFCOperation.read) {
          _message = "Scanning";
        }
        safeNotifyListeners();
        NfcManager.instance.startSession(onDiscovered: (NfcTag nfcTag) async {
          if (nfcOperation == NFCOperation.read) {
            await _readFromTag(tag: nfcTag);
          }
          _hasStarted = false;
          _isProcessing = false;
          safeNotifyListeners();
          await NfcManager.instance.stopSession();
        }, onError: (e) async {
          _hasStarted = false;
          _isProcessing = false;
          _message = e.toString();
          safeNotifyListeners();
        });
      } else {
        _isProcessing = false;
        _hasStarted = false;
        _message = "Please Enable NFC From Settings";
        safeNotifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _hasStarted = false;
      _message = e.toString();
      safeNotifyListeners();
    }
  }

  Future<void> _readFromTag({required NfcTag tag}) async {
    Map<String, dynamic> nfcData = {
      'nfca': tag.data['nfca'],
      'mifareultralight': tag.data['mifareultralight'],
      'ndef': tag.data['ndef']
    };

    String? decodedText;

    if (nfcData.containsKey('ndef') &&
        nfcData['ndef'] != null &&
        nfcData['ndef']['cachedMessage'] != null &&
        nfcData['ndef']['cachedMessage']['records'] != null &&
        nfcData['ndef']['cachedMessage']['records'].isNotEmpty &&
        nfcData['ndef']['cachedMessage']['records'][0]['payload'] != null) {
      List<int> payload =
          nfcData['ndef']['cachedMessage']['records'][0]['payload'];
      if (payload.isNotEmpty) {
        int languageCodeLength = payload[0] & 0x3F;
        decodedText =
            String.fromCharCodes(payload.sublist(languageCodeLength + 1));
      }
    } else if (nfcData.containsKey('mifareultralight') &&
        nfcData['mifareultralight'] != null &&
        nfcData['mifareultralight']['data'] != null) {
      List<int> mifareData = nfcData['mifareultralight']['data'];
      decodedText = String.fromCharCodes(mifareData);
    }

    _message = decodedText ?? "No Data Found";
    final String encryptedText = _message;

    final String encryptionKey = "VLABSOLUTION2023";
    final encrypt.IV iv = encrypt.IV.fromUtf8(encryptionKey);
    final decryptedText = decryptAES(encryptedText, encryptionKey, iv);
    Map<String, dynamic> data = jsonDecode(decryptedText);
    _vcid = data['vcid'];
    String formattedData = '''
Name: ${data["name"]}
Designation: ${data["designation"]}
Code: ${data["code"]}
Union Name: ${data["unionName"]}
''';
    print(vcid);
    _message = formattedData;
    safeNotifyListeners();
  }
}

enum NFCOperation { read }
