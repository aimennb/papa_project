import 'dart:convert';

import '../local/app_database.dart';
import '../models/models.dart';

class FactureLockedException implements Exception {
  FactureLockedException(this.message);

  final String message;

  @override
  String toString() => 'FactureLockedException: $message';
}

class UnauthorizedActionException implements Exception {
  UnauthorizedActionException(this.message);

  final String message;

  @override
  String toString() => 'UnauthorizedActionException: $message';
}

abstract class FactureRepository {
  Future<List<Facture>> list({String? query, FactureStatus? status});
  Future<Facture?> findById(String id);
  Future<Facture> create(Facture facture);
  Future<Facture> update(Facture facture, {required UserRole role});
  Future<void> delete(String id, {required UserRole role});
  Future<Facture> lockFacture(String id, {required String actorId});
  Future<String> reserveNumero();
  Future<ParametresApp> loadParametres();
  Future<void> saveParametres(ParametresApp parametres);
  Future<List<Client>> suggestClients(String pattern);
  Future<Client> saveClient(Client client);
  Future<Client?> findClient(String id);
  Future<void> bootstrap();
}

class DriftFactureRepository implements FactureRepository {
  DriftFactureRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Facture> create(Facture facture) async {
    return _db.insertFacture(facture);
  }

  @override
  Future<void> delete(String id, {required UserRole role}) async {
    if (role != UserRole.admin) {
      throw UnauthorizedActionException('Seul un ADMIN peut supprimer une facture');
    }
    await _db.deleteFacture(id);
  }

  @override
  Future<Facture?> findById(String id) => _db.findFacture(id);

  @override
  Future<List<Facture>> list({String? query, FactureStatus? status}) =>
      _db.loadFactures(search: query, status: status);

  @override
  Future<Facture> update(Facture facture, {required UserRole role}) async {
    if (facture.isLocked && role != UserRole.admin) {
      throw FactureLockedException('Facture verrouillée');
    }

    final before = await _db.findFacture(facture.id);
    final updated = await _db.updateFacture(facture);
    if (before != null && before.isLocked && role == UserRole.admin) {
      await _db.insertAuditLog(
        entityType: 'facture',
        entityId: facture.id,
        action: 'UPDATE_LOCKED',
        beforeState: jsonEncode(before.toJson()),
        afterState: jsonEncode(updated.toJson()),
        actor: facture.createdBy,
        at: DateTime.now(),
      );
    }
    return updated;
  }

  @override
  Future<Facture> lockFacture(String id, {required String actorId}) async {
    final existing = await _db.findFacture(id);
    if (existing == null) {
      throw StateError('Facture introuvable');
    }
    if (existing.isLocked) {
      return existing;
    }
    final lockedAt = DateTime.now();
    await _db.lockFacture(id, lockedAt);
    await _db.insertAuditLog(
      entityType: 'facture',
      entityId: id,
      action: 'LOCK',
      beforeState: jsonEncode(existing.toJson()),
      afterState: jsonEncode(existing.copyWith(
        status: FactureStatus.locked,
        lockedAt: lockedAt,
      ).toJson()),
      actor: actorId,
      at: lockedAt,
    );
    final refreshed = await _db.findFacture(id);
    if (refreshed == null) {
      throw StateError('Facture introuvable après verrouillage');
    }
    return refreshed;
  }

  @override
  Future<String> reserveNumero() => _db.reserveNumero();

  @override
  Future<ParametresApp> loadParametres() => _db.loadParametres();

  @override
  Future<void> saveParametres(ParametresApp parametres) =>
      _db.upsertParametres(parametres);

  @override
  Future<List<Client>> suggestClients(String pattern) =>
      _db.suggestClients(pattern);

  @override
  Future<Client> saveClient(Client client) => _db.upsertClient(client);

  @override
  Future<Client?> findClient(String id) => _db.findClient(id);

  @override
  Future<void> bootstrap() => _db.seedFixtures();
}
