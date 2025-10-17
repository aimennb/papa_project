import 'package:flutter/material.dart';

class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({super.key});

  static const routeName = '/supplier-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace fournisseur'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue dans l\'espace fournisseur',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
