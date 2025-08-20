import 'dart:convert';
// import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';
import 'package:flutter_device_imei/flutter_device_imei.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  // Database helper instance
  static Database? _database;

  // Initialize database
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    print('🔄 Initializing SQLite database...');
    _database = await _initDatabase();
    print('✅ Database initialization completed');
    return _database!;
  }

  // Create database and login table (with profile_image field)
  Future<Database> _initDatabase() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      print('📍 Database path: $dbPath');

      final db = await openDatabase(
        dbPath,
        version: 4, // Increment version to force recreation
        onCreate: (Database db, int version) async {
          // await db.execute('DROP TABLE IF EXISTS login_data');
          print('📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊hvjhjvkjhgvhjgjmnvbkjgjbvn📊');
          print('🔨 Creating login_data table...');
          await db.execute('''
            CREATE TABLE login_data (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              manager_name TEXT,
              profile_image TEXT,
              registered_movie TEXT,
              mobile_number TEXT,
              password TEXT,
              project_id TEXT,
              production_type_id INTEGER,
              production_house TEXT,
              vmid INTEGER,
              login_date TEXT,
              device_id TEXT,
              vsid TEXT
            )
          ''');
          print('✅ SQLite login_data table created successfully');
        },
        // onUpgrade is not needed unless you want to handle migrations
      );

      // Test database connectivity
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('📋 Available tables: $tables');

      return db;
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  // Save login data to SQLite (ONLY if table is empty - first user only)
  Future<void> saveLoginData() async {
    try {
      print('🔄 Starting saveLoginData...');
      final db = await database;
      print('✅ Database connection obtained');

      // Use a transaction to ensure the database stays open
      await db.transaction((txn) async {
        // For testing purposes, clear existing data first
        await txn.delete('login_data');
        print('🗑️ Cleared existing login data for fresh test');

        // Check if table already contains any data
        final existingData = await txn.query('login_data');
        print('📊 Existing data count: ${existingData.length}');

        if (existingData.isNotEmpty) {
          print(
              '🚫 Login table already contains data. Skipping insert (First user only policy)');
          print('📊 Existing records count: ${existingData.length}');
          print(
              '👤 First user: ${existingData.first['manager_name']} (${existingData.first['mobile_number']})');
          return; // Exit without adding new data
        }

        // Table is empty, proceed with first user registration
        print('✅ Login table is empty. Adding first user data...');
        print('🔍 Current ProfileImage variable value: "$ProfileImage"');
        print('🔍 ProfileImage type: ${ProfileImage.runtimeType}');
        print('🔍 ProfileImage length: ${ProfileImage?.length}');

        // Prepare login data for first user
        final loginData = {
          'manager_name': managerName ?? '',
          'profile_image': ProfileImage ?? '',
          'registered_movie': registeredMovie ?? '',
          'mobile_number': loginmobilenumber.text,
          'password': loginpassword.text,
          'project_id': projectId ?? '',
          'production_type_id': productionTypeId ?? 0,
          'production_house': productionHouse ?? '',
          'vmid': vmid ?? 0,
          'login_date': DateTime.now().toIso8601String(),
          'device_id': _deviceId,
          'vsid': loginresponsebody?['vsid']?.toString() ?? '',
        };

        print(
            '📝 ProfileImage value being saved: "${loginData['profile_image']}"');
        print('📝 Full login data being saved: $loginData');
        print('📝 Adding FIRST USER login data: $loginData');

        // Insert first user login data within transaction
        final insertResult = await txn.insert(
          'login_data',
          loginData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        print(
            '🎉 FIRST USER login data saved to SQLite successfully with ID: $insertResult');
      });

      // Verify the data was stored correctly outside transaction
      final savedData = await getActiveLoginData();
      print('🔍 Verification - Retrieved first user data: $savedData');
    } catch (e) {
      print('❌ Error saving login data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      // Reset database connection on error
      if (e.toString().contains('database_closed')) {
        print('🔄 Resetting database connection due to closed database');
        _database = null;
      }
    }
  }

  // Get active login data from SQLite (first user only)
  Future<Map<String, dynamic>?> getActiveLoginData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC', // Get the first user (lowest ID)
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      print('Error getting login data: $e');
      return null;
    }
  }

  // Get first user data (helper function)
  Future<Map<String, dynamic>?> getFirstUserData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC', // Always get the first user
        limit: 1,
      );

      if (maps.isNotEmpty) {
        print(
            '👤 First user found: ${maps.first['manager_name']} (${maps.first['mobile_number']})');
        return maps.first;
      }
      print('🔍 No users found in database');
      return null;
    } catch (e) {
      print('Error getting first user data: $e');
      return null;
    }
  }

  // Test SQLite functionality
  Future<void> testSQLite() async {
    try {
      print('🧪 Running SQLite test...');
      final db = await database;

      // Test basic query
      final result = await db.rawQuery('SELECT sqlite_version()');
      print('📊 SQLite Version: $result');

      // Test table existence
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='login_data'");
      print('🔍 Login table exists: ${tables.isNotEmpty}');

      if (tables.isNotEmpty) {
        // Test table structure
        final columns = await db.rawQuery('PRAGMA table_info(login_data)');
        print('📋 Table structure: $columns');
      }

      print('✅ SQLite test completed successfully');
    } catch (e) {
      print('❌ SQLite test failed: $e');
    }
  }

  // Clear first user login data (removes the registered first user)
  Future<void> clearLoginData() async {
    try {
      final db = await database;

      // Get first user info before deleting
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        print(
            '🗑️ Clearing first user: ${firstUser['manager_name']} (${firstUser['mobile_number']})');
      }

      // Delete all records (reset for new first user)
      await db.delete('login_data');
      print(
          '✅ First user login data cleared successfully - Ready for new first user registration');
    } catch (e) {
      print('❌ Error clearing login data: $e');
    }
  }

  Future<bool> isNfcSupported() async {
    return await NfcManager.instance.isAvailable();
  }

  bool _isLoading = false;
  String? deviceId;
  Map? getdeviceidresponse;
  String? managerName;
  String? ProfileImage;

  int? vmid;
  bool screenloading = false;
  bool _obscureText = true;
  String _deviceId = 'Unknown';

  Future<void> _initDeviceId() async {
    String deviceId = 'Unknown';
    try {
      deviceId = await FlutterDeviceImei.instance.getIMEI() ?? 'Unknown';
      print('📱 Device IMEI: $deviceId');
    } catch (e) {
      print('❌ Error getting device IMEI: $e');
      deviceId = 'Error-${DateTime.now().millisecondsSinceEpoch}';
    }
    if (!mounted) return;
    setState(() {
      _deviceId = deviceId;
    });
    print('🔑 Final Device ID: $_deviceId');
  }

  Future<void> initializeDevice() async {
    try {
      await _initDeviceId();
      if (_deviceId != 'Unavailable' && !_deviceId.startsWith('Failed')) {
        await passDeviceId();
      } else {
        print('Device ID not available: $_deviceId');
        // Set managerName to null to show error UI
        setState(() {
          managerName = null;
        });
      }
    } catch (e) {
      print('Error in initializeDevice: $e');
      setState(() {
        managerName = null;
      });
    }
  }

  // No permission request needed for flutter_device_imei

  Future<void> passDeviceId() async {
    setState(() {
      screenloading = true;
    });

    try {
      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'MIUzptHJWQqh0+/ytZy1/Hcjc8DfNH6OdiYJYg8lXd4nQLHlsRlsZ/k6G1uj/hY5w96n9dAg032gjp9ygMGCtg0YSlEgpXVPCWi79/pGZz6Motai4bYdua29xKvWVn8X0U87I/ZG6NCwYSCAdk9/6jYc75hCyd2z59F0GYorGNPLmkhGodpfabxRr8zheVXRnG9Ko2I7/V2Y83imaiRpF7k+g43Vd9XLFPVsRukcfkxWatuW336BEKeuX6Ts9JkY0Y9BKv4IdlHkOKwgxMf22zBV7IoJkL1XlGJlVCTsvchYN9Lx8NXQksxK8UPPMbU1hCRY4Jbr0/IIfntxd4vsng==',
        },
        body: jsonEncode(<String, dynamic>{"deviceid": _deviceId.toString()}),
      );

      setState(() {
        screenloading = false;
      });

      if (response.statusCode == 200) {
        print("Device ID response: ${response.body}");
        getdeviceidresponse = json.decode(response.body);

        if (getdeviceidresponse != null &&
            getdeviceidresponse!['responseData'] != null &&
            getdeviceidresponse!['responseData'] is List &&
            (getdeviceidresponse!['responseData'] as List).isNotEmpty) {
          setState(() {
            final responseData = getdeviceidresponse!['responseData'][0];
            projectId = responseData['projectId'] ?? "";
            managerName = responseData['managerName'] ?? "Unknown";
            ProfileImage = responseData['profileImage'] ?? "Unknown";
            registeredMovie = responseData['projectName'] ?? "N/A";
            vmid = responseData['vmId'] ?? "N/A";
            productionTypeId = responseData['productionTypeId'] ?? 0;
            productionHouse = responseData['productionHouse'] ?? "N/A";
          });
        } else {
          print("Warning: responseData is null, not a list, or empty");
          setState(() {
            managerName = null; // This will trigger the error message UI
          });
        }
        print("Device ID sent successfully!");
      } else {
        print("Failed to send Device ID: ${response.body}");
        setState(() {
          managerName = null; // Trigger error message UI on failed request
        });
      }
    } catch (e) {
      print("Error in passDeviceId: $e");
      setState(() {
        screenloading = false;
        managerName = null; // Trigger error message UI on exception
      });
    }
  }

  Future<void> baseurl() async {
    try {
      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'VMETID':
              'byrZ4bZrKm09R4O7WH6SPd7tvAtGnK1/plycMSP8sD5TKI/VZR0tHBKyO/ogYUIf4Qk6HJXvgyGzg58v0xmlMoRJABt3qUUWGtnJj/EKBsrOaFFGZ6xAbf6k6/ktf2gKsruyfbF2/D7r1CFZgUlmTmubGS1oMZZTSU433swBQbwLnPSreMNi8lIcHJKR2WepQnzNkwPPXxA4/XuZ7CZqqsfO6tmjnH47GoHr7H+FC8GK24zU3AwGIpX+Yg/efeibwapkP6mAya+5BTUGtNtltGOm0q7+2EJAfNcrSTdmoDB8xBerLaNNHhwVHowNIu+8JZl2QM0F/gmVpB55cB8rqg=='
        },
        body: jsonEncode(
            <String, String>{"baseURL": "producermember.cinefo.club"}),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody != null && responseBody['result'] != null) {
          setState(() {
            baseurlresponsebody = responseBody;
            baseurlresult = responseBody['result'];
          });
        } else {
          print('Invalid base URL response structure');
        }
      } else {
        print('Failed to get base URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in baseurl(): $e');
    }
  }

  Future<void> loginr() async {
    print("loginr() called📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊");
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if baseurlresult is available
      if (baseurlresult == null) {
        setState(() {
          _isLoading = false;
        });
        showmessage(context, "Base URL not loaded. Please try again.", "ok");
        return;
      }

      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VPID': baseurlresult?['vpid']?.toString() ?? '',
          "BASEURL": "producermember.cinefo.club",
          'VPTEMPLATEID': baseurlresult?['vptemplteID']?.toString() ?? '',
          'VMETID':
              'jcd3r0UZg4FnqnFKCfAZqwj+d5Y7TJhxN6vIvKsoJIT++90iKP3dELmti79Q+W7aVywvVbhfoF5bdW32p33PbRRTT27Jt3pahRrFzUe5s0jQBoeE0jOraLITDQ6RBv0QoscoOGxL7n0gEWtLE15Bl/HSF2kG5pQYft+ZyF4DNsLf7tGXTz+w/30bv6vMTGmwUIDWqbEet/+5AAjgxEMT/G4kiZifX0eEb3gMxycdMchucGbMkhzK+4bvZKmIjX+z6uz7xqb1SMgPnjKmoqCk8w833K9le4LQ3KSYkcVhyX9B0Q3dDc16JDtpEPTz6b8rTwY8puqlzfuceh5mWogYuA=='
        },
        body: jsonEncode(<String, dynamic>{
          "mobileNumber": loginmobilenumber.text,
          "password": loginpassword.text,
        }),
      );
      print(
          "Login HTTP status:📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊hvjhjvkjhgvhjgjmnvbkjgjbvn📊 ${response.statusCode}");

      // Print response body in chunks to avoid truncation
      final responseBody = response.body;
      print("Login HTTP response length: ${responseBody.length}");
      const chunkSize = 800; // Safe chunk size for Flutter console
      for (int i = 0; i < responseBody.length; i += chunkSize) {
        final end = (i + chunkSize < responseBody.length)
            ? i + chunkSize
            : responseBody.length;
        final chunk = responseBody.substring(i, end);
        print("Login HTTP response chunk ${(i ~/ chunkSize) + 1}: $chunk");
      }
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          print("📊 Decoded JSON response:");
          print("📊 Response keys: ${responseBody.keys.toList()}");

          if (responseBody['responseData'] != null) {
            print(
                "📊 ResponseData keys: ${responseBody['responseData'].keys.toList()}");
            print("📊 ResponseData content: ${responseBody['responseData']}");

            // Check if profileImage exists in responseData
            if (responseBody['responseData']['profileImage'] != null) {
              print(
                  "📸 ProfileImage found in responseData: ${responseBody['responseData']['profileImage']}");
            } else {
              print("⚠️ ProfileImage NOT found in responseData");
            }
          }

          if (responseBody['vsid'] != null) {
            print("📊 VSID: ${responseBody['vsid']}");
          }

          if (responseBody != null && responseBody['responseData'] != null) {
            setState(() {
              loginresponsebody = responseBody;
              loginresult = responseBody['responseData'];

              // Update ProfileImage from login response if available
              // Check multiple possible locations for profileImage
              String? loginProfileImage;

              if (responseBody['responseData'] is Map &&
                  responseBody['responseData']['profileImage'] != null) {
                loginProfileImage =
                    responseBody['responseData']['profileImage'];
                print(
                    '📸 Found ProfileImage in responseData map: $loginProfileImage');
              } else if (responseBody['responseData'] is List &&
                  (responseBody['responseData'] as List).isNotEmpty) {
                final firstItem = (responseBody['responseData'] as List)[0];
                if (firstItem is Map && firstItem['profileImage'] != null) {
                  loginProfileImage = firstItem['profileImage'];
                  print(
                      '📸 Found ProfileImage in responseData list[0]: $loginProfileImage');
                }
              } else if (responseBody['profileImage'] != null) {
                loginProfileImage = responseBody['profileImage'];
                print(
                    '📸 Found ProfileImage in root response: $loginProfileImage');
              }

              if (loginProfileImage != null &&
                  loginProfileImage.isNotEmpty &&
                  loginProfileImage != 'Unknown') {
                ProfileImage = loginProfileImage;
                print(
                    '📸 Updated ProfileImage from login response: $ProfileImage');
              } else {
                print(
                    '⚠️ No valid ProfileImage found in login response, keeping existing: $ProfileImage');
              }
            });

            if (productionTypeId == 3) {
              // Update ProfileImage from login response before saving
              String? loginProfileImage;

              if (responseBody['responseData'] is Map &&
                  responseBody['responseData']['profileImage'] != null) {
                loginProfileImage =
                    responseBody['responseData']['profileImage'];
                print(
                    '📸 Found ProfileImage in responseData map: $loginProfileImage');
              } else if (responseBody['responseData'] is List &&
                  (responseBody['responseData'] as List).isNotEmpty) {
                final firstItem = (responseBody['responseData'] as List)[0];
                if (firstItem is Map && firstItem['profileImage'] != null) {
                  loginProfileImage = firstItem['profileImage'];
                  print(
                      '📸 Found ProfileImage in responseData list[0]: $loginProfileImage');
                }
              } else if (responseBody['profileImage'] != null) {
                loginProfileImage = responseBody['profileImage'];
                print(
                    '📸 Found ProfileImage in root response: $loginProfileImage');
              }

              if (loginProfileImage != null &&
                  loginProfileImage.isNotEmpty &&
                  loginProfileImage != 'Unknown') {
                ProfileImage = loginProfileImage;
                print(
                    '📸 Updated ProfileImage before saving (prod type 3): $ProfileImage');
              } else {
                print(
                    '⚠️ No valid ProfileImage found for prod type 3, keeping existing: $ProfileImage');
              }

              // Save login data to SQLite after successful login
              print('🔄 Production type 3 - saving login data...');
              await saveLoginData();

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Routescreen()),
                );
              }
            } else {
              print(productionTypeId);
              final loginVmid = loginresult?['vmid'];
              if (vmid != null && loginVmid != null && vmid == loginVmid) {
                // Update ProfileImage from login response if available
                String? loginProfileImage;

                if (loginresult is Map &&
                    loginresult?['profileImage'] != null) {
                  loginProfileImage = loginresult!['profileImage'];
                  print(
                      '📸 Found ProfileImage in loginresult map: $loginProfileImage');
                } else if (loginresult is List &&
                    (loginresult as List).isNotEmpty) {
                  final firstItem = (loginresult as List)[0];
                  if (firstItem is Map && firstItem['profileImage'] != null) {
                    loginProfileImage = firstItem['profileImage'];
                    print(
                        '📸 Found ProfileImage in loginresult list[0]: $loginProfileImage');
                  }
                }

                if (loginProfileImage != null &&
                    loginProfileImage.isNotEmpty &&
                    loginProfileImage != 'Unknown') {
                  ProfileImage = loginProfileImage;
                  print(
                      '📸 Updated ProfileImage from login result: $ProfileImage');
                } else {
                  print(
                      '⚠️ No valid ProfileImage found in login result, keeping existing: $ProfileImage');
                }

                // Save login data to SQLite after successful login
                print('🔄 VM ID matched - saving login data...');
                await saveLoginData();

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Routescreen()),
                  );
                }
              } else {
                showmessage(
                    context,
                    "This device is not registered. Please contact the admin",
                    "ok");
              }
            }
          } else {
            showmessage(context, "Invalid response from server", "ok");
          }
        } catch (e) {
          print("Error parsing login response: $e");
          showmessage(context, "Failed to process login response", "ok");
        }
      } else {
        try {
          final errorBody = json.decode(response.body);
          setState(() {
            loginresponsebody = errorBody;
          });
          showmessage(
              context, errorBody?['errordescription'] ?? "Login failed", "ok");
        } catch (e) {
          print("Error parsing error response: $e");
          showmessage(context, "Login failed", "ok");
        }
        print(response.body + "📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊");
      }
    } catch (e) {
      print("Error in loginr(): $e");
      setState(() {
        _isLoading = false;
      });
      showmessage(context, "Network error. Please try again.", "ok");
    }
  }

  @override
  void dispose() {
    // Don't close database here - let it close naturally
    // _database?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Starting app initialization...');

      // Test SQLite functionality
      await testSQLite();

      // First load base URL
      print('🌐 Loading base URL...');
      await baseurl();
      print('✅ Base URL loaded');

      // Then initialize device
      print('📱 Initializing device...');
      await initializeDevice();
      print('✅ Device initialization completed');
    } catch (e) {
      print('❌ Error during app initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle background overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF164AE9).withOpacity(0.15),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.04),
                // Logo/Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: screenWidth * 0.22,
                        height: screenWidth * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
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
                      SizedBox(height: 12),
                      Text(
                        'Production Login',
                        style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF164AE9),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: managerName == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.redAccent, size: 48),
                                    SizedBox(height: 16),
                                    Text(
                                      'The current device is not configured.\nPlease contact the admin',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.045,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "$_deviceId",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.07),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.06,
                                    vertical: screenHeight * 0.04,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Welcome $managerName!",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Registered Movie: $registeredMovie',
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            color: Colors.grey[700]),
                                      ),
                                      SizedBox(height: screenHeight * 0.04),
                                      TextFormField(
                                        controller: loginmobilenumber,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelText: 'Mobile Number',
                                          prefixIcon: Icon(Icons.phone,
                                              color: Color(0xFF164AE9)),
                                          labelStyle: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      TextFormField(
                                        controller: loginpassword,
                                        keyboardType:
                                            TextInputType.visiblePassword,
                                        obscureText: _obscureText,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock,
                                              color: Color(0xFF164AE9)),
                                          labelStyle: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureText
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // TODO: Implement forgot password
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: Color(0xFF164AE9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.03),
                                      SizedBox(
                                        width: double.infinity,
                                        height: screenHeight * 0.07,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  loginr();
                                                },
                                          style: ElevatedButton.styleFrom(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            padding: EdgeInsets.zero,
                                            backgroundColor: null,
                                          ).copyWith(
                                            backgroundColor:
                                                MaterialStateProperty
                                                    .resolveWith<Color?>(
                                                        (states) {
                                              if (states.contains(
                                                  MaterialState.disabled)) {
                                                return Colors.grey[400];
                                              }
                                              return null;
                                            }),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF164AE9),
                                                  Color(0xFF4F8CFF),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: _isLoading
                                                  ? CircularProgressIndicator(
                                                      color: Colors.white,
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'Login',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                screenWidth *
                                                                    0.045,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(Icons.login,
                                                            color:
                                                                Colors.white),
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
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                  child: Text(
                    'v.2.0.0',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
