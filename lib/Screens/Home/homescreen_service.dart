import 'dart:convert';
import 'package:flutter_device_imei/flutter_device_imei.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:production/variables.dart';

class HomeScreenService {
  // Private variables
  String _imei = 'Unknown';
  bool _isLoading = false;
  bool _screenLoading = false;
  String? _selectedShift;
  int? _selectedShiftId;
  String _selectedCallsheetName = '';
  List<Map<String, dynamic>> _shiftList = [];

  // Getters
  String get imei => _imei;
  bool get isLoading => _isLoading;
  bool get screenLoading => _screenLoading;
  String? get selectedShift => _selectedShift;
  int? get selectedShiftId => _selectedShiftId;
  String get selectedCallsheetName => _selectedCallsheetName;
  List<Map<String, dynamic>> get shiftList => _shiftList;
  List<String> get shiftTimes =>
      _shiftList.map((shift) => shift['shift'].toString()).toList();

  // Setters
  set isLoading(bool value) => _isLoading = value;
  set screenLoading(bool value) => _screenLoading = value;
  set selectedShift(String? value) => _selectedShift = value;
  set selectedShiftId(int? value) => _selectedShiftId = value;
  set selectedCallsheetName(String value) => _selectedCallsheetName = value;

  // IMEI related methods
  Future<void> requestPermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }
  }

  Future<void> initImei() async {
    await requestPermission();
    String? imei;
    try {
      imei = await FlutterDeviceImei.instance.getIMEI();
    } catch (e) {
      imei = 'Failed to get IMEI: $e';
    }
    _imei = imei ?? 'Unavailable';
  }

  Future<void> initializeDevice() async {
    await initImei();
    if (_imei != 'Unavailable' && !_imei.startsWith('Failed')) {
      await passDeviceId();
    } else {
      print('IMEI not available: $_imei');
    }
  }

  // API calls
  Future<Map<String, dynamic>?> passDeviceId() async {
    final response = await http.post(
      processRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'MIUzptHJWQqh0+/ytZy1/Hcjc8DfNH6OdiYJYg8lXd4nQLHlsRlsZ/k6G1uj/hY5w96n9dAg032gjp9ygMGCtg0YSlEgpXVPCWi79/pGZz6Motai4bYdua29xKvWVn8X0U87I/ZG6NCwYSCAdk9/6jYc75hCyd2z59F0GYorGNPLmkhGodpfabxRr8zheVXRnG9Ko2I7/V2Y83imaiRpF7k+g43Vd9XLFPVsRukcfkxWatuW336BEKeuX6Ts9JkY0Y9BKv4IdlHkOKwgxMf22zBV7IoJkL1XlGJlVCTsvchYN9Lx8NXQksxK8UPPMbU1hCRY4Jbr0/IIfntxd4vsng==',
      },
      body: jsonEncode(<String, dynamic>{"deviceid": _imei.toString()}),
    );

    if (response.statusCode == 200) {
      print("Device ID response: ${response.body}");
      final deviceResponse = json.decode(response.body);

      if (deviceResponse != null && deviceResponse['responseData'] != null) {
        // Update global variables for backward compatibility
        getdeviceidresponse = deviceResponse;
        projectId = deviceResponse['responseData'][0]['projectId'] ?? "";
        managerName =
            deviceResponse['responseData'][0]['managerName'] ?? "Unknown";
        registeredMovie =
            deviceResponse['responseData'][0]['projectName'] ?? "N/A";
        vmid = deviceResponse['responseData'][0]['vmId'] ?? "N/A";
        productionTypeId =
            deviceResponse['responseData'][0]['productionTypeId'] ?? 0;
        productionHouse =
            deviceResponse['responseData'][0]['productionHouse'] ?? "N/A";

        print("Device ID sent successfully!");
        return deviceResponse['responseData'][0];
      }
    } else {
      print("Failed to send Device ID: ${response.body}");
    }

    return null;
  }

  Future<void> lookupByVpoidMovies() async {
    final response = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'YVOVs1CRLPdlaq6Zo1blAiKueJV10caebY3quZjYdQPFORqBN7BZFcGo5gXFmjinLp2E6mAEqY7tDnVzJg88k+3tT28LnLxNWzJ4IaU1JXgUR2plf9R6RQrTsl3V9FPARaSuHRx+A26sMhRxFp7Ve2F4XlDRldJEkcel/gM8WSwcZDIrcnXakVk2ZIBM9YnWbuOHTUHfUol6oDGK53bTC+Lnpn/Ld85e7IERcAg/tSQNK/yG09FyQYVo+jpS4XzvTwX6BzFpMyeOYZmjoUjTc7rhihM8upkR0ThKnLTvoGeiACi44GdQ/KQl8mM4eWVuQxivyCi3WBbLWl1FeotEKg==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode(<String, dynamic>{"vpoid": loginresult!['vpoid']}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      movieProjects = data['responseData'];
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> fetchShifts() async {
    _screenLoading = true;

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

    _screenLoading = false;

    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> responseData = jsonDecode(response.body)['responseData'];

      _shiftList = responseData
          .map((shift) => {
                "shiftId": shift['shiftId'],
                "shift": shift['shift'].toString(),
              })
          .toList();

      _selectedShift = null;
      _selectedShiftId = null;
    }
  }

  void onShiftSelected(Map<String, dynamic> shiftData) {
    String fullShiftName = shiftData['shift'] ?? "";

    // Regular expression to extract text within parentheses
    RegExp regExp = RegExp(r'\(([^)]+)\)');
    Match? match = regExp.firstMatch(fullShiftName);

    if (match != null) {
      // Extract the text inside parentheses and set as the callsheet name
      _selectedCallsheetName = match.group(1) ?? "";
    } else {
      // If no match is found, use the full shift name
      _selectedCallsheetName = fullShiftName;
    }
  }

  // Location related methods
  Future<void> ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<Position?> getCurrentLocation() async {
    await ensureLocationPermission();
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Unable to get location: $e");
      return null;
    }
  }

  Future<String> getLocationAddress(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      return "${place.name}, ${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      return "Unknown Location";
    }
  }

  // Callsheet creation
  Future<Map<String, dynamic>> createCallSheet(String name) async {
    Position? position = await getCurrentLocation();
    if (position == null) {
      return {"success": false, "message": "Unable to get location"};
    }

    String locationAddress = await getLocationAddress(position);

    if (name.isEmpty) {
      return {"success": false, "message": "Please enter your name."};
    }

    _isLoading = true;

    final response = await http.post(
      processSessionRequest,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode({
        "name": name,
        "shiftId": _selectedShiftId.toString(),
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "projectId": selectedProjectId.toString(),
        "vmid": loginresult!['vmid'].toString(),
        "vpid": loginresult!['vpid'].toString(),
        "vpoid": loginresponsebody!['vpoid'].toString(),
        "vbpid": loginresponsebody!['vbpid'].toString(),
        "productionTypeid": productionTypeId,
        "location": locationAddress,
        "locationType": "In-Station",
        "locationTypeId": 1,
      }),
    );

    _isLoading = false;

    if (response.statusCode == 200) {
      print(response.body);
      final res = json.decode(response.body);
      if (res['message'] == "Success") {
        return {"success": true, "message": "Created call sheet successfully"};
      } else {
        return {"success": false, "message": res['message']};
      }
    } else {
      return {"success": false, "message": response.body};
    }
  }

  // Initialize all required data
  Future<void> initialize() async {
    await ensureLocationPermission();
    await lookupByVpoidMovies();
    await fetchShifts();
    await initializeDevice();
    await passDeviceId();
  }
}
