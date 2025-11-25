import 'package:flutter/material.dart';
import 'package:health_care/presentation/style/colors.dart';

class HealthReportPage extends StatelessWidget {
  final String jwt;
  const HealthReportPage({super.key, required this.jwt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Report',
          style: TextStyle(color: blackColor),
          ),
      ),
      body: const Center(
        child: Text('Health Report Content Goes Here'),
      ),
    );
  }
}