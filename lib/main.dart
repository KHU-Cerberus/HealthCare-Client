import 'package:flutter/material.dart';
import 'presentation/pages/login/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Care App',
      home: LoginPage(),
    );
  }
}