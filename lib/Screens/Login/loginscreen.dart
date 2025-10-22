import 'dart:convert';
import 'dart:async';
// import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ota_update/ota_update.dart';
import 'package:production/Screens/Route/RouteScreenforincharge.dart';
import 'package:production/Screens/Route/RouteScreenfordriver.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';

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

  // Helper method to create login_data table
  Future<void> _createLoginTable(Database db) async {
    try {
      // await db.execute('DROP TABLE IF EXISTS login_data');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS login_data (
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
          vsid TEXT,
          vpid TEXT,
          vuid INTEGER,
          companyName TEXT,
          email TEXT,
          vbpid INTEGER,
          vcid INTEGER,
          vsubid INTEGER,
          vpoid INTEGER,
          mtypeId INTEGER,
          unitName TEXT,
          vmTypeId INTEGER,
          idcardurl TEXT,
          vpidpo INTEGER,
          vpidbp INTEGER,
          unitid INTEGER,
          subunitid INTEGER,
          platformlogo TEXT,
          driver BOOLEAN DEFAULT 0
        )
      ''');
      print('✅ SQLite login_data table created/verified successfully');
    } catch (e) {
      print('❌ Error creating login_data table: $e');
      rethrow;
    }
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
          print('� onCreate: Creating login_data table...');
          await _createLoginTable(db);
        },
        onOpen: (Database db) async {
          print('📂 onOpen: Ensuring login_data table exists...');
          await _createLoginTable(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          print('⬆️ onUpgrade: Recreating login_data table...');
          await db.execute('DROP TABLE IF EXISTS login_data');
          await _createLoginTable(db);
        },
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

  Future<void> startOtaUpdate(String apkUrl) async {
    try {
      final completer = Completer<void>();

      OtaUpdate()
          .execute(apkUrl, destinationFilename: 'myapp-latest.apk')
          .listen(
        (OtaEvent event) {
          // Handle OTA update events here if needed
          print('OTA Event: ${event.status} - ${event.value}');

          // Complete when download finishes (successful or not)
          if (event.status.toString().contains('DOWNLOAD') &&
              event.value == '100.0') {
            completer.complete();
          }
        },
        onError: (error) {
          print('OTA Update error: $error');
          completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      // Wait for the OTA update to complete
      await completer.future;
    } catch (e) {
      print('OTA Update failed: $e');
      rethrow;
    }
  }

  Future<bool> _showUpdateDialog(BuildContext context, String message,
      int updateTypeId, String apppath) async {
    // Returns true if Update pressed, false if Later pressed
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget dialog = AlertDialog(
            title: const Text("Update Available"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                if (isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text("Downloading update..."),
                ],
              ],
            ),
            actions: isLoading
                ? []
                : [
                    if (updateTypeId != 1)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false); // Later pressed
                        },
                        child: const Text("Later"),
                      ),
                    TextButton(
                      onPressed: () async {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          await startOtaUpdate(apppath);
                          Navigator.pop(
                              context, true); // Update pressed and completed
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                          });
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')),
                          );
                        }
                      },
                      child: const Text("Update"),
                    ),
                  ],
          );
          // Prevent back button if only Update is shown
          if (updateTypeId == 1) {
            return WillPopScope(
              onWillPop: () async => false,
              child: dialog,
            );
          } else {
            return dialog;
          }
        },
      ),
    );
    return result == true;
  }

  // Save login data to SQLite (ONLY if table is empty - first user only)
  Future<void> saveLoginData() async {
    try {
      print('🔄 Starting saveLoginData...');
      final db = await database;
      print('✅ Database connection obtained');

      // Ensure table exists before any operations
      await _createLoginTable(db);
      print('✅ Login table verified/created');

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
          'manager_name': loginresponsebody?['responseData']?['fname'] ?? '',
          'profile_image': ProfileImage ?? '',
          'registered_movie':
              loginresponsebody?['responseData']?['projectName'] ?? '',
          'mobile_number': loginmobilenumber.text,
          'password': loginpassword.text,
          'project_id': loginresponsebody?['responseData']?['projectId'] ?? '',
          'production_type_id':
              loginresponsebody?['responseData']?['productionTypeId'] ?? 0,
          'production_house':
              loginresponsebody?['responseData']?['productionHouse'] ?? '',
          'vmid': loginresponsebody?['responseData']?['vmid'] ?? 0,
          'login_date': DateTime.now().toIso8601String(),
          'vsid': loginresponsebody?['vsid']?.toString() ?? '',
          'vpid': loginresponsebody?['vpid']?.toString() ?? '',
          'vuid': loginresponsebody?['vuid'] ?? 0,
          // 'companyName': loginresponsebody?['companyName']?.toString() ?? '',
          // 'email': loginresponsebody?['email']?.toString() ?? '',
          'vbpid': loginresponsebody?['vbpid'] ?? 0,
          'vcid': loginresponsebody?['vcid'] ?? 0,
          'vsubid': loginresponsebody?['vsubid'] ?? 0,
          'vpoid': loginresponsebody?['vpoid'] ?? 0,
          'mtypeId': loginresponsebody?['mtypeId'] ?? 0,
          'unitName': loginresponsebody?['unitName']?.toString() ?? '',
          'vmTypeId': loginresponsebody?['vmTypeId'] ?? 0,
          'idcardurl': loginresponsebody?['idcardurl']?.toString() ?? '',
          'vpidpo': loginresponsebody?['vpidpo'] ?? 0,
          'vpidbp': loginresponsebody?['vpidbp'] ?? 0,
          'unitid': loginresponsebody?['unitid'] ?? 0,
          'subunitid': loginresponsebody?['subunitid'] ?? 0,
          'platformlogo': loginresponsebody?['platformlogo']?.toString() ?? '',
          'driver': 0, // Default value, will be updated based on navigation
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
      await _createLoginTable(db); // Ensure table exists
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
      await _createLoginTable(db); // Ensure table exists
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

  // Update specific login data fields for driver response
  Future<void> updateDriverLoginData(
      String projectName, String projectId, String productionHouse) async {
    print('🔄 updateDriverLoginData called');
    print('🔍 Input values:');
    print('  projectName: "$projectName"');
    print('  projectId: "$projectId"');
    print('  productionHouse: "$productionHouse"');

    try {
      print('🔄 Getting database connection...');
      final db = await database;
      await _createLoginTable(db); // Ensure table exists
      print('✅ Database connection obtained');

      // Get the first user's ID
      print('🔄 Getting first user data...');
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        final userId = firstUser['id'];
        print('✅ Found user with ID: $userId');

        // Show current data before update
        print('🔍 Current data before update:');
        print('  registered_movie: "${firstUser['registered_movie']}"');
        print('  project_id: "${firstUser['project_id']}"');
        print('  production_house: "${firstUser['production_house']}"');

        // Update the first user's data
        print('🔄 Performing database update...');
        final updateCount = await db.update(
          'login_data',
          {
            'registered_movie': projectName,
            'project_id': projectId,
            'production_house': productionHouse,
          },
          where: 'id = ?',
          whereArgs: [userId],
        );

        print('📊 Update count: $updateCount');

        if (updateCount > 0) {
          print('✅ Driver login data updated successfully');
          print('📝 Updated registered_movie: $projectName');
          print('📝 Updated project_id: $projectId');
          print('📝 Updated production_house: $productionHouse');

          // Verify the update by reading back the data
          final updatedUser = await getFirstUserData();
          if (updatedUser != null) {
            print('🔍 Verified updated data:');
            print('  registered_movie: "${updatedUser['registered_movie']}"');
            print('  project_id: "${updatedUser['project_id']}"');
            print('  production_house: "${updatedUser['production_house']}"');
          }
        } else {
          print('⚠️ Failed to update login data - updateCount is 0');
        }
      } else {
        print('⚠️ No login data found to update - firstUser is null');
      }
    } catch (e) {
      print('❌ Error updating driver login data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $e');
    }

    print('🏁 updateDriverLoginData completed');
  }

  // Update driver field based on navigation route
  Future<void> updateDriverField(bool isDriver) async {
    try {
      print('🔄 Updating driver field to: $isDriver');
      final db = await database;
      await _createLoginTable(db); // Ensure table exists

      // Get the first user's ID
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        final userId = firstUser['id'];

        // Update the driver field
        final updateCount = await db.update(
          'login_data',
          {'driver': isDriver ? 1 : 0},
          where: 'id = ?',
          whereArgs: [userId],
        );

        if (updateCount > 0) {
          print('✅ Driver field updated successfully to: $isDriver');
        } else {
          print('⚠️ Failed to update driver field');
        }
      } else {
        print('⚠️ No user found to update driver field');
      }
    } catch (e) {
      print('❌ Error updating driver field: $e');
    }
  }

  // Clear first user login data (removes the registered first user)
  Future<void> clearLoginData() async {
    try {
      final db = await database;
      await _createLoginTable(db); // Ensure table exists

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
  bool _obscureText = true;
  String? managerName;
  String? ProfileImage;
  int? vmid;

  Future<void> baseurl() async {
    try {
      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'VMETID':
              'byrZ4bZrKm09R4O7WH6SPd7tvAtGnK1/plycMSP8sD5TKI/VZR0tHBKyO/ogYUIf4Qk6HJXvgyGzg58v0xmlMoRJABt3qUUWGtnJj/EKBsrOaFFGZ6xAbf6k6/ktf2gKsruyfbF2/D7r1CFZgUlmTmubGS1oMZZTSU433swBQbwLnPSreMNi8lIcHJKR2WepQnzNkwPPXxA4/XuZ7CZqqsfO6tmjnH47GoHr7H+FC8GK24zU3AwGIpX+Yg/efeibwapkP6mAya+5BTUGtNtltGOm0q7+2EJAfNcrSTdmoDB8xBerLaNNHhwVHowNIu+8JZl2QM0F/gmVpB55cB8rqg=='
        },
        body:
            jsonEncode(<String, String>{"baseURL": "drivermember.cinefo.club"}),
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
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'DEVICETYPE': '2',
          'Content-Type': 'application/json; charset=UTF-8',
          'VPID': baseurlresult?['vpid']?.toString() ?? '',
          "BASEURL": "drivermember.cinefo.club",
          'VPTEMPLATEID': baseurlresult?['vptemplteID']?.toString() ?? '',
          'VMETID':
              'jcd3r0UZg4FnqnFKCfAZqwj+d5Y7TJhxN6vIvKsoJIT++90iKP3dELmti79Q+W7aVywvVbhfoF5bdW32p33PbRRTT27Jt3pahRrFzUe5s0jQBoeE0jOraLITDQ6RBv0QoscoOGxL7n0gEWtLE15Bl/HSF2kG5pQYft+ZyF4DNsLf7tGXTz+w/30bv6vMTGmwUIDWqbEet/+5AAjgxEMT/G4kiZifX0eEb3gMxycdMchucGbMkhzK+4bvZKmIjX+z6uz7xqb1SMgPnjKmoqCk8w833K9le4LQ3KSYkcVhyX9B0Q3dDc16JDtpEPTz6b8rTwY8puqlzfuceh5mWogYuA==',
          'APPNAME': 'Cinefo Production',
          'APPVERSION': packageInfo.version
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
          if (responseBody.keys.toList().contains('updateTypeId')) {
            int updateTypeId = responseBody['updateTypeId'];
            String apppath = responseBody['appPath'];
            String updateMessage = "new version is there please update app";
            bool didUpdate = await _showUpdateDialog(
                context, updateMessage, updateTypeId, apppath);
            print('updateTypeId is there 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊');
            // Only navigate after dialog is handled
            if (didUpdate || updateTypeId != 1) {
              if (mounted) {
                // Check if user is a driver (unitid == 9) before navigation
                if (responseBody['unitid'] != 9) {
                  // Show dialog for non-driver users
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Access Denied'),
                        content: Text('You are not a driver'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            }
          } else {
            print('updateTypeId is not there  📊 📊 📊 📊 📊 📊 📊 📊 📊 📊');
          }

          if (responseBody != null && responseBody['responseData'] != null) {
            setState(() {
              loginresponsebody = responseBody;
              loginresult = responseBody['responseData'];

              // Update global variables from login response
              if (responseBody['responseData'] is Map) {
                final responseData = responseBody['responseData'];
                projectId = responseData['projectId'] ?? '';
                managerName = responseData['managerName'] ?? '';
                registeredMovie = responseData['projectName'] ?? '';
                vmid = responseData['vmid'] ?? 0;
                productionTypeId = responseData['productionTypeId'] ?? 0;
                productionHouse = responseData['productionHouse'] ?? '';
                ProfileImage = responseData['profileImage'] ?? '';

                print('📊 Updated global variables from login response');
              }

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

            // Update ProfileImage from login response before saving
            String? loginProfileImage;

            if (responseBody['responseData'] is Map &&
                responseBody['responseData']['profileImage'] != null) {
              loginProfileImage = responseBody['responseData']['profileImage'];
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
              print('📸 Updated ProfileImage before saving: $ProfileImage');
            }

            // Save login data to SQLite after successful login
            print('🔄 Saving login data...');
            await saveLoginData();

            // Check if user is a driver (unitid == 9)
            if (mounted) {
              if (loginresponsebody?['unitid'] == 9) {
                // Make additional HTTP request for drivers
                try {
                  print(
                      '🚗 User is a driver (unitid == 9), making additional request...');
                  final driverResponse = await http.post(
                    processSessionRequest,
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                      'VMETID':
                          'P8eqnuQ9H24nzw+j/Oq8qih3vw9biFxC4i2XpRLOiSOcHiiqKN5II1gsqhUCeEM5TXUq+Hl19zup0tT7YnANhHFUL5HX9awoCOuKdn+nbYUX4OV3p5oIdjfLmdXQqc4JwrnpQy3kVFX2qtPPooFy9kIRzSjEKcQd0Rhqg4CuDYUxiBVesHhZdpAiTvRvrd4VOreauP6FysEt72O7XhOWvZilN9hQv8mQ+5ALfBFOrTuRu+9P7FczirlqCdUMFhXa64XTupbb4acIq2+bTYBd0I5isowfPBRKFc+GJcJEFnhCknqpDq/r9yxowFOcJUgIMjc0Tc3/S4JiasDqIiouYQ==',
                      'VSID': loginresponsebody?['vsid']?.toString() ?? "",
                    },
                    body: jsonEncode(<String, dynamic>{
                      "vmId": loginresponsebody?['responseData']?['vmid'] ?? 0,
                    }),
                  );
                  vsid = loginresponsebody?['vsid']?.toString() ?? "";
                  print(
                      '🚗 Driver HTTP Response Status: ${driverResponse.statusCode}');
                  print('🚗 Driver HTTP Response Body: ${driverResponse.body}');

                  if (driverResponse.statusCode == 200) {
                    try {
                      final driverResponseBody =
                          json.decode(driverResponse.body);
                      print('🚗 Driver Response JSON: $driverResponseBody');
                      print(
                          '🚗 Driver Response Keys: ${driverResponseBody.keys.toList()}');

                      // Update SQLite with driver response data - Access nested responseData
                      final responseData = driverResponseBody['responseData'];
                      final projectName =
                          responseData?['projectName']?.toString() ?? '';
                      final projectId =
                          responseData?['projectId']?.toString() ?? '';
                      final productionHouse =
                          responseData?['productionHouse']?.toString() ?? '';

                      print('🔍 Extracted values from responseData:');
                      print('🔍 projectName: "$projectName"');
                      print('🔍 projectId: "$projectId"');
                      print('🔍 productionHouse: "$productionHouse"');

                      // Always try to update, even with empty values for testing
                      print('🚗 Attempting SQLite update...');
                      await updateDriverLoginData(
                          projectName, projectId, productionHouse);
                      print('🚗 SQLite update call completed');

                      if (projectName.isNotEmpty ||
                          projectId.isNotEmpty ||
                          productionHouse.isNotEmpty) {
                        print('🚗 Updated SQLite with driver response data');
                      } else {
                        print(
                            '⚠️ All driver data fields are empty, but update was attempted');
                      }

                      // Conditional navigation based on responseData content
                      if (driverResponseBody['responseData'] != null &&
                          driverResponseBody['responseData'].toString() !=
                              '{}' &&
                          driverResponseBody['responseData']
                              .toString()
                              .isNotEmpty) {
                        print(
                            '🚗 ResponseData is not empty, navigating to RoutescreenforIncharge');

                        // Update driver field to false for incharge
                        await updateDriverField(false);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RoutescreenforIncharge()),
                        );
                      } else {
                        print(
                            '🚗 ResponseData is empty, navigating to Routescreenfordriver');

                        // Update driver field to true for driver
                        await updateDriverField(true);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const Routescreenfordriver()),
                        );
                      }
                    } catch (e) {
                      print('❌ Error processing driver response JSON: $e');
                      print(
                          '🚗 Raw driver response body: ${driverResponse.body}');

                      // If JSON parsing fails, go to driver screen
                      print(
                          '🚗 JSON parsing failed, navigating to Routescreenfordriver');

                      // Update driver field to true for driver
                      await updateDriverField(true);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Routescreenfordriver()),
                      );
                    }
                  } else {
                    print(
                        '❌ Driver response status code: ${driverResponse.statusCode}');
                    print('❌ Driver response body: ${driverResponse.body}');

                    // If driver response fails, go to driver screen
                    print(
                        '🚗 Driver response failed, navigating to Routescreenfordriver');

                    // Update driver field to true for driver
                    await updateDriverField(true);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Routescreenfordriver()),
                    );
                  }
                } catch (e) {
                  print('❌ Error in driver HTTP request: $e');

                  // If driver HTTP request fails, go to driver screen
                  print(
                      '🚗 Driver HTTP request failed, navigating to Routescreenfordriver');

                  // Update driver field to true for driver
                  await updateDriverField(true);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Routescreenfordriver()),
                  );
                }
              } else {
                // Show dialog for non-driver users
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Access Denied'),
                      content: Text('You are not a driver'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
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

      // Load base URL
      print('🌐 Loading base URL...');
      await baseurl();
      print('✅ Base URL loaded');
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
                  child: Center(
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
                                  "Login to Continue",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                TextFormField(
                                  controller: loginpassword,
                                  keyboardType: TextInputType.visiblePassword,
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
                                      borderRadius: BorderRadius.circular(12),
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
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: null,
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color?>((states) {
                                        if (states
                                            .contains(MaterialState.disabled)) {
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
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: _isLoading
                                            ? CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          screenWidth * 0.045,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(Icons.login,
                                                      color: Colors.white),
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
                    'V.4.0.2',
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
