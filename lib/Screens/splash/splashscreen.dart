import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/variables.dart';
import 'package:production/Screens/Login/loginscreen.dart';
import 'package:production/Screens/Home/MyHomescreen.dart';
import 'package:production/Screens/Route/RouteScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Database? _database;
  @override
  void initState() {
    super.initState();
    _initializeSplashScreen();
  }

  Future<void> _initializeSplashScreen() async {
    // Wait for 1 second to display splash screen
    await Future.delayed(Duration(seconds: 1));

    try {
      // Get active login data
      final loginData = await _getActiveLoginData();

      if (loginData != null) {
        // Load stored data into global variables
        _loadStoredDataIntoVariables(loginData);

        // Check vsid and navigate accordingly
        if (loginData['vsid'] == null) {
          // Navigate to login screen if vsid is null
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Loginscreen()),
            );
          }
        } else {
          // Navigate to home screen if vsid exists
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Routescreen()),
            );
          }
        }
      } else {
        // No login data found, navigate to login screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Loginscreen()),
          );
        }
      }
    } catch (e) {
      print('Error during splash initialization: $e');
      // On error, navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loginscreen()),
        );
      }
    }
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
                  ],
                ),
              ),
            ),

            // Version info
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'v.4.0.2',
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
