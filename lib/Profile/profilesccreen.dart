import 'package:flutter/material.dart';
import 'package:production/Profile/changepassword.dart';
import 'package:production/Screens/Home/colorcode.dart';

class Profilesccreen extends StatefulWidget {
  const Profilesccreen({super.key});

  @override
  State<Profilesccreen> createState() => _ProfilesccreenState();
}

class _ProfilesccreenState extends State<Profilesccreen> {
  // Controllers for text fields
  final TextEditingController _nameController =
      TextEditingController(text: "John Doe");
  final TextEditingController _ageController =
      TextEditingController(text: "28");
  final TextEditingController _genderController =
      TextEditingController(text: "Male");
  final TextEditingController _phoneController =
      TextEditingController(text: "+1 234 567 8900");

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Profile Avatar and Info Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Profile Fields
                      _buildEditableProfileField(
                          "Name", _nameController, Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildEditableProfileField(
                          "Age", _ageController, Icons.calendar_today_outlined),
                      const SizedBox(height: 15),
                      _buildEditableProfileField(
                          "Gender", _genderController, Icons.wc_outlined),
                      const SizedBox(height: 15),
                      _buildEditableProfileField("Phone Number",
                          _phoneController, Icons.phone_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Save profile changes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: AppColors.primaryLight,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Changepassword()),
                      );
                    },
                    icon: const Icon(Icons.lock_outline, color: Colors.white),
                    label: const Text(
                      "Change Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 30), // Extra spacing to ensure visibility
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableProfileField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            fillColor: Colors.grey[50],
            filled: true,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
