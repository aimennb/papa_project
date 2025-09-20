import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../main.dart';

class FactureCard extends StatelessWidget {
  const FactureCard({super.key, required this.facture, this.onTap});

  final Facture facture;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    switch (facture.status) {
      case FactureStatus.locked:
        return Colors.green.shade600;
      case FactureStatus.canceled:
        return Colors.red.shade600;
      case FactureStatus.draft:
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = facture.status.label;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text('${facture.numero} · ${facture.clientNom}'),
        subtitle: Text(
          '${facture.date.formatShort()} • ${facture.marque}\n'
          '${facture.lignes.length} lignes – Total ${facture.total.toStringAsFixed(2)} DA',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(statusLabel),
          backgroundColor: _statusColor(context).withOpacity(0.12),
          labelStyle: TextStyle(color: _statusColor(context)),
        ),
      ),
    );
  }
}
