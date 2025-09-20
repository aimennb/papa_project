// ignore: avoid_web_libraries_in_flutter, unused_import
import 'dart:io' as io
    if (dart.library.html) 'dart:html' as html;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = io.File(p.join(directory.path, 'bulletins.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_createExecutor());

  static QueryExecutor _createExecutor() {
    if (kIsWeb) {
      return WebDatabase('bulletins_db');
    }
    return _openConnection();
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS bulletins (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              numero TEXT UNIQUE NOT NULL,
              date INTEGER NOT NULL,
              client TEXT NOT NULL,
              marque TEXT NOT NULL,
              consignation TEXT NOT NULL,
              carreau INTEGER NOT NULL
            );
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS lignes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bulletin_id INTEGER NOT NULL,
              marque TEXT NOT NULL,
              nb_colis INTEGER NOT NULL,
              nature TEXT NOT NULL,
              brut REAL NOT NULL,
              tare REAL NOT NULL,
              net REAL NOT NULL,
              prix_unitaire REAL NOT NULL,
              FOREIGN KEY(bulletin_id) REFERENCES bulletins(id) ON DELETE CASCADE
            );
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              telephone TEXT,
              adresse TEXT
            );
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS parametres (
              id INTEGER PRIMARY KEY CHECK (id = 0),
              prefix_numero TEXT NOT NULL,
              prochain_compteur INTEGER NOT NULL,
              carreau_defaut INTEGER NOT NULL,
              devise TEXT NOT NULL,
              pied_de_page TEXT NOT NULL,
              langue TEXT NOT NULL
            );
          ''');
          await customStatement('INSERT OR IGNORE INTO parametres (id, prefix_numero, prochain_compteur, carreau_defaut, devise, pied_de_page, langue) VALUES (0, '', 1, 62, "DA", "Après huit (8) jours, l'emballage ne sera pas remboursé.", "fr");');
        },
      );

  Future<List<BulletinAchat>> loadBulletins({
    String? search,
    DateTime? start,
    DateTime? end,
  }) async {
    final whereClauses = <String>[];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      whereClauses.add('(numero LIKE ? OR client LIKE ?)');
      final query = '%$search%';
      args.addAll([query, query]);
    }

    if (start != null) {
      whereClauses.add('date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      whereClauses.add('date <= ?');
      args.add(end.millisecondsSinceEpoch);
    }

    final whereSql = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';

    final bulletinsRows = await customSelect(
      'SELECT * FROM bulletins $whereSql ORDER BY date DESC, numero DESC',
      variables: args.map((e) => Variable.withDynamic(e)).toList(),
    ).get();

    final bulletins = <BulletinAchat>[];
    for (final row in bulletinsRows) {
      final id = row.data['id'] as int;
      final lignesRows = await customSelect(
        'SELECT * FROM lignes WHERE bulletin_id = ? ORDER BY id ASC',
        variables: [Variable.withInt(id)],
      ).get();
      final lignes = lignesRows
          .map((r) => LigneAchat(
                id: r.data['id'] as int?,
                marque: r.data['marque'] as String,
                nbColis: r.data['nb_colis'] as int,
                nature: r.data['nature'] as String,
                brut: (r.data['brut'] as num).toDouble(),
                tare: (r.data['tare'] as num).toDouble(),
                net: (r.data['net'] as num).toDouble(),
                prixUnitaire: (r.data['prix_unitaire'] as num).toDouble(),
              ))
          .toList();
      bulletins.add(
        BulletinAchat(
          id: id,
          numero: row.data['numero'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(
            row.data['date'] as int,
          ),
          client: row.data['client'] as String,
          marque: row.data['marque'] as String,
          consignation: row.data['consignation'] as String,
          carreau: row.data['carreau'] as int,
          lignes: lignes,
        ),
      );
    }
    return bulletins;
  }

  Future<BulletinAchat?> findBulletin(int id) async {
    final rows = await customSelect(
      'SELECT * FROM bulletins WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final lignesRows = await customSelect(
      'SELECT * FROM lignes WHERE bulletin_id = ? ORDER BY id ASC',
      variables: [Variable.withInt(id)],
    ).get();
    final lignes = lignesRows
        .map((r) => LigneAchat(
              id: r.data['id'] as int?,
              marque: r.data['marque'] as String,
              nbColis: r.data['nb_colis'] as int,
              nature: r.data['nature'] as String,
              brut: (r.data['brut'] as num).toDouble(),
              tare: (r.data['tare'] as num).toDouble(),
              net: (r.data['net'] as num).toDouble(),
              prixUnitaire: (r.data['prix_unitaire'] as num).toDouble(),
            ))
        .toList();
    return BulletinAchat(
      id: row.data['id'] as int,
      numero: row.data['numero'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row.data['date'] as int),
      client: row.data['client'] as String,
      marque: row.data['marque'] as String,
      consignation: row.data['consignation'] as String,
      carreau: row.data['carreau'] as int,
      lignes: lignes,
    );
  }

  Future<int> insertBulletin(BulletinAchat bulletin) async {
    return transaction(() async {
      final id = await customInsert(
        'INSERT INTO bulletins (numero, date, client, marque, consignation, carreau) VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(bulletin.numero),
          Variable.withInt(bulletin.date.millisecondsSinceEpoch),
          Variable.withString(bulletin.client),
          Variable.withString(bulletin.marque),
          Variable.withString(bulletin.consignation),
          Variable.withInt(bulletin.carreau),
        ],
        updates: {},
      );
      for (final ligne in bulletin.lignes) {
        await customInsert(
          'INSERT INTO lignes (bulletin_id, marque, nb_colis, nature, brut, tare, net, prix_unitaire) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable.withInt(id),
            Variable.withString(ligne.marque),
            Variable.withInt(ligne.nbColis),
            Variable.withString(ligne.nature),
            Variable.withReal(ligne.brut),
            Variable.withReal(ligne.tare),
            Variable.withReal(ligne.net),
            Variable.withReal(ligne.prixUnitaire),
          ],
          updates: {},
        );
      }
      return id;
    });
  }

  Future<void> updateBulletin(BulletinAchat bulletin) async {
    if (bulletin.id == null) {
      throw ArgumentError('Bulletin must have an id to update');
    }
    await transaction(() async {
      await customStatement(
        'UPDATE bulletins SET numero = ?, date = ?, client = ?, marque = ?, consignation = ?, carreau = ? WHERE id = ?',
        [
          bulletin.numero,
          bulletin.date.millisecondsSinceEpoch,
          bulletin.client,
          bulletin.marque,
          bulletin.consignation,
          bulletin.carreau,
          bulletin.id,
        ],
      );
      await customStatement(
        'DELETE FROM lignes WHERE bulletin_id = ?',
        [bulletin.id],
      );
      for (final ligne in bulletin.lignes) {
        await customInsert(
          'INSERT INTO lignes (bulletin_id, marque, nb_colis, nature, brut, tare, net, prix_unitaire) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable.withInt(bulletin.id!),
            Variable.withString(ligne.marque),
            Variable.withInt(ligne.nbColis),
            Variable.withString(ligne.nature),
            Variable.withReal(ligne.brut),
            Variable.withReal(ligne.tare),
            Variable.withReal(ligne.net),
            Variable.withReal(ligne.prixUnitaire),
          ],
          updates: {},
        );
      }
    });
  }

  Future<void> deleteBulletin(int id) async {
    await transaction(() async {
      await customStatement('DELETE FROM lignes WHERE bulletin_id = ?', [id]);
      await customStatement('DELETE FROM bulletins WHERE id = ?', [id]);
    });
  }

  Future<void> upsertParametres(ParametresApp params) async {
    await customStatement(
      'INSERT INTO parametres (id, prefix_numero, prochain_compteur, carreau_defaut, devise, pied_de_page, langue) VALUES (0, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET prefix_numero=excluded.prefix_numero, prochain_compteur=excluded.prochain_compteur, carreau_defaut=excluded.carreau_defaut, devise=excluded.devise, pied_de_page=excluded.pied_de_page, langue=excluded.langue',
      [
        params.prefixNumero,
        params.prochainCompteur,
        params.carreauParDefaut,
        params.devise,
        params.piedDePage,
        params.langue,
      ],
    );
  }

  Future<ParametresApp> loadParametres() async {
    final rows = await customSelect('SELECT * FROM parametres LIMIT 1').get();
    if (rows.isEmpty) {
      return ParametresApp.defaults;
    }
    final row = rows.first.data;
    return ParametresApp(
      prefixNumero: row['prefix_numero'] as String,
      prochainCompteur: row['prochain_compteur'] as int,
      carreauParDefaut: row['carreau_defaut'] as int,
      devise: row['devise'] as String,
      piedDePage: row['pied_de_page'] as String,
      langue: row['langue'] as String,
    );
  }

  Future<void> saveClient(Client client) async {
    await customInsert(
      'INSERT INTO clients (nom, telephone, adresse) VALUES (?, ?, ?)',
      variables: [
        Variable.withString(client.nom),
        Variable<String?>(client.telephone),
        Variable<String?>(client.adresse),
      ],
      updates: {},
    );
  }

  Future<List<Client>> suggestClients(String pattern) async {
    final rows = await customSelect(
      'SELECT * FROM clients WHERE nom LIKE ? ORDER BY nom LIMIT 10',
      variables: [Variable.withString('%$pattern%')],
    ).get();
    return rows
        .map((row) => Client(
              id: row.data['id'] as int?,
              nom: row.data['nom'] as String,
              telephone: row.data['telephone'] as String?,
              adresse: row.data['adresse'] as String?,
            ))
        .toList();
  }

  Future<void> seedFixtures() async {
    final bulletins = await customSelect('SELECT COUNT(*) AS total FROM bulletins').get();
    final count = (bulletins.first.data['total'] as int?) ?? 0;
    if (count > 0) {
      return;
    }

    final fixtures = _buildFixtures();
    for (final bulletin in fixtures) {
      await insertBulletin(bulletin);
    }
    await upsertParametres(ParametresApp.defaults);
  }

  List<BulletinAchat> _buildFixtures() {
    final now = DateTime.now();
    return [
      BulletinAchat(
        numero: '0006196',
        date: now.subtract(const Duration(days: 1)),
        client: 'KHENOUCI Chabane',
        marque: 'Tomate',
        consignation: 'Palettes',
        carreau: 62,
        lignes: const [
          LigneAchat(
            marque: 'DZ',
            nbColis: 12,
            nature: 'Tomates',
            brut: 120,
            tare: 5,
            net: 115,
            prixUnitaire: 80,
          ),
          LigneAchat(
            marque: 'DZ',
            nbColis: 10,
            nature: 'Courgettes',
            brut: 100,
            tare: 4,
            net: 96,
            prixUnitaire: 90,
          ),
        ],
      ),
      BulletinAchat(
        numero: '0006197',
        date: now,
        client: 'Ahmed B.',
        marque: 'Pomme',
        consignation: 'Bacs',
        carreau: 62,
        lignes: const [
          LigneAchat(
            marque: 'FR',
            nbColis: 8,
            nature: 'Pommes Golden',
            brut: 80,
            tare: 3,
            net: 77,
            prixUnitaire: 120,
          ),
        ],
      ),
    ];
  }
}
