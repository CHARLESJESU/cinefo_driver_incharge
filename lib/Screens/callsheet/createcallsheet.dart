import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as path;
import '../../Tesing/Sqlitelist.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class CreateCallSheet extends StatefulWidget {
  const CreateCallSheet({super.key});

  @override
  State<CreateCallSheet> createState() => _CreateCallSheetState();
}

class _CreateCallSheetState extends State<CreateCallSheet> {
  bool _isLoading = false;

  bool screenLoading = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  String? selectedShift; // No default value
  DateTime? selectedDate; // Selected date for the callsheet

  List<String> shiftTimes = [];
  int selectedLocationType = 1;
  int? selectedShiftId;
  double? selectedLatitude;
  double? selectedLongitude;
  List<Map<String, dynamic>> shiftList = [];
  Map? createCallSheetresponse1;
  Map? createCallSheetresponse2;
  String _deviceId = 'Unknown';
  String? managerName;
  String? registeredMovie;
  String selectedCallsheetName = '';

  Future<void> _initDeviceId() async {
    await _requestPermission();
    String deviceId = 'Unknown';
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID
        print('🤖 Android Device ID: $deviceId');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'iOS-Unknown';
        print('🍎 iOS Device ID: $deviceId');
      } else {
        deviceId = 'Platform-Not-Supported';
        print('❌ Unsupported platform');
      }

      // Ensure we have a valid device ID
      if (deviceId.isEmpty) {
        deviceId = 'Empty-Device-ID-${DateTime.now().millisecondsSinceEpoch}';
        print('⚠️ Device ID was empty, using fallback');
      }
    } catch (e, stackTrace) {
      deviceId = 'Error-${DateTime.now().millisecondsSinceEpoch}';
      print('❌ Device ID error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');

      // Try a fallback approach
      try {
        if (Platform.isAndroid) {
          DeviceInfoPlugin basicInfo = DeviceInfoPlugin();
          AndroidDeviceInfo basicAndroidInfo = await basicInfo.androidInfo;
          String fallbackId =
              '${basicAndroidInfo.brand}-${basicAndroidInfo.model}-${DateTime.now().millisecondsSinceEpoch}';
          deviceId = fallbackId;
          print('🔄 Using fallback Android ID: $deviceId');
        }
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        deviceId = 'Fallback-Failed-${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
    });
  }

  Future<void> initializeDevice() async {
    try {
      await _initDeviceId();
      if (_deviceId != 'Unavailable' && !_deviceId.startsWith('Failed')) {
        await passDeviceId();
      } else {
        print('Device ID not available: $_deviceId');
        // Set fallback values if Device ID is not available
        if (mounted) {
          setState(() {
            managerName = "Device ID not available";
            registeredMovie = "N/A";
          });
        }
      }
    } catch (e) {
      print('Error in initializeDevice: $e');
      if (mounted) {
        setState(() {
          managerName = "Error initializing device";
          registeredMovie = "N/A";
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    // For device_info_plus, we don't need special permissions for Android ID
    // Just check if we can access basic device info
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      await deviceInfo.androidInfo; // Test access
      print('✅ Device info access available');
    } catch (e) {
      print('⚠️ Limited device info access: $e');
    }
  }

  Future<void> _pickLocation() async {
    setState(() {
      _locationController.text = "Fetching location...";
    });

    Position? position = await Geolocator.getLastKnownPosition();

    if (position == null) {
      position = await _determinePosition();
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
        _locationController.text = "Fetching address...";
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            pickedLocation.latitude, pickedLocation.longitude);

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
          _locationController.text = fullAddress;
        });
      } catch (e) {
        setState(() {
          _locationController.text = "Address not found";
        });
      }
    }
  }

  String getLocationTypeLabel(int id) {
    switch (id) {
      case 1:
        return "In-station";
      case 2:
        return "Out-station";
      case 3:
        return "Out-Side City";
      default:
        return "Unknown";
    }
  }

  Future<void> printVSIDFromLoginData() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));
      final List<Map<String, dynamic>> loginRows =
          await db.query('login_data', orderBy: 'id ASC', limit: 1);
      if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
        print('Fetched VSID from login_data: \\${loginRows.first['vsid']}');
        vsid = loginRows.first['vsid'];
        projectId = loginRows.first['project_id'];
        vmid = loginRows.first['vmid'];
        vpid = loginRows.first['vpid'];
        vpoid = loginRows.first['vpoid'];
        vbpid = loginRows.first['vbpid'];
        productionTypeId = loginRows.first['production_type_id'];
      } else {
        print('VSID not found in login_data table.');
      }
      await db.close();
    } catch (e) {
      print('Error fetching VSID from login_data: \\${e.toString()}');
    }
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate != null && selectedDate!.isAfter(today)
          ? selectedDate!
          : today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best, // Improves speed
      timeLimit: Duration(seconds: 5), // Prevents long delays
    );
  }

  Future<void> createCallSheet() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        selectedDate == null) {
      showmessage(
          context, "Please fill in all required fields including date.", "ok");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final payload = {
      "name": _nameController.text,
      "shiftId": selectedShiftId,
      "latitude": selectedLatitude,
      "longitude": selectedLongitude,
      "projectId": projectId,
      "vmid": loginresult!['vmid'],
      "vpid": loginresult!['vpid'],
      "vpoid": loginresponsebody!['vpoid'],
      "vbpid": loginresponsebody!['vbpid'],
      "productionTypeid": productionTypeId,
      "location": _locationController.text,
      "locationType": getLocationTypeLabel(selectedLocationType),
      "locationTypeId": selectedLocationType,
      "created_at":
          selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
    location = _locationController.text;
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

    setState(() {
      _isLoading = false;
    });
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
        showsuccessPopUp(context, "created call sheet successfully", () {
          Navigator.pop(context);
        });
      } else {
        showmessage(context, createCallSheetresponse1!['message'], "ok");
      }
    } else {
      showmessage(context, response.body, "ok");
    }
  }

  Future<void> passDeviceId() async {
    try {
      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'lb+u8AHQGWL1qQsbAPInJlw74qN/CO11M+zHF2J5xA8ATonyNjJbolrErxHS5J62zttxxaH19jWydCT+ynunHecYrHdCg2VNdx7y9W3uC91rR4vOUGnnbOZqqXVnkXsVsnjFP6FidZjmxYmYsHiiX3iMckkd1eMHoew/SZYZJNriRZ9aIl7RwOhFExH6cBufpjKE4UIiCR0Wtj09SEMwGyh1RgE0sI9VzsmM6Cyto56RjkkeLOcD6Lv5SLXmPDul6jgIiwVjelkiHOCmTnI8L4/+esXkkAmdvTgA/4WgkQPAQwse/YhTOOsePwaxlzYC3Ut0ipJ9qt2eqGWUdeWoQw==',
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode(<String, dynamic>{"deviceid": _deviceId.toString()}),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final responseBody = json.decode(response.body);

        // Validate response structure and data availability
        if (responseBody != null &&
            responseBody['responseData'] != null &&
            responseBody['responseData'] is List &&
            (responseBody['responseData'] as List).isNotEmpty) {
          // Check if widget is still mounted before setState
          if (!mounted) return;

          setState(() {
            getdeviceidresponse = responseBody;
            final responseData = responseBody['responseData'][0];

            managerName = responseData['managerName'] ?? "Unknown";
            registeredMovie = responseData['projectName'] ?? "N/A";
            vmid = responseData['vmId'] ?? "N/A";
            productionHouse = responseData['productionHouse'] ?? "N/A";
            projectId = responseData['projectId'] ?? "N/A";
          });

          print("Device ID sent successfully!");
        } else {
          print("Warning: responseData is null, not a list, or empty");
          if (mounted) {
            setState(() {
              managerName = "Device not configured";
              registeredMovie = "N/A";
            });
          }
        }
      } else {
        final errorBody = json.decode(response.body);
        print("Failed to send Device ID: ${response.body}");

        if (mounted) {
          setState(() {
            getdeviceidresponse = errorBody;
            managerName = "Error loading data";
            registeredMovie = "N/A";
          });
        }
      }
    } catch (e) {
      print("Error in passDeviceId: $e");
      if (mounted) {
        setState(() {
          managerName = "Error loading data";
          registeredMovie = "N/A";
        });
      }
    }
  }

  Future<void> shift() async {
    if (!mounted) return;

    setState(() {
      screenLoading = true;
    });

    try {
      final response = await http.post(
        processSessionRequest,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'hS1nHKbqxtay7ZfN0tzo5IxtJZLsZXbcVJS90oRm9KRUElvpSu/G/ik57TYlj4PTIfKxYI6P80/LHBjJjUO2XJv2k73r1mhjdd0z1w6z3okJ6uE5+XL1BJiaLjaS+aI7bx7tb9i0Ul8nfe7T059A5AZ6dx5gfML/njWo3K2ltOqcA8sCq7gjijxsKi4JY0LhkGMlHe9D4b+It08K8oHFCpV66R+acr8+iqbiPbWeOn/PphpwA7rDzNkBX5NEvudefosrJ0bfaJpHtMZnh7fYcw1eAAveV7fYc9zxX/W72ILQXlSCFxeeiONi9LfoJsfvkWRS7HtOrtD1x1Q08VeG/w==',
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode({"productionType": productionTypeId}),
      );

      // Check if widget is still mounted before processing response
      if (!mounted) return;

      setState(() {
        screenLoading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody != null && responseBody['responseData'] != null) {
          List<dynamic> responseData = responseBody['responseData'];

          shiftList = responseData
              .map((shift) => {
                    "shiftId": shift['shiftId'],
                    "shift": shift['shift'].toString(),
                  })
              .toList();

          shiftTimes =
              shiftList.map((shift) => shift['shift'].toString()).toList();

          if (mounted) {
            setState(() {
              selectedShift =
                  null; // ✅ Important: keep it null so dropdown shows hint
              selectedShiftId = null; // Optionally reset this too
            });
          }
        }
      } else {
        print("Failed to load shifts: ${response.body}");
      }
    } catch (e) {
      print("Error in shift(): $e");
      if (mounted) {
        setState(() {
          screenLoading = false;
        });
      }
    }
  }

  void onShiftSelected(Map<String, dynamic> shiftData) {
    String fullShiftName = shiftData['shift'] ?? "";

    // Regular expression to extract text within parentheses
    RegExp regExp = RegExp(r'\(([^)]+)\)');
    Match? match = regExp.firstMatch(fullShiftName);

    if (match != null) {
      // Extract the text inside parentheses and set as the callsheet name
      selectedCallsheetName = match.group(1) ?? "";
    } else {
      selectedCallsheetName = fullShiftName;
    }

    _nameController.text = selectedCallsheetName;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    initializeDevice();
    passDeviceId();
    shift();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Create callsheet"),
          backgroundColor: Colors.white,
        ),
        body: screenLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(children: [
                SingleChildScrollView(
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: Padding(
                            padding:
                                EdgeInsets.only(left: 20, right: 20, top: 10),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Your Details',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 530,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: const Color.fromARGB(
                                                    255, 223, 222, 222))),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 20, left: 15, right: 15),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Shift',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              SizedBox(height: 6),
                                              Container(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: DropdownButton<String>(
                                                    value:
                                                        selectedShift, // remains null initially
                                                    hint: Text(
                                                        "Select Shift"), // shows until selected
                                                    isExpanded: true,
                                                    underline: SizedBox(),
                                                    items:
                                                        shiftList.map((shift) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: shift['shift'],
                                                        child: Text(
                                                            shift['shift']),
                                                      );
                                                    }).toList(),
                                                    onChanged: (shiftName) {
                                                      if (shiftName != null) {
                                                        Map<String, dynamic>
                                                            shiftData =
                                                            shiftList
                                                                .firstWhere(
                                                          (shift) =>
                                                              shift['shift'] ==
                                                              shiftName,
                                                        );
                                                        setState(() {
                                                          selectedShift =
                                                              shiftName;
                                                          selectedShiftId =
                                                              shiftData[
                                                                  'shiftId'];
                                                        });
                                                        onShiftSelected(
                                                            shiftData);
                                                      }
                                                    },
                                                  )),
                                              SizedBox(height: 10),
                                              Text(
                                                'Date',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              SizedBox(height: 6),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 50,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: InkWell(
                                                  onTap: _selectDate,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          selectedDate != null
                                                              ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                                              : "Select Date",
                                                          style: TextStyle(
                                                            color: selectedDate !=
                                                                    null
                                                                ? Colors.black
                                                                : Colors
                                                                    .grey[600],
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.calendar_today,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Callsheet name',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16),
                                              ),
                                              SizedBox(
                                                height: 6,
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 50,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: TextField(
                                                  controller: _nameController,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text('Location type',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              SizedBox(height: 6),
                                              Container(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child:
                                                      DropdownButtonFormField<
                                                          int>(
                                                    value: selectedLocationType,
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                    ),
                                                    icon: Icon(
                                                        Icons.arrow_drop_down),
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: 1,
                                                          child: Text(
                                                              "In-station")),
                                                      DropdownMenuItem(
                                                          value: 2,
                                                          child: Text(
                                                              "Out-station")),
                                                      DropdownMenuItem(
                                                          value: 3,
                                                          child: Text(
                                                              "Outside City")),
                                                    ],
                                                    onChanged: (int? newValue) {
                                                      if (newValue != null) {
                                                        setState(() {
                                                          selectedLocationType =
                                                              newValue;
                                                        });
                                                      }
                                                    },
                                                  )),
                                              Text('Location',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              SizedBox(
                                                height: 6,
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _locationController,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    suffixIcon: IconButton(
                                                      icon: Icon(Icons.map),
                                                      onPressed: _pickLocation,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Offline mode checkbox removed
                                            ],
                                          ),
                                        ),
                                      )),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        createCallSheet();
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Color.fromRGBO(
                                              10,
                                              69,
                                              254,
                                              1,
                                            )),
                                        child: Center(
                                          child: _isLoading
                                              ? CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  'Create',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17),
                                                ),
                                        ),
                                      ),
                                    ),
                                  )
                                ]))))
              ]));
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
