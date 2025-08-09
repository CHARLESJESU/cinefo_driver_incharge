import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:production/Screens/Attendance/intime.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/variables.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

String transformVcidToImageUrl(String vcid) {
  final transformedVcid = vcid
      .replaceAll('/', '_')
      .replaceAll('=', '-')
      .replaceAll('+', '-')
      .replaceAll('#', '-');
  return 'https://vfs.vframework.in/Upload/vcard/Image/$transformedVcid.png';
}

void showResultDialogi(
  BuildContext context,
  String message,
  VoidCallback onDismissed,
  String vcid,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _CountdownDialog(
        message: message,
        onDismissed: onDismissed,
        vcid: vcid,
      );
    },
  );
}

class _CountdownDialog extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;
  final String vcid;

  const _CountdownDialog({
    Key? key,
    required this.message,
    required this.onDismissed,
    required this.vcid,
  }) : super(key: key);

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  Future<void> saveIntimeToSQLite(Map<String, dynamic> data) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(path.join(dbPath, 'production_login.db'));
    // Drop the old table if it exists to ensure schema is correct

    await db.execute('''
      CREATE TABLE IF NOT EXISTS intime (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        designation TEXT,
        code TEXT,
        unionName TEXT,
        vcid TEXT,
        marked_at TEXT,
        latitude TEXT,
        longitude TEXT,
        location TEXT
      )
    ''');
    await db.insert('intime', data);
    await db.close();
  }

  String? latitude, longitude, location;
  Position? _currentPosition;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  bool _isloading = false;
  bool _attendanceMarked = false;
  String debugMessage = '';
  int _secondsLeft = 2;
  Timer? _timer;
  bool first = false;
  String responseMessage = "";

  void updateDebugMessage(String msg) {
    if (!mounted) return;
    setState(() {
      debugMessage = msg;
    });
  }

  @override
  void initState() {
    super.initState();
    // _syncOfflineData();
    _getCurrentLocation();
    if (widget.message != "Please Enable NFC From Settings") {
      _startCountdown();
      print('Passing vcid to dialog: $vcid');
    }
    if (widget.message != "Please Enable NFC From Settings") {
      markattendance(widget.vcid); // <-- auto mark attendance
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    updateDebugMessage("Checking location service...");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      updateDebugMessage("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        updateDebugMessage("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      updateDebugMessage("Location permission permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        _currentPosition = position;
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        location =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
      updateDebugMessage("Location fetched: $location");
    } catch (e) {
      updateDebugMessage("Error fetching location: $e");
    }
  }

  Future<void> markattendance(String vcid) async {
    setState(() {
      first = true;
    });
    if (_attendanceMarked) return;
    setState(() => _isloading = true);
    _attendanceMarked = true;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("markattendance called with vcid: $vcid");

      // 1. Prepare the data to save
      Map<String, dynamic> intimeData = {
        'name': '',
        'designation': '',
        'code': '',
        'unionName': '',
        'vcid': vcid,
        'marked_at': DateTime.now().toIso8601String(),
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'location': location ?? "Unknown",
      };
      final lines = widget.message.split('\n');
      for (final line in lines) {
        if (line.startsWith('Name:'))
          intimeData['name'] = line.replaceFirst('Name:', '').trim();
        if (line.startsWith('Designation:'))
          intimeData['designation'] =
              line.replaceFirst('Designation:', '').trim();
        if (line.startsWith('Code:'))
          intimeData['code'] = line.replaceFirst('Code:', '').trim();
        if (line.startsWith('Union Name:'))
          intimeData['unionName'] = line.replaceFirst('Union Name:', '').trim();
      }

      // 2. Save to SQLite first
      await saveIntimeToSQLite(intimeData);

      // 3. Fetch the just-saved row (latest by marked_at)
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));
      final List<Map<String, dynamic>> rows = await db.query(
        'intime',
        orderBy: 'marked_at DESC',
        limit: 1,
      );
      await db.close();

      if (rows.isNotEmpty) {
        final row = rows.first;

        // 4. Prepare the requestBody from the row
        final requestBody = jsonEncode({
          "data": row['vcid'],
          "callsheetid": productionTypeId == 3 ? 0 : callsheetid,
          "projectid": productionTypeId == 3 ? selectedProjectId : projectId,
          "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
          "doubing": {
            "mainCharacter": 0,
            "smallCharacter": 0,
            "bitCharacter": 0,
            "singlebitCharacter": 0,
            "group": 0,
            "fight": 0,
            "singlebitCharacterOtherLanguage": 0,
            "mainCharacterOtherLanguage": 0,
            "smallCharacterOtherLanguage": 0,
            "bitCharacterOtherLanguage": 0,
            "groupOtherLanguage": 0,
            "fightOtherLanguage": 0,
            "voicetest": 0,
            "correction": 0,
            "leadRole": 0,
            "secondLeadRole": 0,
            "leadRoleOtherLanguage": 0,
            "secondLeadRoleOtherLanguage": 0
          },
          "latitude": row['latitude'],
          "longitude": row['longitude'],
          "attendanceStatus": "1",
          "location": row['location'],
        });

        // 5. POST to API
        final response = await http.post(
          processSessionRequest,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'VMETID':
                "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
            'VSID': loginresponsebody?['vsid']?.toString() ?? "",
          },
          body: requestBody,
        );

        setState(() {
          first = false;
        });
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final msg = result['message'];
          final err = result['errordescription'];
          print(result);
          print(row['vcid']);

          if (msg == "Success") {
            updateDebugMessage("Attendance marked successfully.");
            setState(() => responseMessage = "Attendance marked successfully.");
          } else {
            updateDebugMessage("Attendance failed: $err");
            setState(() => responseMessage = "Attendance failed: $err");
          }
        } else {
          setState(
              () => responseMessage = "Server error: ${response.statusCode}");
          updateDebugMessage("Server error: ${response.statusCode}");
          print(requestBody);
          print(loginresponsebody?['vsid']);
        }
      }
    } catch (e) {
      print('Error in markattendance: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isloading = false);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_secondsLeft == 0) {
        _timer?.cancel();
        await markattendance(widget.vcid);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => NFCNotifier(),
              child: IntimeScreen(),
            ),
          ),
        );
        widget.onDismissed();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = transformVcidToImageUrl(widget.vcid);
    final isNfcDisabled = widget.message == "Please Enable NFC From Settings";

    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNfcDisabled)
            ClipOval(
              child: widget.vcid.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person,
                            size: 60, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 10),
          Text(
            responseMessage.isNotEmpty ? responseMessage : widget.message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (_isloading)
            const CircularProgressIndicator(
              color: Colors.black,
            ),
        ],
      ),
    );
  }
}
