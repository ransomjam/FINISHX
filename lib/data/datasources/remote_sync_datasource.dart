import 'dart:convert';
import 'dart:io';
import '../../domain/models/sync_status.dart';

/// Abstraction for remote cloud synchronisation.
abstract interface class RemoteSyncDataSource {
  bool get isConfigured;

  /// Attempts to push pending operations to a configured remote backend.
  /// Returns true only when confirmed by a real remote server.
  Future<bool> pushOperations(List<PendingSyncOperation> operations);
}

/// Production HTTP remote sync datasource for FinishX backend API.
class HttpRemoteSyncDataSource implements RemoteSyncDataSource {
  HttpRemoteSyncDataSource({
    String? baseUrl,
    this.authToken,
  }) : baseUrl = baseUrl ?? defaultBaseUrl;

  /// Production Render base URL with fallback to local development.
  static const String defaultBaseUrl = 'https://finishx-api.onrender.com/api/v1';

  final String baseUrl;
  final String? authToken;

  @override
  bool get isConfigured => baseUrl.isNotEmpty && baseUrl.startsWith('http');

  @override
  Future<bool> pushOperations(List<PendingSyncOperation> operations) async {
    if (!isConfigured || operations.isEmpty) return false;

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$baseUrl/sync/events');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      if (authToken != null && authToken!.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }

      final payload = {
        'events': operations.map((op) => {
          'id': op.id,
          'eventType': op.operation,
          'payload': {
            'entityType': op.entityType,
            'entityId': op.entityId,
          },
          'clientTimestamp': op.queuedAt.toIso8601String(),
        }).toList(),
      };

      request.write(jsonEncode(payload));
      final response = await request.close();

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // Offline or network error: return false so operations remain queued safely
      return false;
    } finally {
      client?.close();
    }
  }
}

/// Default implementation used until a real remote API is configured.
class UnconfiguredRemoteSyncDataSource implements RemoteSyncDataSource {
  const UnconfiguredRemoteSyncDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<bool> pushOperations(List<PendingSyncOperation> operations) async {
    return false;
  }
}
