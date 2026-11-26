import '../enums/app_enums.dart';

class Session {
  const Session({
    required this.id,
    required this.journeyId,
    required this.scheduledDate,
    required this.plannedStartHour,
    required this.plannedStartMinute,
    required this.plannedEndHour,
    required this.plannedEndMinute,
    required this.status,
    required this.syncState,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String journeyId;
  final DateTime scheduledDate;
  final int plannedStartHour;
  final int plannedStartMinute;
  final int plannedEndHour;
  final int plannedEndMinute;
  final SessionStatus status;
  final SyncState syncState;
  final DateTime? startedAt;
  final DateTime? endedAt;

  DateTime get plannedStartDateTime => DateTime(
    scheduledDate.year,
    scheduledDate.month,
    scheduledDate.day,
    plannedStartHour,
    plannedStartMinute,
  );

  DateTime get plannedEndDateTime {
    final end = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      plannedEndHour,
      plannedEndMinute,
    );
    if (end.isAfter(plannedStartDateTime)) return end;
    return end.add(const Duration(days: 1));
  }

  int get plannedDurationMinutes =>
      plannedEndDateTime.difference(plannedStartDateTime).inMinutes;

  int get durationMinutes => plannedDurationMinutes;

  Session copyWith({
    SessionStatus? status,
    SyncState? syncState,
    DateTime? startedAt,
    DateTime? endedAt,
    int? plannedStartHour,
    int? plannedStartMinute,
    int? plannedEndHour,
    int? plannedEndMinute,
  }) {
    return Session(
      id: id,
      journeyId: journeyId,
      scheduledDate: scheduledDate,
      plannedStartHour: plannedStartHour ?? this.plannedStartHour,
      plannedStartMinute: plannedStartMinute ?? this.plannedStartMinute,
      plannedEndHour: plannedEndHour ?? this.plannedEndHour,
      plannedEndMinute: plannedEndMinute ?? this.plannedEndMinute,
      status: status ?? this.status,
      syncState: syncState ?? this.syncState,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'scheduledDate': scheduledDate.toIso8601String(),
    'plannedStartHour': plannedStartHour,
    'plannedStartMinute': plannedStartMinute,
    'plannedEndHour': plannedEndHour,
    'plannedEndMinute': plannedEndMinute,
    'status': status.name,
    'syncState': syncState.name,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    journeyId: json['journeyId'] as String,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    plannedStartHour: json['plannedStartHour'] as int,
    plannedStartMinute: json['plannedStartMinute'] as int,
    plannedEndHour: json['plannedEndHour'] as int,
    plannedEndMinute: json['plannedEndMinute'] as int,
    status: SessionStatus.values.byName(json['status'] as String),
    syncState: SyncState.values.byName(
      json['syncState'] as String? ?? SyncState.synced.name,
    ),
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null,
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
  );
}
