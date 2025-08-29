import 'package:flutter/material.dart';

class JourniarArtistScreen extends StatefulWidget {
  const JourniarArtistScreen({super.key});

  @override
  State<JourniarArtistScreen> createState() => _JourniarArtistScreenState();
}

class _JourniarArtistScreenState extends State<JourniarArtistScreen> {
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
            title: const Text("Journiar Artist",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Text(
              "Journiar Artist Screen Content",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
