import '../../core/utils/id_generator.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/sync_status.dart';
import '../datasources/local_storage_datasource.dart';
import '../datasources/remote_sync_datasource.dart';

class SyncRepository {
  SyncRepository({
    required LocalStorageDataSource storage,
    RemoteSyncDataSource remote = const UnconfiguredRemoteSyncDataSource(),
  }) : _storage = storage,
       _remote = remote;

  final LocalStorageDataSource _storage;
  final RemoteSyncDataSource _remote;

  bool get isOfflineMode =>
      _storage.readBool(LocalStorageDataSource.keyOfflineMode);

  bool get isRemoteConfigured => _remote.isConfigured;

  List<PendingSyncOperation> getPendingOperations() {
    return _storage
        .readList(LocalStorageDataSource.keyPendingSyncOps)
        .map(PendingSyncOperation.fromJson)
        .toList();
  }

  SyncStatus getCurrentStatus() {
    final offline = isOfflineMode;
    final pending = getPendingOperations();
    final lastLocal = _storage.readDateTime(
      LocalStorageDataSource.keyLastLocalSave,
    );
    final lastRemote = _storage.readDateTime(
      LocalStorageDataSource.keyLastRemoteSync,
    );

    final state = offline
        ? SyncState.offline
        : (pending.isNotEmpty ? SyncState.pendingSync : SyncState.synced);

    return SyncStatus(
      state: state,
      pendingOperationsCount: pending.length,
      isOfflineMode: offline,
      isRemoteBackendConfigured: _remote.isConfigured,
      lastLocalSaveAt: lastLocal,
      lastRemoteSyncAt: lastRemote,
    );
  }

  /// Determines the initial syncState to stamp on newly mutated local records.
  SyncState stateForNewMutation() {
    if (isOfflineMode) return SyncState.offline;
    if (!_remote.isConfigured) return SyncState.pendingSync;
    return SyncState.pendingSync;
  }

  Future<SyncStatus> enqueueMutation({
    required String entityType,
    required String entityId,
    required String operation,
    DateTime? now,
  }) async {
    final current = getPendingOperations();
    current.add(
      PendingSyncOperation(
        id: IdGenerator.next('sync'),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        queuedAt: now ?? DateTime.now(),
      ),
    );
    await _storage.writeList(
      LocalStorageDataSource.keyPendingSyncOps,
      current.map((e) => e.toJson()).toList(),
    );

    if (!isOfflineMode && _remote.isConfigured) {
      return attemptSynchronisation();
    }
    return getCurrentStatus();
  }

  Future<SyncStatus> setOfflineMode(bool offline) async {
    await _storage.writeBool(LocalStorageDataSource.keyOfflineMode, offline);
    if (!offline && _remote.isConfigured) {
      return attemptSynchronisation();
    }
    return getCurrentStatus();
  }

  /// Attempts to flush queued mutations ONLY if connectivity is active AND
  /// a genuine remote backend is configured. Never fakes remote sync.
  Future<SyncStatus> attemptSynchronisation() async {
    if (isOfflineMode || !_remote.isConfigured) {
      return getCurrentStatus();
    }
    final pending = getPendingOperations();
    if (pending.isEmpty) return getCurrentStatus();

    final pushed = await _remote.pushOperations(pending);
    if (pushed) {
      await _storage.writeList(LocalStorageDataSource.keyPendingSyncOps, []);
      await _storage.writeDateTime(
        LocalStorageDataSource.keyLastRemoteSync,
        DateTime.now(),
      );
    }
    return getCurrentStatus();
  }
}
