import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/local/app_database.dart';
import '../../data/models/models.dart';
import '../../data/repositories/facture_repository.dart';
import '../../data/repositories/sync_repository.dart';
import 'sync_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final factureRepositoryProvider = Provider<FactureRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftFactureRepository(db);
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final client = ref.watch(httpClientProvider);
  return SyncRepository(db, client);
});

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  final controller = SyncController(
    repository,
    Connectivity(),
    ref,
    parametresProvider: parametresProvider,
  );
  controller.initialize();
  return controller;
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(factureRepositoryProvider);
  await repo.bootstrap();
  final params = await repo.loadParametres();
  ref.read(parametresProvider.notifier).setInitial(params);
});

class ParametresNotifier extends StateNotifier<AsyncValue<ParametresApp>> {
  ParametresNotifier(this._repository)
      : super(const AsyncValue.loading());

  final FactureRepository _repository;

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
    final repo = ref.watch(factureRepositoryProvider);
    return ParametresNotifier(repo);
  },
);
