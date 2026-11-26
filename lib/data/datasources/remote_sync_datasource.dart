import '../../domain/models/sync_status.dart';

/// Abstraction for remote cloud synchronisation.
abstract interface class RemoteSyncDataSource {
  bool get isConfigured;

  /// Attempts to push pending operations to a configured remote backend.
  /// Returns true only when confirmed by a real remote server.
  Future<bool> pushOperations(List<PendingSyncOperation> operations);
}

/// Default implementation used until a real remote API is configured.
///
/// Explicitly reports [isConfigured] as false and never fakes remote sync.
class UnconfiguredRemoteSyncDataSource implements RemoteSyncDataSource {
  const UnconfiguredRemoteSyncDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<bool> pushOperations(List<PendingSyncOperation> operations) async {
    return false;
  }
}
