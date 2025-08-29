import 'package:flutter/material.dart';

class Lightmanscreen extends StatefulWidget {
  const Lightmanscreen({super.key});

  @override
  State<Lightmanscreen> createState() => _LightmanscreenState();
}

class _LightmanscreenState extends State<Lightmanscreen> {
  @override
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
            title:
                const Text("Light Man", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Text(
              "Lightman Screen Content",
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
