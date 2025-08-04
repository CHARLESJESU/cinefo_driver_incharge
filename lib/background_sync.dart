import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:production/variables.dart';
import 'package:workmanager/workmanager.dart';

const syncTask = "syncOfflineAttendance";
String? latitude, longitude, location;

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTask) {
      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          return Future.value(true); // No internet
        }

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> storedList =
            prefs.getStringList("offline_attendance") ?? [];

        List<String> updatedList = [];

        for (String jsonData in storedList) {
          try {
            Map<String, dynamic> data = jsonDecode(jsonData);

            final response = await http.post(
              processSessionRequest,
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'VMETID':
                    "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
                'VSID': loginresponsebody?['vsid'] ?? "",
              },
              body: jsonEncode({
                "data": data['vcid'],
                "callsheetid": callsheetid.toString(),
                "projectid": projectId.toString(),
                "latitude": position.latitude.toString(),
                "longitude": position.longitude.toString(),
                "attendanceStatus": "1",
                "location": location.toString(),
              }),
            );
            if (response.statusCode != 200 ||
                jsonDecode(response.body)['message'] != "Success") {
              updatedList.add(jsonData);
            }
          } catch (_) {
            updatedList.add(jsonData); // keep unsynced ones
          }
        }

        await prefs.setStringList("offline_attendance", updatedList);
      } catch (_) {}
    }
    return Future.value(true);
  });
}
