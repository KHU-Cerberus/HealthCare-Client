import 'package:flutter/material.dart';

class SleepLogPage extends StatelessWidget {
  final String baseUrl;
  final String jwt;

  const SleepLogPage({Key? key, required this.baseUrl, required this.jwt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Log'),
      ),
      body: Center(
        child: Text('Sleep Log Page - Base URL: $baseUrl'),
      ),
    );
  }
}