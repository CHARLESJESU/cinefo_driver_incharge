import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_device_imei/flutter_device_imei.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';

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

  List<String> shiftTimes = [];
  int selectedLocationType = 1;
  int? selectedShiftId;
  double? selectedLatitude;
  double? selectedLongitude;
  List<Map<String, dynamic>> shiftList = [];
  Map? createCallSheetresponse1;
  Map? createCallSheetresponse2;
  String _imei = 'Unknown';
  String? managerName;
  String? registeredMovie;
  String selectedCallsheetName = '';

  Future<void> _initImei() async {
    await _requestPermission();
    String? imei;
    try {
      imei = await FlutterDeviceImei.instance.getIMEI();
    } catch (e) {
      imei = 'Failed to get IMEI: $e';
    }

    if (!mounted) return;

    setState(() {
      _imei = imei ?? 'Unavailable';
    });
  }

  Future<void> initializeDevice() async {
    await _initImei();
    if (_imei != 'Unavailable' && !_imei.startsWith('Failed')) {
      await passDeviceId();
    } else {
      print('IMEI not available: $_imei');
    }
  }

  Future<void> _requestPermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
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
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      showmessage(context, "Please fill in all required fields.", "ok");
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
      "locationTypeId": selectedLocationType
    };
    final response = await http.post(
      processSessionRequest,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode({
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
        "locationTypeId": selectedLocationType
      }),
    );

    setState(() {
      _isLoading = false;
    });

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
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Routescreen(initialIndex: 1),
              ));
        });
      } else {
        showmessage(context, createCallSheetresponse1!['message'], "ok");
      }
    } else {
      showmessage(context, response.body, "ok");
    }
  }

  Future<void> passDeviceId() async {
    final response = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'lb+u8AHQGWL1qQsbAPInJlw74qN/CO11M+zHF2J5xA8ATonyNjJbolrErxHS5J62zttxxaH19jWydCT+ynunHecYrHdCg2VNdx7y9W3uC91rR4vOUGnnbOZqqXVnkXsVsnjFP6FidZjmxYmYsHiiX3iMckkd1eMHoew/SZYZJNriRZ9aIl7RwOhFExH6cBufpjKE4UIiCR0Wtj09SEMwGyh1RgE0sI9VzsmM6Cyto56RjkkeLOcD6Lv5SLXmPDul6jgIiwVjelkiHOCmTnI8L4/+esXkkAmdvTgA/4WgkQPAQwse/YhTOOsePwaxlzYC3Ut0ipJ9qt2eqGWUdeWoQw==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode(<String, dynamic>{"deviceid": _imei.toString()}),
    );

    if (response.statusCode == 200) {
      print(response.body);
      getdeviceidresponse = json.decode(response.body);
      if (getdeviceidresponse != null &&
          getdeviceidresponse!['responseData'] != null) {
        setState(() {
          managerName = getdeviceidresponse!['responseData'][0]
                  ['managerName'] ??
              "Unknown";
          registeredMovie =
              getdeviceidresponse!['responseData'][0]['projectName'] ?? "N/A";
          vmid = getdeviceidresponse!['responseData'][0]['vmId'] ?? "N/A";
          productionHouse = getdeviceidresponse!['responseData'][0]
                  ['productionHouse'] ??
              "N/A";
          projectId =
              getdeviceidresponse!['responseData'][0]['projectId'] ?? "N/A";
        });
      }
      print("Device ID sent successfully!");

      print(response.body);
    } else {
      getdeviceidresponse = json.decode(response.body);
      print("Failed to send Device ID: ${response.body}");
    }
  }

  Future<void> shift() async {
    setState(() {
      screenLoading = true;
    });

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

    setState(() {
      screenLoading = false;
    });

    if (response.statusCode == 200) {
      List<dynamic> responseData = jsonDecode(response.body)['responseData'];

      shiftList = responseData
          .map((shift) => {
                "shiftId": shift['shiftId'],
                "shift": shift['shift'].toString(),
              })
          .toList();

      shiftTimes = shiftList.map((shift) => shift['shift'].toString()).toList();

      setState(() {
        selectedShift =
            null; // ✅ Important: keep it null so dropdown shows hint
        selectedShiftId = null; // Optionally reset this too
      });
    } else {
      // Handle error if needed
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
                                  Text(
                                      'Fill in your shift details to create a new callsheet'),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 380,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenPadding = MediaQuery.of(context).padding;

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
