import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class SyncApiException implements Exception {
  SyncApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'SyncApiException(statusCode: $statusCode, message: $message)';
}

class SyncApiClient {
  SyncApiClient({
    required Uri baseUri,
    http.Client? httpClient,
  })  : _baseUri = baseUri,
        _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;

  Uri _endpoint(String path, [Map<String, String>? queryParameters]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final base = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    final resolved = base.resolve(normalized);
    if (queryParameters == null) {
      return resolved;
    }
    return resolved.replace(queryParameters: queryParameters);
  }

  Future<void> pushSnapshot(SyncSnapshot snapshot) async {
    final response = await _httpClient.post(
      _endpoint('sync/push'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(snapshot.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw SyncApiException(
      'Échec de l\'envoi des données (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  Future<SyncSnapshot?> pullSnapshot({DateTime? since}) async {
    final query = <String, String>{};
    if (since != null) {
      query['since'] = since.toUtc().toIso8601String();
    }
    final response = await _httpClient.get(
      _endpoint('sync/pull', query.isEmpty ? null : query),
    );
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncSnapshot.fromJson(data);
    }
    throw SyncApiException(
      'Échec de la récupération (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }
}
