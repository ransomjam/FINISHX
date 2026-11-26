import '../enums/app_enums.dart';

class WeeklyReflection {
  const WeeklyReflection({
    required this.id,
    required this.journeyId,
    required this.weekStartDate,
    required this.completedCommitments,
    required this.biggestWin,
    required this.biggestChallenge,
    required this.nextWeekFocus,
    required this.createdAt,
    required this.syncState,
  });

  final String id;
  final String journeyId;
  final DateTime weekStartDate;
  final WeeklyCompletionAnswer completedCommitments;
  final String biggestWin;
  final String biggestChallenge;
  final String nextWeekFocus;
  final DateTime createdAt;
  final SyncState syncState;

  WeeklyReflection copyWith({SyncState? syncState}) => WeeklyReflection(
    id: id,
    journeyId: journeyId,
    weekStartDate: weekStartDate,
    completedCommitments: completedCommitments,
    biggestWin: biggestWin,
    biggestChallenge: biggestChallenge,
    nextWeekFocus: nextWeekFocus,
    createdAt: createdAt,
    syncState: syncState ?? this.syncState,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'weekStartDate': weekStartDate.toIso8601String(),
    'completedCommitments': completedCommitments.name,
    'biggestWin': biggestWin,
    'biggestChallenge': biggestChallenge,
    'nextWeekFocus': nextWeekFocus,
    'createdAt': createdAt.toIso8601String(),
    'syncState': syncState.name,
  };

  factory WeeklyReflection.fromJson(Map<String, dynamic> json) =>
      WeeklyReflection(
        id: json['id'] as String,
        journeyId: json['journeyId'] as String,
        weekStartDate: DateTime.parse(json['weekStartDate'] as String),
        completedCommitments: WeeklyCompletionAnswer.values.byName(
          json['completedCommitments'] as String,
        ),
        biggestWin: json['biggestWin'] as String,
        biggestChallenge: json['biggestChallenge'] as String,
        nextWeekFocus: json['nextWeekFocus'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncState: SyncState.values.byName(
          json['syncState'] as String? ?? SyncState.synced.name,
        ),
      );
}
