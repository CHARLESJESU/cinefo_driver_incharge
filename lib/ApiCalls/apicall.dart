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

Future<Map<String, dynamic>> decryptapi({
  required String encryptdata,
  required String uiddata,
  required String vsid,
}) async {
  try {
    final payload = {"data": encryptdata};
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'lHEiVtuLv8SFG0kxOydaeOm0OdIIZ9HGIYj4yxNL1AvGbTwX4GOxGwTe9EWnT4gIYGsegd6oxl3gRpQWJQDvvBzZ3DCehjDUCxKgXd5LiGgCRiKAhvpINP08iBxuQldbTVuIxdzV1X0RQJvUZ/cxh3mesg1gx9gWlHZ2mvZAxIPjdpZFY7HCyY058DD+uQGMAc5MpKs21MCQF2jTHI11y1EYoWoYqCH+2/Tf/bIeFtRwGM8keGaXrSShsskWKEXcS4t4jNRV3ch1/t/QPjcbFU4Lqg6GU35234pJmDHCLs5vDxCV2G7Ro7j8YZZkJMDc6xo39fRBT1YjL8tZ9sJ3ZQ==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print('🚗 Decrypt API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 Decrypt API Response Status: ${payload}');
    print('🚗 Decrypts API Response Body: ${tripstatusresponse.body}');

    if (tripstatusresponse.statusCode == 200) {
      try {
        final responseBody = jsonDecode(tripstatusresponse.body);
        final vcid = responseBody['responseData']['vcid'];
        return {
          'statusCode': tripstatusresponse.statusCode,
          'body': tripstatusresponse.body,
          'vcid': vcid,
          'success': true,
        };
      } catch (parseError) {
        print('❌ Error parsing response: $parseError');
        return {
          'statusCode': tripstatusresponse.statusCode,
          'body': tripstatusresponse.body,
          'vcid': null,
          'success': true,
        };
      }
    } else {
      return {
        'statusCode': tripstatusresponse.statusCode,
        'body': tripstatusresponse.body,
        'vcid': null,
        'success': false,
      };
    }
  } catch (e) {
    print('❌ Error in decryptapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'vcid': null,
      'success': false,
    };
  }
}

Future<Map<String, dynamic>> datacollectionapi({
  required int vcid,
  required String rfid,
  required String vsid,
}) async {
  try {
    // Convert rfid from string to numerical type
    print('🔄 Converting RFID: $rfid');
    dynamic rfidNumeric;

    try {
      // First, try parsing as decimal (most common case for numeric strings)
      if (rfid.contains(':') || rfid.contains(' ')) {
        // If it contains separators, treat as hex
        String cleanRfid = rfid.replaceAll(':', '').replaceAll(' ', '');
        print('🔄 Cleaned hex RFID: $cleanRfid');
        rfidNumeric = BigInt.parse(cleanRfid, radix: 16);
        print('✅ Converted hex to BigInt: $rfidNumeric');

        // Try to convert to int if it fits
        if (rfidNumeric <= BigInt.from(0x7FFFFFFFFFFFFFFF)) {
          rfidNumeric = rfidNumeric.toInt();
          print('✅ Converted BigInt to int: $rfidNumeric');
        }
      } else {
        // Try parsing as decimal first
        rfidNumeric = BigInt.parse(rfid);
        print('✅ Parsed as decimal BigInt: $rfidNumeric');

        // Try to convert to int if it fits
        if (rfidNumeric <= BigInt.from(0x7FFFFFFFFFFFFFFF)) {
          rfidNumeric = rfidNumeric.toInt();
          print('✅ Converted BigInt to int: $rfidNumeric');
        }
      }
    } catch (parseError) {
      print(
          '⚠️ Could not parse RFID as number, keeping as string: $parseError');
      // Keep as string if conversion fails
      rfidNumeric = rfid;
    }

    final payload = {"vcid": vcid, "rfid": rfidNumeric};
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'cEaZFUbJTVPh4nn1q/OkOGnG7bxNbYO6J5u3eZbobZBDeLCyCVHe1D+ey6YNiy7HsWoceFbDts95o4VD7iwZ5VbIyfJd/9Wx6FS0eE5P+jxAh/MpyArcp8u5lM5qL8VAxiWzTNHns6quPcCsgB1jeMiFuhQozs0e5/tdHHDe2SQqtqQCfghKswFN9g+vElZ1wy1VRzbRQOHU16+CzxxKrRKbbczcJGNKZqbLk9ggw3fVcR2KYVHPRJWJ7E4GdvGWHTsotxbY9ZxlkdN6pasna9fMmIWf+TuLsKUphiNUEql/YsGRgu8U+YZRREMXjQcGlfysVb4BZzwdkV/8UfJ5jQ==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 datacollection API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 datacollection API Response Status: ${payload}');
    print('🚗 datacollection API Response Body: ${tripstatusresponse.body}');

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

Future<Map<String, dynamic>> lookupcallsheetapi({
  required int projectid,
  required String vsid,
}) async {
  try {
    final payload = {"projectid": projectid, "statusid": 1};
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'RxvjE+jpr7/hdMwDmyDIz5+FC3qCCTJfmFVMypvuabzCRU/uge/pTo80n0qeb1J+XPjQ/JulyZ/5ufuiPOEQ9xm84PHIeHYz3dXvNCuuyFYO1Vfpq4B79KHm5kEbv5M3YvEn7YSUoetwT0mnNMUJUB1zwDNoOxCk7MQ7+71CXlphHDn/O5Nx1klD0Pc/LlDdZmwV2WcKWRvNgvlllG3eAVuVO8A4ng0mR14Rr/lfJfK0wxH7xu/9UShGk5529kKcRYtndqTr4CgCozRTInR1cIUbkKoeCCbdykcuVmEY8h23UatlRLGUsD9FJXRioRmOo9hKOgtk9FxC1qoJhV+x+g==',
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
