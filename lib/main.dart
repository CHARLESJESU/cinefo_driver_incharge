import 'package:flutter/material.dart';

import 'package:production/Screens/splash/splashscreen.dart';

import 'Screens/Attendance/dailogei.dart';
import 'variables.dart'; // Import the file where routeObserver is defined

void main() {
  IntimeSyncService().startSync(); // Start background FIFO sync at app startup
  runApp(
    // MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => DubbingConfigProvider()),
    //   ],
    MyApp(),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: SplashScreen(),
    );
  }
}
