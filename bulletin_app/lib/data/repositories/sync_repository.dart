import 'package:http/http.dart' as http;

import '../local/app_database.dart';
import '../models/models.dart';
import '../remote/sync_api_client.dart';

class SyncException implements Exception {
  SyncException(this.message);

  final String message;

  @override
  String toString() => 'SyncException: $message';
}

class SyncRepository {
  SyncRepository(this._db, this._httpClient);

  final AppDatabase _db;
  final http.Client _httpClient;

  Future<SyncMetadata> loadMetadata() => _db.loadSyncMetadata();

  Future<SyncMetadata> synchronize({required Uri endpoint}) async {
    final metadata = await _db.loadSyncMetadata();
    final client = SyncApiClient(baseUri: endpoint, httpClient: _httpClient);

    try {
      final snapshot = await _db.exportSnapshot();
      await client.pushSnapshot(snapshot);
      final remoteSnapshot = await client.pullSnapshot(
        since: metadata.lastSyncedAt,
      );
      if (remoteSnapshot != null) {
        await _db.applySnapshot(remoteSnapshot);
      }
      final updated = metadata.copyWith(
        lastSyncedAt: DateTime.now(),
        lastStatus: SyncStatus.success,
        clearError: true,
      );
      await _db.upsertSyncMetadata(updated);
      return updated;
    } on SyncApiException catch (e) {
      final failure = metadata.copyWith(
        lastStatus: SyncStatus.error,
        lastError: e.message,
      );
      await _db.upsertSyncMetadata(failure);
      throw SyncException(e.message);
    } catch (e) {
      final failure = metadata.copyWith(
        lastStatus: SyncStatus.error,
        lastError: e.toString(),
      );
      await _db.upsertSyncMetadata(failure);
      throw SyncException('Erreur de synchronisation: $e');
    }
  }
}
