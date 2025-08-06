import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:production/Screens/Attendance/attendanceservice.dart';
import 'package:production/Screens/Attendance/dailogei.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntimeScreen extends StatefulWidget {
  const IntimeScreen({super.key});

  @override
  State<IntimeScreen> createState() => _IntimeScreenState();
}

class _IntimeScreenState extends State<IntimeScreen> {
  String debugMessage = '';
  bool isOffline = false; // 🔁 default is Online

  Future<void> handleVCID(String vcid) async {
    if (isOffline) {
      await storeVCIDLocally(vcid);
      updateDebugMessage("Saved VCID locally (Offline): $vcid");
    } else {
      // Online Mode – Direct API call
      await AttendanceService.markAttendance(vcid);
      updateDebugMessage("Marked Attendance Online: $vcid");
    }
  }

  Future<void> storeVCIDLocally(String vcid) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('offline_vcids') ?? [];
    if (!stored.contains(vcid)) {
      stored.add(vcid);
      await prefs.setStringList('offline_vcids', stored);
    }
  }

  void updateDebugMessage(String msg) {
    if (mounted) {
      setState(() {
        debugMessage = msg;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NFCNotifier>(context, listen: false)
          .startNFCOperation(nfcOperation: NFCOperation.read);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("In-time", style: TextStyle(color: Colors.black)),
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text("Online", style: TextStyle(color: Colors.black)),
              Switch(
                value: isOffline,
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      isOffline = value;
                      debugMessage =
                          value ? "Offline Mode ON" : "Online Mode ON";
                    });
                  }
                },
              ),
              const Text("Offline", style: TextStyle(color: Colors.black)),
              const SizedBox(width: 8),
            ],
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Routescreen(initialIndex: 1),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(debugMessage),
                Image.asset('assets/markattendance.png'),
                const SizedBox(height: 20),
                Consumer<NFCNotifier>(
                  builder: (context, provider, _) {
                    if (provider.isProcessing) {
                      return const Text(
                        'Please hold the card near',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    if (provider.message.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        await handleVCID(provider.vcid.toString());
                        Navigator.pop(context);
                        showResultDialogi(
                          context,
                          provider.message,
                          () {},
                          provider.vcid.toString(),
                        );
                      });
                    }

                    return const SizedBox();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
