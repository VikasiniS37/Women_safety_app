import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Image Display Test')),
        body: Center(
          child: Image.asset(
            'lib/uploads/1000062900.jpg',  // Correct path to the image in the 'lib/uploads/' folder
            height: 150,
            width: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Display an error message if the image can't be loaded
              return Text('Image not available');
            },
          ),
        ),
      ),
    );
  }
}
