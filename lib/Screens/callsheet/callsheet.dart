import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Attendance/intime.dart';
import 'package:production/Screens/Attendance/outtimecharles.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Home/colorcode.dart';
import 'package:production/Screens/callsheet/closecallsheet.dart';
import 'package:production/Screens/callsheet/createcallsheet.dart';
import 'package:production/Screens/configuration/configuration.dart';
import 'package:production/variables.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class CallSheet extends StatefulWidget {
  const CallSheet({super.key});

  @override
  State<CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends State<CallSheet> {
  bool screenloading = false;
  Timer? _timer;
  String? managerName;

  String? callsheetname;
  String? shift;
  String? date;

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

  bool _isFetching = false;

  bool _hasPrinted = false;
  Future<void> passProjectid() async {
    if (_isFetching) return;
    _isFetching = true;

    // Check if widget is still mounted before calling setState
    if (!mounted) {
      _isFetching = false;
      return;
    }

    setState(() {
      screenloading = true;
    });

    try {
      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'jcE4lU852/+XbxPdJm8fG6BUxYLRihYi8j7I3u4P8cyvB9wQjFzbbRWvQnVm+b3UU6oSS7uyJPQ0E0fStyI6G03jIsbO8NpC9OrUUTeGbt2+7H5TTcq9K7oXByB/T4TTJJVJyOEUwXi0vOgPpnEYeL2QQ+LxZV7br3QCXrtfpP+plZGOOXNgu3bql5ui24sNddmvEOo8e32zn1Kuj+rrh1R7eyxdh8kw9veA0iNJhQBSBEF3h8k+Rpj9rBf9W+Hrixki4wQKXOKBux1TyLD9lJIMu/3by0bFHWffyTnys27RbpjGHkgAVyodrZQZLGfi1qMS7DmCx/MASuaGEQAP9w==',
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode(<String, dynamic>{"projectid": projectId.toString()}),
      );

      if (response.statusCode == 200) {
        passProjectidresponse = json.decode(response.body);
        if (!_hasPrinted) {
          print(projectId.toString());
          print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌");
          print(passProjectidresponse);
          _hasPrinted = true;
        }

        if (passProjectidresponse != null &&
            passProjectidresponse!['responseData'] != null &&
            mounted) {
          // Check mounted before setState
          setState(() {
            callsheetname = passProjectidresponse!['responseData'][0]
                    ['callsheetname'] ??
                "Unknown";
            callsheetid = passProjectidresponse!['responseData'][0]
                    ['callsheetid'] ??
                "Unknown";
            shift =
                passProjectidresponse!['responseData'][0]['shift'] ?? "Unknown";
            date = passProjectidresponse!['responseData'][0]['createdDate'] ??
                "Unknown";
          });
        }
      } else {
        if (!_hasPrinted) {
          print(projectId.toString());
          _hasPrinted = true;
        }
        passProjectidresponse = json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching project ID: $e");
    } finally {
      // Check mounted before final setState
      if (mounted) {
        setState(() {
          screenloading = false;
        });
      }
      _isFetching = false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Start initial fetch
    passProjectid();

    // Set up periodic timer with mounted check
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      if (mounted && !_isFetching) {
        passProjectid();
      } else if (!mounted) {
        // Cancel timer if widget is not mounted
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    // Cancel timer and clear reference
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isMobile =
            sizingInformation.deviceScreenType == DeviceScreenType.mobile;
        final horizontalPadding = isMobile ? 20.0 : 60.0;
        final fontSizeHeader = isMobile ? 18.0 : 24.0;
        final fontSizeSub = isMobile ? 14.0 : 18.0;

        return Scaffold(
          backgroundColor: const Color.fromRGBO(247, 244, 244, 1),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Stack(
                  children: [
                    // Full screen blue container
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height - 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2B5682),
                            Color(0xFF24426B),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          top: 20,
                          right: horizontalPadding,
                          bottom: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("CallSheet",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSizeHeader,
                                        fontWeight: FontWeight.w500)),
                                const Spacer(),
                                if (productionTypeId != 3)
                                  GestureDetector(
                                    onTap: () {
                                      if (passProjectidresponse?[
                                              'errordescription'] ==
                                          "No Record found") {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const CreateCallSheet()));
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today's Schedule section above profile card
                    Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 60 : 70,
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Schedule",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: fontSizeHeader,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main callsheet container with all information
                    if (callsheetname != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: isMobile ? 120 : 130,
                          left: horizontalPadding,
                          right: horizontalPadding,
                        ),
                        child: Container(
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
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Movie name at the top center
                                Text(
                                  registeredMovie ?? "No Movie",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B5682),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                // ...existing code for the rest of the card...
                                // First row: Date and Time
                                Row(
                                  children: [
                                    // Left side - Date
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              date ?? "No Date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2B5682),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Right side - Time
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Time",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                shift ?? "No Shift",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2B5682),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                // Second row: ID and Location
                                Row(
                                  children: [
                                    // Left side - ID
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "ID",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              callsheetname ?? "Unknown",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2B5682),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Right side - Location
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Location",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              locationofcharles ?? "Chennai",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2B5682),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 25),
                                // Action buttons row
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (productionTypeId == 3 ||
                                              (productionTypeId == 2 &&
                                                  passProjectidresponse?[
                                                          'errordescription'] !=
                                                      "No Record found")) {
                                            isoffline = false;
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
                                        },
                                        child: _actionButton(
                                          "In-time",
                                          Icons.login,
                                          AppColors.primaryLight,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
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
                                        },
                                        child: _actionButton(
                                          "Out-time",
                                          Icons.logout,
                                          AppColors.primaryLight,
                                        ),
                                      ),
                                      if (productionTypeId != 3)
                                        GestureDetector(
                                          onTap: () {
                                            if (passProjectidresponse?[
                                                    'errordescription'] !=
                                                "No Record found") {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const ConfigurationScreen()));
                                            }
                                          },
                                          child: _actionButton(
                                            "Config",
                                            Icons.settings,
                                            AppColors.primaryLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Close callsheet button
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CloseCallSheet(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Close Callsheet",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
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
                      ),

                    // No callsheet message when there's no active callsheet
                    if (callsheetname == null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: isMobile ? 180 : 200,
                          left: horizontalPadding,
                          right: horizontalPadding,
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(40),
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
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No Callsheet Found",
                                    style: TextStyle(
                                      fontSize: fontSizeHeader,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Create a new callsheet to get started",
                                    style: TextStyle(
                                      fontSize: fontSizeSub,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
        );
      },
    );
  }

  Widget _actionButton(String title, IconData icon, Color color) {
    return Column(
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
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
