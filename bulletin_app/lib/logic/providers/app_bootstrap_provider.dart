import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/models/models.dart';
import '../../data/repositories/bulletin_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final bulletinRepositoryProvider = Provider<BulletinRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftBulletinRepository(db);
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(bulletinRepositoryProvider);
  await repo.bootstrap();
  final params = await repo.loadParametres();
  ref.read(parametresProvider.notifier).setInitial(params);
});

class ParametresNotifier extends StateNotifier<AsyncValue<ParametresApp>> {
  ParametresNotifier(this._repository)
      : super(const AsyncValue.loading());

  final BulletinRepository _repository;

  void setInitial(ParametresApp params) {
    if (!mounted) return;
    state = AsyncValue.data(params);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final params = await _repository.loadParametres();
      state = AsyncValue.data(params);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(ParametresApp params) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveParametres(params);
      state = AsyncValue.data(params);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final parametresProvider =
    StateNotifierProvider<ParametresNotifier, AsyncValue<ParametresApp>>(
  (ref) {
    final repo = ref.watch(bulletinRepositoryProvider);
    return ParametresNotifier(repo);
  },
);
