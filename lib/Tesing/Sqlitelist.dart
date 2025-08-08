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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Initialize database connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database connection (NO TABLE CREATION)
  Future<Database> _initDatabase() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      print('📍 SQLite List - Connecting to existing database: $dbPath');

      // Just open the existing database without onCreate
      final db = await openDatabase(
        dbPath,
        version: 1,
        // REMOVED: onCreate callback since table already exists from login screen
      );

      // Verify the table exists (created by login screen)
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='login_data'");

      if (tables.isEmpty) {
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

  // Initialize database and fetch data
  Future<void> _initializeDatabase() async {
    try {
      await _fetchLoginData();
    } catch (e) {
      print('❌ Error initializing database: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch all login data from database
  Future<void> _fetchLoginData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final db = await database;

      // Get all login records ordered by date (newest first)
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'login_date DESC',
      );

      print('📊 SQLite List - Retrieved ${maps.length} login records');

      setState(() {
        _loginData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching login data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear all login data
  Future<void> _clearAllData() async {
    try {
      final db = await database;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Clear All Data'),
          content: Text(
              'Are you sure you want to clear all login data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await db.delete('login_data');
        print('🗑️ All login data cleared');
        await _fetchLoginData(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All login data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error clearing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete specific record
  Future<void> _deleteRecord(int id) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Record'),
          content: Text('Are you sure you want to delete this login record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final db = await database;
        await db.delete('login_data', where: 'id = ?', whereArgs: [id]);
        print('🗑️ Login record $id deleted');
        await _fetchLoginData(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format date for display
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
        title: Text(
          'SQLite Login Data',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF355E8C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLoginData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearAllData,
            tooltip: 'Clear All Data',
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
                    'Loading login data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _loginData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage,
                        size: 64,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No login data found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Login through the app to see data here',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Data summary header
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Records: ${_loginData.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Active: ${_loginData.where((item) => item['is_active'] == 1).length}',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _loginData.length,
                        itemBuilder: (context, index) {
                          final item = _loginData[index];

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            child: ExpansionTile(
                              title: Text(
                                item['manager_name'] ?? 'Unknown Manager',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Movie: ${item['registered_movie'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Date: ${_formatDate(item['login_date'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRecord(item['id']),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildDetailRow('Mobile Number',
                                          item['mobile_number']),
                                      _buildDetailRow(
                                          'Project ID', item['project_id']),
                                      _buildDetailRow(
                                          'Production Type ID',
                                          item['production_type_id']
                                              ?.toString()),
                                      _buildDetailRow('Production House',
                                          item['production_house']),
                                      _buildDetailRow(
                                          'VM ID', item['vmid']?.toString()),
                                      _buildDetailRow('Login Date',
                                          _formatDate(item['login_date'])),
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
