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
          try {
            if (nfcOperation == NFCOperation.read) {
              await _readFromTag(tag: nfcTag);
            }
          } catch (e) {
            print('Error in NFC discovery: $e');
            _message = "Error reading NFC: ${e.toString()}";
            safeNotifyListeners();
          } finally {
            _hasStarted = false;
            _isProcessing = false;
            safeNotifyListeners();
            // Stop session immediately after reading
            await NfcManager.instance.stopSession();
          }
        }, onError: (e) async {
          _hasStarted = false;
          _isProcessing = false;
          _message = e.toString();
          safeNotifyListeners();
          await NfcManager.instance.stopSession();
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
    try {
      print('DEBUG: Starting NFC tag reading...');
      String? decodedText;

      // Check NDEF data first (more reliable)
      if (tag.data.containsKey('ndef') && tag.data['ndef'] != null) {
        final ndefData = tag.data['ndef'];
        if (ndefData['cachedMessage'] != null &&
            ndefData['cachedMessage']['records'] != null &&
            ndefData['cachedMessage']['records'].isNotEmpty) {
          final payload = ndefData['cachedMessage']['records'][0]['payload'];
          if (payload != null && payload.isNotEmpty) {
            int languageCodeLength = payload[0] & 0x3F;
            decodedText =
                String.fromCharCodes(payload.sublist(languageCodeLength + 1));
            print(
                'DEBUG: NDEF data extracted: ${decodedText.length > 20 ? decodedText.substring(0, 20) + '...' : decodedText}');
          }
        }
      }

      // Fallback to Mifare Ultralight if NDEF failed
      if (decodedText == null && tag.data.containsKey('mifareultralight')) {
        final mifareData = tag.data['mifareultralight'];
        if (mifareData != null && mifareData['data'] != null) {
          List<int> data = mifareData['data'];
          decodedText = String.fromCharCodes(data);
          print(
              'DEBUG: Mifare data extracted: ${decodedText.length > 20 ? decodedText.substring(0, 20) + '...' : decodedText}');
        }
      }

      if (decodedText == null || decodedText.isEmpty) {
        print('DEBUG: No data found on NFC card');
        _message = "No Data Found";
        safeNotifyListeners();
        return;
      }

      print('DEBUG: Starting decryption...');
      // Decrypt and parse the data
      final String encryptionKey = "VLABSOLUTION2023";
      final encrypt.IV iv = encrypt.IV.fromUtf8(encryptionKey);
      final decryptedText = decryptAES(decodedText, encryptionKey, iv);
      print('DEBUG: Decryption completed');

      Map<String, dynamic> data = jsonDecode(decryptedText);
      _vcid = data['vcid'];
      print('DEBUG: VCID extracted: $_vcid');

      String formattedData = '''
Name: ${data["name"] ?? "N/A"}
Designation: ${data["designation"] ?? "N/A"}
Code: ${data["code"] ?? "N/A"}
Union Name: ${data["unionName"] ?? "N/A"}
''';

      print('DEBUG: Formatted data created');
      _message = formattedData;
      safeNotifyListeners();
      print('DEBUG: NFC reading completed successfully');
    } catch (e) {
      print('ERROR in _readFromTag: $e');
      _message = "Error reading card data: $e";
      _vcid = null;
      safeNotifyListeners();
    }
  }
}

enum NFCOperation { read }
