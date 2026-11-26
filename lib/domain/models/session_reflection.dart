import '../enums/app_enums.dart';

class SessionReflection {
  const SessionReflection({
    required this.id,
    required this.sessionId,
    required this.journeyId,
    required this.feeling,
    required this.createdAt,
    required this.syncState,
  });

  final String id;
  final String sessionId;
  final String journeyId;
  final SessionFeeling feeling;
  final DateTime createdAt;
  final SyncState syncState;

  SessionReflection copyWith({SyncState? syncState}) => SessionReflection(
    id: id,
    sessionId: sessionId,
    journeyId: journeyId,
    feeling: feeling,
    createdAt: createdAt,
    syncState: syncState ?? this.syncState,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'journeyId': journeyId,
    'feeling': feeling.name,
    'createdAt': createdAt.toIso8601String(),
    'syncState': syncState.name,
  };

  factory SessionReflection.fromJson(Map<String, dynamic> json) =>
      SessionReflection(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        journeyId: json['journeyId'] as String,
        feeling: SessionFeeling.values.byName(json['feeling'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncState: SyncState.values.byName(
          json['syncState'] as String? ?? SyncState.synced.name,
        ),
      );
}
