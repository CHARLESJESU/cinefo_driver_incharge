import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/Screens/Home/colorcode.dart';
import 'package:production/variables.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Createtrip extends StatefulWidget {
  const Createtrip({super.key});

  @override
  State<Createtrip> createState() => _CreatetripState();
}

class _CreatetripState extends State<Createtrip> {
  bool screenLoading = false;
  // Database and login data
  Database? _database;
  Map<String, dynamic>? loginData;

  // Dummy data for dropdowns (replace with real data as needed)
  String tripType = 'Pick Up';
  List<String> driverList = []; // Will be populated from server
  List<String> filteredDriverList = []; // For search functionality
  List<Map<String, dynamic>> driverDataList = []; // Store complete driver data
  String? selectedDriver;
  String? selectedPerson;
  DateTime? selectedPickupDate; // Add pickup date
  TimeOfDay? selectedTime;
  // Location variables
  double? selectedLatitude;
  double? selectedLongitude;
  String? locationUrl;

  // Controllers for new fields
  final TextEditingController contactPersonNameController =
      TextEditingController();
  final TextEditingController contactPersonNoController =
      TextEditingController();
  final TextEditingController alternateContactNoController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController driverSearchController =
      TextEditingController(); // Search controller

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database connection
  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return await openDatabase(
      dbPath,
      version: 1,
    );
  }

  // Load login data from SQLite
  Future<void> _loadLoginData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        setState(() {
          loginData = maps.first;
        });
        print('✅ Login data loaded successfully');
        print('🔍 VSID: ${loginData!['vsid']}');
        print('🔍 VPOID: ${loginData!['vpoid']}');
        print('🔍 VBPID: ${loginData!['vbpid']}');
      } else {
        print('⚠️ No login data found');
      }
    } catch (e) {
      print('❌ Error loading login data: $e');
    }
  }

  // Load members when driver dropdown is clicked
  Future<void> _loadMembers() async {
    if (loginData == null) {
      print('⚠️ Login data not available');
      return;
    }

    // Prevent multiple simultaneous calls
    if (screenLoading) {
      print('⚠️ Already loading members, skipping request');
      return;
    }

    try {
      setState(() {
        screenLoading = true;
      });

      print('🔄 Starting member load request...');
      print(
          '🔍 Request data: vpoid=${loginData!['vpoid']}, vbpid=${loginData!['vbpid']}');

      final loadmemberResponse = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'jRguckopTAozCAYpGMJczcdkbq7rjgNYdQOq3Rfko53QuAg47CGLiSBfYVqiujVKHN5WknCnkksvr5bBJ+mtEHJCXFLgqxikobX+BnjBm7n/EtoNlQM10pgS00zReMFh4KfYDNvRFVEwcSewUP0DRJYjVTk0ZAgtH5otp8TkRZOsEYN++2qVsVI4e+A7cSDk1hhOYNkDCT6r5Pk0vC0RMnesgn49yJoUixGOUBpvVNwIo4fpZVrOxX69Z5XMdL/lXlfWJIXsK18da9d13BdYIC8jUYatbj3IoUpOpKW1GieyAQ+DH4XhcGutZ5WKz5+g5bu9CiOgLklW3ibQfywcLQ==',
          'VSID': loginData!['vsid']?.toString() ?? '',
        },
        body: jsonEncode(<String, dynamic>{
          "vpoid": loginData!['vpoid'] ?? 0,
          "vbpid": loginData!['vbpid'] ?? 0,
        }),
      );

      print(
          '🚗 Load members HTTP Response Status: ${loadmemberResponse.statusCode}');

      // Print response body in chunks for better debugging
      final responseBodyString = loadmemberResponse.body;
      print('🚗 Response body length: ${responseBodyString.length}');
      const chunkSize = 500;
      for (int i = 0; i < responseBodyString.length; i += chunkSize) {
        final end = (i + chunkSize < responseBodyString.length)
            ? i + chunkSize
            : responseBodyString.length;
        final chunk = responseBodyString.substring(i, end);
        print('🚗 Response chunk ${(i ~/ chunkSize) + 1}: $chunk');
      }

      if (loadmemberResponse.statusCode == 200) {
        try {
          final responseBody = json.decode(loadmemberResponse.body);
          print('✅ Parsed JSON successfully');
          print('🔍 Response type: ${responseBody.runtimeType}');

          // Debug response structure
          if (responseBody is Map<String, dynamic>) {
            print('🔍 Response keys: ${responseBody.keys.toList()}');
            responseBody.forEach((key, value) {
              print(
                  '🔍 Key "$key": ${value.runtimeType} - ${value.toString().length > 100 ? value.toString().substring(0, 100) + "..." : value}');
            });
          }

          // Process the response and update driverList with server data
          if (responseBody != null) {
            List<String> newDriverList = [];
            List<Map<String, dynamic>> newDriverDataList = [];

            // Check if responseBody is a List (array of drivers)
            if (responseBody is List) {
              print(
                  '📋 Processing direct array response with ${responseBody.length} items');
              for (int i = 0; i < responseBody.length; i++) {
                var driver = responseBody[i];
                print('🔍 Driver $i: $driver');
                if (driver is Map<String, dynamic>) {
                  String fname = driver['fname']?.toString() ?? 'Unknown';
                  String code = driver['code']?.toString() ?? 'N/A';
                  String mobilenumber =
                      driver['mobileNumber']?.toString() ?? 'N/A';

                  // Store complete driver data
                  newDriverDataList.add({
                    'fname': fname,
                    'code': code,
                    'mobileNumber': mobilenumber,
                    'vmid': driver['vmid'] ?? 0,
                    'vcid': driver['vcid'] ?? 0,
                  });

                  // Format: fname-code-mobilenumber
                  String driverDisplay = '$fname-$code-$mobilenumber';
                  newDriverList.add(driverDisplay);
                  print('✅ Added driver: $driverDisplay');
                }
              }
            }
            // Check if responseBody has nested data
            else if (responseBody is Map<String, dynamic>) {
              print('📋 Processing nested object response');
              // Try different possible keys for the driver data
              List<dynamic>? driversData;

              if (responseBody['drivers'] != null) {
                driversData = responseBody['drivers'];
                print('🔍 Found drivers in "drivers" key');
              } else if (responseBody['data'] != null) {
                driversData = responseBody['data'];
                print('🔍 Found drivers in "data" key');
              } else if (responseBody['responseData'] != null) {
                driversData = responseBody['responseData'];
                print('🔍 Found drivers in "responseData" key');
              } else if (responseBody['result'] != null) {
                driversData = responseBody['result'];
                print('🔍 Found drivers in "result" key');
              }

              if (driversData != null) {
                print(
                    '📋 Processing ${driversData.length} drivers from nested data');
                for (int i = 0; i < driversData.length; i++) {
                  var driver = driversData[i];
                  print('🔍 Driver $i: $driver');
                  if (driver is Map<String, dynamic>) {
                    String fname = driver['fname']?.toString() ?? 'Unknown';
                    String code = driver['code']?.toString() ?? 'N/A';
                    String mobilenumber =
                        driver['mobileNumber']?.toString() ?? 'N/A';

                    // Store complete driver data
                    newDriverDataList.add({
                      'fname': fname,
                      'code': code,
                      'mobileNumber': mobilenumber,
                      'vmid': driver['vmid'] ?? 0,
                      'vcid': driver['vcid'] ?? 0,
                    });

                    // Format: fname-code-mobilenumber
                    String driverDisplay = '$fname-$code-$mobilenumber';
                    newDriverList.add(driverDisplay);
                    print('✅ Added driver: $driverDisplay');
                  }
                }
              } else {
                print('⚠️ No drivers data found in any expected keys');
              }
            }

            // Update the UI with new driver list
            setState(() {
              if (newDriverList.isNotEmpty) {
                driverList = newDriverList;
                driverDataList = newDriverDataList;
                filteredDriverList =
                    List.from(newDriverList); // Initialize filtered list
                print('✅ Updated UI with ${newDriverList.length} drivers');
              } else {
                driverList = ['No drivers available'];
                driverDataList = [];
                filteredDriverList = ['No drivers available'];
                print('⚠️ No valid drivers found, showing placeholder');
              }
            });

            print('🔍 Final driver list: $driverList');
          }
        } catch (e) {
          print('❌ Error parsing JSON response: $e');
          print('🔍 Raw response body: ${loadmemberResponse.body}');
          setState(() {
            driverList = ['Error loading drivers'];
            driverDataList = [];
            filteredDriverList = ['Error loading drivers'];
          });
        }
      } else {
        print('❌ Failed to load members: ${loadmemberResponse.statusCode}');
        print('❌ Response body: ${loadmemberResponse.body}');
        setState(() {
          driverList = ['Failed to load drivers'];
          driverDataList = [];
          filteredDriverList = ['Failed to load drivers'];
        });
      }
    } catch (e) {
      print('❌ Error loading members: $e');
      setState(() {
        driverList = ['Network error'];
        driverDataList = [];
        filteredDriverList = ['Network error'];
      });
    } finally {
      setState(() {
        screenLoading = false;
      });
      print('🏁 Member loading completed');
    }
  }

  // Filter drivers based on search query with real-time character matching
  void _filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDriverList = List.from(driverList);
      } else {
        String lowerQuery = query.toLowerCase();
        filteredDriverList = driverList.where((driver) {
          String lowerDriver = driver.toLowerCase();

          // Split driver info to search in different parts
          List<String> driverParts = driver.split('-');
          String driverName =
              driverParts.isNotEmpty ? driverParts[0].toLowerCase() : '';
          String driverCode =
              driverParts.length > 1 ? driverParts[1].toLowerCase() : '';
          String driverMobile =
              driverParts.length > 2 ? driverParts[2].toLowerCase() : '';

          // Check if query matches start of name, code, mobile, or anywhere in the string
          return driverName.startsWith(lowerQuery) ||
              driverCode.startsWith(lowerQuery) ||
              driverMobile.startsWith(lowerQuery) ||
              lowerDriver.contains(lowerQuery);
        }).toList();

        // Sort results: prioritize those that start with the query
        filteredDriverList.sort((a, b) {
          String aName = a.split('-')[0].toLowerCase();
          String bName = b.split('-')[0].toLowerCase();

          bool aStartsWithQuery = aName.startsWith(lowerQuery);
          bool bStartsWithQuery = bName.startsWith(lowerQuery);

          if (aStartsWithQuery && !bStartsWithQuery) return -1;
          if (!aStartsWithQuery && bStartsWithQuery) return 1;

          return aName.compareTo(bName);
        });
      }
    });
    print('🔍 Search query: "$query"');
    print('🔍 Filtered results: ${filteredDriverList.length} drivers');
    if (filteredDriverList.isNotEmpty) {
      print('🔍 Top matches: ${filteredDriverList.take(3).join(", ")}');
    }
  }

  // Build driver item with text highlighting
  Widget _buildDriverItem(String driver, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Text(
        driver,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      );
    }

    // Split driver info to highlight different parts
    List<String> driverParts = driver.split('-');
    String driverName = driverParts.isNotEmpty ? driverParts[0] : '';
    String driverCode = driverParts.length > 1 ? driverParts[1] : '';
    String driverMobile = driverParts.length > 2 ? driverParts[2] : '';

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: Colors.black),
        children: [
          _buildHighlightedTextSpan(driverName, searchQuery),
          if (driverCode.isNotEmpty) ...[
            TextSpan(text: '-', style: TextStyle(color: Colors.grey[600])),
            _buildHighlightedTextSpan(driverCode, searchQuery),
          ],
          if (driverMobile.isNotEmpty) ...[
            TextSpan(text: '-', style: TextStyle(color: Colors.grey[600])),
            _buildHighlightedTextSpan(driverMobile, searchQuery),
          ],
        ],
      ),
    );
  }

  // Helper method to create highlighted text spans
  TextSpan _buildHighlightedTextSpan(String text, String searchQuery) {
    if (searchQuery.isEmpty || text.isEmpty) {
      return TextSpan(text: text);
    }

    String lowerText = text.toLowerCase();
    String lowerQuery = searchQuery.toLowerCase();

    List<TextSpan> spans = [];
    int startIndex = 0;

    while (startIndex < text.length) {
      int index = lowerText.indexOf(lowerQuery, startIndex);

      if (index == -1) {
        // No more matches, add remaining text
        spans.add(TextSpan(text: text.substring(startIndex)));
        break;
      }

      // Add text before match
      if (index > startIndex) {
        spans.add(TextSpan(text: text.substring(startIndex, index)));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: TextStyle(
          backgroundColor: Colors.yellow[200],
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ));

      startIndex = index + searchQuery.length;
    }

    return TextSpan(children: spans);
  }

  // Show driver selection dialog with search
  Future<void> _showDriverSelectionDialog() async {
    // Reset search when opening dialog
    driverSearchController.clear();
    filteredDriverList = List.from(driverList);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Driver', style: TextStyle(fontSize: 18)),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Search field
                    TextFormField(
                      controller: driverSearchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        hintText: 'Search drivers...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        suffixIcon: driverSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  driverSearchController.clear();
                                  _filterDrivers('');
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _filterDrivers(value);
                        setDialogState(() {});
                      },
                    ),
                    SizedBox(height: 12),

                    // Results count
                    if (driverSearchController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${filteredDriverList.length} drivers found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Driver list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDriverList.length,
                        itemBuilder: (context, index) {
                          String driver = filteredDriverList[index];
                          bool isSelected = selectedDriver == driver;

                          return ListTile(
                            dense: true,
                            title: _buildDriverItem(
                                driver, driverSearchController.text),
                            selected: isSelected,
                            selectedTileColor: Colors.blue[50],
                            onTap: () {
                              setState(() {
                                selectedDriver = driver;
                              });
                              Navigator.of(context).pop();
                              print('✅ Selected driver: $driver');
                            },
                            trailing: isSelected
                                ? Icon(Icons.check, color: Colors.blue)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Validate all fields before saving
  void _validateAndSaveTrip() {
    List<String> missingFields = [];

    // Check required fields
    if (selectedDriver == null || selectedDriver!.isEmpty) {
      missingFields.add('Driver selection');
    }

    // Check pickup time for Pick Up trips
    if (tripType == 'Pick Up' && selectedTime == null) {
      missingFields.add('Pick Up Time');
    }

    // Check pickup date for Pick Up trips
    if (tripType == 'Pick Up' && selectedPickupDate == null) {
      missingFields.add('Pick Up Date');
    }

    if (contactPersonNameController.text.trim().isEmpty) {
      missingFields.add('Contact Person Name');
    }

    if (contactPersonNoController.text.trim().isEmpty) {
      missingFields.add('Contact Person Number');
    }

    if (locationController.text.trim().isEmpty) {
      missingFields.add('Location');
    }

    // Show validation results
    if (missingFields.isNotEmpty) {
      _showValidationError(missingFields);
    } else {
      _saveTrip();
    }
  }

  // Show validation error dialog
  void _showValidationError(List<String> missingFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Missing Information', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please fill in the following required fields:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              ...missingFields
                  .map((field) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.red),
                            SizedBox(width: 8),
                            Text(field, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // Save trip data
  void _saveTrip() async {
    // Print trip data for debugging
    print('🎉 TRIP SAVED SUCCESSFULLY');
    print('📋 Trip Type: $tripType');
    print('🚗 Driver: $selectedDriver');
    if (tripType == 'Pick Up' && selectedPickupDate != null) {
      print(
          '📅 Pick Up Date: ${selectedPickupDate!.day}/${selectedPickupDate!.month}/${selectedPickupDate!.year}');
    }
    if (tripType == 'Pick Up' && selectedTime != null) {
      print('⏰ Pick Up Time: ${selectedTime!.format(context)}');
    }
    print('👤 Contact Person: ${contactPersonNameController.text}');
    print('📞 Contact Number: ${contactPersonNoController.text}');
    if (alternateContactNoController.text.trim().isNotEmpty) {
      print('📞 Alternate Contact: ${alternateContactNoController.text}');
    }
    print('📍 Location: ${locationController.text}');
    if (locationUrl != null) {
      print('🔗 Location URL: $locationUrl');
    }

    // API call to create trip
    try {
      // Parse driver info (format: Name-Code-Mobile)
      String? driverName;
      String? driverCode;
      String? driverMobile;
      int drivervmid = 0;
      int drivervcid = 0;

      if (selectedDriver != null && selectedDriver!.contains('-')) {
        final parts = selectedDriver!.split('-');
        driverName = parts.isNotEmpty ? parts[0] : '';
        driverCode = parts.length > 1 ? parts[1] : '';
        driverMobile = parts.length > 2 ? parts[2] : '';

        // Find the corresponding driver data to get vmid and vcid
        for (var driverData in driverDataList) {
          if (driverData['fname'] == driverName &&
              driverData['code'] == driverCode &&
              driverData['mobileNumber'] == driverMobile) {
            drivervmid = driverData['vmid'] ?? 0;
            drivervcid = driverData['vcid'] ?? 0;
            print('🔍 Found driver IDs: vmid=$drivervmid, vcid=$drivervcid');
            break;
          }
        }
      }
      final payload = {
        "vpid": loginData?["vpid"] ?? 0,
        "tripttypeid": tripType == "Pick Up" ? 1 : 2,
        "tripType": tripType,
        "inchargevmid": loginData?["vmid"] ?? 0,
        "inchargeName": loginData?["manager_name"] ?? '',
        "vpoid": loginData?["vpoid"] ?? 0,
        "vbpid": loginData?["vbpid"] ?? 0,
        "unitid": loginData?["unitid"] ?? 0,
        "subunitid": loginData?["subunitid"] ?? 0,
        "projectid": loginData?["project_id"] ?? 0,
        "projectname": loginData?["registered_movie"] ?? '',
        "inchargevcid": loginData?["vcid"] ?? 0,
        "drivervmid": drivervmid,
        "drivercode": driverCode ?? '',
        "drivervcid": drivervcid,
        "driverName": driverName ?? '',
        "driverMobilenumber": driverMobile ?? '',
        "latitude": selectedLatitude?.toString() ?? '',
        "longtitude": selectedLongitude?.toString() ?? '',
        "location": locationController.text,
        "tripdate": selectedPickupDate != null
            ? "${selectedPickupDate!.year}-${selectedPickupDate!.month.toString().padLeft(2, '0')}-${selectedPickupDate!.day.toString().padLeft(2, '0')}"
            : '',
        "triptime": selectedTime != null ? selectedTime!.format(context) : '',
        "contactpersonname": contactPersonNameController.text,
        "contactpersonmobile": contactPersonNoController.text,
        "contactpersonalternatemobile": alternateContactNoController.text,
        "locationurl": locationUrl ?? '',
      };
      final createtripResponse = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'k+UnxgpyJFtbhHBcNgiwMctkSDb0/LZImpdqp2QlixSbONNAMlSbS41JItIprv1EpDBixc5WWktQx/FCwvkVHEHmIzviCUWcyuE8EhZaCGPH6CbKH2EPiny8/q8ZvlF7jlJNrbHwx8o4SqqxEwNlErUhBPyFXN8BgtKbCkGI7XeuYy8Twet/t+X4kdzjestXB9yks2Y5TzJu8P3ZPY/jYvzF+QbgAQQwzCZ7RtOWy93EV9p5pZFOH5NAzHdbXU8mrV6rxFZ5wfOPynlV6Q63pAWN+0faVYtK/4kEEW4kzmkpewVsRTlUYeTLjsiIwZdSXGdGaNmK87qa480tqz29Uw==',
          'VSID': loginData!['vsid']?.toString() ?? '',
        },
        body: jsonEncode(payload),
      );

      print(
          '🛰️ CreateTrip API Response Status: ${createtripResponse.statusCode}');
      print('🛰️ CreateTrip API Payload: $payload');
      print('🛰️ CreateTrip API Response Body: ${createtripResponse.body}');

      if (createtripResponse.statusCode == 200) {
        print('✅ Trip created successfully on server!');

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trip created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset form after successful creation
        _resetForm();
      } else {
        print(
            '⚠️ Trip creation failed with status: ${createtripResponse.statusCode}');

        // Show error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create trip. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error calling CreateTrip API: $e');

      // Show error SnackBar for exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Network error. Please check your connection.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Reset form after successful save
  void _resetForm() {
    setState(() {
      tripType = 'Pick Up';
      selectedDriver = null;
      selectedTime = null;
      selectedPickupDate = null;
      selectedLatitude = null;
      selectedLongitude = null;
      locationUrl = null;
      contactPersonNameController.clear();
      contactPersonNoController.clear();
      alternateContactNoController.clear();
      locationController.clear();
      driverSearchController.clear();
      filteredDriverList = List.from(driverList);
    });
    print('🔄 Form reset successfully');
  }

  // Select pickup date
  Future<void> _selectPickupDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedPickupDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedPickupDate) {
      setState(() {
        selectedPickupDate = picked;
      });
    }
  }

  // Pick location using map
  Future<void> _pickLocation() async {
    setState(() {
      locationController.text = "Fetching location...";
    });

    Position? position;

    try {
      // Try to get last known position first
      position = await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('⚠️ Could not get last known position: $e');
      position = null;
    }

    if (position == null) {
      try {
        position = await _determinePosition();
      } catch (e) {
        print('⚠️ Could not get current position: $e');
        // Use default location (you can change these coordinates to your preferred default)
        position = Position(
          latitude: 28.6139, // Default to Delhi, India (you can change this)
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        setState(() {
          locationController.text = "Enter Location";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location permission denied. Please select location manually on the map.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    LatLng initialPosition = LatLng(position.latitude, position.longitude);

    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenStreetMapScreen(initialPosition),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        locationController.text = "Fetching address...";
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            pickedLocation.latitude, pickedLocation.longitude);

        if (placemarks.isNotEmpty) {
          String fullAddress = [
            placemarks.first.street,
            placemarks.first.subLocality,
            placemarks.first.locality,
            placemarks.first.administrativeArea,
            placemarks.first.country
          ].where((e) => e != null && e.isNotEmpty).join(", ");

          setState(() {
            selectedLatitude = pickedLocation.latitude;
            selectedLongitude = pickedLocation.longitude;
            locationUrl =
                "https://maps.google.com/?q=${pickedLocation.latitude},${pickedLocation.longitude}";
            print('🔗 Location URL generated successfully: $locationUrl');
            locationController.text = fullAddress.isNotEmpty
                ? fullAddress
                : "Lat: ${pickedLocation.latitude.toStringAsFixed(6)}, Lng: ${pickedLocation.longitude.toStringAsFixed(6)}";
          });
        } else {
          setState(() {
            selectedLatitude = pickedLocation.latitude;
            selectedLongitude = pickedLocation.longitude;
            locationUrl =
                "https://maps.google.com/?q=${pickedLocation.latitude},${pickedLocation.longitude}";
            print('🔗 Location URL generated successfully: $locationUrl');
            locationController.text =
                "Lat: ${pickedLocation.latitude.toStringAsFixed(6)}, Lng: ${pickedLocation.longitude.toStringAsFixed(6)}";
          });
        }
      } catch (e) {
        print('⚠️ Error getting address: $e');
        setState(() {
          selectedLatitude = pickedLocation.latitude;
          selectedLongitude = pickedLocation.longitude;
          locationUrl =
              "https://maps.google.com/?q=${pickedLocation.latitude},${pickedLocation.longitude}";
          print('🔗 Location URL generated successfully: $locationUrl');
          locationController.text =
              "Lat: ${pickedLocation.latitude.toStringAsFixed(6)}, Lng: ${pickedLocation.longitude.toStringAsFixed(6)}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not get address for selected location. Coordinates saved.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // User cancelled location selection
      setState(() {
        locationController.text = "";
      });
    }
  }

  // Determine current position
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable location services in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permissions are denied. Please grant location permission to use this feature.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please go to app settings and enable location permission.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      // If getting current position fails, try with lower accuracy
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        );
      } catch (e) {
        throw Exception(
            'Unable to get current location. Please try again or select location manually on the map.');
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen(); // Initialize everything when screen loads
  }

  // Initialize screen - load login data and then members
  Future<void> _initializeScreen() async {
    await _loadLoginData(); // Load login data first
    if (loginData != null) {
      await _loadMembers(); // Then load members automatically
    }
  }

  @override
  void dispose() {
    _database?.close();
    contactPersonNameController.dispose();
    contactPersonNoController.dispose();
    alternateContactNoController.dispose();
    locationController.dispose();
    driverSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
      ),
      body: Container(
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
        child: screenLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading drivers...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: topPadding,
                        left: 20,
                        right: 20,
                        bottom:
                            90), // Increased bottom padding to avoid bottom navigation
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Your Details',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Color.fromARGB(255, 223, 222, 222)),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, left: 15, right: 15, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Trip Type',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      Radio<String>(
                                        fillColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        value: 'Pick Up',
                                        groupValue: tripType,
                                        onChanged: (val) {
                                          setState(() {
                                            tripType = val!;
                                          });
                                        },
                                      ),
                                      const Text('Pick Up',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      Radio<String>(
                                        fillColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        value: 'Drop',
                                        groupValue: tripType,
                                        onChanged: (val) {
                                          setState(() {
                                            tripType = val!;
                                          });
                                        },
                                      ),
                                      const Text('Drop',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Driver selection
                                  const Text('Select Driver',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),

                                  // Driver selection field (tap to open searchable dialog)
                                  GestureDetector(
                                    onTap: () => _showDriverSelectionDialog(),
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                          hintText: driverList.isEmpty
                                              ? 'Loading drivers...'
                                              : 'Tap to select driver',
                                          suffixIcon:
                                              Icon(Icons.arrow_drop_down),
                                        ),
                                        controller: TextEditingController(
                                          text: selectedDriver ?? '',
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (tripType == 'Pick Up') ...[
                                    const Text('Pick Up Date',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectPickupDate,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            hintText: 'Select Date',
                                            suffixIcon:
                                                Icon(Icons.calendar_today),
                                          ),
                                          controller: TextEditingController(
                                            text: selectedPickupDate == null
                                                ? ''
                                                : "${selectedPickupDate!.day}/${selectedPickupDate!.month}/${selectedPickupDate!.year}",
                                          ),
                                          readOnly: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Pick Up Time',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _selectTime(context),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            hintText: 'Select Time',
                                          ),
                                          controller: TextEditingController(
                                            text: selectedTime == null
                                                ? ''
                                                : selectedTime!.format(context),
                                          ),
                                          readOnly: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Contact Person Name
                                  const Text('Contact Person Name',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: contactPersonNameController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      hintText: 'Enter Contact Person Name',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Contact Person No
                                  const Text('Contact Person No',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: contactPersonNoController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      hintText: 'Enter Contact Person No',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Alternate Contact No
                                  const Text('Alternate Contact No',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: alternateContactNoController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      hintText: 'Enter Alternate Contact No',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Location
                                  const Text('Location',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: locationController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      hintText: 'Enter Location',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.location_on),
                                        onPressed: _pickLocation,
                                        tooltip: 'Pick location from map',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Pickup person selection
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _validateAndSaveTrip,
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                              ).copyWith(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                  (states) => null,
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2B5682),
                                      Color(0xFF24426B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Create Trip',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class OpenStreetMapScreen extends StatefulWidget {
  final LatLng initialPosition;
  OpenStreetMapScreen(this.initialPosition, {Key? key}) : super(key: key);

  @override
  _OpenStreetMapScreenState createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  late LatLng selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialPosition;
  }

  // 🔍 Function to Search for Location
  Future<void> _searchLocation() async {
    String query = _searchController.text;
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        setState(() {
          selectedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.move(selectedLocation, 15.0);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not found!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchLocation,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🗺️ Map (Expanded for responsiveness)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 13.0,
                    onTap: (_, latLng) {
                      setState(() {
                        selectedLocation = latLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 40.0,
                          height: 40.0,
                          child: const Icon(Icons.location_on,
                              size: 40, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Floating Button for Confirm
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, selectedLocation),
        icon: const Icon(Icons.check),
        label: const Text("Confirm"),
      ),
    );
  }
}
