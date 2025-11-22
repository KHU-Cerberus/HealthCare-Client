import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  final String token;

  const HomePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* example
      appBar: AppBar(
        title: Text('Welcome, $username'),
      ),
      body: Center(
        child: Text('Hello, $username! This is the home page.'),
      ), */
    );
  }
}