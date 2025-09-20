import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/bulletin_repository.dart';
import '../../printing/pdf_service.dart';
import 'app_bootstrap_provider.dart';
import 'bulletins_list_provider.dart';

final currentBulletinProvider = StateNotifierProvider<CurrentBulletinNotifier,
    AsyncValue<BulletinAchat>>((ref) {
  final repo = ref.watch(bulletinRepositoryProvider);
  final paramsNotifier = ref.watch(parametresProvider.notifier);
  final pdf = ref.watch(pdfServiceProvider);
  return CurrentBulletinNotifier(ref, repo, paramsNotifier, pdf);
});

class CurrentBulletinNotifier
    extends StateNotifier<AsyncValue<BulletinAchat>> {
  CurrentBulletinNotifier(
    this._ref,
    this._repository,
    this._parametresNotifier,
    this._pdfService,
  ) : super(const AsyncValue.loading());

  final Ref _ref;
  final BulletinRepository _repository;
  final ParametresNotifier _parametresNotifier;
  final PdfService _pdfService;

  Future<void> load({int? id}) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        final params = await _repository.loadParametres();
        final numero = _formatNumero(
          params.prefixNumero,
          params.prochainCompteur,
        );
        final bulletin = BulletinAchat(
          numero: numero,
          date: DateTime.now(),
          client: '',
          marque: '',
          consignation: '',
          carreau: params.carreauParDefaut,
          lignes: const [
            LigneAchat(
              marque: '',
              nbColis: 0,
              nature: '',
              brut: 0,
              tare: 0,
              net: 0,
              prixUnitaire: 0,
            ),
          ],
        );
        state = AsyncValue.data(bulletin);
      } else {
        final existing = await _repository.findById(id);
        if (existing != null) {
          state = AsyncValue.data(existing);
        } else {
          state = AsyncValue.error('Introuvable', StackTrace.current);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  BulletinAchat _require() {
    final value = state.value;
    if (value == null) {
      throw StateError('Bulletin non chargé');
    }
    return value;
  }

  void updateHeader({
    String? client,
    String? marque,
    String? consignation,
    int? carreau,
    DateTime? date,
  }) {
    final current = _require();
    state = AsyncValue.data(
      current.copyWith(
        client: client ?? current.client,
        marque: marque ?? current.marque,
        consignation: consignation ?? current.consignation,
        carreau: carreau ?? current.carreau,
        date: date ?? current.date,
      ),
    );
  }

  void updateLine(int index, LigneAchat ligne) {
    final current = _require();
    final lignes = [...current.lignes];
    if (index >= 0 && index < lignes.length) {
      lignes[index] = ligne;
      state = AsyncValue.data(current.copyWith(lignes: lignes));
    }
  }

  void addLine(LigneAchat ligne) {
    final current = _require();
    final lignes = [...current.lignes, ligne];
    state = AsyncValue.data(current.copyWith(lignes: lignes));
  }

  void duplicateLine(int index) {
    final current = _require();
    final lignes = [...current.lignes];
    if (index >= 0 && index < lignes.length) {
      lignes.insert(index + 1, lignes[index].copyWith());
      state = AsyncValue.data(current.copyWith(lignes: lignes));
    }
  }

  void removeLine(int index) {
    final current = _require();
    final lignes = [...current.lignes];
    if (index >= 0 && index < lignes.length && lignes.length > 1) {
      lignes.removeAt(index);
      state = AsyncValue.data(current.copyWith(lignes: lignes));
    }
  }

  Future<BulletinAchat> save() async {
    final current = _require();
    if (current.lignes.isEmpty) {
      throw Exception('Au moins une ligne est requise');
    }
    if (current.id == null) {
      final params = await _repository.loadParametres();
      final id = await _repository.create(current);
      final updatedBulletin = current.copyWith(id: id);
      final newParams = params.copyWith(
        prochainCompteur: params.prochainCompteur + 1,
      );
      await _repository.saveParametres(newParams);
      _parametresNotifier.setInitial(newParams);
      state = AsyncValue.data(updatedBulletin);
      await _ref.read(bulletinsListProvider.notifier).refresh();
      return updatedBulletin;
    } else {
      await _repository.update(current);
      await _ref.read(bulletinsListProvider.notifier).refresh();
      return current;
    }
  }

  Future<Uint8List> generatePdf() async {
    final current = _require();
    return _pdfService.buildPdf(current);
  }

  String _formatNumero(String prefix, int compteur) {
    return '$prefix${compteur.toString().padLeft(6, '0')}';
  }
}
