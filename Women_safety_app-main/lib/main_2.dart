import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '1_open.dart'; // Import 1_open.dart for the splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // The splash screen will be the first screen
    );
  }
}
