import 'package:flutter/material.dart';

import 'package:production/Screens/Home/MyHomescreen.dart';
import 'package:production/Screens/Trip/agenttripreport.dart';

import 'package:production/Screens/callsheet/callsheetforincharge.dart';

import 'package:production/Screens/Trip/inchargereport.dart';
import 'package:production/Screens/report/reportforcallsheet.dart';

import 'package:production/variables.dart';

class RoutescreenforAgent extends StatefulWidget {
  final int initialIndex;

  const RoutescreenforAgent(
      {super.key, this.initialIndex = 0}); // Default to Home tab

  @override
  State<RoutescreenforAgent> createState() => _RoutescreenforAgentState();
}

class _RoutescreenforAgentState extends State<RoutescreenforAgent> {
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
      backgroundColor: Color(0xFF355E8C),

      body: SafeArea(
        child: _getScreenWidget(_currentIndex),
      ),
      // Align(
      //   alignment: Alignment.bottomCenter,
      //   child: SafeArea(
      //     top: false,
      //     child: SizedBox(
      //       height: 70,
      //       child: Stack(
      //         children: [
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF355E8C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Callsheet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reports',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.trip_origin),
          //   label: 'Trip',
          // ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
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
              ? Callsheetforincharge()
              : const MyHomescreen();
        } else {
          // For productionTypeId == 2 or any other case
          return Callsheetforincharge();
        }

      case 2:
        return Reportforcallsheet();
    // case 3:
    //   return TripScreen();
      default:
        return const MyHomescreen();
    }
  }
}
