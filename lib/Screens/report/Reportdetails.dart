import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/sessionexpired.dart';
import 'package:production/variables.dart';

class Reportdetails extends StatefulWidget {
  final String projectId;

  const Reportdetails({super.key, required this.projectId});

  @override
  State<Reportdetails> createState() => _ReportdetailsState();
}

class _ReportdetailsState extends State<Reportdetails> {
  List<AttendanceEntry> reportData = [];
  bool isLoading = true;

  Future<void> reportsscreen() async {
    try {
      final response = await http.post(
        processSessionRequest,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              "M1eZ6wLvBLCuSi4sdl6UoLJWnxZP5rJeLboXP93ukEsq/wVU4oxKSDUuD0ztNzeehHyKegLPgfFNJhMOm+sVeofs6HNJwTmSvrVpE2uIedFafjzruD4npza1tgz9gi0VYTaAU4gnqdtXEC4BCBjz6dGXV0BBdDWKpag1fZnOdB4+h2P9bv946GvG53+PsxFC30VEt5utBorby+AeL3xW6HjsK72KpZkE/YROUmdqwyjGapxu0NmAij2+zB9yYYvINMJa68aeBSEiaqWWKdJyqSL1nE3HhwmWJX/XCp+dNBRjtwgK5JZMIcsOl+ZX298fE0bghyXkq0lw69Kjmw2lmw==",
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode({
          "callsheetid": callsheetid.toString(),
          "projectId": widget.projectId,
        }),
      );
      if (response.statusCode == 200) {
        print(response.body);
        final decoded = jsonDecode(response.body);
        if (decoded['responseData'] != null) {
          List<AttendanceEntry> entries = (decoded['responseData'] as List)
              .map((e) => AttendanceEntry.fromJson(e))
              .toList();
          setState(() {
            reportData = entries;
            isLoading = false;
          });
        }
      } else {
      Map error = jsonDecode(response.body);
      print(error);
      if (error['errordescription'] == "Session Expired") {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Sessionexpired()));
      }
      setState(() {
        isLoading = false;
      });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    reportsscreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(left: 30, top: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 20),
                      Text(
                        "Report Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(228, 215, 248, 1),
                        border: Border.all(
                          color: Color.fromRGBO(131, 77, 218, 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            child: Text('In Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            child: Text('Out Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final entry = reportData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text(entry.memberName)),
                                Expanded(child: Text(entry.inTime ?? "--")),
                                Expanded(child: Text(entry.outTime ?? "--")),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceEntry {
  final String memberName;
  final String? inTime;
  final String? outTime;

  AttendanceEntry({
    required this.memberName,
    this.inTime,
    this.outTime,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      memberName: json['memberName'] ?? '',
      inTime: json['intime'],
      outTime: json['outTime'],
    );
  }
}
