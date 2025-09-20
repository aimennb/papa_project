import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../logic/providers/bulletins_list_provider.dart';
import '../../logic/providers/current_bulletin_provider.dart';
import '../widgets/bulletin_card.dart';
import 'bulletin_edit_screen.dart';
import 'settings_screen.dart';

class BulletinListScreen extends ConsumerStatefulWidget {
  const BulletinListScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<BulletinListScreen> createState() => _BulletinListScreenState();
}

class _BulletinListScreenState extends ConsumerState<BulletinListScreen> {
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
    final bulletinsState = ref.watch(bulletinsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulletins d\'achat'),
        actions: [
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
                labelText: 'Rechercher',
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(bulletinsListProvider.notifier)
                        .applyQuery(null);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(bulletinsListProvider.notifier)
                    .applyQuery(value.trim().isEmpty ? null : value.trim());
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bulletinsState.when(
                data: (bulletins) => _buildList(bulletins),
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
          await ref.read(currentBulletinProvider.notifier).load();
          if (!mounted) return;
          await Navigator.of(context).pushNamed(BulletinEditScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  Widget _buildList(List<BulletinAchat> bulletins) {
    if (bulletins.isEmpty) {
      return const Center(child: Text('Aucun bulletin'));
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        final bulletin = bulletins[index];
        return BulletinCard(
          bulletin: bulletin,
          onTap: () async {
            await ref
                .read(currentBulletinProvider.notifier)
                .load(id: bulletin.id);
            if (!mounted) return;
            await Navigator.of(context)
                .pushNamed(BulletinEditScreen.routeName, arguments: bulletin.id);
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: bulletins.length,
    );
  }
}
