import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/facture_repository.dart';
import 'app_bootstrap_provider.dart';

final factureQueryProvider = StateProvider<String?>((ref) => null);
final factureStatusFilterProvider =
    StateProvider<FactureStatus?>((ref) => null);

class FacturesListController
    extends StateNotifier<AsyncValue<List<Facture>>> {
  FacturesListController(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _fetch();
  }

  final FactureRepository _repository;
  final Ref _ref;

  Future<void> _fetch() async {
    final query = _ref.read(factureQueryProvider);
    final status = _ref.read(factureStatusFilterProvider);
    state = const AsyncValue.loading();
    try {
      final factures = await _repository.list(query: query, status: status);
      state = AsyncValue.data(factures);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _fetch();

  void applyQuery(String? query) {
    _ref.read(factureQueryProvider.notifier).state = query;
  }

  void applyStatus(FactureStatus? status) {
    _ref.read(factureStatusFilterProvider.notifier).state = status;
  }
}

final facturesListProvider =
    StateNotifierProvider<FacturesListController, AsyncValue<List<Facture>>>(
        (ref) {
  final repo = ref.watch(factureRepositoryProvider);
  final controller = FacturesListController(repo, ref);
  ref.listen<String?>(
    factureQueryProvider,
    (_, __) => controller.refresh(),
    fireImmediately: false,
  );
  ref.listen<FactureStatus?>(
    factureStatusFilterProvider,
    (_, __) => controller.refresh(),
    fireImmediately: false,
  );
  return controller;
});
