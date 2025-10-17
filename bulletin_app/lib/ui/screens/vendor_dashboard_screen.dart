import 'package:flutter/material.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  static const routeName = '/vendor-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace vendeur'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue dans l\'espace vendeur',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
