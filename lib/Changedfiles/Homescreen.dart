// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_device_imei/flutter_device_imei.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:production/Screens/Route/RouteScreen.dart';
// import 'package:production/methods.dart';
// import 'package:production/variables.dart';
// import 'package:responsive_builder/responsive_builder.dart';

// class MovieListScreen extends StatefulWidget {
//   const MovieListScreen({super.key});

//   @override
//   State<MovieListScreen> createState() => _MovieListScreenState();
// }

// class _MovieListScreenState extends State<MovieListScreen> {
//   bool _isLoading = false;
//   bool screenLoading = false;
//   TextEditingController _nameController = TextEditingController();
//   TextEditingController _locationController = TextEditingController();
//   String? selectedShift; // No default value

//   List<String> shiftTimes = [];
//   int selectedLocationType = 1;
//   int? selectedShiftId;
//   double? selectedLatitude;
//   double? selectedLongitude;
//   List<Map<String, dynamic>> shiftList = [];
//   Map? createCallSheetresponse1;
//   Map? createCallSheetresponse2;
//   String _imei = 'Unknown';
//   String? managerName;

//   String selectedCallsheetName = '';
//   bool isLoading = false;
//   Future<void> _initImei() async {
//     await _requestPermission();
//     String? imei;
//     try {
//       imei = await FlutterDeviceImei.instance.getIMEI();
//     } catch (e) {
//       imei = 'Failed to get IMEI: $e';
//     }

//     if (!mounted) return;

//     setState(() {
//       _imei = imei ?? 'Unavailable';
//     });
//   }

//   Future<void> initializeDevice() async {
//     await _initImei();
//     if (_imei != 'Unavailable' && !_imei.startsWith('Failed')) {
//       await passDeviceId();
//     } else {
//       print('IMEI not available: $_imei');
//     }
//   }

//   Future<void> _requestPermission() async {
//     var status = await Permission.phone.status;
//     if (!status.isGranted) {
//       await Permission.phone.request();
//     }
//   }

//   Future<void> lookupbyvpoidmovies() async {
//     final response = await http.post(
//       processSessionRequest,
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'VMETID':
//             'YVOVs1CRLPdlaq6Zo1blAiKueJV10caebY3quZjYdQPFORqBN7BZFcGo5gXFmjinLp2E6mAEqY7tDnVzJg88k+3tT28LnLxNWzJ4IaU1JXgUR2plf9R6RQrTsl3V9FPARaSuHRx+A26sMhRxFp7Ve2F4XlDRldJEkcel/gM8WSwcZDIrcnXakVk2ZIBM9YnWbuOHTUHfUol6oDGK53bTC+Lnpn/Ld85e7IERcAg/tSQNK/yG09FyQYVo+jpS4XzvTwX6BzFpMyeOYZmjoUjTc7rhihM8upkR0ThKnLTvoGeiACi44GdQ/KQl8mM4eWVuQxivyCi3WBbLWl1FeotEKg==',
//         'VSID': loginresponsebody?['vsid']?.toString() ?? "",
//       },
//       body: jsonEncode(<String, dynamic>{"vpoid": loginresult!['vpoid']}),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         movieProjects = data['responseData'];
//       });
//     } else {
//       print("Error: ${response.body}");
//     }
//   }

//   Future<void> shift() async {
//     setState(() {
//       screenLoading = true;
//     });

//     final response = await http.post(
//       processSessionRequest,
//       headers: {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'VMETID':
//             'hS1nHKbqxtay7ZfN0tzo5IxtJZLsZXbcVJS90oRm9KRUElvpSu/G/ik57TYlj4PTIfKxYI6P80/LHBjJjUO2XJv2k73r1mhjdd0z1w6z3okJ6uE5+XL1BJiaLjaS+aI7bx7tb9i0Ul8nfe7T059A5AZ6dx5gfML/njWo3K2ltOqcA8sCq7gjijxsKi4JY0LhkGMlHe9D4b+It08K8oHFCpV66R+acr8+iqbiPbWeOn/PphpwA7rDzNkBX5NEvudefosrJ0bfaJpHtMZnh7fYcw1eAAveV7fYc9zxX/W72ILQXlSCFxeeiONi9LfoJsfvkWRS7HtOrtD1x1Q08VeG/w==',
//         'VSID': loginresponsebody?['vsid']?.toString() ?? "",
//       },
//       body: jsonEncode({"productionType": productionTypeId}),
//     );

//     setState(() {
//       screenLoading = false;
//     });

//     if (response.statusCode == 200) {
//       print(response.body);

//       List<dynamic> responseData = jsonDecode(response.body)['responseData'];

//       shiftList = responseData
//           .map((shift) => {
//                 "shiftId": shift['shiftId'],
//                 "shift": shift['shift'].toString(),
//               })
//           .toList();

//       shiftTimes = shiftList.map((shift) => shift['shift'].toString()).toList();

//       setState(() {
//         selectedShift =
//             null; // ✅ Important: keep it null so dropdown shows hint
//         selectedShiftId = null; // Optionally reset this too
//       });
//     } else {
//       // Handle error if needed
//     }
//   }

//   void onShiftSelected(Map<String, dynamic> shiftData) {
//     String fullShiftName = shiftData['shift'] ?? "";

//     // Regular expression to extract text within parentheses
//     RegExp regExp = RegExp(r'\(([^)]+)\)');
//     Match? match = regExp.firstMatch(fullShiftName);

//     if (match != null) {
//       // Extract the text inside parentheses and set as the callsheet name
//       selectedCallsheetName = match.group(1) ?? "";
//     } else {
//       // If no match is found, use the full shift name
//       selectedCallsheetName = fullShiftName;
//     }

//     // Set the name controller with the selected callsheet name
//     _nameController.text = selectedCallsheetName;

//     setState(() {});
//   }

//   Future<void> _ensureLocationPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }
//   }

//   Future<void> createCallSheet() async {
//     await _ensureLocationPermission();

//     Position position;
//     try {
//       position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//     } catch (e) {
//       showmessage1(context, "Unable to get location: $e", "ok");
//       return;
//     }

//     String locationAddress = "";
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       Placemark place = placemarks[0];
//       locationAddress =
//           "${place.name}, ${place.locality}, ${place.administrativeArea}";
//     } catch (e) {
//       locationAddress = "Unknown Location";
//     }

//     if (_nameController.text.isEmpty) {
//       showmessage1(context, "Please enter your name.", "ok");
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     final response = await http.post(
//       processSessionRequest,
//       headers: {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'VMETID':
//             'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
//         'VSID': loginresponsebody?['vsid']?.toString() ?? "",
//       },
//       body: jsonEncode({
//         "name": _nameController.text,
//         "shiftId": selectedShiftId.toString(),
//         "latitude": position.latitude.toString(),
//         "longitude": position.longitude.toString(),
//         "projectId": selectedProjectId.toString(),
//         "vmid": loginresult!['vmid'].toString(),
//         "vpid": loginresult!['vpid'].toString(),
//         "vpoid": loginresponsebody!['vpoid'].toString(),
//         "vbpid": loginresponsebody!['vbpid'].toString(),
//         "productionTypeid": productionTypeId,
//         "location": locationAddress,
//         "locationType": "In-Station",
//         "locationTypeId": 1,
//       }),
//     );
//     setState(() {
//       isLoading = false;
//     });

//     if (response.statusCode == 200) {
//       print(response.body);
//       final res = json.decode(response.body);
//       if (res['message'] == "Success") {
//         showsuccessPopUp(context, "Created call sheet successfully", () {
//           // ✅ Shift ended, allow navigation
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => Routescreen(initialIndex: 1)),
//           );
//         });
//       } else {
//         print(response.body);
//         showmessage1(context, res['message'], "ok");
//       }
//     } else {
//       print(response.body);
//       showmessage1(context, response.body, "ok");
//     }
//   }

//   void showmessage1(BuildContext context, String message, String ok) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return SimpleDialog(
//           title: const Text('Message'),
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(left: 25, right: 25),
//               child: Text(
//                 message,
//                 style: const TextStyle(fontSize: 16),
//                 textAlign: TextAlign.start,
//                 overflow: TextOverflow.visible,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).push(
//                     MaterialPageRoute(builder: (context) => MovieListScreen()));
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showInitialPopup(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Select Type'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 100,
//                 height: 30,
//                 decoration: BoxDecoration(
//                     color: Colors.grey,
//                     borderRadius: BorderRadius.circular(10)),
//                 child: GestureDetector(
//                     onTap: () async {
//                       // Save the higher context (outside the dialog)
//                       final parentContext =
//                           Navigator.of(context, rootNavigator: true).context;

//                       await shift(); // Fetch shift list

//                       Navigator.pop(context); // Close current dialog

//                       if (shiftList.isNotEmpty) {
//                         // Delay to ensure first dialog is closed
//                         Future.delayed(Duration(milliseconds: 300), () {
//                           _showCallsheetPopup(
//                               parentContext); // Use parent context to show new dialog
//                         });
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text("Failed to load shifts")),
//                         );
//                       }
//                     },
//                     child: Center(child: Text('Callsheet'))),
//               ),
//               SizedBox(
//                 height: 20,
//               ),
//               Container(
//                 width: 100,
//                 height: 30,
//                 decoration: BoxDecoration(
//                     color: Colors.grey,
//                     borderRadius: BorderRadius.circular(10)),
//                 child: GestureDetector(
//                     onTap: () async {
//                       Navigator.of(context).pop(); // Close popup
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Routescreen(initialIndex: 1),
//                         ),
//                       );
//                     },
//                     child: Center(child: Text('Fixed'))),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showCallsheetPopup(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//                 title: Text('Select Shift'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     SizedBox(height: 20),
//                     SizedBox(height: 6),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 10),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: DropdownButton<String>(
//                         value: selectedShift,
//                         hint: Text("Select Shift"),
//                         isExpanded: true,
//                         underline: SizedBox(),
//                         items: shiftList.map((shift) {
//                           return DropdownMenuItem<String>(
//                             value: shift['shift'],
//                             child: Text(shift['shift']),
//                           );
//                         }).toList(),
//                         onChanged: (shiftName) {
//                           if (shiftName != null) {
//                             Map<String, dynamic> shiftData =
//                                 shiftList.firstWhere(
//                               (shift) => shift['shift'] == shiftName,
//                             );
//                             setState(() {
//                               selectedShift = shiftName;
//                               selectedShiftId = shiftData['shiftId'];
//                             });
//                             onShiftSelected(shiftData);
//                           }
//                         },
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     ElevatedButton(
//                         onPressed: () async {
//                           final parentContext =
//                               Navigator.of(context, rootNavigator: true)
//                                   .context;

//                           Navigator.pop(context); // Close current dialog

//                           createCallSheet();
//                         },
//                         child: isLoading
//                             ? CircularProgressIndicator()
//                             : Text('OK'))
//                   ],
//                 ));
//           },
//         );
//       },
//     );
//   }

//   Future<void> passDeviceId() async {
//     final response = await http.post(
//       processRequest,
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'VMETID':
//             'MIUzptHJWQqh0+/ytZy1/Hcjc8DfNH6OdiYJYg8lXd4nQLHlsRlsZ/k6G1uj/hY5w96n9dAg032gjp9ygMGCtg0YSlEgpXVPCWi79/pGZz6Motai4bYdua29xKvWVn8X0U87I/ZG6NCwYSCAdk9/6jYc75hCyd2z59F0GYorGNPLmkhGodpfabxRr8zheVXRnG9Ko2I7/V2Y83imaiRpF7k+g43Vd9XLFPVsRukcfkxWatuW336BEKeuX6Ts9JkY0Y9BKv4IdlHkOKwgxMf22zBV7IoJkL1XlGJlVCTsvchYN9Lx8NXQksxK8UPPMbU1hCRY4Jbr0/IIfntxd4vsng==',
//       },
//       body: jsonEncode(<String, dynamic>{"deviceid": _imei.toString()}),
//     );

//     if (response.statusCode == 200) {
//       print("hbnkdhb : ${response.body}");
//       getdeviceidresponse = json.decode(response.body);
//       if (getdeviceidresponse != null &&
//           getdeviceidresponse!['responseData'] != null) {
//         setState(() {
//           projectId =
//               getdeviceidresponse!['responseData'][0]['projectId'] ?? "";
//           managerName = getdeviceidresponse!['responseData'][0]
//                   ['managerName'] ??
//               "Unknown";
//           registeredMovie =
//               getdeviceidresponse!['responseData'][0]['projectName'] ?? "N/A";
//           vmid = getdeviceidresponse!['responseData'][0]['vmId'] ?? "N/A";
//           productionTypeId =
//               getdeviceidresponse!['responseData'][0]['productionTypeId'] ?? 0;
//           productionHouse = getdeviceidresponse!['responseData'][0]
//                   ['productionHouse'] ??
//               "N/A";
//         });
//       }
//       print("Device ID sent successfully!");

//       print(response.body);
//     } else {
//       print("Failed to send Device ID: ${response.body}");
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _ensureLocationPermission();
//     lookupbyvpoidmovies();
//     shift();
//     initializeDevice();
//     passDeviceId();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color(0xFF2B5682),
//                 Color(0xFF24426B),
//               ],
//             ),
//           ),
//         ),
//         Scaffold(
//           backgroundColor: Colors.transparent,
//           appBar: AppBar(
//             automaticallyImplyLeading: false,
//             title: Text(productionTypeId == 3 ? 'Movies' : ''),
//           ),
//           body: SafeArea(
//             child: SingleChildScrollView(
//               child: ResponsiveBuilder(
//                 builder: (context, sizingInformation) {
//                   final isMobile =
//                       sizingInformation.deviceScreenType == DeviceScreenType.mobile;

//                   if (productionTypeId == 3) {
//                     if (movieProjects.isEmpty) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     return ListView.builder(
//                       itemCount: movieProjects.length,
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isMobile ? 10 : 40,
//                         vertical: 10,
//                       ),
//                       itemBuilder: (context, index) {
//                         final project = movieProjects[index];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           child: Card(
//                             elevation: 4,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ListTile(
//                               leading:
//                                   const Icon(Icons.movie, color: Colors.deepPurple),
//                               title: Text(
//                                 project['projectTitle'],
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: isMobile ? 16 : 20,
//                                 ),
//                               ),
//                               trailing: const Icon(Icons.chevron_right),
//                               onTap: () {
//                                 setState(() {
//                                   selectedProjectId = project['projectId'].toString();
//                                   selectedProjectTitle =
//                                       project['projectTitle'].toString();
//                                 });

//                                 if (selectedProjectId != null &&
//                                     selectedProjectId!.isNotEmpty) {
//                                   _showInitialPopup(context);
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                         content: Text('Please select a movie first')),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   } else {
//                     return Center(
//                       child: Container(
//                         // width: isMobile ? double.infinity : 400,
//                         padding: EdgeInsets.all(20),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               registeredMovie ?? "Loading...",
//                               style: TextStyle(
//                                 fontSize: isMobile ? 24 : 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               productionHouse ?? "Loading...",
//                               style: TextStyle(
//                                 fontSize: isMobile ? 16 : 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.purple,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
