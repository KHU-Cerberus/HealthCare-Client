import 'package:flutter/material.dart'; 

class SleepingPatternPage extends StatelessWidget {
  final String baseUrl;
  final String jwt;
  const SleepingPatternPage({super.key, required this.baseUrl, required this.jwt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleeping Pattern'),
      ),
      body: const Center(
        child: Text('This is the Sleeping Pattern Page'),
      ),
    );
  }
}