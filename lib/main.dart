import 'package:flutter/material.dart';
import 'package:health_care/presentation/pages/login/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp(
    baseUrl: 'http://10.0.2.2:8080',
  ));
}

class MyApp extends StatelessWidget {
  final String baseUrl;

  const MyApp({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Care App',
      home: LoginPage(baseUrl: baseUrl),
    );
  }
}