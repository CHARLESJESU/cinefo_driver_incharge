import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';

class CloseCallSheet extends StatefulWidget {
  const CloseCallSheet({super.key});

  @override
  State<CloseCallSheet> createState() => _CloseCallSheetState();
}

class _CloseCallSheetState extends State<CloseCallSheet> {
  bool _isLoading = false;
  bool screenLoading = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  String? selectedShift;
  List<String> shiftTimes = [];
  int selectedLocationType = 0;
  int? selectedShiftId;
  double? selectedLatitude;
  double? selectedLongitude;
  List<Map<String, dynamic>> shiftList = [];
  Map? createCallSheetresponse1;
  Map? createCallSheetresponse2;
  bool _isloading = false;
  String? managerName;
  String? registeredMovie;

  String _deviceId = 'Unknown';

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
    await _initDeviceId();
    if (_deviceId != 'Unavailable' && !_deviceId.startsWith('Failed')) {
      await passDeviceId();
    } else {
      print('Device ID not available: $_deviceId');
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

  showcard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          actions: <Widget>[
            SizedBox(
              height: 20,
            ),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
              ),
            ),
            SizedBox(
              height: 200,
            ),
          ],
        );
      },
    );
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
      body: jsonEncode(<String, dynamic>{"deviceid": _deviceId.toString()}),
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
      print(response.body);

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

  TextEditingController _timeController = TextEditingController();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> closecallsheet() async {
    setState(() {
      _isLoading = true;
    });
    final payload = {
      "callshettId": callsheetid.toString(),
      "projectid": projectId,
      "shiftid": selectedShiftId,
      "callSheetStatusId": 3,
      "callSheetTime": _timeController.text
    };
    final response = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'O/OtGf1bn9oD4GFpjRQ+Dec3uinWC4FwTdbrFCyiQDpN8SPMhon+ZaDHuLsnBHmfqGAjFXy6Gdjt6mQwzwqgfdWu+e+M8qwNk8gX9Ca3JxFQc++CDr8nd1Mrr57aHoLMlXprbFMxNy7ptfNoccm61r/9/lHCANMOt85n05HVfccknlopttLI5WM7DsNVU60/x5qylzlpXL24l8KwEFFPK1ky410+/uI3GkYi0l1u9DektKB/m1CINVbQ1Oob+FOW5lhNsBjqgpM/x1it89d7chbThdP5xlpygZsuG0AW4lakebF3ze497e16600v72fclgAZ3M21C0zUM4w9XIweMg==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode(<String, dynamic>{
        "callshettId": callsheetid.toString(),
        "projectid": projectId,
        "shiftid": selectedShiftId,
        "callSheetStatusId": 3,
        "callSheetTime": _timeController.text
      }),
    );
    setState(() {
      _isLoading = false;
    });
    print('--- ✅ Call Sheet Closed Successfully ---');
    print('Request Payload:');
    payload.forEach((key, value) {
      print('$key: $value');
    });
    print('VSID: ${loginresponsebody?['vsid']?.toString() ?? ""}');
    print('Response: ${response.body}');
    print('----------------------------------------');
    if (response.statusCode == 200) {
      closecallsheetresponse = json.decode(response.body);

      if (closecallsheetresponse!['message'] == "Success") {
        showsuccessPopUp(context, "callsheet closed successfully", () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Routescreen(initialIndex: 1),
            ),
          );
        });
      } else if (closecallsheetresponse!['message'] == null) {
        showSimplePopUp(
          context,
          closecallsheetresponse!['errordescription'],
        );
      }

      _timeController.clear();

      print(response.body);
      // print();
    } else {
      showmessage(context, response.body, "ok");
      print(response.body);
    }
  }

  @override
  void initState() {
    super.initState();
    shift();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 244, 1),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(3, 62, 240, 1),
        title: const Text(
          'Close callsheet',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 🕒 Shift Dropdown
                const Text('Shift',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Container(
                  width: screenWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedShift,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: shiftTimes.map((shift) {
                      return DropdownMenuItem(
                        value: shift,
                        child: Text(shift),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedShift = value!;
                        selectedShiftId = shiftList.firstWhere(
                            (shift) => shift['shift'] == value)['shiftId'];
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Status Dropdown
                const Text('Status',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Container(
                  width: screenWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: selectedLocationType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Completed")),
                      DropdownMenuItem(value: 1, child: Text("Cancel")),
                    ],
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedLocationType = newValue;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ⏰ Time Picker
                const Text('Select time',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Container(
                  width: screenWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 💾 Save Button
                GestureDetector(
                  onTap: closecallsheet,
                  child: Container(
                    width: screenWidth,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(3, 62, 240, 1),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
