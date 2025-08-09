// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:production/Screens/Attendance/attendanceservice.dart';

// class Offlinemodescreen extends StatefulWidget {
//   const Offlinemodescreen({super.key});

//   @override
//   State<Offlinemodescreen> createState() => _OfflinemodescreenState();
// }

// class _OfflinemodescreenState extends State<Offlinemodescreen> {
//   List<String> vcidList = [];
//   bool isLoading = false;
//   int processedCount = 0;
//   int totalCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     loadOfflineVCIDs();
//   }

//   Future<void> loadOfflineVCIDs() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       vcidList = prefs.getStringList('offline_vcids') ?? [];
//     });
//   }

//   Future<void> syncVCIDs({required bool isInTime}) async {
//     if (vcidList.isEmpty) return;

//     setState(() {
//       isLoading = true;
//       processedCount = 0;
//       totalCount = vcidList.length;
//     });

//     for (final vcid in vcidList) {
//       if (isInTime) {
//         await AttendanceService.markAttendance(vcid);
//       } else {
//         await AttendanceService.markAttendanceOut(vcid);
//       }

//       setState(() {
//         processedCount++;
//       });
//     }

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('offline_vcids');

//     setState(() {
//       vcidList.clear();
//       isLoading = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//             isInTime ? 'In Time sync completed' : 'Out Time sync completed'),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Offline VCID Sync")),
//       body: isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const CircularProgressIndicator(),
//                   const SizedBox(height: 16),
//                   Text("Processed $processedCount of $totalCount VCIDs"),
//                 ],
//               ),
//             )
//           : vcidList.isEmpty
//               ? const Center(child: Text("No offline VCIDs found"))
//               : Column(
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: vcidList.length,
//                         itemBuilder: (context, index) {
//                           return ListTile(
//                             title: Text("VCID: ${vcidList[index]}"),
//                           );
//                         },
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16.0, vertical: 8),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: () => syncVCIDs(isInTime: true),
//                             icon: const Icon(Icons.login),
//                             label: const Text("In Time"),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () => syncVCIDs(isInTime: false),
//                             icon: const Icon(Icons.logout),
//                             label: const Text("Out Time"),
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//     );
//   }
// }
