import 'package:flutter/material.dart';
import 'package:production/Screens/Attendance/dailogei.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';

import 'package:provider/provider.dart';

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

  // Future<void> handleVCID(String vcid) async {
  //   await AttendanceService.markAttendance(vcid);
  //   updateDebugMessage("Marked Attendance Online: $vcid");
  // }

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
  void dispose() {
    // Stop NFC when leaving the screen
    try {
      Provider.of<NFCNotifier>(context, listen: false).dispose();
    } catch (e) {
      print('Error disposing NFC: $e');
    }
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
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
                        final currentMessage = provider.message;
                        final currentVcid = provider.vcid;
                        provider.clearNfcData();
                        showResultDialogi(
                          context,
                          currentMessage,
                          () {
                            // Restart NFC listening after dialog closes
                            Future.delayed(Duration(milliseconds: 500), () {
                              if (mounted) {
                                Provider.of<NFCNotifier>(context, listen: false)
                                    .startNFCOperation(
                                        nfcOperation: NFCOperation.read);
                              }
                            });
                          },
                          currentVcid.toString(),
                          '1', // In-time attendance status
                        );
                        // await handleVCID(provider.vcid.toString());
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
