import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../data/repositories/sync_repository.dart';
import '../../logic/providers/current_facture_provider.dart';
import '../../logic/providers/factures_list_provider.dart';
import '../../logic/providers/sync_controller.dart';
import '../widgets/facture_card.dart';
import 'facture_edit_screen.dart';
import 'settings_screen.dart';

class FactureListScreen extends ConsumerStatefulWidget {
  const FactureListScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<FactureListScreen> createState() => _FactureListScreenState();
}

class _FactureListScreenState extends ConsumerState<FactureListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facturesState = ref.watch(facturesListProvider);
    final status = ref.watch(factureStatusFilterProvider);
    final syncState = ref.watch(syncControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Factures / Bulletins d'achat"),
        actions: [
          IconButton(
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _syncIcon(syncState),
                    color: _syncIconColor(Theme.of(context), syncState),
                  ),
            tooltip: _syncTooltip(syncState),
            onPressed: (!syncState.hasConfiguration || syncState.isSyncing)
                ? null
                : () async {
                    try {
                      await ref
                          .read(syncControllerProvider.notifier)
                          .syncNow(manual: true);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Synchronisation terminée'),
                        ),
                      );
                    } on SyncException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Erreur de synchronisation: ${e.message}'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur inattendue: $e'),
                        ),
                      );
                    }
                  },
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<FactureStatus?>(
              value: status,
              hint: const Text('Statut'),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Tous'),
                ),
                DropdownMenuItem(
                  value: FactureStatus.draft,
                  child: Text('Brouillon'),
                ),
                DropdownMenuItem(
                  value: FactureStatus.locked,
                  child: Text('Verrouillé'),
                ),
                DropdownMenuItem(
                  value: FactureStatus.canceled,
                  child: Text('Annulé'),
                ),
              ],
              onChanged: (value) => ref
                  .read(facturesListProvider.notifier)
                  .applyStatus(value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher client ou numéro',
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(facturesListProvider.notifier).applyQuery(null);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (value) {
                ref.read(facturesListProvider.notifier).applyQuery(
                      value.trim().isEmpty ? null : value.trim(),
                    );
              },
            ),
            const SizedBox(height: 16),
            _SyncStatusBanner(state: syncState),
            const SizedBox(height: 16),
            Expanded(
              child: facturesState.when(
                data: (factures) => _buildList(factures),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Erreur: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ref.read(currentFactureProvider.notifier).load();
          if (!mounted) return;
          await Navigator.of(context).pushNamed(FactureEditScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle facture'),
      ),
    );
  }

  Widget _buildList(List<Facture> factures) {
    if (factures.isEmpty) {
      return const Center(child: Text('Aucune facture disponible'));
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        final facture = factures[index];
        return FactureCard(
          facture: facture,
          onTap: () async {
            await ref
                .read(currentFactureProvider.notifier)
                .load(id: facture.id);
            if (!mounted) return;
            await Navigator.of(context)
                .pushNamed(FactureEditScreen.routeName, arguments: facture.id);
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: factures.length,
    );
  }

  IconData _syncIcon(SyncState state) {
    switch (state.status) {
      case SyncStatus.error:
        return Icons.sync_problem;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.idle:
      default:
        return Icons.sync;
    }
  }

  Color? _syncIconColor(ThemeData theme, SyncState state) {
    switch (state.status) {
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.offline:
        return theme.colorScheme.outline;
      case SyncStatus.success:
        return theme.colorScheme.secondary;
      default:
        return null;
    }
  }

  String _syncTooltip(SyncState state) {
    if (!state.hasConfiguration) {
      return 'Configurer un serveur distant dans les paramètres';
    }
    if (state.isSyncing) {
      return 'Synchronisation en cours';
    }
    if (!state.isOnline) {
      return 'Hors ligne';
    }
    if (state.lastSuccessfulSync != null) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm');
      return 'Dernière synchronisation: ${formatter.format(state.lastSuccessfulSync!)}';
    }
    return 'Synchroniser maintenant';
  }
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForStatus(state.status);
    final color = _colorForStatus(theme, state.status);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    final messages = <String>[];

    if (state.isSyncing) {
      messages.add('Synchronisation en cours...');
    } else if (!state.isOnline) {
      messages.add(
        'Hors ligne - les données seront synchronisées dès le retour du réseau.',
      );
    } else if (!state.hasConfiguration) {
      messages.add(
        'Configurez un serveur distant dans les paramètres pour activer la synchronisation.',
      );
    } else if (state.status == SyncStatus.error && state.lastError != null) {
      messages.add(state.lastError!);
    } else if (state.syncEnabled) {
      messages.add(
        'Synchronisation automatique toutes les ${state.interval.inMinutes} minutes.',
      );
    } else {
      messages.add(
        'Synchronisation manuelle disponible via le bouton en haut à droite.',
      );
    }

    if (state.lastSuccessfulSync != null &&
        !(state.status == SyncStatus.error && state.lastError != null)) {
      messages.add(
        'Dernière synchro: ${formatter.format(state.lastSuccessfulSync!)}',
      );
    }

    final title = () {
      switch (state.status) {
        case SyncStatus.syncing:
          return 'Synchronisation en cours';
        case SyncStatus.success:
          return 'Synchronisation réussie';
        case SyncStatus.error:
          return 'Erreur de synchronisation';
        case SyncStatus.offline:
          return 'Mode hors ligne';
        case SyncStatus.idle:
          return state.syncEnabled
              ? 'Synchronisation prête'
              : 'Synchronisation en attente';
      }
    }();

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(messages.join('\n')),
        isThreeLine: messages.length > 1,
      ),
    );
  }

  static IconData _iconForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.error:
        return Icons.sync_problem;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.idle:
      default:
        return Icons.cloud_queue;
    }
  }

  static Color? _colorForStatus(ThemeData theme, SyncStatus status) {
    switch (status) {
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.offline:
        return theme.colorScheme.outline;
      case SyncStatus.success:
        return theme.colorScheme.secondary;
      case SyncStatus.syncing:
        return theme.colorScheme.primary;
      case SyncStatus.idle:
      default:
        return theme.colorScheme.primary;
    }
  }
}
