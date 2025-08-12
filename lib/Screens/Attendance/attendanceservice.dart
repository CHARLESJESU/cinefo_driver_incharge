// // lib/services/attendance_service.dart

// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:production/variables.dart'; // where processSessionRequest, loginresponsebody are defined

// class AttendanceService {
//   static Future<void> markAttendance(String vcid) async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       final response = await http.post(
//         processSessionRequest,
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           'VMETID':
//               "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
//           'VSID': loginresponsebody?['vsid']?.toString() ?? "",
//         },
//         body: jsonEncode({
//           "data": vcid,
//           "callsheetid": productionTypeId == 3 ? 0 : callsheetid,
//           "projectid": productionTypeId == 3 ? projectid : projectid,
//           "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
//           "doubing": {},
//           "latitude": position.latitude.toString(),
//           "longitude": position.longitude.toString(),
//           "attendanceStatus": "1",
//           "location": "Unknown",
//         }),
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         if (result['message'] == 'Success') {
//           print("Synced VCID $vcid successfully.");
//         } else {
//           print("Server error: ${result['errordescription']}");
//         }
//       } else {
//         print("HTTP error ${response.statusCode} for VCID $vcid");
//       }
//     } catch (e) {
//       print("Exception during sync for VCID $vcid: $e");
//     }
//   }
//   //  static Future<void> markAttendanceOut(String vcid) async {
//   //   try {
//   //     Position position = await Geolocator.getCurrentPosition(
//   //       desiredAccuracy: LocationAccuracy.high,
//   //     );

//   //     final response = await http.post(
//   //       processSessionRequest,
//   //       headers: {
//   //         'Content-Type': 'application/json; charset=UTF-8',
//   //         'VMETID':
//   //             "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
//   //         'VSID': loginresponsebody?['vsid']?.toString() ?? "",
//   //       },
//   //       body: jsonEncode({
//   //         "data": vcid,
//   //         "callsheetid": productionTypeId == 3 ? 0 : callsheetid,
//   //         "projectid": productionTypeId == 3 ? projectid : projectid,
//   //         "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
//   //         "doubing": {},
//   //         "latitude": position.latitude.toString(),
//   //         "longitude": position.longitude.toString(),
//   //         "attendanceStatus": "1",
//   //         "location": "Unknown",
//   //       }),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final result = jsonDecode(response.body);
//   //       if (result['message'] == 'Success') {
//   //         print("Synced VCID $vcid successfully.");
//   //       } else {
//   //         print("Server error: ${result['errordescription']}");
//   //       }
//   //     } else {
//   //       print("HTTP error ${response.statusCode} for VCID $vcid");
//   //     }
//   //   } catch (e) {
//   //     print("Exception during sync for VCID $vcid: $e");
//   //   }
//   // }
// }
