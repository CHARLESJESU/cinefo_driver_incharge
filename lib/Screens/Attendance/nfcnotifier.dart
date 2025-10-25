import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
// shared_preferences import removed (not used here)
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

  /// Start an NFC session and perform the requested [nfcOperation].
  ///
  /// Optional [onTag] callback is invoked with the discovered [NfcTag]
  /// before the notifier parses/decrypts it. This allows callers to extract
  /// raw UID bytes (or other metadata) while still reusing the notifier's
  /// parsing logic.
  Future<void> startNFCOperation(
      {required NFCOperation nfcOperation,
      String dataType = "",
      void Function(NfcTag tag)? onTag}) async {
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
        NfcManager.instance.startSession(
            pollingOptions: {NfcPollingOption.iso14443},
            onDiscovered: (NfcTag nfcTag) async {
              try {
                // Give caller a chance to inspect the raw tag (UID, etc.)
                if (onTag != null) {
                  try {
                    onTag(nfcTag);
                  } catch (e) {
                    // Swallow errors in the caller-provided callback to
                    // avoid breaking the notifier's flow.
                    print('Error in onTag callback: $e');
                  }
                }

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

      // Treat tag.data as dynamic and only access map keys when it's a Map.
      final dynamic raw = (tag as dynamic).data;

      // Check NDEF data first (more reliable)
      if (raw is Map && raw.containsKey('ndef') && raw['ndef'] != null) {
        final ndefData = raw['ndef'];
        if (ndefData is Map &&
            ndefData['cachedMessage'] != null &&
            ndefData['cachedMessage'] is Map &&
            ndefData['cachedMessage']['records'] != null &&
            (ndefData['cachedMessage']['records'] is List) &&
            ndefData['cachedMessage']['records'].isNotEmpty) {
          final record = ndefData['cachedMessage']['records'][0];
          final payload = (record is Map) ? record['payload'] : null;
          if (payload != null) {
            try {
              // Normalize to List<int>/Uint8List if possible
              final List<int> payloadList = List<int>.from(payload);

              // Try NDEF Text record parse (status byte + language code)
              if (payloadList.isNotEmpty) {
                int languageCodeLength = payloadList[0] & 0x3F;
                if (languageCodeLength + 1 < payloadList.length) {
                  decodedText = String.fromCharCodes(
                      payloadList.sublist(languageCodeLength + 1));
                  print(
                      'DEBUG: NDEF text parse extracted: ${decodedText.length > 20 ? decodedText.substring(0, 20) + '...' : decodedText}');
                }
              }

              // If NDEF text parse failed, try direct UTF-8 decode as fallback
              if (decodedText == null && payloadList.isNotEmpty) {
                try {
                  decodedText = String.fromCharCodes(payloadList);
                  print(
                      'DEBUG: NDEF fallback direct decode extracted: ${decodedText.length > 20 ? decodedText.substring(0, 20) + '...' : decodedText}');
                } catch (e) {
                  print('DEBUG: direct payload decode failed: $e');
                }
              }
            } catch (e) {
              print('DEBUG: failed to normalize NDEF payload: $e');
            }
          }
        }
      }

      // Fallback to Mifare Ultralight if NDEF failed
      if (decodedText == null &&
          raw is Map &&
          raw.containsKey('mifareultralight')) {
        final mifareData = raw['mifareultralight'];
        if (mifareData is Map && mifareData['data'] != null) {
          try {
            final dynamic dataListRaw = mifareData['data'];
            final List<int> dataList = List<int>.from(dataListRaw);
            if (dataList.isNotEmpty) {
              decodedText = String.fromCharCodes(dataList);
              print(
                  'DEBUG: Mifare data extracted: ${decodedText.length > 20 ? decodedText.substring(0, 20) + '...' : decodedText}');
            }
          } catch (e) {
            print('DEBUG: failed to parse mifare data: $e');
          }
        }
      }

      if (decodedText == null || decodedText.isEmpty) {
        print('DEBUG: No data found on NFC card — raw tag: $raw');
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

  /// Public wrapper to allow external callers to hand an [NfcTag] to this
  /// notifier for parsing/decryption. This simply forwards to the private
  /// [_readFromTag] and preserves the notifier behaviour (message/vcid).
  ///
  /// nfcUIDreader.dart
  Future<void> handleTag(NfcTag tag) async {
    await _readFromTag(tag: tag);
  }
}

enum NFCOperation { read }