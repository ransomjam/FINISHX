import '../enums/app_enums.dart';

class PendingSyncOperation {
  const PendingSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.queuedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) =>
      PendingSyncOperation(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        operation: json['operation'] as String,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );
}

class SyncStatus {
  const SyncStatus({
    required this.state,
    required this.pendingOperationsCount,
    required this.isOfflineMode,
    required this.isRemoteBackendConfigured,
    this.lastLocalSaveAt,
    this.lastRemoteSyncAt,
  });

  final SyncState state;
  final int pendingOperationsCount;
  final bool isOfflineMode;
  final bool isRemoteBackendConfigured;
  final DateTime? lastLocalSaveAt;
  final DateTime? lastRemoteSyncAt;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingOperationsCount,
    bool? isOfflineMode,
    bool? isRemoteBackendConfigured,
    DateTime? lastLocalSaveAt,
    DateTime? lastRemoteSyncAt,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingOperationsCount:
          pendingOperationsCount ?? this.pendingOperationsCount,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isRemoteBackendConfigured:
          isRemoteBackendConfigured ?? this.isRemoteBackendConfigured,
      lastLocalSaveAt: lastLocalSaveAt ?? this.lastLocalSaveAt,
      lastRemoteSyncAt: lastRemoteSyncAt ?? this.lastRemoteSyncAt,
    );
  }
}
