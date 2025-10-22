import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:production/variables.dart';

// Function to update trip status
Future<Map<String, dynamic>> tripstatusapi({
  required int tripid,
  required String latitude,
  required String longitude,
  required String location,
  required String tripStatus,
  required int tripStatusid,
  required String vsid,
}) async {
  try {
    final payload = {
      "tripid": tripid,
      "latitude": latitude,
      "longtitude": longitude,
      "location": location,
      "tripStatus": tripStatus,
      "tripStatusid": tripStatusid,
    };
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'D0zhyy9lNlBY7/+KG2nRGWiU+qhMzvEApl3KhRQEqAx6gv6kjaWlFIXabxdIn4U5xbwI2Nm5cMWpfoc2tqiiGUhsFXxGW5x195YFaeFmyiuxTX/D1gn5DWNhJ/AW+5FTuYHwKvVN9GeK/aZ1+pzc4HZO4/6F+M+cX6Uro7Gwq0qF3n5v68yYO2E6EaHM9z/MbZ/JPZVMUmzLdPQqOTtuZS6w2yCvofPdnCXz1pBBWvl7++2CZRBaEsppCrZrPJ54zNBVqcgRIJ/v40KcNbmePMi/risJpamT6Tj9NLr0Z7b9rr/I3P3ERtPL4IiU6DMJUy9ZmJ/uViga5dcQdZrtEw==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 Trip Status API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 Trip Status API Response Status: ${payload}');
    print('🚗 Trip Status API Response Body: ${tripstatusresponse.body}');

    return {
      'statusCode': tripstatusresponse.statusCode,
      'body': tripstatusresponse.body,
      'success': tripstatusresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}
