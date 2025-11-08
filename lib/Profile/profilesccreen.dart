import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:production/Screens/Home/colorcode.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart';

class Profilesccreen extends StatefulWidget {
  const Profilesccreen({super.key});

  @override
  State<Profilesccreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<Profilesccreen> {
  File? _profileImage;
  Map<String, dynamic>? loginData;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchLoginData() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(path.join(dbPath, 'production_login.db'));
    final List<Map<String, dynamic>> loginMaps = await db.query('login_data');
    if (loginMaps.isNotEmpty) {
      setState(() {
        loginData = loginMaps.first;
      });
    }
    await db.close();
  }

  Widget buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: TextStyle(color: Colors.white70))),
          SizedBox(width: 16), // Add horizontal space between label and value
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLoginData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            const Text('Profile Info', style: TextStyle(color: Colors.white)),
      ),
      body: loginData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/cni.png') as ImageProvider,
                    ),
                    Positioned(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blue,
                          child:
                              Icon(Icons.edit, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loginData?["manager_name"] ?? '',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Divider(color: Colors.white24, height: 30, thickness: 1),
                buildProfileField('Name', loginData?["manager_name"] ?? ''),
                buildProfileField('Mobile', loginData?["mobile_number"] ?? ''),
                buildProfileField('Designation', loginData?["subUnitName"] ?? ''),
                buildProfileField(
                    'Production House', loginData?["production_house"] ?? ''),
              ],
            ),
    );
  }
}
