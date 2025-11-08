import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:production/Screens/Attendance/dailogei.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:provider/provider.dart';

class IntimeScreen extends StatelessWidget {
  const IntimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set attendance status for In Time
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
  // Controller and focus node for the RFID text box
  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocusNode = FocusNode();
  // Track last RFID handled to avoid duplicate dialog launches
  String _lastHandledRfid = '';

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
      // Request focus for the RFID text box after the first frame so it
      // becomes active automatically when this screen appears.
      FocusScope.of(context).requestFocus(_rfidFocusNode);
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
    // Dispose controller and focus node
    _rfidController.dispose();
    _rfidFocusNode.dispose();
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
                // Numeric-only, auto-focused RFID text box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      controller: _rfidController,
                      focusNode: _rfidFocusNode,
                      autofocus: true,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'RFID',
                        hintText: 'Enter numeric RFID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Image.asset('assets/markattendance.png'),
                const SizedBox(height: 20),
                Consumer<NFCNotifier>(
                  builder: (context, provider, _) {
                    // If provider has an rfid value, auto-fill the text box.
                    final rawRfid = provider.rfid;
                    if (rawRfid != null && rawRfid.isNotEmpty) {
                      // Sanitize to digits only to respect the numeric-only TextField.
                      final sanitizedRfid = rawRfid.replaceAll(RegExp(r'[^0-9]'), '');
                      if (_rfidController.text != sanitizedRfid) {
                        _rfidController.text = sanitizedRfid;
                        _rfidController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _rfidController.text.length),
                        );
                        // Keep focus on the RFID field after autofill so keyboard stays active
                        FocusScope.of(context).requestFocus(_rfidFocusNode);
                      }
                    }

                    // If user typed/scanned RFID manually into the text field
                    // and its length reaches >= 10, open the result dialog once.
                    final manualRfid = _rfidController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    if (manualRfid.length >= 10 && _lastHandledRfid != manualRfid) {
                      _lastHandledRfid = manualRfid;
                      // Call the dialog with a blank vcid and the RFID from controller
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final dialogMessage = debugMessage.isNotEmpty ? debugMessage : 'Manual RFID entry detected';
                        final currentVcid = provider.vcid;
                        showResultDialogi(
                          context,
                          dialogMessage,
                          () {
                            // On dismiss: clear controller, reset last handled and restart NFC
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                _rfidController.clear();
                                _lastHandledRfid = '';
                                Provider.of<NFCNotifier>(context, listen: false)
                                    .startNFCOperation(nfcOperation: NFCOperation.read);
                                // After clearing and restarting NFC, put focus back on the RFID field
                                FocusScope.of(context).requestFocus(_rfidFocusNode);
                              }
                            });
                          },
                          currentVcid.toString(),
                          _rfidController.text, // pass the actual text string
                          '1', // In-time attendance status
                        );
                      });
                    }

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
                        // Capture RFID before clearing provider data (provider.clearNfcData() will null it)
                        final currentRfid = provider.rfid ?? '';
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
                          currentRfid,
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