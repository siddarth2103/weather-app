import 'package:flutter/material.dart';
//import 'home.dart'; // adjust path if needed
import 'selectcity.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SelectCity(),
    ); // 👈 don't forget this semicolon
  }
}
// This is the main entry point of the Flutter application.