import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/Screens/report/callsheetmembers.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../../ApiCalls/apicall.dart' as apicalls;
import '../callsheet/callsheet_detail.dart';

class Reportforcallsheet extends StatefulWidget {
  const Reportforcallsheet({super.key});

  @override
  State<Reportforcallsheet> createState() => _ReportforcallsheeteState();
}

class _ReportforcallsheeteState extends State<Reportforcallsheet> {
  Database? _database;
  Map<String, dynamic>? logindata;
  bool _isLoading = false;
  List<Map<String, dynamic>> callSheetData = [];
  String global_projectidString = " ";
  @override
  void initState() {
    super.initState();
    _initializeAndCallAPI();
  }

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database connection
  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return await openDatabase(
      dbPath,
      version: 1,
      // This just connects to existing database
    );
  }

  // Get login data from SQLite
  Future<Map<String, dynamic>?> _getLoginData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        print('📊 Login data found: ${maps.first}');
        return maps.first;
      }
      print('🔍 No login data found in table');
      return null;
    } catch (e) {
      print('❌ Error getting login data: $e');
      return null;
    }
  }

  // Initialize and call API
  Future<void> _initializeAndCallAPI() async {
    setState(() => _isLoading = true);

    try {
      // First fetch the login_data table values
      logindata = await _getLoginData();

      if (logindata != null) {
        // Call lookupcallsheetapi with retrieved values
        await _callLookupCallsheetAPI();
      } else {
        _showError('No login data found. Please login first.');
      }
    } catch (e) {
      _showError('Error initializing: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Call the lookup callsheet API
  Future<void> _callLookupCallsheetAPI() async {
    try {
      // Convert projectid to integer
      int projectidInt;
      final projectidValue = logindata!['project_id'];
      if (projectidValue is String) {
        projectidInt = int.tryParse(projectidValue) ?? 0;
      } else if (projectidValue is int) {
        projectidInt = projectidValue;
      } else {
        projectidInt = 0;
      }

      print(
          '🔄 Converting project_id: $projectidValue (${projectidValue.runtimeType}) → $projectidInt');
      global_projectidString = projectidInt.toString();
      final result = await apicalls.lookupcallsheetapi(
        projectid: projectidInt,
        vsid: logindata!['vsid'] ?? '',
      );

      if (result['success']) {
        print('✅ Lookup callsheet API successful');
        print('📄 Response: ${result['body']}');

        // Parse the response and extract callsheet data
        _parseCallSheetResponse(result['body']);
        _showSuccess('Callsheet data loaded successfully!');
      } else {
        print('❌ Lookup callsheet API failed: ${result['body']}');
        _showError('Failed to load callsheet data: ${result['body']}');
      }
    } catch (e) {
      print('❌ Error calling lookup callsheet API: $e');
      _showError('Error loading callsheet data: $e');
    }
  }

  // Parse the API response and extract callsheet data
  void _parseCallSheetResponse(String responseBody) {
    try {
      final Map<String, dynamic> response = jsonDecode(responseBody);
      if (response['responseData'] != null &&
          response['responseData'] is List) {
        setState(() {
          callSheetData =
          List<Map<String, dynamic>>.from(response['responseData']);
        });
        print('📋 Parsed ${callSheetData.length} callsheet records');
      }
    } catch (e) {
      print('❌ Error parsing callsheet response: $e');
      setState(() {
        callSheetData = [];
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2B5682),
                Color(0xFF24426B),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              "Call Sheets Report",
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Call sheets list section
                  if (_isLoading)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: Color(0xFF2B5682),
                        ),
                      ),
                    )
                  else if (callSheetData.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No Call Sheets Available",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Call Sheets Section
                        if (callSheetData.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Report List",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...callSheetData.map((callSheet) =>
                              _buildCallSheetCard(context, callSheet)),
                        ],
                      ],
                    ),
                  // Add extra bottom padding to prevent content from being hidden by navigation
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build call sheet card widget similar to incharge report style
  Widget _buildCallSheetCard(
      BuildContext context, Map<String, dynamic> callSheet) {
    // Extract fields from callSheet map
    final String callSheetId = callSheet['callSheetId']?.toString() ?? "N/A";
    final String callSheetNo = callSheet['callSheetNo']?.toString() ?? "N/A";
    final String projectName = callSheet['projectName']?.toString() ?? "N/A";
    final String createdDate = callSheet['createdDate']?.toString() ??
        callSheet['date']?.toString() ??
        "N/A";
    final String shift = callSheet['shift']?.toString() ?? "N/A";
    final String status = callSheet['callsheetStatus']?.toString() ?? "N/A";
    return GestureDetector(
      onTap: () {
        // Navigate to the full callsheet detail screen (new file)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Callsheetmembers(projectId: global_projectidString,maincallsheetid: callSheetId,isOffline: false),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A6FA5).withOpacity(0.1),
                    const Color(0xFF2E4B73).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Call Sheet #$callSheetNo",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Project Name
            Row(
              children: [
                Icon(
                  Icons.movie,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  "Project: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    projectName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Call Sheet ID and Created Date
            Row(
              children: [
                Icon(
                  Icons.badge,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  "ID: $callSheetId",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  createdDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF355E8C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Shift Information
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  "Shift: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    shift,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
        return Colors.green;
      case 'in-progress':
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}
