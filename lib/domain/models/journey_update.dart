import '../enums/app_enums.dart';

class JourneyUpdate {
  const JourneyUpdate({
    required this.id,
    required this.journeyId,
    required this.text,
    required this.createdAt,
    required this.syncState,
    this.sessionId,
  });

  final String id;
  final String journeyId;
  final String? sessionId;
  final String text;
  final DateTime createdAt;
  final SyncState syncState;

  JourneyUpdate copyWith({SyncState? syncState}) => JourneyUpdate(
    id: id,
    journeyId: journeyId,
    sessionId: sessionId,
    text: text,
    createdAt: createdAt,
    syncState: syncState ?? this.syncState,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'sessionId': sessionId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'syncState': syncState.name,
  };

  factory JourneyUpdate.fromJson(Map<String, dynamic> json) => JourneyUpdate(
    id: json['id'] as String,
    journeyId: json['journeyId'] as String,
    sessionId: json['sessionId'] as String?,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    syncState: SyncState.values.byName(
      json['syncState'] as String? ?? SyncState.synced.name,
    ),
  );
}
