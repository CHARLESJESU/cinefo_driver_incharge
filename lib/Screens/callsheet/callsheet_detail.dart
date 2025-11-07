import 'package:flutter/material.dart';
import 'package:production/Screens/Attendance/intime.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Attendance/outtimecharles.dart';
import 'package:production/Screens/Home/colorcode.dart';
import 'package:production/Screens/Route/RouteScreenforincharge.dart';
import 'package:production/Screens/configuration/configuration.dart';
import 'package:production/variables.dart';
import 'package:provider/provider.dart';

class CallsheetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> callsheet;
  const CallsheetDetailScreen({Key? key, required this.callsheet})
      : super(key: key);

  // Method to update callsheet status (Pack Up functionality)
  Future<void> _updateCallsheetStatus(
      String callSheetNo, BuildContext context) async {
    try {
      // Here you can add API call to update callsheet status to 'closed'
      // For now, just show success message
      print('✅ Callsheet status set to closed: $callSheetNo');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call sheet marked as packed up successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error updating callsheet status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating callsheet status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set global callsheetid to the current callsheet's callSheetId
    try {
      callsheetid = callsheet['callSheetId'];
    } catch (_) {
      callsheetid = null;
    }

    // Map API response to offline screen format
    final String name = callsheet['name']?.toString() ?? 'Regular';
    final String? id = callsheet['callSheetNo']?.toString();
    final String? location = callsheet['location']?.toString();
    final String? Moviename = callsheet['projectName']?.toString();
    final String? time = callsheet['shift']?.toString();

    // Format created date from API response - exactly like offline screen
    String createdAtRaw = '';
    String createdAtDisplay = '';

    try {
      if (callsheet['createdDate'] != null) {
        final dateStr = callsheet['createdDate'].toString();
        if (dateStr.contains('-')) {
          // API provides DD-MM-YYYY format
          createdAtDisplay = dateStr;
          // Convert to YYYY-MM-DD for parsing (like offline screen)
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            createdAtRaw = '${parts[2]}-${parts[1]}-${parts[0]}';
          }
        }
      } else if (callsheet['date'] != null) {
        // Handle YYYYMMDD format
        final d = callsheet['date'].toString();
        if (d.length == 8) {
          final y = d.substring(0, 4);
          final m = d.substring(4, 6);
          final day = d.substring(6, 8);
          createdAtDisplay = '$day-$m-$y';
          createdAtRaw = '$y-$m-$day';
        }
      }
    } catch (_) {
      createdAtDisplay = 'Unknown';
    }

    // Robust date comparison for button enable/disable - exact same logic as offline
    final DateTime now = DateTime.now();
    DateTime? callsheetDate;
    bool isToday = false;
    bool isPastDate = false;
    bool dateParseError = false;
    try {
      callsheetDate = DateTime.parse(createdAtRaw);
    } catch (e) {
      print('Error parsing date: $e');
      dateParseError = true;
    }
    if (callsheetDate != null) {
      final DateTime callsheetDay =
          DateTime(callsheetDate.year, callsheetDate.month, callsheetDate.day);
      final DateTime today = DateTime(now.year, now.month, now.day);
      isToday = callsheetDay == today;
      isPastDate = callsheetDay.isBefore(today);
      print('Callsheet date: '
          '${callsheetDay.toIso8601String()} | Today: ${today.toIso8601String()} | isToday: $isToday | isPastDate: $isPastDate');
    } else {
      print(
          'Callsheet date missing or invalid, enabling attendance buttons by default.');
    }
    // Button enable/disable logic - only for Pack Up button
    bool enableCloseButton =
        isToday || isPastDate || dateParseError || callsheetDate == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable automatic back button
        title: Text(
          'Callsheet Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2B5682),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color.fromRGBO(247, 244, 244, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        Moviename ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B5682),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Date",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  createdAtDisplay,
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Time",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  time ?? 'Unknown',
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "ID",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  id != null && name.isNotEmpty
                                      ? "$id-$name"
                                      : 'Unknown',
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 100,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Location",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final loc = location ?? 'Unknown';
                                    double fontSize = 10;
                                    if (loc.length > 40) {
                                      fontSize = 9;
                                    }
                                    if (loc.length > 80) {
                                      fontSize = 7;
                                    }
                                    return Text(
                                      loc,
                                      style: TextStyle(
                                        color: Color(0xFF2B5682),
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    // Action buttons row with exact same functionality as offline screen
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              print('In-time tapped. productionTypeId: '
                                  '[33m$productionTypeId[0m, passProjectidresponse: '
                                  '\u001b[33m${passProjectidresponse?['errordescription']}\u001b[0m');
                              if (productionTypeId == 3) {
                                print('Proceeding: productionTypeId == 3');
                                isoffline = true;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const IntimeScreen())));
                              } else if (productionTypeId == 2) {
                                print(
                                    'Proceeding: productionTypeId == 2 (no passProjectidresponse check)');
                                isoffline = true;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const IntimeScreen())));
                              } else {
                                // Allow access for any other productionTypeId (including 0, 1, etc.)
                                print(
                                    'Proceeding: productionTypeId == $productionTypeId (allowing access)');
                                isoffline = true;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const IntimeScreen())));
                              }
                            },
                            child: _actionButton(
                              "In-time",
                              Icons.login,
                              AppColors.primaryLight,
                              enabled: true,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              print('Out-time tapped. productionTypeId: '
                                  '[33m$productionTypeId[0m, passProjectidresponse: '
                                  '\u001b[33m${passProjectidresponse?['errordescription']}\u001b[0m');
                              if (productionTypeId == 3) {
                                print('Proceeding: productionTypeId == 3');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const Outtimecharles())));
                              } else if (productionTypeId == 2) {
                                print(
                                    'Proceeding: productionTypeId == 2 (no passProjectidresponse check)');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const Outtimecharles())));
                              } else {
                                // Allow access for any other productionTypeId (including 0, 1, etc.)
                                print(
                                    'Proceeding: productionTypeId == $productionTypeId (allowing access)');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                            create: (_) => NFCNotifier(),
                                            child: const Outtimecharles())));
                              }
                            },
                            child: _actionButton(
                              "Out-time",
                              Icons.logout,
                              AppColors.primaryLight,
                              enabled: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String title, IconData icon, Color color,
      {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5, // Make disabled buttons semi-transparent
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
