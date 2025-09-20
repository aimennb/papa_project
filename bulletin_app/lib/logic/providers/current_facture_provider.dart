import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';
import '../../data/repositories/facture_repository.dart';
import '../../printing/pdf_service.dart';
import 'app_bootstrap_provider.dart';
import 'auth_provider.dart';
import 'factures_list_provider.dart';

const _uuid = Uuid();

class FactureFormState {
  const FactureFormState({required this.facture, required this.client});

  final Facture facture;
  final Client client;

  double get total => facture.total;

  FactureFormState copyWith({Facture? facture, Client? client}) {
    return FactureFormState(
      facture: facture ?? this.facture,
      client: client ?? this.client,
    );
  }
}

final currentFactureProvider = StateNotifierProvider<CurrentFactureNotifier,
    AsyncValue<FactureFormState>>((ref) {
  final repo = ref.watch(factureRepositoryProvider);
  final paramsNotifier = ref.watch(parametresProvider.notifier);
  final pdf = ref.watch(pdfServiceProvider);
  final user = ref.watch(currentUserProvider);
  return CurrentFactureNotifier(ref, repo, paramsNotifier, pdf, user);
});

class CurrentFactureNotifier
    extends StateNotifier<AsyncValue<FactureFormState>> {
  CurrentFactureNotifier(
    this._ref,
    this._repository,
    this._parametresNotifier,
    this._pdfService,
    this._currentUser,
  ) : super(const AsyncValue.loading());

  final Ref _ref;
  final FactureRepository _repository;
  final ParametresNotifier _parametresNotifier;
  final PdfService _pdfService;
  final UserAccount _currentUser;

  Future<void> load({String? id}) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        final numero = await _repository.reserveNumero();
        final params = await _repository.loadParametres();
        _parametresNotifier.setInitial(params);
        final now = DateTime.now();
        final client = Client(
          id: _uuid.v4(),
          nom: '',
          telephone: '',
          region: '',
          createdAt: now,
        );
        final facture = Facture(
          id: _uuid.v4(),
          numero: numero,
          date: now,
          clientId: client.id,
          clientNom: client.nom,
          marque: '',
          consignation: '',
          carreau: params.carreauParDefaut,
          lignes: [
            LigneAchat(
              id: _uuid.v4(),
              fournisseurId: null,
              marque: '',
              nbColis: 0,
              nature: '',
              brut: 0,
              tare: 0,
              net: 0,
              prixUnitaire: 0,
            ),
          ],
          status: FactureStatus.draft,
          createdBy: _currentUser.id,
          createdAt: now,
          lockedAt: null,
        );
        state = AsyncValue.data(FactureFormState(facture: facture, client: client));
      } else {
        final facture = await _repository.findById(id);
        if (facture == null) {
          state = AsyncValue.error('Facture introuvable', StackTrace.current);
          return;
        }
        final client = await _repository.findClient(facture.clientId) ??
            Client(
              id: facture.clientId,
              nom: facture.clientNom,
              telephone: '',
              region: '',
              createdAt: facture.createdAt,
            );
        state =
            AsyncValue.data(FactureFormState(facture: facture, client: client));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  FactureFormState _require() {
    final value = state.value;
    if (value == null) {
      throw StateError('Facture non chargée');
    }
    return value;
  }

  void updateHeader({
    String? marque,
    String? consignation,
    int? carreau,
    DateTime? date,
  }) {
    final current = _require();
    final facture = current.facture.copyWith(
      marque: marque,
      consignation: consignation,
      carreau: carreau,
      date: date,
    );
    state = AsyncValue.data(current.copyWith(facture: facture));
  }

  void updateClientName(String value) {
    final current = _require();
    final client = current.client.copyWith(nom: value);
    final facture = current.facture.copyWith(
      clientId: client.id,
      clientNom: client.nom,
    );
    state = AsyncValue.data(current.copyWith(facture: facture, client: client));
  }

  void updateLine(int index, LigneAchat ligne) {
    final current = _require();
    final lignes = [...current.facture.lignes];
    if (index >= 0 && index < lignes.length) {
      lignes[index] = ligne;
      final facture = current.facture.copyWith(lignes: lignes);
      state = AsyncValue.data(current.copyWith(facture: facture));
    }
  }

  void addLine() {
    final current = _require();
    final lignes = [
      ...current.facture.lignes,
      LigneAchat(
        id: _uuid.v4(),
        fournisseurId: null,
        marque: '',
        nbColis: 0,
        nature: '',
        brut: 0,
        tare: 0,
        net: 0,
        prixUnitaire: 0,
      ),
    ];
    final facture = current.facture.copyWith(lignes: lignes);
    state = AsyncValue.data(current.copyWith(facture: facture));
  }

  void duplicateLine(int index) {
    final current = _require();
    final lignes = [...current.facture.lignes];
    if (index >= 0 && index < lignes.length) {
      final duplicated = lignes[index].copyWith(id: _uuid.v4());
      lignes.insert(index + 1, duplicated);
      final facture = current.facture.copyWith(lignes: lignes);
      state = AsyncValue.data(current.copyWith(facture: facture));
    }
  }

  void removeLine(int index) {
    final current = _require();
    final lignes = [...current.facture.lignes];
    if (index >= 0 && index < lignes.length && lignes.length > 1) {
      lignes.removeAt(index);
      final facture = current.facture.copyWith(lignes: lignes);
      state = AsyncValue.data(current.copyWith(facture: facture));
    }
  }

  Future<FactureFormState> save() async {
    final current = _require();
    if (current.client.nom.trim().isEmpty) {
      throw Exception('Le client est obligatoire');
    }
    if (current.facture.lignes.isEmpty) {
      throw Exception('Au moins une ligne est requise');
    }

    final client = await _repository.saveClient(current.client);
    var facture = current.facture.copyWith(
      clientId: client.id,
      clientNom: client.nom,
    );

    if (facture.id.isEmpty) {
      facture = facture.copyWith(id: _uuid.v4());
    }

    if (current.facture.createdBy.isEmpty) {
      facture = facture.copyWith(createdBy: _currentUser.id);
    }

    Facture saved;
    if (await _repository.findById(facture.id) == null) {
      saved = await _repository.create(facture);
    } else {
      saved = await _repository.update(facture, role: _currentUser.role);
    }

    final newState = FactureFormState(facture: saved, client: client);
    state = AsyncValue.data(newState);
    await _ref.read(facturesListProvider.notifier).refresh();
    return newState;
  }

  Future<FactureFormState> lock() async {
    final current = _require();
    final locked = await _repository.lockFacture(
      current.facture.id,
      actorId: _currentUser.id,
    );
    final updated = current.copyWith(facture: locked);
    state = AsyncValue.data(updated);
    await _ref.read(facturesListProvider.notifier).refresh();
    return updated;
  }

  Future<Uint8List> generatePdf() async {
    final current = _require();
    return _pdfService.buildPdf(
      facture: current.facture,
      client: current.client,
    );
  }
}
