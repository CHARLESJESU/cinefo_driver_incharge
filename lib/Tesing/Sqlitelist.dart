import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class Sqlitelist extends StatefulWidget {
  @override
  _SqlitelistState createState() => _SqlitelistState();
}

class _SqlitelistState extends State<Sqlitelist> {
  Database? _database;
  List<Map<String, dynamic>> _loginData = [];
  List<Map<String, dynamic>> _intimeData = [];
  bool _isLoading = true;
  int _viewMode = 0; // 0: login, 1: intime

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Helper to ensure database is open, reopens if closed
  Future<Database> ensureDatabaseOpen() async {
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      print('📍 SQLite List - Connecting to existing database: $dbPath');
      final db = await openDatabase(
        dbPath,
        version: 1,
      );
      final logintable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='login_data'");
      if (logintable.isEmpty) {
        throw Exception(
            'Login table not found. Please login first to create the database.');
      }
      print('✅ SQLite List - Connected to existing login_data table');
      print('📋 Table verification: Found login_data table');
      return db;
    } catch (e) {
      print('❌ SQLite List - Database connection error: $e');
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      await _fetchLoginData();
      await _fetchIntimeData();
    } catch (e) {
      print('❌ Error initializing database: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLoginData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'login_date DESC',
      );
      print('📊 SQLite List - Retrieved \\${maps.length} login records');
      setState(() {
        _loginData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching login data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIntimeData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final intimeTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='intime'");
      if (intimeTable.isEmpty) {
        setState(() {
          _intimeData = [];
          _isLoading = false;
        });
        return;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'intime',
        orderBy: 'marked_at DESC',
      );
      print('📊 SQLite List - Retrieved \\${maps.length} intime records');
      setState(() {
        _intimeData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching intime data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF355E8C),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          tooltip: 'Back',
        ),
        title: Text(
          _viewMode == 0 ? 'SQLite Login Data' : 'SQLite Intime Data',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF355E8C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () {
              setState(() {
                _viewMode = (_viewMode + 1) % 2; // toggle between 0 and 1
              });
            },
            tooltip: _viewMode == 0 ? 'Show Intime Data' : 'Show Login Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              if (_viewMode == 0) {
                await _fetchLoginData();
              } else {
                await _fetchIntimeData();
              }
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading ${_viewMode == 0 ? 'login' : 'intime'} data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : (_viewMode == 0 ? _loginData.isEmpty : _intimeData.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage,
                        size: 64,
                        color: Color.fromRGBO(255, 255, 255, 0.6),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _viewMode == 0 ? 'No login data found' : 'No intime data found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _viewMode == 0
                            ? 'Login through the app to see data here'
                            : 'Mark attendance to see intime data here',
                        style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Records: ${_viewMode == 0 ? _loginData.length : _intimeData.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _viewMode == 0 ? _loginData.length : _intimeData.length,
                        itemBuilder: (context, index) {
                          final item = _viewMode == 0 ? _loginData[index] : _intimeData[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            child: ExpansionTile(
                              title: Text(
                                _viewMode == 0
                                    ? (item['manager_name'] ?? 'Unknown Manager')
                                    : (item['name'] ?? 'No Name'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: _viewMode == 0
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Movie: ${item['registered_movie'] ?? 'N/A'}', style: TextStyle(fontSize: 14)),
                                        Text('Date: ${_formatDate(item['login_date'])}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('VCID: ${item['vcid'] ?? 'N/A'}', style: TextStyle(fontSize: 14)),
                                        Text('Date: ${_formatDate(item['marked_at'])}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                              trailing: SizedBox(width: 8),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: _viewMode == 0
                                        ? [
                                            _buildDetailRow('Manager Name', item['manager_name']),
                                            _buildDetailRow('Profile Image', item['profile_image']),
                                            _buildDetailRow('Registered Movie', item['registered_movie']),
                                            _buildDetailRow('Mobile Number', item['mobile_number']),
                                            _buildDetailRow('Designation', item['subUnitName']),
                                            _buildDetailRow('Password', item['password']),
                                            _buildDetailRow('Project ID', item['project_id']),
                                            _buildDetailRow('Production Type ID', item['production_type_id']?.toString()),
                                            _buildDetailRow('Production House', item['production_house']),
                                            _buildDetailRow('VMID', item['vmid']?.toString()),
                                            _buildDetailRow('Login Date', _formatDate(item['login_date'])),
                                            _buildDetailRow('Device ID', item['device_id']),
                                            _buildDetailRow('VSID', item['vsid']),
                                            _buildDetailRow('VPID', item['vpid']),
                                            _buildDetailRow('VUID', item['vuid']?.toString()),
                                            _buildDetailRow('Company Name', item['companyName']),
                                            _buildDetailRow('Email', item['email']),
                                            _buildDetailRow('VBPID', item['vbpid']?.toString()),
                                            _buildDetailRow('VCID', item['vcid']?.toString()),
                                            _buildDetailRow('VSUBID', item['vsubid']?.toString()),
                                            _buildDetailRow('VPOID', item['vpoid']?.toString()),
                                            _buildDetailRow('MTypeId', item['mtypeId']?.toString()),
                                            _buildDetailRow('Unit Name', item['unitName']),
                                            _buildDetailRow('VMTypeId', item['vmTypeId']?.toString()),
                                            _buildDetailRow('ID Card URL', item['idcardurl']),
                                            _buildDetailRow('VPIDPO', item['vpidpo']?.toString()),
                                            _buildDetailRow('VPIDBP', item['vpidbp']?.toString()),
                                            _buildDetailRow('Unit ID', item['unitid']?.toString()),
                                            _buildDetailRow('Sub Unit ID', item['subunitid']?.toString()),
                                            _buildDetailRow('Platform Logo', item['platformlogo']),
                                          ]
                                        : [
                                            _buildDetailRow('Name', item['name']),
                                            _buildDetailRow('Designation', item['designation']),
                                            _buildDetailRow('Code', item['code']),
                                            _buildDetailRow('Union Name', item['unionName']),
                                            _buildDetailRow('VCID', item['vcid']),
                                            _buildDetailRow('RFID', item['rfid']),
                                            _buildDetailRow('CallsheetID', item['callsheetid']?.toString()),
                                            _buildDetailRow('Marked At', _formatDate(item['marked_at'])),
                                            _buildDetailRow('attendance_status', item['attendance_status']),
                                            _buildDetailRow('Mode', item['mode']),
                                            _buildDetailRow('attendanceDate', item['attendanceDate']),
                                            _buildDetailRow('attendanceTime', item['attendanceTime']),
                                          ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
