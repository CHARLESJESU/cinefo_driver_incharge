import 'package:flutter/material.dart';

class Createtrip extends StatefulWidget {
  const Createtrip({super.key});

  @override
  State<Createtrip> createState() => _CreatetripState();
}

class _CreatetripState extends State<Createtrip> {
  bool screenLoading = false;
  // Dummy data for dropdowns (replace with real data as needed)
  List<String> callsheetList = ['Callsheet 1', 'Callsheet 2', 'Callsheet 3'];
  String? selectedCallsheet;
  String tripType = 'Pick Up';
  List<String> driverList = ['Driver A', 'Driver B', 'Driver C'];
  String? selectedDriver;
  List<String> personList = ['Person X', 'Person Y', 'Person Z'];
  String? selectedPerson;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
        child: screenLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Your Details',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Color.fromARGB(255, 223, 222, 222)),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, left: 15, right: 15, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Callsheet selection
                                  const Text('Select Callsheet',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedCallsheet,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items: callsheetList
                                        .map((sheet) => DropdownMenuItem(
                                              value: sheet,
                                              child: Text(sheet),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedCallsheet = val;
                                      });
                                    },
                                    hint: const Text('Select Callsheet'),
                                  ),
                                  const SizedBox(height: 16),
                                  // Pick up / Drop radio buttons
                                  const Text('Trip Type',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      Radio<String>(
                                        fillColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        value: 'Pick Up',
                                        groupValue: tripType,
                                        onChanged: (val) {
                                          setState(() {
                                            tripType = val!;
                                          });
                                        },
                                      ),
                                      const Text('Pick Up',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      Radio<String>(
                                        fillColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        value: 'Drop',
                                        groupValue: tripType,
                                        onChanged: (val) {
                                          setState(() {
                                            tripType = val!;
                                          });
                                        },
                                      ),
                                      const Text('Drop',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Driver selection
                                  const Text('Select Driver',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedDriver,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items: driverList
                                        .map((driver) => DropdownMenuItem(
                                              value: driver,
                                              child: Text(driver),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedDriver = val;
                                      });
                                    },
                                    hint: const Text('Select Driver'),
                                  ),
                                  const SizedBox(height: 16),
                                  // Pickup person selection
                                  const Text('Select Pickup Person',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedPerson,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items: personList
                                        .map((person) => DropdownMenuItem(
                                              value: person,
                                              child: Text(person),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedPerson = val;
                                      });
                                    },
                                    hint: const Text('Select Pickup Person'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                              ).copyWith(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                  (states) => null,
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2B5682),
                                      Color(0xFF24426B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Create Trip',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
    );
  }
}
