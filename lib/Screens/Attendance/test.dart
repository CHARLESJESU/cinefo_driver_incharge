import 'package:flutter/material.dart';

class AutoButtonPressExample extends StatefulWidget {
  const AutoButtonPressExample({super.key});

  @override
  State<AutoButtonPressExample> createState() => _AutoButtonPressExampleState();
}

class _AutoButtonPressExampleState extends State<AutoButtonPressExample> {
  @override
  void initState() {
    super.initState();

    // Trigger the button press automatically without user interaction
    Future.delayed(Duration(seconds: 2), () {
      _simulateButtonPress();
    });
  }

  // The same logic that you want to run when the button is pressed
  void _simulateButtonPress() {
    print("Button pressed automatically!");
    // You can also call any logic you want to trigger here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Button Press Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // This logic will be triggered programmatically and will not require a tap
            _simulateButtonPress();
          },
          child: const Text('Press Me'), // This is just for display, no tap needed
        ),
      ),
    );
  }
}


