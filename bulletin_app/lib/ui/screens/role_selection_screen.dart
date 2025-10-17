import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'supplier_dashboard_screen.dart';
import 'vendor_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const routeName = '/role-selection';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un rôle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            _RoleCard(
              title: 'Administrateur',
              description: 'Gérer les paramètres et la configuration.',
              routeName: AdminDashboardScreen.routeName,
            ),
            SizedBox(height: 16),
            _RoleCard(
              title: 'Vendeur',
              description: 'Créer et consulter les factures de vente.',
              routeName: VendorDashboardScreen.routeName,
            ),
            SizedBox(height: 16),
            _RoleCard(
              title: 'Fournisseur',
              description: 'Suivre les livraisons et les approvisionnements.',
              routeName: SupplierDashboardScreen.routeName,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.routeName,
  });

  final String title;
  final String description;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed(routeName),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Accéder',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
