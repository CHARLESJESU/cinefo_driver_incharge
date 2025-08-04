import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/Screens/Home/homescreen_service.dart';
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/methods.dart';
import 'package:production/variables.dart';
import 'package:responsive_builder/responsive_builder.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // Service instance
  final HomeScreenService _service = HomeScreenService();

  // UI state variables
  TextEditingController _nameController = TextEditingController();
  String? managerName;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _service.initialize();
    setState(() {}); // Refresh UI after initialization
  }

  // UI Helper methods
  void showmessage1(BuildContext context, String message, String ok) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Message'),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.start,
                overflow: TextOverflow.visible,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MovieListScreen()));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showInitialPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10)),
                child: GestureDetector(
                    onTap: () async {
                      final parentContext =
                          Navigator.of(context, rootNavigator: true).context;

                      await _service.fetchShifts();
                      setState(() {}); // Update UI

                      Navigator.pop(context);

                      if (_service.shiftList.isNotEmpty) {
                        Future.delayed(Duration(milliseconds: 300), () {
                          _showCallsheetPopup(parentContext);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to load shifts")),
                        );
                      }
                    },
                    child: Center(child: Text('Callsheet'))),
              ),
              SizedBox(height: 20),
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10)),
                child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Routescreen(initialIndex: 1),
                        ),
                      );
                    },
                    child: Center(child: Text('Fixed'))),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCallsheetPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
                title: Text('Select Shift'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _service.selectedShift,
                        hint: Text("Select Shift"),
                        isExpanded: true,
                        underline: SizedBox(),
                        items: _service.shiftList.map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift['shift'],
                            child: Text(shift['shift']),
                          );
                        }).toList(),
                        onChanged: (shiftName) {
                          if (shiftName != null) {
                            Map<String, dynamic> shiftData =
                                _service.shiftList.firstWhere(
                              (shift) => shift['shift'] == shiftName,
                            );
                            setDialogState(() {
                              _service.selectedShift = shiftName;
                              _service.selectedShiftId = shiftData['shiftId'];
                            });
                            _service.onShiftSelected(shiftData);
                            _nameController.text =
                                _service.selectedCallsheetName;
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _createCallSheet();
                        },
                        child: _service.isLoading
                            ? CircularProgressIndicator()
                            : Text('OK'))
                  ],
                ));
          },
        );
      },
    );
  }

  Future<void> _createCallSheet() async {
    final result = await _service.createCallSheet(_nameController.text);

    if (result['success']) {
      showsuccessPopUp(context, result['message'], () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Routescreen(initialIndex: 1)),
        );
      });
    } else {
      showmessage1(context, result['message'], "ok");
    }

    setState(() {}); // Update UI
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
            title: Text(productionTypeId == 3 ? 'Movies' : ''),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveBuilder(
                builder: (context, sizingInformation) {
                  final isMobile = sizingInformation.deviceScreenType ==
                      DeviceScreenType.mobile;

                  if (productionTypeId == 3) {
                    if (movieProjects.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      itemCount: movieProjects.length,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 40,
                        vertical: 10,
                      ),
                      itemBuilder: (context, index) {
                        final project = movieProjects[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.movie,
                                  color: Colors.deepPurple),
                              title: Text(
                                project['projectTitle'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 16 : 20,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                setState(() {
                                  selectedProjectId =
                                      project['projectId'].toString();
                                  selectedProjectTitle =
                                      project['projectTitle'].toString();
                                });

                                if (selectedProjectId != null &&
                                    selectedProjectId!.isNotEmpty) {
                                  _showInitialPopup(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Please select a movie first')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Container(
                        // width: isMobile ? double.infinity : 400,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              registeredMovie ?? "Loading...",
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              productionHouse ?? "Loading...",
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
