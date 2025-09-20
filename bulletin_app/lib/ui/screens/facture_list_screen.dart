import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../logic/providers/current_facture_provider.dart';
import '../../logic/providers/factures_list_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Factures / Bulletins d'achat"),
        actions: [
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
}
