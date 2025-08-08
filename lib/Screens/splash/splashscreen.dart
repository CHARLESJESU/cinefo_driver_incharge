import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:production/Screens/Login/loginscreen.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/variables.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Database? _database;
  bool _isCheckingConnectivity = true;
  String _statusMessage = "Checking connectivity...";

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndProceed();
  }

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database connection (NO TABLE CREATION - connects to existing DB)
  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return await openDatabase(
      dbPath,
      version: 1,
      // REMOVED: onCreate callback since table is created by login screen
      // This just connects to existing database
    );
  }

  // Check internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check by trying to reach a reliable server
      // You can replace this with your app's server check
      return true;
    } catch (e) {
      print('Connectivity check error: $e');
      return false;
    }
  }

  // Get any login data from SQLite (check if table has any records)
  Future<Map<String, dynamic>?> _getActiveLoginData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC', // Get first user (matches login screen logic)
        limit: 1,
      );

      if (maps.isNotEmpty) {
        print(
            '📊 Login data found: ${maps.first['manager_name']} (${maps.first['mobile_number']})');
        return maps.first;
      }
      print('🔍 No login data found in table');
      return null;
    } catch (e) {
      print('Error getting login data: $e');
      return null;
    }
  }

  // Load stored data into global variables
  void _loadStoredDataIntoVariables(Map<String, dynamic> loginData) {
    managerName = loginData['manager_name'];
    registeredMovie = loginData['registered_movie'];
    projectId = loginData['project_id'];
    productionTypeId = loginData['production_type_id'] ?? 0;
    productionHouse = loginData['production_house'];
    vmid = loginData['vmid'];

    // Set mobile number and password in controllers
    loginmobilenumber.text = loginData['mobile_number'] ?? '';
    loginpassword.text = loginData['password'] ?? '';

    print('Loaded stored data: Manager=$managerName, Movie=$registeredMovie');
  }

  // Main connectivity check and flow control
  Future<void> _checkConnectivityAndProceed() async {
    setState(() {
      _statusMessage = "Checking internet connectivity...";
    });

    await Future.delayed(
        Duration(seconds: 2)); // Show splash for at least 2 seconds

    bool hasInternet = await _checkInternetConnectivity();

    if (hasInternet) {
      // Internet available - go to login screen
      setState(() {
        _statusMessage = "Internet connected. Loading login...";
      });

      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loginscreen()),
        );
      }
    } else {
      // No internet - show offline mode dialog
      setState(() {
        _isCheckingConnectivity = false;
        _statusMessage = "No internet connection detected";
      });

      _showOfflineModeDialog();
    }
  }

  // Show offline mode confirmation dialog
  void _showOfflineModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'Would you like to continue this app in offline mode?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryConnectivity();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedOfflineMode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(
                'Continue Offline',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Retry connectivity check
  void _retryConnectivity() {
    setState(() {
      _isCheckingConnectivity = true;
      _statusMessage = "Retrying connection...";
    });
    _checkConnectivityAndProceed();
  }

  // Proceed in offline mode
  Future<void> _proceedOfflineMode() async {
    setState(() {
      _statusMessage = "Checking offline data...";
    });

    // Check if there's ANY login data in SQLite (not null = has data)
    Map<String, dynamic>? loginData = await _getActiveLoginData();

    if (loginData == null) {
      // No login data found (table is empty) - show registration error
      print('❌ Login table is empty - showing registration error');
      _showRegistrationError();
    } else {
      // Login data found (table != null) - load it and go to route screen
      print('✅ Login data exists - proceeding to RouteScreen');
      _loadStoredDataIntoVariables(loginData);

      setState(() {
        _statusMessage = "Login data found. Loading app...";
      });

      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Routescreen()),
        );
      }
    }
  }

  // Show device not registered error
  void _showRegistrationError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Device Not Registered',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'This device is not registered. Please contact the admin.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryConnectivity();
              },
              child: Text(
                'Try Again',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the app or go to a help screen
                Navigator.of(context).pop();
                // You can add navigation to a help screen here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2B5682),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/tenkrow.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // App Title
                    Text(
                      'Production App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: 50),

                    // Loading indicator and status
                    if (_isCheckingConnectivity)
                      Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                        ],
                      ),

                    // Status message
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Version info
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'v.2.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
