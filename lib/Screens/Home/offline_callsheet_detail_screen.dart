import 'package:flutter/material.dart';
import 'package:production/Screens/Attendance/intime.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Attendance/outtimecharles.dart';
import 'package:production/Screens/Home/colorcode.dart';
import 'package:production/Screens/configuration/configuration.dart';
import 'package:production/Screens/callsheet/closecallsheet.dart';
import 'package:production/variables.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class OfflineCallsheetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> callsheet;
  const OfflineCallsheetDetailScreen({Key? key, required this.callsheet})
      : super(key: key);

  // Method to delete callsheet from SQLite database
  Future<void> _deleteCallsheetFromDB(String callSheetNo) async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      Database db = await openDatabase(dbPath);

      int result = await db.delete(
        'callsheet',
        where: 'callSheetNo = ?',
        whereArgs: [callSheetNo],
      );

      await db.close();

      if (result > 0) {
        print('✅ Callsheet deleted successfully: $callSheetNo');
      } else {
        print('⚠️ No callsheet found with ID: $callSheetNo');
      }
    } catch (e) {
      print('❌ Error deleting callsheet: $e');
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
    final String name = callsheet['callsheetname']?.toString() ?? 'Unknown';

    final String createdAtRaw =
        (callsheet['created_at']?.toString() ?? '').split('T').first;
    // For display only
    String createdAtDisplay = createdAtRaw;
    try {
      if (createdAtRaw.isNotEmpty) {
        final parts = createdAtRaw.split('-');
        if (parts.length == 3) {
          createdAtDisplay = "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      }
    } catch (_) {}
    final String? id = callsheet['callSheetNo']?.toString();
    final String? location = callsheet['location']?.toString();
    final String? Moviename = callsheet['MovieName']?.toString();
    final String? time = callsheet['shift']?.toString();

    // Get current date for comparison
    final DateTime now = DateTime.now();
    final String currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Parse the createdAtRaw date for logic
    DateTime? callsheetDate;
    try {
      callsheetDate = DateTime.parse(createdAtRaw);
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Determine button states based on date comparison
    bool isToday = createdAtRaw == currentDate;
    bool isPastDate = false;

    if (callsheetDate != null) {
      final DateTime callsheetDay =
          DateTime(callsheetDate.year, callsheetDate.month, callsheetDate.day);
      final DateTime today = DateTime(now.year, now.month, now.day);

      isPastDate = callsheetDay.isBefore(today);
    }

    // Button enable/disable logic
    bool enableAttendanceButtons =
        isToday; // In-time, Out-time, Config only enabled for today
    bool enableCloseButton =
        isToday || isPastDate; // Close button enabled for today and past dates

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
                                    double fontSize = 12;
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
                    // Action buttons row with exact same functionality as callsheet
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
                            onTap: enableAttendanceButtons
                                ? () {
                                    if (productionTypeId == 3 ||
                                        (productionTypeId == 2 &&
                                            passProjectidresponse?[
                                                    'errordescription'] !=
                                                "No Record found")) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ChangeNotifierProvider(
                                                      create: (_) =>
                                                          NFCNotifier(),
                                                      child:
                                                          const IntimeScreen())));
                                    }
                                  }
                                : null, // Disable tap when not enabled
                            child: _actionButton(
                              "In-time",
                              Icons.login,
                              enableAttendanceButtons
                                  ? AppColors.primaryLight
                                  : Colors.grey,
                              enabled: enableAttendanceButtons,
                            ),
                          ),
                          GestureDetector(
                            onTap: enableAttendanceButtons
                                ? () {
                                    if (productionTypeId == 3 ||
                                        (productionTypeId == 2 &&
                                            passProjectidresponse?[
                                                    'errordescription'] !=
                                                "No Record found")) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ChangeNotifierProvider(
                                                      create: (_) =>
                                                          NFCNotifier(),
                                                      child:
                                                          Outtimecharles())));
                                    }
                                  }
                                : null, // Disable tap when not enabled
                            child: _actionButton(
                              "Out-time",
                              Icons.logout,
                              enableAttendanceButtons
                                  ? AppColors.primaryLight
                                  : Colors.grey,
                              enabled: enableAttendanceButtons,
                            ),
                          ),
                          if (productionTypeId != 3)
                            GestureDetector(
                              onTap: enableAttendanceButtons
                                  ? () {
                                      if (passProjectidresponse?[
                                              'errordescription'] !=
                                          "No Record found") {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ConfigurationScreen()));
                                      }
                                    }
                                  : null, // Disable tap when not enabled
                              child: _actionButton(
                                "Config",
                                Icons.settings,
                                enableAttendanceButtons
                                    ? AppColors.primaryLight
                                    : Colors.grey,
                                enabled: enableAttendanceButtons,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Close callsheet button with date-based enable/disable
                    Opacity(
                      opacity: enableCloseButton ? 1.0 : 0.5,
                      child: GestureDetector(
                        onTap: enableCloseButton
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CloseCallSheet(),
                                  ),
                                );
                              }
                            : null, // Disable tap for future dates
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: enableCloseButton
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: enableCloseButton
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                color: enableCloseButton
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Close Callsheet",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: enableCloseButton
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
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
