import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Hello',
            style: TextStyle(color: Colors.black, fontSize: 32),
          ),
        ),
      ),
    ),
  );
}
