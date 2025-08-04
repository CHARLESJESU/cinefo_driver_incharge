import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:production/Screens/report/Reportdetails.dart';
import 'package:production/sessionexpired.dart';
import 'package:production/variables.dart';

class Reports extends StatefulWidget {
  final String projectId;
  final String callsheetid;

  const Reports(
      {super.key, required this.projectId, required this.callsheetid});
  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  List<Map<String, dynamic>> callSheets = [];
  bool isLoading = true; // State for loading indicator

  @override
  void initState() {
    super.initState();
    callsheet(); // Fetch API data on screen load
  }

  Future<void> callsheet() async {
    final response = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'CpgDDfl7OjvtUfpQTq2Ay6pOFg0PjAExT+oKNsVaRW6PmfKxZqN0t1/tLoQjXSTMPIhb1P7rk0FStcwChgtzyZ9eB2gYIew67wiUjlmQquYyrB/isPKkyl8JtOi93+DhAd5xnejC8R45wEhEEt7kCpEIFSqdfg0TqXbProryg+wohtZFfMscEDmgdR6WwcdfyQzpR82+0QK1oPm/CxeYWUATCA1FKW4sqYCtiXANLlIaxAEcjB8SxKoxrixmGqO32n9eTvFHGm80EkZ1x+0o9lL5FeLGiqqdRYD34jEP/NsKAKbU6Q6UfE4VZuxoomWDMLL5Cp2QKj5YuWoY1NVdSg==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode({
        "projectid": projectId.toString(),
        "callsheetid": "0",
        "vmid": vmid.toString()
      }),
    );
    if (response.statusCode == 200) {
      print(response.body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == "200" && data['responseData'] != null) {
        setState(() {
          callSheets = List<Map<String, dynamic>>.from(data['responseData']);
          isLoading = false;
        });
      }
    } else {
      Map error = jsonDecode(response.body);
      print(error);
      if (error['errordescription'] == "Session Expired") {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Sessionexpired()));
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : callSheets.isEmpty
              ? const Center(child: Text("No CallSheets Available"))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                      child: Text(
                        "CallSheets Overview",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w300),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: callSheets.length,
                        itemBuilder: (context, index) {
                          final callsheet = callSheets[index];
                          return containerBox(
                            context,
                            callsheet['callSheetNo'] ?? "N/A",
                            callsheet['callsheetStatus'] ?? "N/A",
                            callsheet['location'] ?? "N/A",
                            callsheet['date'],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget containerBox(
    BuildContext context,
    String title,
    String callsheetStatus,
    String location,
    dynamic dateValue,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    String formattedDate = "Invalid Date";
    if (dateValue != null && dateValue.toString().trim().isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(dateValue.toString());
        formattedDate = DateFormat("dd/MM/yyyy").format(parsedDate);
      } catch (e) {
        print("Error parsing date: $e");
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Reportdetails(projectId: projectId.toString())));
        },
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Gradient header
                Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color.fromRGBO(238, 232, 255, 0.8),
                        Color.fromRGBO(236, 211, 249, 0.8),
                        Color(0xFFFDD9FF),
                        Color.fromRGBO(255, 255, 255, 0.8),
                      ],
                    ),
                  ),
                ),
                // Title & location
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(location,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[300]),
                // Status and Date
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Row(
                    children: [
                      Text("Status: $callsheetStatus",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
