// Fetch and print VSID from login_data table
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:production/variables.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

Future<void> printVSIDFromLoginData() async {
  try {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(path.join(dbPath, 'production_login.db'));
    final List<Map<String, dynamic>> loginRows =
        await db.query('login_data', orderBy: 'id ASC', limit: 1);
    if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
      print('Fetched VSID from login_data: \\${loginRows.first['vsid']}');
    } else {
      print('VSID not found in login_data table.');
    }
    await db.close();
  } catch (e) {
    print('Error fetching VSID from login_data: \\${e.toString()}');
  }
}

Future<void> createCallSheetFromOffline(
    Map<String, dynamic> callsheetData, BuildContext context) async {
  Map? createCallSheetresponse1;
  await printVSIDFromLoginData();
  final payload = {
    "name": callsheetData['callsheetname'] ?? '',
    "shiftId": callsheetData['shiftId'] ?? '',
    "latitude": callsheetData['latitude'] ?? '',
    "longitude": callsheetData['longitude'] ?? '',
    "projectId": projectId,
    "vmid": loginresult != null ? loginresult!['vmid'] : '',
    "vpid": loginresult != null ? loginresult!['vpid'] : '',
    "vpoid": loginresponsebody != null ? loginresponsebody!['vpoid'] : '',
    "vbpid": loginresponsebody != null ? loginresponsebody!['vbpid'] : '',
    "productionTypeid": productionTypeId,
    "location": callsheetData['location'] ?? '',
    "locationType": callsheetData['locationType'] ?? '',
    "locationTypeId": callsheetData['locationTypeId'] ?? '',
    "created_at": callsheetData['created_at'] ?? '',
  };
  final response = await http.post(
    processSessionRequest,
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'VMETID':
          'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
      'VSID': loginresponsebody?['vsid']?.toString() ?? "",
    },
    body: jsonEncode(payload),
  );

  print(response.body + "❌❌❌❌❌❌❌❌❌");
  print('Request Payload:');
  payload.forEach((key, value) {
    print('$key: $value');
  });
  print('VSID: ${loginresponsebody?['vsid']?.toString() ?? ""}');
  print('Response: ${response.body}');
  print('----------------------------------------');
  if (response.statusCode == 200) {
    print(response.body);
    createCallSheetresponse1 = json.decode(response.body);
    if (createCallSheetresponse1!['message'] == "Success") {
      // Update callsheetData with new callSheetNo and callSheetId from response
      final responseData = createCallSheetresponse1['responseData'];
      if (responseData != null) {
        // Update local SQLite
        try {
          var dbPath = await getDatabasesPath();
          var db = await openDatabase(dbPath + '/production_login.db');
          await db.update(
            'callsheetoffline',
            {
              'callSheetNo': responseData['callSheetNo'],
              'callSheetId': responseData['callSheetId'],
            },
            where: 'callSheetNo = ?',
            whereArgs: [callsheetData['callSheetNo']],
          );
          await db.close();
        } catch (e) {
          print('Error updating local callsheetoffline: ' + e.toString());
        }
      }
      showsuccessPopUp(context, "created call sheet successfully", () async {
        // After success, update all matching rows in intime table
        try {
          var dbPath = await getDatabasesPath();
          var db = await openDatabase(dbPath + '/production_login.db');

          print('Updating intime table:');
          print('Setting callsheetid to: ${responseData['callSheetId']}');
          print('Where callsheetid was: ${callsheetData['callSheetId']}');

          int updatedRows = await db.update(
            'intime',
            {
              'callsheetid': responseData['callSheetId'],
            },
            where: 'callsheetid = ?',
            whereArgs: [callsheetData['callSheetId']],
          );

          print('Updated $updatedRows rows in intime table');

          // Query the updated rows for syncing
          final List<Map<String, dynamic>> rows = await db.query(
            'intime',
            where: 'callsheetid = ?',
            whereArgs: [responseData['callSheetId']],
            orderBy: 'id ASC', // FIFO
          );

          for (final row in rows) {
            print('IntimeSyncService: Attempting to POST row id=${row['id']}');
            final requestBody = jsonEncode({
              "data": row['vcid'],
              "callsheetid": productionTypeId == 3 ? 0 : row['callsheetid'],
              "projectid":
                  productionTypeId == 3 ? selectedProjectId : projectId,
              "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
              "doubing": {},
              "latitude": row['latitude'],
              "longitude": row['longitude'],
              "attendanceStatus": row['attendance_status'],
              "location": row['location'],
            });

            // Get VSID from loginresponsebody or fallback to SQLite
            String? vsid = loginresponsebody?['vsid']?.toString();
            if (vsid == null || vsid.isEmpty) {
              try {
                final dbPath2 = await getDatabasesPath();
                final db2 = await openDatabase(
                    path.join(dbPath2, 'production_login.db'));
                final List<Map<String, dynamic>> loginRows =
                    await db2.query('login_data', orderBy: 'id ASC', limit: 1);
                if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
                  vsid = loginRows.first['vsid'].toString();
                }
                await db2.close();
              } catch (e) {
                print('Error fetching vsid from SQLite: $e');
              }
            }

            print("📊📊📊📊📊📊📊📊📊📊 VSID: $vsid");
            print("📊📊📊📊📊📊📊📊📊📊 Request Body: $processSessionRequest");
            final response = await http.post(
              processSessionRequest,
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'VMETID':
                    "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
                'VSID': vsid ?? "",
              },
              body: requestBody,
            );
            print(
                'IntimeSyncService: Sending POST request with body: $requestBody');
            // Print response body in chunks to handle large responses
            print('📊 Response body length: ${response.body.length}');
            if (response.body.isNotEmpty) {
              const int chunkSize = 800; // Print in chunks of 800 characters
              for (int i = 0; i < response.body.length; i += chunkSize) {
                int end = (i + chunkSize < response.body.length)
                    ? i + chunkSize
                    : response.body.length;
                print(
                    '📊 Chunk ${(i / chunkSize).floor() + 1}: ${response.body.substring(i, end)}');
              }
            } else {
              print('📊 Response body is empty');
            }

            print('IntimeSyncService: POST statusCode=${response.statusCode}');
            if (response.statusCode == 200 || response.statusCode == 1017) {
              print(
                  "IntimeSyncService: Deleting row id=${row['id']} after successful POST.");
              try {
                await db
                    .delete('intime', where: 'id = ?', whereArgs: [row['id']]);
                print("✅ Successfully deleted record id=${row['id']}");
              } catch (e) {
                print('❌ Error deleting record: $e');
              }
            } else if (response.statusCode == -1 ||
                response.statusCode == 400 ||
                response.statusCode == 500) {
              print(
                  "IntimeSyncService: Skipping row id=${row['id']} due to statusCode=${response.statusCode}. Data not deleted.");
              // Skip this row, do not delete, continue to next row
              continue;
            } else {
              print(
                  "IntimeSyncService: POST failed for row id=${row['id']}, stopping sync this cycle.");
              // Stop on first failure to preserve FIFO
              break;
            }
          }

          // After all attendance syncing is complete, close the call sheet
          final payload = {
            "callshettId": responseData['callSheetId'].toString(),
            "projectid": projectId,
            "shiftid": callsheetData['shiftId'],
            "callSheetStatusId": 3,
            "callSheetTime": DateFormat('HH:mm').format(DateTime.now())
          };

          final closeResponse = await http.post(
            processSessionRequest,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'VMETID':
                  'O/OtGf1bn9oD4GFpjRQ+Dec3uinWC4FwTdbrFCyiQDpN8SPMhon+ZaDHuLsnBHmfqGAjFXy6Gdjt6mQwzwqgfdWu+e+M8qwNk8gX9Ca3JxFQc++CDr8nd1Mrr57aHoLMlXprbFMxNy7ptfNoccm61r/9/lHCANMOt85n05HVfccknlopttLI5WM7DsNVU60/x5qylzlpXL24l8KwEFFPK1ky410+/uI3GkYi0l1u9DektKB/m1CINVbQ1Oob+FOW5lhNsBjqgpM/x1it89d7chbThdP5xlpygZsuG0AW4lakebF3ze497e16600v72fclgAZ3M21C0zUM4w9XIweMg==',
              'VSID': loginresponsebody?['vsid']?.toString() ?? "",
            },
            body: jsonEncode(<String, dynamic>{
              "callshettId": responseData['callSheetId'].toString(),
              "projectid": projectId,
              "shiftid": callsheetData['shiftId'],
              "callSheetStatusId": 3,
              "callSheetTime": DateFormat('HH:mm').format(DateTime.now())
            }),
          );
          print(payload);
          print('--- ✅ Call Sheet Closed Successfully ---');

          // Close the main database connection at the very end
          await db.close();
        } catch (e) {
          print('Error updating intime table: ' + e.toString());
        }
      });
    } else {
      showmessage(context, createCallSheetresponse1!['message'], "ok");
    }
  } else {
    showmessage(context, response.body, "ok");
  }
}

void showmessage(BuildContext context, String message, String ok) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void showsuccessPopUp(
    BuildContext context, String message, Future<void> Function() onDismissed) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(message),
          ),
        ],
      );
    },
  );

  Future.delayed(const Duration(seconds: 1), () async {
    Navigator.of(context).pop();
    print('Pop-up dismissed');
    await onDismissed();
  });
}
