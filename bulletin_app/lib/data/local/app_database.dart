import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'app_database_executor.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await _createSchema();
          await _seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _dropLegacySchema();
            await _createSchema();
            await _seedDefaults();
          }
          if (from < 3) {
            await _migrateToV3();
          }
        },
      );

  Future<void> _createSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS clients (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        telephone TEXT NOT NULL,
        region TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS fournisseurs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        telephone TEXT,
        adresse TEXT,
        created_at INTEGER NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS approvisionnements (
        id TEXT PRIMARY KEY,
        fournisseur_id TEXT NOT NULL REFERENCES fournisseurs(id) ON DELETE CASCADE,
        date INTEGER NOT NULL,
        marque TEXT NOT NULL,
        nature_produit TEXT NOT NULL,
        nb_colis INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS factures (
        id TEXT PRIMARY KEY,
        numero TEXT NOT NULL UNIQUE,
        date INTEGER NOT NULL,
        client_id TEXT NOT NULL REFERENCES clients(id),
        marque TEXT NOT NULL,
        consignation TEXT NOT NULL,
        carreau INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        locked_at INTEGER
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS lignes (
        id TEXT PRIMARY KEY,
        facture_id TEXT NOT NULL REFERENCES factures(id) ON DELETE CASCADE,
        fournisseur_id TEXT,
        marque TEXT NOT NULL,
        nb_colis INTEGER NOT NULL,
        nature TEXT NOT NULL,
        brut REAL NOT NULL,
        tare REAL NOT NULL,
        net REAL NOT NULL,
        prix_unitaire REAL NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS parametres (
        id TEXT PRIMARY KEY,
        prefix_numero TEXT NOT NULL,
        prochain_compteur INTEGER NOT NULL,
        carreau_par_defaut INTEGER NOT NULL,
        devise TEXT NOT NULL,
        pied_de_page TEXT NOT NULL,
        langue TEXT NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        before_state TEXT,
        after_state TEXT,
        actor TEXT NOT NULL,
        at INTEGER NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        id TEXT PRIMARY KEY,
        last_synced_at INTEGER,
        last_status TEXT NOT NULL,
        last_error TEXT
      );
    ''');
  }

  Future<void> _dropLegacySchema() async {
    const legacyTables = [
      'lignes',
      'bulletins',
      'factures',
      'approvisionnements',
      'fournisseurs',
      'clients',
      'parametres',
      'audit_logs',
      'sync_metadata',
    ];
    for (final table in legacyTables) {
      await customStatement('DROP TABLE IF EXISTS ' + table);
    }
  }

  Future<void> _seedDefaults() async {
    await customStatement(
      'INSERT OR IGNORE INTO parametres (id, prefix_numero, prochain_compteur, carreau_par_defaut, devise, pied_de_page, langue, remote_endpoint, sync_enabled, sync_interval_minutes) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        ParametresApp.defaults.id,
        ParametresApp.defaults.prefixNumero,
        ParametresApp.defaults.prochainCompteur,
        ParametresApp.defaults.carreauParDefaut,
        ParametresApp.defaults.devise,
        ParametresApp.defaults.piedDePage,
        ParametresApp.defaults.langue,
        ParametresApp.defaults.remoteEndpoint,
        ParametresApp.defaults.syncEnabled ? 1 : 0,
        ParametresApp.defaults.syncIntervalMinutes,
      ],
    );

    await customStatement(
      'INSERT OR IGNORE INTO sync_metadata (id, last_synced_at, last_status, last_error) '
      'VALUES (?, NULL, ?, NULL)',
      [
        SyncMetadata.defaults.id,
        SyncMetadata.defaults.lastStatus.dbValue,
      ],
    );
  }

  Future<void> _migrateToV3() async {
    final columns = await customSelect('PRAGMA table_info(parametres)').get();
    final names = columns.map((row) => row.data['name'] as String).toSet();

    if (!names.contains('remote_endpoint')) {
      await customStatement(
        "ALTER TABLE parametres ADD COLUMN remote_endpoint TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!names.contains('sync_enabled')) {
      await customStatement(
        'ALTER TABLE parametres ADD COLUMN sync_enabled INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!names.contains('sync_interval_minutes')) {
      await customStatement(
        'ALTER TABLE parametres ADD COLUMN sync_interval_minutes INTEGER NOT NULL DEFAULT ${ParametresApp.defaults.syncIntervalMinutes}',
      );
    }

    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        id TEXT PRIMARY KEY,
        last_synced_at INTEGER,
        last_status TEXT NOT NULL,
        last_error TEXT
      );
    ''');

    await customStatement(
      'INSERT OR IGNORE INTO sync_metadata (id, last_synced_at, last_status, last_error) '
      'VALUES (?, NULL, ?, NULL)',
      [
        SyncMetadata.defaults.id,
        SyncMetadata.defaults.lastStatus.dbValue,
      ],
    );
  }

  Future<List<Facture>> loadFactures({
    String? search,
    FactureStatus? status,
  }) async {
    final whereClauses = <String>[];
    final variables = <Variable<dynamic>>[];

    if (search != null && search.isNotEmpty) {
      whereClauses.add('(f.numero LIKE ? OR c.nom LIKE ?)');
      final query = '%$search%';
      variables.add(Variable.withString(query));
      variables.add(Variable.withString(query));
    }
    if (status != null) {
      whereClauses.add('f.status = ?');
      variables.add(Variable.withString(status.dbValue));
    }

    final whereSql = whereClauses.isEmpty
        ? ''
        : 'WHERE ' + whereClauses.join(' AND ');

    final rows = await customSelect(
      'SELECT f.*, c.nom AS client_nom FROM factures f '
      'JOIN clients c ON c.id = f.client_id '
      '$whereSql ORDER BY f.date DESC, f.numero DESC',
      variables: variables,
    ).get();

    final result = <Facture>[];
    for (final row in rows) {
      final fact = await _mapFacture(row.data);
      result.add(fact);
    }
    return result;
  }

  Future<Facture?> findFacture(String id) async {
    final rows = await customSelect(
      'SELECT f.*, c.nom AS client_nom FROM factures f '
      'JOIN clients c ON c.id = f.client_id WHERE f.id = ? LIMIT 1',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapFacture(rows.first.data);
  }

  Future<Facture> insertFacture(Facture facture) async {
    return transaction(() async {
      final factureId = facture.id.isEmpty ? _uuid.v4() : facture.id;
      await customStatement(
        'INSERT INTO factures (id, numero, date, client_id, marque, consignation, carreau, status, created_by, created_at, locked_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          factureId,
          facture.numero,
          facture.date.millisecondsSinceEpoch,
          facture.clientId,
          facture.marque,
          facture.consignation,
          facture.carreau,
          facture.status.dbValue,
          facture.createdBy,
          facture.createdAt.millisecondsSinceEpoch,
          facture.lockedAt?.millisecondsSinceEpoch,
        ],
      );

      for (final ligne in facture.lignes) {
        final ligneId = ligne.id.isEmpty ? _uuid.v4() : ligne.id;
        await customStatement(
          'INSERT INTO lignes (id, facture_id, fournisseur_id, marque, nb_colis, nature, brut, tare, net, prix_unitaire) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ligneId,
            factureId,
            ligne.fournisseurId,
            ligne.marque,
            ligne.nbColis,
            ligne.nature,
            ligne.brut,
            ligne.tare,
            ligne.net,
            ligne.prixUnitaire,
          ],
        );
      }

      final saved = await findFacture(factureId);
      if (saved == null) {
        throw StateError('Facture non retrouvée après insertion');
      }
      return saved;
    });
  }

  Future<Facture> updateFacture(Facture facture) async {
    return transaction(() async {
      await customStatement(
        'UPDATE factures SET numero=?, date=?, client_id=?, marque=?, consignation=?, carreau=?, status=?, created_by=?, created_at=?, locked_at=? '
        'WHERE id=?',
        [
          facture.numero,
          facture.date.millisecondsSinceEpoch,
          facture.clientId,
          facture.marque,
          facture.consignation,
          facture.carreau,
          facture.status.dbValue,
          facture.createdBy,
          facture.createdAt.millisecondsSinceEpoch,
          facture.lockedAt?.millisecondsSinceEpoch,
          facture.id,
        ],
      );
      await customStatement('DELETE FROM lignes WHERE facture_id = ?', [facture.id]);
      for (final ligne in facture.lignes) {
        final ligneId = ligne.id.isEmpty ? _uuid.v4() : ligne.id;
        await customStatement(
          'INSERT INTO lignes (id, facture_id, fournisseur_id, marque, nb_colis, nature, brut, tare, net, prix_unitaire) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ligneId,
            facture.id,
            ligne.fournisseurId,
            ligne.marque,
            ligne.nbColis,
            ligne.nature,
            ligne.brut,
            ligne.tare,
            ligne.net,
            ligne.prixUnitaire,
          ],
        );
      }
      final updated = await findFacture(facture.id);
      if (updated == null) {
        throw StateError('Facture non retrouvée après mise à jour');
      }
      return updated;
    });
  }

  Future<void> deleteFacture(String id) async {
    await transaction(() async {
      await customStatement('DELETE FROM lignes WHERE facture_id = ?', [id]);
      await customStatement('DELETE FROM factures WHERE id = ?', [id]);
    });
  }

  Future<void> lockFacture(String id, DateTime lockedAt) async {
    await customStatement(
      'UPDATE factures SET status=?, locked_at=? WHERE id=?',
      [
        FactureStatus.locked.name,
        lockedAt.millisecondsSinceEpoch,
        id,
      ],
    );
  }

  Future<String> reserveNumero() async {
    return transaction(() async {
      final rows = await customSelect(
        'SELECT prefix_numero, prochain_compteur, carreau_par_defaut, devise, pied_de_page, langue '
        'FROM parametres WHERE id = ? LIMIT 1',
        variables: [Variable.withString(ParametresApp.defaults.id)],
      ).get();
      final data = rows.isEmpty ? null : rows.first.data;
      final prefix = data?['prefix_numero'] as String? ??
          ParametresApp.defaults.prefixNumero;
      final compteur = data?['prochain_compteur'] as int? ??
          ParametresApp.defaults.prochainCompteur;
      final carreau = data?['carreau_par_defaut'] as int? ??
          ParametresApp.defaults.carreauParDefaut;
      final devise = data?['devise'] as String? ??
          ParametresApp.defaults.devise;
      final piedDePage = data?['pied_de_page'] as String? ??
          ParametresApp.defaults.piedDePage;
      final langue = data?['langue'] as String? ??
          ParametresApp.defaults.langue;
      final numero = prefix + compteur.toString().padLeft(6, '0');
      await customStatement(
        'INSERT INTO parametres (id, prefix_numero, prochain_compteur, carreau_par_defaut, devise, pied_de_page, langue, remote_endpoint, sync_enabled, sync_interval_minutes) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET prochain_compteur=excluded.prochain_compteur, prefix_numero=excluded.prefix_numero, '
        'carreau_par_defaut=excluded.carreau_par_defaut, devise=excluded.devise, pied_de_page=excluded.pied_de_page, langue=excluded.langue',
        [
          ParametresApp.defaults.id,
          prefix,
          compteur + 1,
          carreau,
          devise,
          piedDePage,
          langue,
          ParametresApp.defaults.remoteEndpoint,
          ParametresApp.defaults.syncEnabled ? 1 : 0,
          ParametresApp.defaults.syncIntervalMinutes,
        ],
      );
      return numero;
    });
  }

  Future<ParametresApp> loadParametres() async {
    final rows = await customSelect(
      'SELECT * FROM parametres WHERE id = ? LIMIT 1',
      variables: [Variable.withString(ParametresApp.defaults.id)],
    ).get();
    if (rows.isEmpty) {
      return ParametresApp.defaults;
    }
    final row = rows.first.data;
    return ParametresApp(
      id: row['id'] as String,
      prefixNumero: row['prefix_numero'] as String,
      prochainCompteur: row['prochain_compteur'] as int,
      carreauParDefaut: row['carreau_par_defaut'] as int,
      devise: row['devise'] as String,
      piedDePage: row['pied_de_page'] as String,
      langue: row['langue'] as String,
      remoteEndpoint: row['remote_endpoint'] as String? ?? '',
      syncEnabled: ((row['sync_enabled'] as int?) ?? 0) == 1,
      syncIntervalMinutes:
          (row['sync_interval_minutes'] as int?) ?? ParametresApp.defaults.syncIntervalMinutes,
    );
  }

  Future<void> upsertParametres(ParametresApp params) async {
    await customStatement(
      'INSERT INTO parametres (id, prefix_numero, prochain_compteur, carreau_par_defaut, devise, pied_de_page, langue, remote_endpoint, sync_enabled, sync_interval_minutes) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET prefix_numero=excluded.prefix_numero, prochain_compteur=excluded.prochain_compteur, '
      'carreau_par_defaut=excluded.carreau_par_defaut, devise=excluded.devise, pied_de_page=excluded.pied_de_page, langue=excluded.langue, '
      'remote_endpoint=excluded.remote_endpoint, sync_enabled=excluded.sync_enabled, sync_interval_minutes=excluded.sync_interval_minutes',
      [
        params.id,
        params.prefixNumero,
        params.prochainCompteur,
        params.carreauParDefaut,
        params.devise,
        params.piedDePage,
        params.langue,
        params.remoteEndpoint,
        params.syncEnabled ? 1 : 0,
        params.syncIntervalMinutes,
      ],
    );
  }

  Future<SyncMetadata> loadSyncMetadata() async {
    final rows = await customSelect(
      'SELECT * FROM sync_metadata WHERE id = ? LIMIT 1',
      variables: [Variable.withString(SyncMetadata.defaults.id)],
    ).get();
    if (rows.isEmpty) {
      return SyncMetadata.defaults;
    }
    final data = rows.first.data;
    return SyncMetadata(
      id: data['id'] as String,
      lastSyncedAt: data['last_synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['last_synced_at'] as int)
          : null,
      lastStatus:
          SyncStatusSerializer.fromDatabase(data['last_status'] as String),
      lastError: data['last_error'] as String?,
    );
  }

  Future<void> upsertSyncMetadata(SyncMetadata metadata) async {
    await customStatement(
      'INSERT INTO sync_metadata (id, last_synced_at, last_status, last_error) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET last_synced_at=excluded.last_synced_at, last_status=excluded.last_status, last_error=excluded.last_error',
      [
        metadata.id,
        metadata.lastSyncedAt?.millisecondsSinceEpoch,
        metadata.lastStatus.dbValue,
        metadata.lastError,
      ],
    );
  }

  Future<SyncSnapshot> exportSnapshot() async {
    final clientsRows = await customSelect(
      'SELECT * FROM clients ORDER BY created_at ASC',
    ).get();
    final clients = clientsRows
        .map(
          (row) => Client(
            id: row.data['id'] as String,
            nom: row.data['nom'] as String,
            telephone: row.data['telephone'] as String,
            region: row.data['region'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.data['created_at'] as int,
            ),
          ),
        )
        .toList();

    final factures = await loadFactures();
    final parametres = await loadParametres();

    return SyncSnapshot(
      generatedAt: DateTime.now(),
      parametres: parametres,
      clients: clients,
      factures: factures,
    );
  }

  Future<void> applySnapshot(SyncSnapshot snapshot) async {
    await transaction(() async {
      for (final client in snapshot.clients) {
        await customStatement(
          'INSERT INTO clients (id, nom, telephone, region, created_at) VALUES (?, ?, ?, ?, ?) '
          'ON CONFLICT(id) DO UPDATE SET nom=excluded.nom, telephone=excluded.telephone, region=excluded.region, created_at=excluded.created_at',
          [
            client.id,
            client.nom,
            client.telephone,
            client.region,
            client.createdAt.millisecondsSinceEpoch,
          ],
        );
      }

      for (final facture in snapshot.factures) {
        await customStatement(
          'INSERT INTO factures (id, numero, date, client_id, marque, consignation, carreau, status, created_by, created_at, locked_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
          'ON CONFLICT(id) DO UPDATE SET numero=excluded.numero, date=excluded.date, client_id=excluded.client_id, marque=excluded.marque, '
          'consignation=excluded.consignation, carreau=excluded.carreau, status=excluded.status, created_by=excluded.created_by, created_at=excluded.created_at, locked_at=excluded.locked_at',
          [
            facture.id,
            facture.numero,
            facture.date.millisecondsSinceEpoch,
            facture.clientId,
            facture.marque,
            facture.consignation,
            facture.carreau,
            facture.status.dbValue,
            facture.createdBy,
            facture.createdAt.millisecondsSinceEpoch,
            facture.lockedAt?.millisecondsSinceEpoch,
          ],
        );

        await customStatement(
          'DELETE FROM lignes WHERE facture_id = ?',
          [facture.id],
        );

        for (final ligne in facture.lignes) {
          final ligneId = ligne.id.isEmpty ? _uuid.v4() : ligne.id;
          await customStatement(
            'INSERT INTO lignes (id, facture_id, fournisseur_id, marque, nb_colis, nature, brut, tare, net, prix_unitaire) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              ligneId,
              facture.id,
              ligne.fournisseurId,
              ligne.marque,
              ligne.nbColis,
              ligne.nature,
              ligne.brut,
              ligne.tare,
              ligne.net,
              ligne.prixUnitaire,
            ],
          );
        }
      }

      final localParams = await loadParametres();
      final remoteParams = snapshot.parametres;
      final nextCompteur = remoteParams.prochainCompteur > localParams.prochainCompteur
          ? remoteParams.prochainCompteur
          : localParams.prochainCompteur;

      final merged = localParams.copyWith(
        prefixNumero: remoteParams.prefixNumero,
        prochainCompteur: nextCompteur,
        carreauParDefaut: remoteParams.carreauParDefaut,
        devise: remoteParams.devise,
        piedDePage: remoteParams.piedDePage,
        langue: remoteParams.langue,
      );
      await upsertParametres(merged);
    });
  }

  Future<List<Client>> suggestClients(String pattern) async {
    final rows = await customSelect(
      'SELECT * FROM clients WHERE nom LIKE ? ORDER BY nom LIMIT 10',
      variables: [Variable.withString('%$pattern%')],
    ).get();
    return rows
        .map(
          (row) => Client(
            id: row.data['id'] as String,
            nom: row.data['nom'] as String,
            telephone: row.data['telephone'] as String,
            region: row.data['region'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.data['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<Client> upsertClient(Client client) async {
    final clientId = client.id.isEmpty ? _uuid.v4() : client.id;
    await customStatement(
      'INSERT INTO clients (id, nom, telephone, region, created_at) VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET nom=excluded.nom, telephone=excluded.telephone, region=excluded.region',
      [
        clientId,
        client.nom,
        client.telephone,
        client.region,
        client.createdAt.millisecondsSinceEpoch,
      ],
    );
    return client.copyWith(id: clientId);
  }

  Future<Client?> findClient(String id) async {
    final rows = await customSelect(
      'SELECT * FROM clients WHERE id = ? LIMIT 1',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    final data = rows.first.data;
    return Client(
      id: data['id'] as String,
      nom: data['nom'] as String,
      telephone: data['telephone'] as String,
      region: data['region'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
    );
  }

  Future<void> seedFixtures() async {
    final countRow = await customSelect(
      'SELECT COUNT(*) AS total FROM factures',
    ).getSingleOrNull();
    final countData = countRow?.data;
    final count = (countData?['total'] as int?) ?? 0;
    if (count > 0) {
      return;
    }

    final now = DateTime.now();
    final client1 = Client(
      id: _uuid.v4(),
      nom: 'KHENOUCI Chabane',
      telephone: '0555 010101',
      region: 'Alger',
      createdAt: now.subtract(const Duration(days: 90)),
    );
    final client2 = Client(
      id: _uuid.v4(),
      nom: 'Ahmed B.',
      telephone: '0555 020202',
      region: 'Boumerdès',
      createdAt: now.subtract(const Duration(days: 30)),
    );

    await upsertClient(client1);
    await upsertClient(client2);

    final facture1 = Facture(
      id: _uuid.v4(),
      numero: '0006196',
      date: now.subtract(const Duration(days: 1)),
      clientId: client1.id,
      clientNom: client1.nom,
      marque: 'Tomate',
      consignation: 'Palettes',
      carreau: 62,
      status: FactureStatus.locked,
      lignes: [
        LigneAchat(
          id: _uuid.v4(),
          fournisseurId: null,
          marque: 'DZ',
          nbColis: 12,
          nature: 'Tomates',
          brut: 120,
          tare: 5,
          net: 115,
          prixUnitaire: 80,
        ),
        LigneAchat(
          id: _uuid.v4(),
          fournisseurId: null,
          marque: 'DZ',
          nbColis: 10,
          nature: 'Courgettes',
          brut: 100,
          tare: 4,
          net: 96,
          prixUnitaire: 90,
        ),
      ],
      createdBy: 'seed',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      lockedAt: now.subtract(const Duration(days: 1, hours: 1)),
    );

    final facture2 = Facture(
      id: _uuid.v4(),
      numero: '0006197',
      date: now,
      clientId: client2.id,
      clientNom: client2.nom,
      marque: 'Pomme',
      consignation: 'Bacs',
      carreau: 62,
      status: FactureStatus.draft,
      lignes: [
        LigneAchat(
          id: _uuid.v4(),
          fournisseurId: null,
          marque: 'FR',
          nbColis: 8,
          nature: 'Pommes Golden',
          brut: 80,
          tare: 3,
          net: 77,
          prixUnitaire: 120,
        ),
      ],
      createdBy: 'seed',
      createdAt: now.subtract(const Duration(hours: 3)),
      lockedAt: null,
    );

    await insertFacture(facture1);
    await insertFacture(facture2);
    await upsertParametres(
      ParametresApp.defaults.copyWith(prochainCompteur: 6198),
    );
  }

  Future<Facture> _mapFacture(Map<String, dynamic> data) async {
    final factureId = data['id'] as String;
    final lignesRows = await customSelect(
      'SELECT * FROM lignes WHERE facture_id = ? ORDER BY rowid ASC',
      variables: [Variable.withString(factureId)],
    ).get();

    final lignes = lignesRows
        .map(
          (row) => LigneAchat(
            id: row.data['id'] as String,
            fournisseurId: row.data['fournisseur_id'] as String?,
            marque: row.data['marque'] as String,
            nbColis: row.data['nb_colis'] as int,
            nature: row.data['nature'] as String,
            brut: (row.data['brut'] as num).toDouble(),
            tare: (row.data['tare'] as num).toDouble(),
            net: (row.data['net'] as num).toDouble(),
            prixUnitaire: (row.data['prix_unitaire'] as num).toDouble(),
          ),
        )
        .toList();

    return Facture(
      id: factureId,
      numero: data['numero'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      clientId: data['client_id'] as String,
      clientNom: data['client_nom'] as String,
      marque: data['marque'] as String,
      consignation: data['consignation'] as String,
      carreau: data['carreau'] as int,
      status:
          FactureStatusSerializer.fromDatabase(data['status'] as String),
      lignes: lignes,
      createdBy: data['created_by'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lockedAt: data['locked_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['locked_at'] as int)
          : null,
    );
  }

  Future<void> insertAuditLog({
    required String entityType,
    required String entityId,
    required String action,
    String? beforeState,
    String? afterState,
    required String actor,
    required DateTime at,
  }) async {
    await customStatement(
      'INSERT INTO audit_logs (id, entity_type, entity_id, action, before_state, after_state, actor, at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        entityType,
        entityId,
        action,
        beforeState,
        afterState,
        actor,
        at.millisecondsSinceEpoch,
      ],
    );
  }
}
