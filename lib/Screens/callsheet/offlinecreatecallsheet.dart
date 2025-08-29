import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class OfflineCreateCallSheet extends StatefulWidget {
  const OfflineCreateCallSheet({super.key});

  @override
  State<OfflineCreateCallSheet> createState() => _OfflineCreateCallSheetState();
}

class _OfflineCreateCallSheetState extends State<OfflineCreateCallSheet> {
  Future<void> _createCallSheet() async {
    // Validate all required fields
    if (selectedShift == null || selectedShift!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a shift.')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter callsheet name.')),
      );
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date.')),
      );
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter location.')),
      );
      return;
    }
    if (selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shift ID is missing. Please reselect shift.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final db = await _callsheetDb;

      // Fetch login_data for MovieName, projectId, productionTypeid
      final loginRows = await db.query('login_data', limit: 1);
      if (loginRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login data not found.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final loginData = loginRows.first;

      // Generate unique callSheetId (auto-increment handled by SQLite)
      // Generate unique callSheetNo: "CN" + (max existing id + 1)
      final result =
          await db.rawQuery('SELECT MAX(id) as maxId FROM callsheetoffline');
      int nextId = (result.first['maxId'] as int? ?? 0) + 1;
      String callSheetNo = 'CN$nextId';

      // Prepare data
      Map<String, dynamic> data = {
        // id is auto-increment
        'callSheetId': nextId,
        'callSheetNo': callSheetNo,
        'MovieName': loginData['registered_movie'],
        'callsheetname': _nameController.text,
        'shift': selectedShift,
        'shiftId': selectedShiftId,
        'latitude': 0,
        'longitude': 0,
        'projectId': loginData['project_id'],
        'productionTypeid': loginData['production_type_id'],
        'location': _locationController.text,
        'locationType': selectedLocationType == 1
            ? 'In-station'
            : selectedLocationType == 2
                ? 'Out-station'
                : 'Outside City',
        'locationTypeId': selectedLocationType,
        'created_at': selectedDate != null
            ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
            : DateTime.now().toIso8601String(),
        'status': 'open',
      };

      await db.insert('callsheetoffline', data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Callsheet created successfully!')),
      );
      Navigator.of(context).pop();
      setState(() => _isLoading = false);
      // Optionally clear fields or pop screen
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool _isLoading = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  String? selectedShift;
  DateTime? selectedDate;
  int selectedLocationType = 1;
  List<Map<String, dynamic>> shiftList = [];
  List<String> shiftTimes = [];
  int? selectedShiftId;
  Future<Database> get _callsheetDb async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return openDatabase(
      dbPath,
      version: 2,
      onOpen: (db) async {
        // await db.execute('DROP TABLE IF EXISTS callsheetoffline');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS callsheetoffline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            callSheetId INTEGER,
            callSheetNo TEXT,
            MovieName TEXT,
            callsheetname TEXT,
            shift TEXT,
            shiftId INTEGER,
            latitude REAL,
            longitude REAL,
            projectId TEXT,
            productionTypeid INTEGER,
            location TEXT,
            locationType TEXT,
            locationTypeId INTEGER,
            created_at TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // You can add mock data for shiftList if needed for UI preview
    shiftList = [
      {"shiftId": 1, "shift": "2AM - 9AM (Sunrise)"},
      {"shiftId": 2, "shift": "6AM - 6PM (Regular)"},
      {"shiftId": 3, "shift": "2PM - 10PM (Evening)"},
      {"shiftId": 4, "shift": "6PM - 2AM (Night)"},
      {"shiftId": 5, "shift": "10PM - 6AM (Mid-Night)"},
    ];
    shiftTimes = shiftList.map((shift) => shift['shift'].toString()).toList();
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create callsheet (Offline)"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Your Details',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 530,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color.fromARGB(255, 223, 222, 222)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, left: 15, right: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shift',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedShift,
                                  hint: const Text("Select Shift"),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: shiftList.map((shift) {
                                    return DropdownMenuItem<String>(
                                      value: shift['shift'],
                                      child: Text(shift['shift']),
                                    );
                                  }).toList(),
                                  onChanged: (shiftName) {
                                    if (shiftName != null) {
                                      Map<String, dynamic> shiftData =
                                          shiftList.firstWhere(
                                        (shift) => shift['shift'] == shiftName,
                                      );
                                      // Extract label from shift string, e.g., '6AM - 6PM (Regular)' => 'Regular'
                                      String label = '';
                                      final RegExp labelRegExp =
                                          RegExp(r'\(([^)]+)\)');
                                      final match =
                                          labelRegExp.firstMatch(shiftName);
                                      if (match != null &&
                                          match.groupCount >= 1) {
                                        label = match.group(1)!;
                                      } else {
                                        label = shiftName; // fallback
                                      }
                                      setState(() {
                                        selectedShift = shiftName;
                                        selectedShiftId = shiftData['shiftId'];
                                        _nameController.text = label;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedDate != null
                                              ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                              : "Select Date",
                                          style: TextStyle(
                                            color: selectedDate != null
                                                ? Colors.black
                                                : Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today,
                                            color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Callsheet name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Location type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<int>(
                                  value: selectedLocationType,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 1, child: Text("In-station")),
                                    DropdownMenuItem(
                                        value: 2, child: Text("Out-station")),
                                    DropdownMenuItem(
                                        value: 3, child: Text("Outside City")),
                                  ],
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedLocationType = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const Text('Location',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter location',
                                  ),
                                ),
                              ),
                              // Removed Enable Offline Mode checkbox
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _createCallSheet,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromRGBO(10, 69, 254, 1),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Create',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
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
        ],
      ),
    );
  }
}
