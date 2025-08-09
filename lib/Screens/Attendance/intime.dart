import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:production/Screens/Attendance/attendanceservice.dart';
import 'package:production/Screens/Attendance/dailogei.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntimeScreen extends StatelessWidget {
  const IntimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NFCNotifier>(
      create: (_) => NFCNotifier(),
      builder: (context, child) => _IntimeScreenBody(),
    );
  }
}

class _IntimeScreenBody extends StatefulWidget {
  @override
  State<_IntimeScreenBody> createState() => _IntimeScreenBodyState();
}

class _IntimeScreenBodyState extends State<_IntimeScreenBody> {
  String debugMessage = '';
  bool isOffline = false; // 🔁 default is Online

  Future<void> handleVCID(String vcid) async {
    await AttendanceService.markAttendance(vcid);
    updateDebugMessage("Marked Attendance Online: $vcid");
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

                    if (provider.message.isNotEmpty && provider.vcid != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        await handleVCID(provider.vcid.toString());
                        final currentMessage = provider.message;
                        final currentVcid = provider.vcid;
                        provider.clearNfcData();
                        showResultDialogi(
                          context,
                          currentMessage,
                          () {},
                          currentVcid.toString(),
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
