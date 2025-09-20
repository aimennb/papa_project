import '../local/app_database.dart';
import '../models/models.dart';

abstract class BulletinRepository {
  Future<List<BulletinAchat>> list({String? query});
  Future<BulletinAchat?> findById(int id);
  Future<int> create(BulletinAchat bulletin);
  Future<void> update(BulletinAchat bulletin);
  Future<void> delete(int id);
  Future<ParametresApp> loadParametres();
  Future<void> saveParametres(ParametresApp parametres);
  Future<List<Client>> suggestClients(String pattern);
  Future<void> bootstrap();
}

class DriftBulletinRepository implements BulletinRepository {
  DriftBulletinRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> create(BulletinAchat bulletin) => _db.insertBulletin(bulletin);

  @override
  Future<void> delete(int id) => _db.deleteBulletin(id);

  @override
  Future<BulletinAchat?> findById(int id) => _db.findBulletin(id);

  @override
  Future<List<BulletinAchat>> list({String? query}) =>
      _db.loadBulletins(search: query);

  @override
  Future<void> update(BulletinAchat bulletin) =>
      _db.updateBulletin(bulletin);

  @override
  Future<List<Client>> suggestClients(String pattern) =>
      _db.suggestClients(pattern);

  @override
  Future<ParametresApp> loadParametres() => _db.loadParametres();

  @override
  Future<void> saveParametres(ParametresApp parametres) async {
    await _db.upsertParametres(parametres);
  }

  @override
  Future<void> bootstrap() => _db.seedFixtures();
}
