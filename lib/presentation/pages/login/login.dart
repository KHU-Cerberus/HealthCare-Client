import 'package:flutter/material.dart';
import '../home/home.dart';
import 'register.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();

  LoginPage({super.key});

  void _login(BuildContext context) {
    /* example
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: username),
        ),
      );
    }
    */
  }

  void _register(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* example
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () => _register(context),
              child: const Text('Register'),
            ),
          ],
        ),
      ), */
    );
  }
}