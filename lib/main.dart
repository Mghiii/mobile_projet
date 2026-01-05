import 'package:flutter/material.dart';
import 'package:miniprojet/views/LoginScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent,)),
      debugShowCheckedModeBanner: false,
      home: Loginscreen(),
    );
  }
}
