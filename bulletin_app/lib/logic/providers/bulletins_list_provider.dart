import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/bulletin_repository.dart';
import 'app_bootstrap_provider.dart';

final bulletinQueryProvider = StateProvider<String?>((ref) => null);

class BulletinsListController
    extends StateNotifier<AsyncValue<List<BulletinAchat>>> {
  BulletinsListController(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _fetch();
  }

  final BulletinRepository _repository;
  final Ref _ref;

  Future<void> _fetch() async {
    final query = _ref.read(bulletinQueryProvider);
    state = const AsyncValue.loading();
    try {
      final bulletins = await _repository.list(query: query);
      state = AsyncValue.data(bulletins);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _fetch();

  void applyQuery(String? query) {
    _ref.read(bulletinQueryProvider.notifier).state = query;
  }
}

final bulletinsListProvider = StateNotifierProvider<BulletinsListController,
    AsyncValue<List<BulletinAchat>>>((ref) {
  final repo = ref.watch(bulletinRepositoryProvider);
  final controller = BulletinsListController(repo, ref);
  ref.listen<String?>(
    bulletinQueryProvider,
    (_, __) {
      controller.refresh();
    },
    fireImmediately: false,
  );
  return controller;
});
