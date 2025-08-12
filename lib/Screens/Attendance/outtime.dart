import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:production/background_sync.dart';
import 'package:provider/provider.dart';
import 'package:production/Screens/Attendance/nfcnotifier.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OuttimeScreen extends StatefulWidget {
  @override
  _OuttimeScreenState createState() => _OuttimeScreenState();
}

class _OuttimeScreenState extends State<OuttimeScreen> {
  late NFCNotifier nfcNotifier;
  late VoidCallback nfcListener;
  // Save Outtime NFC scan to SQLite with attendance_status = '2'
  bool _isSaving = false;
  Future<void> saveOuttimeToSQLite(String vcid) async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));
      // You can add more fields as needed
      // Parse message for name, designation, code, unionName like dailogei.dart
      final nfcNotifier = Provider.of<NFCNotifier>(context, listen: false);
      final message = nfcNotifier.message ?? '';
      Map<String, dynamic> data = {
        'name': '',
        'designation': '',
        'code': '',
        'unionName': '',
        'vcid': vcid,
        'marked_at': DateTime.now().toIso8601String(),
        'latitude': '',
        'longitude': '',
        'location': '',
        'attendance_status': '2',
      };
      final lines = message.split('\n');
      for (final line in lines) {
        if (line.startsWith('Name:'))
          data['name'] = line.replaceFirst('Name:', '').trim();
        if (line.startsWith('Designation:'))
          data['designation'] = line.replaceFirst('Designation:', '').trim();
        if (line.startsWith('Code:'))
          data['code'] = line.replaceFirst('Code:', '').trim();
        if (line.startsWith('Union Name:'))
          data['unionName'] = line.replaceFirst('Union Name:', '').trim();
      }
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        data['latitude'] = position.latitude.toString();
        data['longitude'] = position.longitude.toString();
      } catch (e) {
        // Location not available, leave as empty
      }
      await db.insert('intime', data);
      await db.close();
      debugPrint('Outtime NFC saved to SQLite with attendance_status=2: $vcid');
    } finally {
      _isSaving = false;
    }
  }

  bool isLoading = false;
  List<Map<String, dynamic>> configs = [];
  String errorMessage = "";

  @override
  void initState() {
    super.initState();

    nfcNotifier = Provider.of<NFCNotifier>(context, listen: false);
    nfcListener = () async {
      final vcid = nfcNotifier.vcid;
      if (vcid != null && vcid.isNotEmpty) {
        // Store NFC scan in SQLite with attendance_status = 2
        await saveOuttimeToSQLite(vcid);
        updateDebugMessage('Outtime NFC stored locally.');
        // Show dialog with fetched data after NFC scan
        await onCardDetected();
        // Do NOT post immediately. The background sync service will handle posting.
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nfcNotifier.startNFCOperation(nfcOperation: NFCOperation.read);
      nfcNotifier.addListener(nfcListener);
    });
    @override
    void dispose() {
      nfcNotifier.removeListener(nfcListener);
      super.dispose();
    }
  }

  String debugMessage = '';
  bool isOffline = true; // default to offline
  // Save VCID only if offline
  Future<void> handleVCID(String vcid) async {
    if (isOffline) {
      await storeVCIDLocally(vcid);
      updateDebugMessage("Saved VCID locally (Offline): $vcid");
    } else {
      updateDebugMessage("Online mode: Not saving VCID locally");
    }
  }

  void updateDebugMessage(String msg) {
    setState(() {
      debugMessage = msg;
    });
  }

  Future<void> storeVCIDLocally(String vcid) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('offline_vcids') ?? [];
    if (!stored.contains(vcid)) {
      stored.add(vcid);
      await prefs.setStringList('offline_vcids', stored);
    }
  }

  Future<void> onCardDetected() async {
    final nfcNotifier = Provider.of<NFCNotifier>(context, listen: false);
    final vcid = nfcNotifier.vcid!;
    final message = nfcNotifier.message ?? "";

    await fetchConfigs();

    if (configs.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DubbingConfigDialog(
          vcid: vcid,
          message: message,
          configs: configs,
          onSave: (updatedStates) {
            dubbingConfigStates = updatedStates;
            finalDoubingMap.clear();
            finalDoubingMap.addAll(updatedStates);
          },
          onDismissed: () {},
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(errorMessage.isEmpty ? "No configs found" : errorMessage)),
      );
    }
  }

  Future<void> fetchConfigs() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        processSessionRequest,
        headers: {
          'Content-Type': 'application/json',
          'VMETID':
              "Bz0Pmf2BnX5zgYLKjoR+OJrgsp8ONRRtexO8AoYyhCYUuJUjCI2wlElILwRm0CQE8Cn2XJkvRY1FT+xuXUYUwqWYSxc40wzbecpGud3i2O4zsN1bX1FAjHWR2JgSyUXEAhjpyrtln15IkXD62j9GgqrJlR4yfFWLv14HkX+L0dMxF67Mm13f6cUQXYaQS8AJs+H2BqVwjnGqVvVaJ8tGor8cadKoDqiwst9C8g2KshLLlPLdyuKirErLThbp+qZ5nQgPJeMtvjuqU9m2p6RmsxuAZgH4+R5Z4jA2OZjlnOO/1hs4K9KWOzMovGiGLuXKfXZbII7wQdX7kItn8uepCQ==",
          'VSID': loginresponsebody?['vsid']?.toString() ?? '',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final result = jsonDecode(response.body);
        if (result['message'] == 'Success') {
          final fetchedConfigs =
              List<Map<String, dynamic>>.from(result['responseData']);
          setState(() {
            configs = fetchedConfigs;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load configs';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Exception: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OutTime"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Routescreen(initialIndex: 1)),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/markattendance.png'),
            SizedBox(height: 10),
            isLoading
                ? CircularProgressIndicator()
                : Text(
                    errorMessage.isNotEmpty
                        ? errorMessage
                        : "Tap your NFC card to begin",
                    style: TextStyle(fontSize: 16),
                  ),
          ],
        ),
      ),
    );
  }
}

class DubbingConfigDialog extends StatefulWidget {
  final List<Map<String, dynamic>> configs;
  final Function(Map<String, int>) onSave;
  final String message;
  final VoidCallback onDismissed;
  final String vcid;

  const DubbingConfigDialog({
    required this.configs,
    required this.onSave,
    required this.message,
    required this.vcid,
    required this.onDismissed,
    Key? key,
  }) : super(key: key);

  @override
  State<DubbingConfigDialog> createState() => _DubbingConfigDialogState();
}

class _DubbingConfigDialogState extends State<DubbingConfigDialog> {
  late Map<String, int> localStates; // holds 0,1 or -1 (rejected)
  Map<String, int> bitCounts = {}; // Key by dubbingConfigId or name
  bool first = false;
  String? debugMessage;
  bool _attendanceMarked = false;
  bool _isloading = false;
  String? responseMessage;
  Timer? _timer;
  int _secondsLeft = 2;

  void onIncrementTap(String configId) {
    bitCounts[configId] = (bitCounts[configId] ?? 0) + 1;
    // You can set a max limit if needed
  }

  void onDecrementTap(String configId) {
    bitCounts[configId] = (bitCounts[configId] ?? 0) - 1;
    if (bitCounts[configId]! < 0) {
      bitCounts[configId] = 0; // Prevent negative counts
    }
  }

  void onResetTap(String configId) {
    bitCounts[configId] = 0;
  }

  Map<String, int> dubbingStatusMap = {
    "mainCharacter": 0,
    "smallCharacter": 0,
    "bitCharacter": 0,
    "singlebitCharacter": 0,
    "group": 0,
    "fight": 0,
    "singlebitCharacterOtherLanguage": 0,
    "mainCharacterOtherLanguage": 0,
    "smallCharacterOtherLanguage": 0,
    "bitCharacterOtherLanguage": 0,
    "groupOtherLanguage": 0,
    "fightOtherLanguage": 0,
    "voicetest": 0,
    "correction": 0,
    "leadRole": 0,
    "secondLeadRole": 0,
    "leadRoleOtherLanguage": 0,
    "secondLeadRoleOtherLanguage": 0,
  };

  // Map UI dubbingConfigName to API keys
  final Map<String, String> apiKeyMapping = {
    'Important Character': 'mainCharacter',
    'Small Character': 'smallCharacter',
    'Multiple Bits': 'bitCharacter',
    'Single Bit Character': 'singlebitCharacter',
    'Group Voice': 'group',
    'Fight Scene': 'fight',
    'Voice Test': 'voicetest',
    'Corrections': "correction"
    // add other mappings here if needed...
  };

  Future<void> markattendance3(String vcid) async {
    if (_attendanceMarked) return;
    setState(() {
      _isloading = true;
      _attendanceMarked = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      for (var config in widget.configs) {
        final displayName = config['dubbingConfigName'] as String;
        final apiKey = apiKeyMapping[displayName] ?? _toCamelCase(displayName);

        // If type is null, force "Bits" for "Multiple Bits"
        String? type = config['type'];
        if (type == null && displayName == 'Multiple Bits') {
          type = 'Bits';
        }

        print('Processing config: $displayName, apiKey: $apiKey, type: $type');

        if (type == 'Bits') {
          int count = bitCounts[apiKey] ?? 0;
          print('bitCounts for $apiKey: $count');
          dubbingStatusMap[apiKey] = (count == 5) ? 1 : count;
        } else {
          print('localStates for $apiKey: ${localStates[apiKey]}');
          dubbingStatusMap[apiKey] = localStates[apiKey] ?? 0;
        }
      }
      print('Uploading payload: ${jsonEncode(dubbingStatusMap)}');
      final response = await http.post(
        processSessionRequest,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode({
          "data": vcid,
          "callsheetid": 0,
          "projectid": selectedProjectId.toString(),
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "attendanceStatus": 2,
          "productionTypeId": productionTypeId,
          "doubing": dubbingStatusMap,
          "location": location ?? "Unknown",
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['message'] == "Success") {
          setState(() {
            responseMessage = "Attendance marked successfully.";
            _isloading = false;
          });

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Success"),
              content: Text(responseMessage.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => NFCNotifier(),
                child: OuttimeScreen(),
              ),
            ),
          );

          // Navigate only *after* dialog is dismissed
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => NFCNotifier(),
                child: OuttimeScreen(),
              ),
            ),
          );

          return; // Exit early to prevent further navigation in finally block
        } else {
          final result = jsonDecode(response.body);
          setState(() => responseMessage = "${result['errordescription']}");
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Failed"),
              content: Text(responseMessage.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => NFCNotifier(),
                          child: OuttimeScreen(),
                        ),
                      ),
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() =>
            responseMessage = "Server error: ${response.body.toString()}");
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("failed"),
            content: Text(responseMessage.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => NFCNotifier(),
                        child: OuttimeScreen(),
                      ),
                    ),
                  );
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => responseMessage = "Attendance error: $e");
    } finally {
      setState(() => _isloading = false);
      // Remove navigation from here to avoid multiple navigations
    }
  }

  Future<void> markattendance(String vcid) async {
    setState(() {
      first = true;
    });
    if (_attendanceMarked) return;
    setState(() => _isloading = true);
    _attendanceMarked = true;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final requestbody = jsonEncode({
        "data": vcid,
        "callsheetid": productionTypeId == 3 ? 0 : callsheetid,
        "projectid": productionTypeId == 3 ? selectedProjectId : projectId,
        "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
        "doubing": {
          "mainCharacter": 0,
          "smallCharacter": 0,
          "bitCharacter": 0,
          "singlebitCharacter": 0,
          "group": 0,
          "fight": 0,
          "singlebitCharacterOtherLanguage": 0,
          "mainCharacterOtherLanguage": 0,
          "smallCharacterOtherLanguage": 0,
          "bitCharacterOtherLanguage": 0,
          "groupOtherLanguage": 0,
          "fightOtherLanguage": 0,
          "voicetest": 0,
          "correction": 0,
          "leadRole": 0,
          "secondLeadRole": 0,
          "leadRoleOtherLanguage": 0,
          "secondLeadRoleOtherLanguage": 0
        },
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "attendanceStatus": "2",
        "location": location ?? "Unknown",
      });
      print(requestbody);
      print("markattendance called with vcid: $vcid");
      // Mark attendance API call
      final response = await http.post(
        processSessionRequest, // Replace with your API URL
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
          'VSID': loginresponsebody?['vsid']?.toString() ?? "",
        },
        body: jsonEncode({
          "data": vcid,
          "callsheetid": productionTypeId == 3 ? 0 : callsheetid,
          "projectid": productionTypeId == 3 ? selectedProjectId : projectId,
          "productionTypeId": productionTypeId == 3 ? productionTypeId : 2,
          "doubing": {
            "mainCharacter": 0,
            "smallCharacter": 0,
            "bitCharacter": 0,
            "singlebitCharacter": 0,
            "group": 0,
            "fight": 0,
            "singlebitCharacterOtherLanguage": 0,
            "mainCharacterOtherLanguage": 0,
            "smallCharacterOtherLanguage": 0,
            "bitCharacterOtherLanguage": 0,
            "groupOtherLanguage": 0,
            "fightOtherLanguage": 0,
            "voicetest": 0,
            "correction": 0,
            "leadRole": 0,
            "secondLeadRole": 0,
            "leadRoleOtherLanguage": 0,
            "secondLeadRoleOtherLanguage": 0
          },
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "attendanceStatus": "2",
          "location": location ?? "Unknown",
        }),
      );
      setState(() {
        first = false;
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['message'] == "Success") {
          setState(() {
            responseMessage = "Attendance marked successfully.";
          });
          // Optional: delay before closing dialog or navigating
          await Future.delayed(Duration(seconds: 3));
          if (!mounted) return;
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => NFCNotifier(),
                child: OuttimeScreen(),
              ),
            ),
          );
        } else {
          setState(() {
            responseMessage =
                result['err'] ?? result['errordescription'] ?? "Unknown error";
          });
        }
      } else {
        setState(() {
          responseMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isloading = false;
      });
    }
  }

  void updateDebugMessage(String msg) {
    setState(() {
      debugMessage = msg;
    });
  }

  @override
  void initState() {
    super.initState();
    localStates = {};
    bitCounts = {};
    if (productionTypeId == 2 &&
        widget.message != "Please Enable NFC From Settings") {
      _secondsLeft = 1;
      _startCountdown();
    }

    for (var config in widget.configs) {
      final displayName = config['dubbingConfigName'] as String;
      final apiKey = apiKeyMapping[displayName] ?? _toCamelCase(displayName);
      final type = config['type'];

      localStates[apiKey] = 0;
      if (type == 'Bits') {
        bitCounts[apiKey] = 0;
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsLeft == 0) {
        _timer?.cancel();

        await markattendance(widget.vcid);

        if (!mounted) return;

        // Wait 5 seconds before closing the dialog and navigating
        await Future.delayed(Duration(seconds: 2));

        // Now close dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        // Navigate after closing dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => NFCNotifier(),
              child: OuttimeScreen(),
            ),
          ),
        );

        widget.onDismissed();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String _toCamelCase(String input) {
    final words = input.split(RegExp(r'[\s_]+'));
    final camel = words.first.toLowerCase() +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
    return camel;
  }

  String transformVcidToImageUrl(String vcid) {
    final transformedVcid = vcid
        .replaceAll('/', '_')
        .replaceAll('=', '-')
        .replaceAll('+', '-')
        .replaceAll('#', '-');
    return 'https://vfs.vframework.in/Upload/vcard/Image/$transformedVcid.png';
  }

  void _reject(String apiKey) {
    setState(() {
      localStates[apiKey] = -1;
      if (bitCounts.containsKey(apiKey)) bitCounts[apiKey] = 0;
      dubbingStatusMap[apiKey] = -1;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$apiKey rejected")));
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = transformVcidToImageUrl(widget.vcid);
    final isNfcDisabled = widget.message == "Please Enable NFC From Settings";
    return AlertDialog(
      title: productionTypeId == 3
          ? Text("Select Dubbing Configurations")
          : Text('Attendance'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ClipOval(
              child: widget.vcid.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person,
                            size: 60, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Text(widget.message, textAlign: TextAlign.center),
            if (responseMessage != null && responseMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  responseMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: responseMessage == "Attendance marked successfully."
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            productionTypeId == 3
                ? Column(
                    children: widget.configs.map((config) {
                      final displayName = config['dubbingConfigName'] as String;
                      final apiKey = apiKeyMapping[displayName] ??
                          _toCamelCase(displayName);
                      final bool isMultipleBits =
                          displayName == 'Multiple Bits';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(displayName)),
                          if (isMultipleBits)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      int current = bitCounts[apiKey] ?? 0;
                                      if (current > 0) {
                                        bitCounts[apiKey] = current - 1;
                                        localStates[apiKey] =
                                            (bitCounts[apiKey]! > 0) ? 1 : 0;
                                      }
                                    });
                                  },
                                ),
                                Text('${bitCounts[apiKey] ?? 0}'),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      int current = bitCounts[apiKey] ?? 0;
                                      if (current < 5) {
                                        bitCounts[apiKey] = current + 1;
                                        localStates[apiKey] = 1;
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      bitCounts[apiKey] = 0;
                                      localStates[apiKey] = -1;
                                    });
                                  },
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Checkbox(
                                  value: localStates[apiKey] == 1,
                                  onChanged: (val) {
                                    setState(() {
                                      localStates[apiKey] = val == true ? 1 : 0;
                                      if (bitCounts.containsKey(apiKey)) {
                                        bitCounts[apiKey] = 0;
                                      }
                                    });
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _reject(apiKey);
                                  },
                                  child: Container(
                                      width: 50,
                                      height: 20,
                                      color: Colors.red,
                                      child: Center(
                                        child: Text(
                                          'reject',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )),
                                )
                              ],
                            ),
                        ],
                      );
                    }).toList(),
                  )
                : SizedBox(),
            if (_isloading) CircularProgressIndicator(),
          ],
        ),
      ),
      actions: productionTypeId == 2
          ? [] // No buttons if type is 2
          : [
              ElevatedButton(
                onPressed: _isloading || isNfcDisabled
                    ? null
                    : () async {
                        if (productionTypeId == 3) {
                          widget.onSave(dubbingStatusMap);
                          await markattendance3(
                              widget.vcid); // 👈 Make sure this is called
                        }
                      },
                child: Text('Save'),
              ),
              ElevatedButton(
                onPressed: _isloading || isNfcDisabled
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => NFCNotifier(),
                              child: OuttimeScreen(),
                            ),
                          ),
                        );
                      },
                child: Text('Cancel'),
              ),
            ],
    );
  }
}
