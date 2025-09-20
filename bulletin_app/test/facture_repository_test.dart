import 'package:bulletin_app/data/local/app_database.dart';
import 'package:bulletin_app/data/models/models.dart';
import 'package:bulletin_app/data/repositories/facture_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Facture repository', () {
    late AppDatabase db;
    late DriftFactureRepository repository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftFactureRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('reserveNumero increments sequentially', () async {
      final first = await repository.reserveNumero();
      final second = await repository.reserveNumero();

      expect(first, '000001');
      expect(second, '000002');
    });

    test('locking prevents modification for non admin', () async {
      final client = await repository.saveClient(
        Client(
          id: 'c1',
          nom: 'Client Test',
          telephone: '',
          region: '',
          createdAt: DateTime.now(),
        ),
      );
      final numero = await repository.reserveNumero();
      final factureDraft = Facture(
        id: 'f1',
        numero: numero,
        date: DateTime.now(),
        clientId: client.id,
        clientNom: client.nom,
        marque: 'Tomate',
        consignation: 'Bacs',
        carreau: 62,
        lignes: const [
          LigneAchat(
            id: 'l1',
            fournisseurId: null,
            marque: 'DZ',
            nbColis: 10,
            nature: 'Tomates',
            brut: 120,
            tare: 5,
            net: 115,
            prixUnitaire: 80,
          ),
        ],
        status: FactureStatus.draft,
        createdBy: 'tester',
        createdAt: DateTime.now(),
        lockedAt: null,
      );

      final saved = await repository.create(factureDraft);
      final locked = await repository.lockFacture(saved.id, actorId: 'tester');
      expect(locked.status, FactureStatus.locked);

      expect(
        () => repository.update(locked, role: UserRole.facture),
        throwsA(isA<FactureLockedException>()),
      );

      final updatedByAdmin = await repository.update(
        locked.copyWith(marque: 'Pomme'),
        role: UserRole.admin,
      );
      expect(updatedByAdmin.marque, 'Pomme');
    });
  });
}
