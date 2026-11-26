import '../enums/app_enums.dart';
import 'journey.dart';
import 'journey_update.dart';
import 'session.dart';
import 'session_reflection.dart';
import 'weekly_reflection.dart';

class JourneyArchive {
  const JourneyArchive({
    required this.id,
    required this.journey,
    required this.finalStatus,
    required this.completedSessionsCount,
    required this.totalScheduledCount,
    required this.consistencyPercentage,
    required this.updatesCount,
    required this.durationDays,
    required this.archivedAt,
    this.sessions = const [],
    this.reflections = const [],
    this.updates = const [],
    this.weeklyReflections = const [],
  });

  final String id;
  final Journey journey;
  final JourneyStatus finalStatus;
  final int completedSessionsCount;
  final int totalScheduledCount;
  final int consistencyPercentage;
  final int updatesCount;
  final int durationDays;
  final DateTime archivedAt;
  final List<Session> sessions;
  final List<SessionReflection> reflections;
  final List<JourneyUpdate> updates;
  final List<WeeklyReflection> weeklyReflections;

  bool get isCancelled => finalStatus == JourneyStatus.cancelled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journey': journey.toJson(),
    'finalStatus': finalStatus.name,
    'completedSessionsCount': completedSessionsCount,
    'totalScheduledCount': totalScheduledCount,
    'consistencyPercentage': consistencyPercentage,
    'updatesCount': updatesCount,
    'durationDays': durationDays,
    'archivedAt': archivedAt.toIso8601String(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'reflections': reflections.map((r) => r.toJson()).toList(),
    'updates': updates.map((u) => u.toJson()).toList(),
    'weeklyReflections': weeklyReflections.map((w) => w.toJson()).toList(),
  };

  factory JourneyArchive.fromJson(Map<String, dynamic> json) => JourneyArchive(
    id: json['id'] as String,
    journey: Journey.fromJson(json['journey'] as Map<String, dynamic>),
    finalStatus: JourneyStatus.values.byName(json['finalStatus'] as String),
    completedSessionsCount: json['completedSessionsCount'] as int,
    totalScheduledCount: json['totalScheduledCount'] as int,
    consistencyPercentage: json['consistencyPercentage'] as int,
    updatesCount: json['updatesCount'] as int,
    durationDays: json['durationDays'] as int,
    archivedAt: DateTime.parse(json['archivedAt'] as String),
    sessions: (json['sessions'] as List<dynamic>? ?? [])
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList(),
    reflections: (json['reflections'] as List<dynamic>? ?? [])
        .map((e) => SessionReflection.fromJson(e as Map<String, dynamic>))
        .toList(),
    updates: (json['updates'] as List<dynamic>? ?? [])
        .map((e) => JourneyUpdate.fromJson(e as Map<String, dynamic>))
        .toList(),
    weeklyReflections: (json['weeklyReflections'] as List<dynamic>? ?? [])
        .map((e) => WeeklyReflection.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
