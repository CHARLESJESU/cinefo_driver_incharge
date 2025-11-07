import 'package:flutter/material.dart';
import '../../datafetchfromsqlite.dart';
import '../../ApiCalls/apicall.dart';
import '../../variables.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Driverreport extends StatefulWidget {
  const Driverreport({super.key});

  @override
  State<Driverreport> createState() => _DriverreportState();
}

class _DriverreportState extends State<Driverreport> {
  bool _loading = true;
  String _status = 'Initializing...';
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _loading = true;
      _status = 'Fetching local login data...';
    });

    try {
      await fetchloginDataFromSqlite(); // populates vmid, unitid, productionTypeId globals

      setState(() {
        _status = 'Calling driver report API...';
      });

      // Safely provide vmid/unitid/vsid (fall back to 0 or empty string)
      final dynamic rawResult = await driverreportapi(vmid: vmid ?? 0, unitid: unitid ?? 0, vsid: vsid ?? " ");

      // driverreportapi returns a Map with keys ('statusCode','body','success')
      // or it could return a raw JSON string; normalize to a Map by parsing
      Map<String, dynamic> result = {};
      try {
        String? bodyString;
        if (rawResult is Map) {
          // If helper returned wrapper map, inspect 'body'
          if (rawResult.containsKey('body')) {
            final body = rawResult['body'];
            if (body is String) {
              bodyString = body;
            } else if (body is Map) {
              result = Map<String, dynamic>.from(body);
            } else {
              // e.g., already Map but with different structure
              result = Map<String, dynamic>.from(rawResult);
            }
          } else {
            result = Map<String, dynamic>.from(rawResult);
          }
        } else if (rawResult is String) {
          bodyString = rawResult;
        }

        if (bodyString != null) {
          try {
            final decoded = jsonDecode(bodyString);
            if (decoded is Map) result = Map<String, dynamic>.from(decoded);
          } catch (e) {
            // leave result empty on parse failure
          }
        }
      } catch (e) {
        result = {};
      }

      debugPrint('driverreportapi normalized result keys: ${result.keys}');

      if (result.containsKey('responseData') && result['responseData'] != null) {
        final List<dynamic> rd = result['responseData'];
        final parsed = rd.map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList();

        if (mounted) {
          setState(() {
            reports = parsed;
            _status = 'Loaded ${reports.length} report(s)';
          });
        }
      } else {
        setState(() {
          _status = 'No report data returned';
        });
      }
    } catch (e, st) {
      print('Error in _initData: $e\n$st');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatAttendanceDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final s = raw.toString().trim();

    // If it's exactly 8 digits like 20251030, treat as YYYYMMDD
    final eightDigits = RegExp(r'^\d{8}\$');
    if (eightDigits.hasMatch(s)) {
      final y = s.substring(0, 4);
      final m = s.substring(4, 6);
      final d = s.substring(6, 8);
      try {
        final dt = DateTime.parse('$y-$m-$d');
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (e) {
        return s;
      }
    }

    // Fallback: try parsing as ISO or other common formats
    final dt = DateTime.tryParse(s);
    if (dt != null) return DateFormat('dd/MM/yyyy').format(dt);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2B5682),
                Color(0xFF24426B),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,

            title: const Text(
              'Driver Report',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (_loading)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  else if (reports.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Report Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ...reports.map((r) => _reportCard(r)).toList(),
                      ],
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportCard(Map<String, dynamic> r) {
    final callsheetNo = r['callsheetNO']?.toString() ?? 'N/A';
    final projectName = r['projectName']?.toString() ?? 'N/A';
    final intime = r['intime']?.toString() ?? 'N/A';
    final outTime = r['outTime']?.toString() ?? 'N/A';
    final attendanceDate = _formatAttendanceDate(r['attendanceDate']);

    // Format display date as dd/MM/yyyy for UI
    String displayDate = attendanceDate;

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Color.fromRGBO(158, 158, 158, 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x1A4A6FA5), Color(0x1A2E4B73)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Callsheet: $callsheetNo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(43, 86, 130, 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      projectName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // In Time / Out Time / Attendance Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('In: $intime', style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 12)),
                const SizedBox(width: 16),
                Text('Out: $outTime', style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 12)),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
