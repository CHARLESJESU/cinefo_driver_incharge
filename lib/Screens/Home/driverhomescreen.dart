import 'package:flutter/material.dart';
import 'package:production/Profile/profilesccreen.dart';
import 'package:production/Profile/changepassword.dart';
import 'package:production/Tesing/Sqlitelist.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/Screens/Login/loginscreen.dart';
import 'package:intl/intl.dart';
import 'package:production/ApiCalls/apicall.dart';
import 'package:production/Screens/Home/otpscreen.dart';
import 'package:production/variables.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class DriverMyhomescreen extends StatefulWidget {
  const DriverMyhomescreen({super.key});

  @override
  State<DriverMyhomescreen> createState() => _DriverMyHomescreenState();
}

class _DriverMyHomescreenState extends State<DriverMyhomescreen> {
  String? _deviceId;
  String? _managerName;
  String? _mobileNumber;
  String? _profileImage;
  String? vsid;
  int? vmid;
  List<Map<String, dynamic>> _tripsList = [];
  bool _isLoadingTrips = false;
  Set<int> _expandedTripIds = {}; // Track which trips are expanded

  @override
  void initState() {
    super.initState();
    _initializeData();
    // No RouteAware auto-refresh here (removed per request).
  }

  Future<void> _initializeData() async {
    await _fetchLoginAndCallsheetData();
    await _Drivertripdetails();
  }

  // Public refresh helper: re-fetch login data and trips and update UI.
  // This is used after init and after updating trip status so the UI
  // reflects the latest backend state.
  Future<void> _refreshPage() async {
    try {
      if (!mounted) return;
      // Optionally show loading state
      setState(() {
        _isLoadingTrips = true;
      });

      await _fetchLoginAndCallsheetData();
      await _Drivertripdetails();

      if (!mounted) return;
      setState(() {
        _isLoadingTrips = false;
      });
      print('✅ Page refresh completed');
    } catch (e) {
      print('❌ Error during page refresh: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
    }
  }

  Future<void> _Drivertripdetails() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTrips = true;
    });
final payload={"vmid": vmid, "statusid": 1};
    try {
      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'fWT+AmFtvfK9fjLYmJYL5Ca6co0oZ437saTMHvDaLc7xynuSH4QaJ1Eh63nWSAPxJ5dJEJjwwsWXV0eeBjCiy0jcfjFO7X+E2kgDeMeukCjobCBmlSBPo9eWr/M9kKyqhmJnkeEo1S0OHK+a3yTyMZBA7YGF1XvGnFK6OoBPl1aKJTicvjWH7bVMXfQZr265UGVES27B5mIDFtNgziq6uHoXdd2nBCY2UqdPT3+W+r2clpdj1LTty7SI/CCU/Cf1gJmtAMZQot7YiBqD6ijaXvTwKdrxoZ7rqZkmliRhLMkM8Kgth8LGXmXPZJQYMxGVaQ2DAQTmhP5FSOzcejE1yA==',
          'VSID': vsid ?? "",
        },
        body: jsonEncode(payload),
      );

      print('🔍 DRIVER TRIP DETAILS RESPONSE: ${response.statusCode}');
      print('🔍 DRIVER TRIP DETAILS RESPONSE: ${response.body}');
      print('🔍 DRIVER TRIP DETAILS RESPONSE: ${payload}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == "200" && data['responseData'] != null) {
          setState(() {
            _tripsList = List<Map<String, dynamic>>.from(data['responseData']);
            _isLoadingTrips = false;
          });
          print('✅ Successfully loaded ${_tripsList.length} trips');
        } else {
          setState(() {
            _tripsList = [];
            _isLoadingTrips = false;
          });
        }
      } else {
        setState(() {
          _tripsList = [];
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching trips: $e');
      if (mounted) {
        setState(() {
          _tripsList = [];
          _isLoadingTrips = false;
        });
      }
    }
  }

  Future<void> _fetchLoginAndCallsheetData() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      final db = await openDatabase(dbPath);
      // Fetch login_data
      final List<Map<String, dynamic>> loginMaps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (loginMaps.isNotEmpty && mounted) {
        setState(() {
          _deviceId = loginMaps.first['device_id']?.toString() ?? 'N/A';
          _managerName = loginMaps.first['manager_name']?.toString() ?? '';
          _mobileNumber = loginMaps.first['mobile_number']?.toString() ?? '';
          _profileImage = loginMaps.first['profile_image']?.toString();
          vsid = loginMaps.first['vsid']?.toString() ?? "";
          vmid = loginMaps.first['vmid'] ?? 0;
        });
      }
      // Ensure callsheetoffline table exists

      // Fetch callsheet data
    } catch (e) {
      setState(() {
        _deviceId = 'N/A';
        _managerName = '';
        _mobileNumber = '';
        _profileImage = null;
        vsid = "";
        vmid = 0;
      });
    }
  }

  // Method to perform logout - delete all login data and navigate to login screen
  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF2B5682),
                ),
                SizedBox(width: 20),
                Text('Logging out...'),
              ],
            ),
          );
        },
      );

      // Delete all data from login_data table
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      final db = await openDatabase(dbPath);

      // Delete all records from login_data table
      await db.delete('login_data');
      await db.close();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const Loginscreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');

      // Close loading dialog if it's open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF2B5682),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout(); // Call the logout method
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to format date
  String _formatTripDate(String dateStr) {
    try {
      if (dateStr.length == 8) {
        // Format: DDMMYYYY
        String day = dateStr.substring(6, 8);
        String month = dateStr.substring(4, 6);
        String year = dateStr.substring(0, 4);
        DateTime date = DateTime.parse('$year-$month-$day');
        return DateFormat('dd/MM/yyyy').format(date);
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  // Method to toggle trip expansion
  void _toggleTripExpansion(int tripId) {
    setState(() {
      if (_expandedTripIds.contains(tripId)) {
        _expandedTripIds.remove(tripId);
      } else {
        _expandedTripIds.add(tripId);
      }
    });
  }

  // Build trip card widget
  Widget _buildTripCard(Map<String, dynamic> trip) {
    final int tripId = trip['tripid'] ?? 0;
    final bool isExpanded = _expandedTripIds.contains(tripId);

    // Map tripstatusid to a display label and color. If tripstatusid
    // is not present, fall back to tripType string and existing color logic.


    final dynamic statusRaw = trip['tripstatusid'];
    final dynamic Triptype = trip['tripttypeid'];

    print(statusRaw);
    final int statusId = statusRaw;
    final int Triptypeid = Triptype;

    final String statusLabel = statusId == 1
        ? 'Assigned'
        : statusId == 2
            ? 'Arrived'
            : statusId == 3
        ? 'Trip Started'
        : 'N/A';
    final Color statusColor = statusId == 1
        ? Colors.orange
        : statusId == 2
            ? Colors.green
            : _getTripTypeColor('');

    // Decide button action label based on statusId. Compute this here
    // (outside of the widget tree) to avoid syntax errors.
    // If statusId == 3, the trip has already started and the button
    // should be disabled. Provide an appropriate label for that state.
    final bool isDisabled = statusId == 3;
    print(Triptypeid);
    print("mass");
    final String actionLabel = (Triptypeid==2)? 'End Trip':(statusId == 1)
        ? 'Arrived'
        : (statusId == 2 ? 'Start' :(isDisabled ? 'Started' : 'Arrived'));

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      ),
      child: Column(
        children: [
          // Main trip info (always visible)
          InkWell(
            onTap: () => _toggleTripExpansion(tripId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Show Trip ID and the trip type together so the trip type
                      // appears near the left side of the status label.
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Trip ID: ${trip['tripid'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2B5682),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            // Trip type label (e.g. "Pick Up") placed before the status
                            // container so it appears to the left of it.
                            if ((trip['tripType'] ?? '').toString().isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTripTypeColor(
                                          trip['tripType']?.toString() ?? '')
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  trip['tripType']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getTripTypeColor(
                                        trip['tripType']?.toString() ?? ''),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip['location'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        _formatTripDate(trip['tripdate']?.toString() ?? ''),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF355E8C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        trip['triptime'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF355E8C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Action Button - label depends on trip status
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      // Disable the button when isDisabled is true by setting
                      // onPressed to null. This also applies the disabled
                      // visual state automatically.
                      onPressed: isDisabled
                          ? null
                          : () {
                              // If the button label is 'Start', navigate to OTP screen
                              if (actionLabel.toLowerCase() == 'start') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Otpscreen(tripid: tripId)),
                                );
                              } else {
                                // Otherwise perform the existing arrived/update action
                                _handleArrivedButton(trip);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        // When disabled, use a greyed out background to
                        // reinforce the disabled state. Note: Flutter will
                        // override colors appropriately when onPressed is null
                        // but we provide a fallback color for consistency.
                        backgroundColor:
                            isDisabled ? Colors.grey.shade400 : Color(0xFF2B5682),
                        foregroundColor:
                            isDisabled ? Colors.grey.shade200 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: isDisabled ? 0 : 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              isDisabled ? Icons.block : Icons.check_circle,
                              size: 18),
                          SizedBox(width: 8),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded details (shown when expanded)
          if (isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 8),

                  Text(
                    'Contact Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2B5682),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Contact Person Name
                  _buildDetailRow(
                    Icons.person,
                    'Contact Person',
                    trip['contactpersonname'] ?? 'N/A',
                  ),
                  SizedBox(height: 8),

                  // Contact Person Mobile
                  _buildDetailRow(
                    Icons.phone,
                    'Contact Mobile',
                    trip['contactpersonmobile'] ?? 'N/A',
                  ),
                  SizedBox(height: 8),

                  // Alternate Contact Mobile
                  _buildDetailRow(
                    Icons.phone_android,
                    'Alternate Mobile',
                    trip['contactpersonalternatemobile'] ?? 'N/A',
                  ),
                  SizedBox(height: 8),

                  // Location URL
                  if (trip['locationurl'] != null &&
                      trip['locationurl'].toString().isNotEmpty)
                    _buildDetailRow(
                      Icons.link,
                      'Location URL',
                      trip['locationurl'] ?? 'N/A',
                      isLink: true,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isLink ? Colors.blue : Colors.grey[700],
              fontWeight: FontWeight.w500,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get trip type color
  Color _getTripTypeColor(String tripType) {
    switch (tripType.toLowerCase()) {
      case 'pick up':
      case 'pick-up':
      case 'pickup':
        return Colors.green;
      case 'drop':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Handle "Arrived" button click
  Future<void> _handleArrivedButton(Map<String, dynamic> trip) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFF2B5682)),
                SizedBox(width: 20),
                Text('Updating trip status...'),
              ],
            ),
          );
        },
      );

    // Build payload for trip status update.
    // Some APIs/name variations use different keys for trip type id, so
    // check several possibilities and accept both int and string values.
    final dynamic tripTypeIdRaw = trip['tripTypeId'] ?? trip['tripttypeid'] ?? trip['tripttypeId'] ?? trip['triptypeid'];
    final int? tripTypeId = tripTypeIdRaw is int
        ? tripTypeIdRaw
        : (tripTypeIdRaw is String ? int.tryParse(tripTypeIdRaw) : null);

    // Base payload fields
    final Map<String, dynamic> payload = {
      "tripid": trip['tripid'] ?? 0,
      "latitude": trip['latitude']?.toString() ?? '',
      "longitude": trip['longtitude']?.toString() ?? '',
      "location": trip['location']?.toString() ?? '',
    };

    // If tripTypeId == 1 (pickup) we mark Arrived (statusId 2), else End trip
    if (tripTypeId == 1) {
      payload.addAll({"tripStatus": "Arrived", "tripStatusid": 2});
    } else {
      payload.addAll({"tripStatus": "End trip", "tripStatusid": 4});
    }

    // Call API using named parameters (matches apicall.tripupdatedstatusapi signature)
    final result = await tripupdatedstatusapi(payload: payload, vsid: vsid ?? '');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show result
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Trip status updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Refresh the page (login & trips) so UI reflects latest state
          await _refreshPage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('❌ Failed to update trip status. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    // massa
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
          endDrawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2B5682),
                    Color(0xFF24426B),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2B5682),
                          Color(0xFF24426B),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        backgroundImage: AssetImage(cinefodriver),
                        radius: 40,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // View Profile
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'View Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Profilesccreen(),
                        ),
                      );
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Change Password
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Changepassword(),
                        ),
                      ); // Close drawer first
                    },
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Logout
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      _showLogoutDialog(context);
                    },
                  ),

                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'vSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sqlitelist(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/cinefo-logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _fetchLoginAndCallsheetData();
              await _Drivertripdetails();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: 100), // Add bottom padding to avoid navigation bar
                child: Column(
                  children: [
                    SizedBox(height: 20), // Space from AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: Color(0xFF355E8C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 7),
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey[300],
                              child: (_profileImage != null &&
                                      _profileImage!.isNotEmpty &&
                                      _profileImage!.toLowerCase() != 'unknown')
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImage!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Icon(Icons.person,
                                              size: 48,
                                              color: Colors.grey[600]);
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.person,
                                              size: 48,
                                              color: Colors.grey[600]);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.person,
                                      size: 48, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_managerName ?? '',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text("Driver",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                  Text(_mobileNumber ?? '',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space after profile container

                    // Trips Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Trips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Trips List
                          if (_isLoadingTrips)
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2B5682),
                                ),
                              ),
                            )
                          else if (_tripsList.isEmpty)
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
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
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _tripsList.length,
                              itemBuilder: (context, index) {
                                return _buildTripCard(_tripsList[index]);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
