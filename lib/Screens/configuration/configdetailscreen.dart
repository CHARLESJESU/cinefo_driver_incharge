import 'package:flutter/material.dart';
import 'package:production/Screens/Route/RouteScreen.dart';

class SelectMembersScreen extends StatefulWidget {
  @override
  _SelectMembersScreenState createState() => _SelectMembersScreenState();
}

class _SelectMembersScreenState extends State<SelectMembersScreen> {
  final List<String> members = ['Ram charan', 'Maaran', 'Aravindh'];
  final Set<int> selectedIndexes = {0, 1}; // Initially selected members

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    });
  }

  void selectAll() {
    setState(() {
      selectedIndexes.length == members.length
          ? selectedIndexes.clear()
          : selectedIndexes.addAll(List.generate(members.length, (i) => i));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    double titleFontSize = screenWidth * 0.045; // e.g. 16 for 360 width
    double memberFontSize = screenWidth * 0.04;
    double selectedCountFontSize = screenWidth * 0.042;
    double buttonFontSize = screenWidth * 0.045;

    // Responsive paddings
    double horizontalPadding = screenWidth * 0.04; // ~16 on 400 width
    double verticalPadding = screenHeight * 0.015; // ~10 on 667 height

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.black, size: screenWidth * 0.07),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Select All",
          style: TextStyle(color: Colors.black, fontSize: titleFontSize),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: selectAll,
            child: Text(
              "Select All",
              style: TextStyle(color: Colors.black, fontSize: titleFontSize),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select the members/member whom you want to add",
                style:
                    TextStyle(color: Colors.black54, fontSize: memberFontSize),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndexes.contains(index);
                return GestureDetector(
                  onTap: () => toggleSelection(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding / 1.5),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border(
                        left: BorderSide(
                          color: Colors.blue,
                          width: screenWidth * 0.008,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: screenWidth * 0.01,
                          offset: Offset(0, screenWidth * 0.005),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            members[index],
                            style: TextStyle(fontSize: memberFontSize),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.green,
                                width: screenWidth * 0.005),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.004),
                            child: CircleAvatar(
                              radius: screenWidth * 0.015,
                              backgroundColor:
                                  isSelected ? Colors.green : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Center(
              child: Text(
                "${selectedIndexes.length} Members selected for helper",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: selectedCountFontSize,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: SizedBox(
              width: double.infinity,
              height: screenHeight * 0.07, // responsive button height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Routescreen()));
                },
                child: Text(
                  "Confirm",
                  style:
                      TextStyle(fontSize: buttonFontSize, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
