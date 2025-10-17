import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace administrateur'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue dans l\'espace administrateur',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
