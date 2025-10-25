import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import '../../ApiCalls/apicall.dart';
import '../../variables.dart';

class NfcHomePage extends StatefulWidget {
  const NfcHomePage({super.key});

  @override
  State<NfcHomePage> createState() => _NfcHomePageState();
}

class _NfcHomePageState extends State<NfcHomePage> {
  String _status = 'Press "Start" and tap a tag';
  String? _uidHex;
  String? _uidDec;
  String? _rawData;
  bool _isSubmitting = false;

  bool _isAvailable = false;
  bool _sessionRunning = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      bool available = await NfcManager.instance.isAvailable();
      setState(() => _isAvailable = available);
    } catch (_) {
      setState(() => _isAvailable = false);
    }
  }

  String _bytesToHex(Uint8List bytes, {String separator = ':'}) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(separator);
  }

  String _bytesToDecLE(Uint8List bytes) {
    BigInt value = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      value |= (BigInt.from(bytes[i]) << (8 * i));
    }
    return value.toString();
  }

  String _bytesToDecLast9(Uint8List bytes) {
    final dec = _bytesToDecLE(bytes);
    if (dec.length <= 10) return dec.padLeft(10, '0');
    return dec.substring(dec.length - 10);
  }

  Uint8List? _findIdIn(dynamic node) {
    if (node == null) return null;

    if (node is Uint8List) {
      if (node.length >= 4 && node.length <= 16) return node;
    }

    if (node is List<int>) {
      final bytes = Uint8List.fromList(node);
      if (bytes.length >= 4 && bytes.length <= 16) return bytes;
    }

    if (node is Map) {
      for (final key in node.keys) {
        final value = node[key];
        final keyLower = key.toString().toLowerCase();
        if (keyLower.contains('id') || keyLower.contains('identifier')) {
          final found = _findIdIn(value);
          if (found != null) return found;
        }
      }
      for (final value in node.values) {
        final found = _findIdIn(value);
        if (found != null) return found;
      }
    }

    if (node is List) {
      for (final item in node) {
        final found = _findIdIn(item);
        if (found != null) return found;
      }
    }

    // Try common dynamic properties safely
    try {
      final dyn = node as dynamic;
      for (final prop in ['id', 'ID', 'identifier', 'tag', 'uid', 'UID']) {
        try {
          final val = _tryGetProp(dyn, prop);
          if (val != null) {
            final found = _findIdIn(val);
            if (found != null) return found;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  dynamic _tryGetProp(dynamic obj, String name) {
    if (obj == null) return null;
    try {
      if (obj is Map) {
        if (obj.containsKey(name)) return obj[name];
        final lower = name.toLowerCase();
        if (obj.containsKey(lower)) return obj[lower];
        return null;
      }
    } catch (_) {}

    try {
      final dyn = obj as dynamic;
      switch (name) {
        case 'id':
          return dyn.id;
        case 'ID':
          return dyn.ID;
        case 'identifier':
          return dyn.identifier;
        case 'tag':
          return dyn.tag;
        case 'uid':
          return dyn.uid;
        case 'UID':
          return dyn.UID;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Decode an NDEF Text record payload, stripping the status byte and
  /// language code (e.g. "en") and returning the decoded text. Returns
  /// null if the payload doesn't look like a text record.
  String? _decodeNdefText(Uint8List payload) {
    if (payload.isEmpty) return null;
    final status = payload[0];
    // status bits: bit7 = encoding (0 = UTF-8, 1 = UTF-16), bits 5..0 = lang length
    final isUtf16 = (status & 0x80) != 0;
    final langLen = status & 0x3F;
    if (payload.length <= 1 + langLen) return null;
    final textBytes = payload.sublist(1 + langLen);
    try {
      if (isUtf16) {
        return utf8.decode(
          textBytes,
        ); // attempting utf8 fallback for utf16 is hard; try utf8 first
      } else {
        return utf8.decode(textBytes);
      }
    } catch (_) {
      return null;
    }
  }

  /// (Removed long recursive string search to simplify code.)

  void _startSession() async {
    if (!_isAvailable) {
      setState(() => _status = 'NFC not available on this device');
      return;
    }

    setState(() {
      _status = 'Waiting for tag...';
      _uidHex = null;
      _uidDec = null;
      _rawData = null;
      _sessionRunning = true;
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          // First, try NDEF extraction (most large encrypted payloads are
          // stored in NDEF records). Use the nfc_manager_ndef wrapper to
          // access records if available.
          String? ndefPayload;
          try {
            final ndef = Ndef.from(tag);
            if (ndef != null) {
              // use dynamic to avoid tight typing on library internals
              final dynNdef = ndef as dynamic;
              final msg = dynNdef.cachedMessage;
              if (msg != null) {
                final records = msg.records as List<dynamic>?;
                if (records != null && records.isNotEmpty) {
                  final parts = <String>[];
                  for (final r in records) {
                    try {
                      final payload = r.payload as dynamic;
                      if (payload is Uint8List || payload is List<int>) {
                        final bytes = payload is Uint8List
                            ? payload
                            : Uint8List.fromList(payload as List<int>);
                        // Try decode as NDEF Text record (strip language code like 'en')
                        try {
                          final text =
                              _decodeNdefText(bytes) ?? utf8.decode(bytes);
                          if (text.trim().isNotEmpty) {
                            parts.add(text.trim());
                            continue;
                          }
                        } catch (_) {}
                        // Fallback to base64
                        parts.add(base64.encode(bytes));
                      } else if (payload is String) {
                        parts.add(payload);
                      } else {
                        parts.add(payload.toString());
                      }
                    } catch (_) {}
                  }
                  if (parts.isNotEmpty) ndefPayload = parts.join(' ');
                }
              }
            }
          } catch (_) {}

          // Capture a meaningful representation of tag.data. Some plugin
          // implementations return a platform object (TagPigeon) whose
          // toString() is just "Instance of 'TagPigeon'". Try to extract a
          // useful string: map -> pretty JSON, bytes -> base64, or search for
          // long strings (payloads) inside the structure.
          final dynamic tagData = (tag as dynamic).data;
          // prefer ndefPayload if found
          String tagDataRepr;
          try {
            if (tagData == null) {
              tagDataRepr = '';
            } else if (tagData is Map) {
              tagDataRepr = const JsonEncoder.withIndent('  ').convert(tagData);
            } else if (tagData is Uint8List) {
              tagDataRepr = base64.encode(tagData);
            } else if (tagData is List<int>) {
              tagDataRepr = base64.encode(Uint8List.fromList(tagData));
            } else if (tagData is String) {
              tagDataRepr = tagData;
            } else {
              tagDataRepr = tagData.toString();
            }
          } catch (_) {
            tagDataRepr = tagData?.toString() ?? '';
          }

          String raw = ndefPayload ??
              (tagDataRepr.isNotEmpty ? tagDataRepr : null) ??
              tag.toString();

          // Produce a full debug dump and print it to console (and save to
          // state so it's visible in-app). Keep this detailed for debugging.
          String dump;
          try {
            if (tagData is Map) {
              dump = const JsonEncoder.withIndent('  ').convert(tagData);
            } else if (tagData is Uint8List) {
              dump =
                  'Uint8List(len=${tagData.length}): ${base64.encode(tagData)}';
            } else if (tagData is List<int>) {
              final bytes = Uint8List.fromList(tagData);
              dump = 'List<int>(len=${bytes.length}): ${base64.encode(bytes)}';
            } else {
              dump = tagData.toString();
            }
          } catch (e) {
            dump = 'Error dumping tag.data: $e';
          }

          // Also include tag.toString() for completeness.
          final fullDump =
              'tag.toString(): ${tag.toString()}\n tag.data dump:\n$dump';
          // Print to console (debugPrint handles long messages better).
          debugPrint(fullDump, wrapWidth: 1200);

          // Attempt to find UID bytes as before
          final uidBytes = _findIdIn((tag as dynamic).data);

          if (uidBytes != null) {
            final hex = _bytesToHex(uidBytes);
            final dec = _bytesToDecLast9(uidBytes);
            setState(() {
              _uidHex = hex;
              _uidDec = dec;
              _rawData = raw;
              _status = 'Tag found — UID: $hex';
            });
          } else {
            // fallback: try some properties
            dynamic maybeId = _tryGetProp((tag as dynamic).data, 'id') ??
                _tryGetProp((tag as dynamic).data, 'ID') ??
                _tryGetProp((tag as dynamic).data, 'tag');
            final fallback = _findIdIn(maybeId);
            if (fallback != null) {
              final hex = _bytesToHex(fallback);
              final dec = _bytesToDecLast9(fallback);
              setState(() {
                _uidHex = hex;
                _uidDec = dec;
                _rawData = raw;
                _status = 'Tag found — UID: $hex';
              });
            } else {
              setState(() {
                _status = 'Tag found — raw data captured';
                _rawData = raw;
                _uidHex = null;
                _uidDec = null;
              });
            }
          }
        } catch (e) {
          setState(() {
            _status = 'Error reading tag: $e';
          });
        } finally {
          await NfcManager.instance.stopSession();
          setState(() => _sessionRunning = false);
        }
      },
    );
  }

  void _stopSession() async {
    await NfcManager.instance.stopSession();
    setState(() {
      _sessionRunning = false;
      _status = 'Session stopped';
    });
  }

  Future<void> _submitData() async {
    if (_rawData == null && _uidHex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No NFC data to submit. Please scan a tag first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call the decrypt API with all three parameters
      final result = await decryptapi(
        encryptdata: _rawData ?? '', // Raw NFC data
        uiddata: _uidDec ?? '', // UID in hex format
        vsid: vsid ?? '', // Using vsid from variables.dart
      );

      if (mounted) {
        if (result['success'] == true) {
          final vcid = result['vcid'];
          print('✅ VCID extracted: $vcid');

          // If vcid is available, call datacollectionapi
          if (vcid != null) {
            try {
              final dataCollectionResult = await datacollectionapi(
                vcid: vcid,
                rfid: _uidDec ?? '', // Using UID hex as RFID
                vsid: vsid ?? '', // Using vsid from variables.dart
              );

              if (dataCollectionResult['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Data collection successful!\nVCID: $vcid\nDecrypt Response: ${result['body']}\nData Collection Response: ${dataCollectionResult['body']}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
                print('✅ Data collection API successful');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Decrypt successful but data collection failed!\nVCID: $vcid\nData Collection Error: ${dataCollectionResult['body']}'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 4),
                  ),
                );
                print(
                    '❌ Data collection API failed: ${dataCollectionResult['body']}');
              }
            } catch (dataCollectionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Decrypt successful but data collection error!\nVCID: $vcid\nError: $dataCollectionError'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
              print('❌ Error in data collection API: $dataCollectionError');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Decrypt successful but no VCID found!\nResponse: ${result['body']}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${result['body']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    if (_sessionRunning) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC UID Reader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('NFC available: ${_isAvailable ? "Yes" : "No"}'),
            const SizedBox(height: 12),
            Text('Status: $_status'),
            const SizedBox(height: 12),
            if (_uidHex != null)
              SelectableText(
                'UID: $_uidHex',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_uidDec != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                'RFID number: $_uidDec',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: _rawData == null
                    ? const Text('Raw tag data will appear here')
                    : SingleChildScrollView(
                        child: SelectableText(
                          _rawData!,
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _sessionRunning ? null : _startSession,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _sessionRunning ? _stopSession : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_rawData != null || _uidHex != null) && !_isSubmitting
                        ? _submitData
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Submitting...'),
                        ],
                      )
                    : const Text(
                        'Submit to Decrypt API',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap the tag to the phone\'s NFC antenna area when it says "Waiting for tag...".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
