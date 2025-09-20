import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../main.dart';

class BulletinCard extends StatelessWidget {
  const BulletinCard({super.key, required this.bulletin, this.onTap});

  final BulletinAchat bulletin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text('${bulletin.numero} · ${bulletin.client}'),
        subtitle: Text(
          '${bulletin.date.formatShort()} • ${bulletin.marque}\n${bulletin.lignes.length} lignes – Total ${bulletin.total.toStringAsFixed(2)} DA',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
