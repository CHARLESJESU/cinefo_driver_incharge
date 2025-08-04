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
      // Mark attendance API call
      final response = await http.post(
        processSessionRequest, // Replace with your API URL
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode({
          "data": vcid,
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
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "attendanceStatus": "1",
          "location": location ?? "Unknown",
        }),
      );
      setState(() {
        first = false;
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final msg = result['message'];
        final err = result['errordescription'];
        print(result);
        print(vcid);

        if (msg == "Success") {
          updateDebugMessage("Attendance marked successfully.");
          setState(() => responseMessage = "Attendance marked successfully.");
        } else if (err == "NOT CLOSED") {
          updateDebugMessage("Previous session not closed.");
          setState(() => responseMessage = "Previous session not closed.");
        } else {
          updateDebugMessage("Attendance failed: $err");
          setState(() => responseMessage = "Attendance failed: $err");
        }
      } else {
        setState(
            () => responseMessage = "Server error: ${response.statusCode}");
        updateDebugMessage("Server error: ${response.statusCode}");
      }
    } catch (e) {
    } finally {
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

  // Future<void> _syncOfflineData() async {
  //   // Get the current location
  //   Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  //   final connectivity = await Connectivity().checkConnectivity();
  //   if (connectivity == ConnectivityResult.none) {
  //     updateDebugMessage("No internet connection, skipping sync.");
  //     return; // Wait until there is a network
  //   }

  //   updateDebugMessage(
  //       "Internet connected, attempting to sync offline data...");

  //   // Retrieve offline stored NFC data
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> storedList = prefs.getStringList("offline_attendance") ?? [];

  //   List<String> updatedList = [];

  //   for (String jsonData in storedList) {
  //     try {
  //       Map<String, dynamic> data = jsonDecode(jsonData);

  //       // Log the data to be sent to the server
  //       print("Syncing data: $data");

  //       // Make the API call to mark attendance
  //       final response = await http.post(
  //         processSessionRequest, // Your API URL
  //         headers: {
  //           'Content-Type': 'application/json; charset=UTF-8',
  //           'VMETID':
  //               "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
  //           'VSID': loginresponsebody?['vsid']?.toString() ?? "",
  //         },
  //         body: jsonEncode({
  //           "data": data['vcid'],
  //           "callsheetid": callsheetid.toString(),
  //           "projectid": projectId.toString(),
  //           "latitude": position.latitude.toString(),
  //           "longitude": position.longitude.toString(),
  //           "attendanceStatus": "2",
  //           "location": location ?? "Unknown",
  //         }),
  //       );

  //       // Log the server response
  //       print("Server response: ${response.body}");

  //       if (response.statusCode == 200) {
  //         final result = jsonDecode(response.body);
  //         final msg = result['message'];
  //         final err = result['errordescription'];
  //         print(result);

  //         if (msg == "Success") {
  //           updateDebugMessage("Attendance marked successfully.");
  //         } else if (err == "NOT CLOSED") {
  //           updateDebugMessage("Previous session not closed.");
  //         } else {
  //           updateDebugMessage("Attendance failed: $err");
  //         }
  //       } else {
  //         updateDebugMessage("Server error: ${response.statusCode}");
  //       }
  //     } catch (e) {
  //       updateDebugMessage("Attendance error: $e");
  //     } finally {
  //       setState(() => _isloading = false);
  //     }
  //   }

  //   // Store the remaining failed items back
  //   await prefs.setStringList("offline_attendance", updatedList);
  // }

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
          // Text(
          //   isNfcDisabled
          //       ? "Please enable NFC from settings to continue."
          //       : "Attendance posted successfully. Validation in process.",
          //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          //   textAlign: TextAlign.center,
          // ),
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
