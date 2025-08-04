import 'package:flutter/material.dart';
import 'package:production/Profile/profilesccreen.dart';
import 'package:production/Screens/Home/Homescreen.dart';
import 'package:production/Screens/Home/MyHomescreen.dart';
import 'package:production/Screens/Home/colorcode.dart';
import 'package:production/Screens/callsheet/callsheet.dart';
import 'package:production/Screens/report/Reports.dart';
import 'package:production/variables.dart';

class Routescreen extends StatefulWidget {
  final int initialIndex;

  const Routescreen({super.key, this.initialIndex = 0}); // Default to Home tab

  @override
  State<Routescreen> createState() => _RoutescreenState();
}

class _RoutescreenState extends State<Routescreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Set initial tab from parameter
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: _getScreenWidget(_currentIndex),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 70,
                child: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle_outline),
                      label: 'Callsheet',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month),
                      label: 'Reports',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.article),
                      label: 'Profile',
                    ),
                  ],
                  currentIndex: _currentIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: AppColors
                      .primaryLight, // Use primary color for selected item
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getScreenWidget(int index) {
    switch (index) {
      case 0:
        // return const MovieListScreen();
        return const MyHomescreen();
      case 1:
        if (productionTypeId == 3) {
          return (selectedProjectId != null && selectedProjectId != "0")
              ? CallSheet()
              : const MovieListScreen();
        } else {
          // For productionTypeId == 2 or any other case
          return CallSheet();
        }

      case 2:
        return Reports(
          projectId: projectid.toString(),
          callsheetid: callsheetid.toString(),
        );
      case 3:
        return const Profilesccreen();
      default:
        return const MovieListScreen();
    }
  }
}
