import 'package:flutter/material.dart';
import 'package:production/Screens/configuration/unitmemberperson.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:production/variables.dart';
import 'dart:convert';

class Individualunitpage extends StatefulWidget {
  final Map<String, dynamic> callsheet;
  final String config_unitname;
  final int config_unitid;
  final int callsheetid;

  const Individualunitpage({
    super.key,
    required this.config_unitname,
    required this.callsheet,
    required this.config_unitid,
    required this.callsheetid,
  });

  @override
  State<Individualunitpage> createState() => _IndividualunitpageState();
}

class _IndividualunitpageState extends State<Individualunitpage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responseUnits = [];
  String _errorMessage = "";
  Future<void> fetchLoginDataAndMakeRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Get database path and open connection
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));

      // Fetch login_data
      final List<Map<String, dynamic>> loginRows = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (loginRows.isNotEmpty && loginRows.first['vpoid'] != null) {
        String? vsidValue = loginRows.first['vsid']?.toString();

        // Prepare payload
        final payload = {"unitId": config_unitid, "showid": 1};

        try {
          // Make HTTP POST request
          final response = await http
              .post(
                processSessionRequest,
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'VMETID': vmetid_fetch_config_unit_allowance,
                  'VSID': vsidValue ?? "",
                },
                body: jsonEncode(payload),
              )
              .timeout(Duration(seconds: 30));

          print('HTTP request completed successfully!');
          print('HTTP Response Status Code: ${response.statusCode}');
          print('Full HTTP Response Body: ${response.body}');

          // Parse the JSON response
          if (response.statusCode == 200) {
            try {
              final Map<String, dynamic> jsonResponse =
                  jsonDecode(response.body);
              if (jsonResponse.containsKey('responseData') &&
                  jsonResponse['responseData'] is List) {
                List<dynamic> responseDataList = jsonResponse['responseData'];
                List<Map<String, dynamic>> units = [];

                for (var item in responseDataList) {
                  if (item is Map<String, dynamic> &&
                      item.containsKey('callsheetConfigid') &&
                      item.containsKey('callsheetConfigName')) {
                    units.add({
                      'callsheetConfigid': item['callsheetConfigid'],
                      'callsheetConfigName': item['callsheetConfigName'],
                    });
                  }
                }

                setState(() {
                  _isLoading = false;
                  _responseUnits = units;
                });
              } else {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      "Invalid response format: responseData not found or not a list";
                });
              }
            } catch (jsonError) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Error parsing JSON: ${jsonError.toString()}";
              });
            }
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = "HTTP Error: Status Code ${response.statusCode}";
            });
          }
        } catch (httpError) {
          print('HTTP Request Error: ${httpError.toString()}');
          setState(() {
            _isLoading = false;
            _errorMessage = "HTTP Request Error: ${httpError.toString()}";
          });
        }
      } else {
        print('vpoid not found in login_data table.');
        setState(() {
          _isLoading = false;
          _errorMessage = "vpoid not found in login_data table.";
        });
      }

      await db.close();
    } catch (e) {
      print(
          'Error fetching login data or making HTTP request: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _errorMessage = "Database error: ${e.toString()}";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the function when the screen initializes
    fetchLoginDataAndMakeRequest();
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
            title: Text('${widget.config_unitname} Configuration',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Airbnb',
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Error',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Airbnb',
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontFamily: 'Airbnb',
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                fetchLoginDataAndMakeRequest();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Airbnb',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _responseUnits.isEmpty
                        ? Center(
                            child: Text(
                              'No units found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Airbnb',
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _responseUnits.length,
                                  itemBuilder: (context, index) {
                                    final unit = _responseUnits[index];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 15),
                                      child: Container(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            String selectedUnitName =
                                                unit['callsheetConfigName'] ??
                                                    'Unknown';

                                            // Set global variables
                                            config_unitname = selectedUnitName;

                                            print(
                                                'Selected Unit ID: ${unit['callsheetConfigid']}');

                                            // Navigate to individual unit page with parameters
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Unitmemberperson(
                                                  callsheet: widget.callsheet,
                                                  config_unitid:
                                                      unit['callsheetConfigid'],
                                                  unitid: widget.config_unitid,
                                                  config_unitname:
                                                      selectedUnitName,
                                                  callsheetid:
                                                      widget.callsheetid,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.withOpacity(0.8),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.all(20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                unit['callsheetConfigName'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Airbnb',
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'ID: ${unit['callsheetConfigid']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                  fontFamily: 'Airbnb',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    fetchLoginDataAndMakeRequest();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Refresh',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Airbnb',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ],
    );
  }
}
