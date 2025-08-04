import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Attendance/intime.dart';
import 'package:production/Screens/Attendance/master.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Attendance/offlinemodescreen.dart';
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

  Future<void> passProjectid() async {
    if (_isFetching) return;
    _isFetching = true;

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
        print(projectId.toString());
        passProjectidresponse = json.decode(response.body);
        print(passProjectidresponse);

        if (passProjectidresponse != null &&
            passProjectidresponse!['responseData'] != null) {
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
        print(projectId.toString());
        passProjectidresponse = json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching project ID: $e");
    } finally {
      setState(() {
        screenloading = false;
      });
      _isFetching = false;
    }
  }

  @override
  void initState() {
    super.initState();
    passProjectid();
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      if (!_isFetching) {
        passProjectid();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        final iconSize = isMobile ? 30.0 : 40.0;

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

                    // Button row with Icons
                    Padding(
                      padding: EdgeInsets.only(
                          top: isMobile ? 70 : 80,
                          left: horizontalPadding,
                          right: horizontalPadding),
                      child: Container(
                        width: double.infinity,
                        height: isMobile ? 100 : 150,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _iconButton(
                                  title: "In-time",
                                  icon: Icons.login,
                                  size: iconSize,
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
                                                          const IntimeScreen())));
                                    }
                                  },
                                  fontSize: fontSizeSub),
                              _iconButton(
                                  title: "Out-time",
                                  icon: Icons.logout,
                                  size: iconSize,
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
                                                      child: OuttimeScreen())));
                                    }
                                  },
                                  fontSize: fontSizeSub),
                              if (productionTypeId != 3)
                                _iconButton(
                                    title: "Config",
                                    icon: Icons.settings,
                                    size: iconSize,
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
                                    fontSize: fontSizeSub),
                              _iconButton(
                                  title: "Close\nCallsheet",
                                  icon: Icons.close,
                                  size: iconSize,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const CloseCallSheet()));
                                  },
                                  fontSize: fontSizeSub),
                              _iconButton(
                                  title: "offline\nCallsheet",
                                  icon: Icons.offline_bolt,
                                  size: iconSize,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const Offlinemodescreen()));
                                  },
                                  fontSize: fontSizeSub),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Schedule section
                    Padding(
                      padding: EdgeInsets.only(
                          top: isMobile ? 250 : 310,
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: 30),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's Schedule",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontSizeHeader)),
                              const SizedBox(height: 8),
                              Text(registeredMovie ?? "",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: fontSizeSub)),
                              const SizedBox(height: 30),
                              callsheetname == null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Text("No callsheet created",
                                            style: TextStyle(
                                                fontSize: fontSizeSub)),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 10),
                                            const Divider(),
                                            _infoRow("Callsheet name",
                                                callsheetname!, fontSizeSub),
                                            const SizedBox(height: 10),
                                            _infoRow("Shift", shift ?? "",
                                                fontSizeSub),
                                            const Divider(),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(date ?? "",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .primaryLight)),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _iconButton({
    required String title,
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: size, color: AppColors.primaryLight),
          const SizedBox(height: 5),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, double fontSize) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
