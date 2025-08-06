import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:production/Screens/Home/colorcode.dart';

class Profilesccreen extends StatefulWidget {
  const Profilesccreen({super.key});

  @override
  State<Profilesccreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<Profilesccreen> {
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: TextStyle(color: Colors.white70))),
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
      body: Column(
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
                    child: Icon(Icons.edit, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('ASIF',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text('View ID Card'),
          ),
          const Divider(color: Colors.white24, height: 30, thickness: 1),
          buildProfileField('Name', 'ASIF'),
          buildProfileField('Mobile', '9840884346'),
          buildProfileField('Email', 'asifsio@gmail.com'),
          buildProfileField('Status', 'Active'),
          buildProfileField('Designation', 'Manager'),
          buildProfileField('Profession', 'GLASS FABRICATOR'),
          buildProfileField('Chapter', 'N/A'),
        ],
      ),
    );
  }
}
