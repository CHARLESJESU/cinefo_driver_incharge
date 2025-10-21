import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:production/sessionexpired.dart';
import 'package:production/variables.dart';

class Inchargereport extends StatefulWidget {
  const Inchargereport({super.key});

  @override
  State<Inchargereport> createState() => _InchargereportState();
}

class _InchargereportState extends State<Inchargereport> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true; // State for loading indicator

  @override
  void initState() {
    super.initState();
    fetchVSIDFromLoginData().then((_) => fetchTrips());
  }

  Future<void> fetchVSIDFromLoginData() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase('${dbPath}/production_login.db');
      final List<Map<String, dynamic>> loginRows =
          await db.query('login_data', orderBy: 'id ASC', limit: 1);
      if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
        setState(() {
          vsid = loginRows.first['vsid'].toString();
          vmid = loginRows.first['vmid'];
          projectId = loginRows.first['project_id'];
        });
      }
      await db.close();
    } catch (e) {
      print('Error fetching VSID from login_data: $e');
    }
  }

  Future<void> fetchTrips() async {
    try {
      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'VLEkHaKT1r5ihTgJbuZy5vwbdtGYQJLle6wIMwDtxBpVjJ+vn9p017wnBS97W69vkLCn2d1blyRna1jSKdbR++uk/UWW4uVC4a1lVltIc1HczsDhM4KGgEaviZj+Bg+YLo3+3sweZbUGzppYGACaw5CZA8R4tVYFoJljffKEghP1ZyydO3v5MMb2pIzNLrKP+H6PklhbATik4btIKe73SSreUdJWxT3xUmNaak8gK8muLG5JDs7xZ4qLzCIwsIJL7sAR5L6Dcy2ZP52FXlDcaa02zuiyDtQYClkDejHdFcE3C6OlxNY3IzEcp80aY6nq9bVNPiGDZGWqyK4LfmrEZQ==',
          'VSID': vsid ?? "",
        },
        body: jsonEncode({"vmid": vmid, "statusid": 0}),
      );
      print('VMID: $vmid');

      // Check if widget is still mounted before processing response
      if (!mounted) return;

      if (response.statusCode == 200) {
        print("✅ Trip Response: ${response.body}");
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == "200" && data['responseData'] != null) {
          // Check mounted before calling setState
          if (mounted) {
            setState(() {
              trips = List<Map<String, dynamic>>.from(data['responseData']);
              isLoading = false;
            });
          }
        }
      } else {
        try {
          Map error = jsonDecode(response.body);
          print(error);

          // Check mounted before navigation and setState
          if (mounted) {
            if (error['errordescription'] == "Session Expired") {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Sessionexpired()));
            }
            setState(() {
              isLoading = false;
            });
          }
        } catch (e) {
          print("Error parsing error response: $e");
          // Check mounted before final setState
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error in fetchTrips(): $e");
      // Check mounted before error setState
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
              "Incharge Trip Reports",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  SizedBox(height: 30),
                  // Reports list section
                  if (isLoading)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2B5682),
                        ),
                      ),
                    )
                  else if (trips.isEmpty)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.car_rental,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No Trips Available",
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
                        // Trips Section
                        if (trips.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Trip List",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...trips.map((trip) => tripContainerBox(
                                context,
                                trip['tripid']?.toString() ?? "N/A",
                                trip['driverName'] ?? "N/A",
                                trip['tripdate']?.toString() ?? "N/A",
                                trip['location'] ?? "N/A",
                                trip['tripType'] ?? "N/A",
                              )),
                        ],
                      ],
                    ),
                  // Add extra bottom padding to prevent content from being hidden by navigation
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget tripContainerBox(BuildContext context, String tripId,
      String driverName, String tripDate, String location, String tripType) {
    String formattedDate = "Invalid Date";
    if (tripDate.isNotEmpty && tripDate != "N/A") {
      try {
        // Handle date format from response (e.g., 20251017)
        if (tripDate.length == 8) {
          String year = tripDate.substring(0, 4);
          String month = tripDate.substring(4, 6);
          String day = tripDate.substring(6, 8);
          DateTime parsedDate = DateTime.parse('$year-$month-$day');
          formattedDate = DateFormat("dd/MM/yyyy").format(parsedDate);
        } else {
          DateTime parsedDate = DateTime.parse(tripDate);
          formattedDate = DateFormat("dd/MM/yyyy").format(parsedDate);
        }
      } catch (e) {
        formattedDate = tripDate; // Use original if parsing fails
      }
    }

    return GestureDetector(
      onTap: () {
        // Print for debug
        print('Navigating to trip details with tripId: $tripId');
        // You can add navigation to trip details here if needed
        /*
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TripDetails(
                    tripId: tripId)));
        */
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A6FA5).withOpacity(0.1),
                    Color(0xFF2E4B73).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Trip ID: $tripId",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTripTypeColor(tripType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tripType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getTripTypeColor(tripType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Driver Name
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  "Driver: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    driverName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Location and Date
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF355E8C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTripTypeColor(String tripType) {
    switch (tripType.toLowerCase()) {
      case 'pickup':
      case 'pick up':
        return Colors.green;
      case 'drop':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
