import '../enums/app_enums.dart';
import 'commitment_schedule.dart';
import 'learning_resource.dart';

class PauseInterval {
  const PauseInterval({
    required this.pausedAt,
    required this.reason,
    this.resumedAt,
  });

  final DateTime pausedAt;
  final PauseReason reason;
  final DateTime? resumedAt;

  PauseInterval copyWith({DateTime? resumedAt}) => PauseInterval(
    pausedAt: pausedAt,
    reason: reason,
    resumedAt: resumedAt ?? this.resumedAt,
  );

  Map<String, dynamic> toJson() => {
    'pausedAt': pausedAt.toIso8601String(),
    'reason': reason.name,
    'resumedAt': resumedAt?.toIso8601String(),
  };

  factory PauseInterval.fromJson(Map<String, dynamic> json) => PauseInterval(
    pausedAt: DateTime.parse(json['pausedAt'] as String),
    reason: PauseReason.values.byName(json['reason'] as String),
    resumedAt: json['resumedAt'] != null
        ? DateTime.parse(json['resumedAt'] as String)
        : null,
  );
}

class Journey {
  const Journey({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.resource,
    required this.startDate,
    required this.targetCompletionDate,
    required this.originalTargetDate,
    required this.status,
    required this.schedule,
    required this.commitmentSignedAt,
    required this.createdAt,
    this.groupId,
    this.pauseReason,
    this.pausedAt,
    this.pauseHistory = const [],
    this.cancelReason,
    this.cancelledAt,
    this.completedAt,
    this.completionOutcome,
    this.proudAccomplishment,
    this.biggestLesson,
  });

  final String id;
  final String userId;
  final String name;
  final JourneyCategory category;
  final LearningResource resource;
  final DateTime startDate;
  final DateTime targetCompletionDate;
  final DateTime originalTargetDate;
  final JourneyStatus status;
  final CommitmentSchedule schedule;
  final DateTime commitmentSignedAt;
  final DateTime createdAt;
  final String? groupId;
  final PauseReason? pauseReason;
  final DateTime? pausedAt;
  final List<PauseInterval> pauseHistory;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final CompletionOutcome? completionOutcome;
  final String? proudAccomplishment;
  final String? biggestLesson;

  bool get wasExtended => targetCompletionDate.isAfter(originalTargetDate);

  Journey copyWith({
    String? name,
    JourneyCategory? category,
    LearningResource? resource,
    DateTime? startDate,
    DateTime? targetCompletionDate,
    DateTime? originalTargetDate,
    JourneyStatus? status,
    CommitmentSchedule? schedule,
    String? groupId,
    PauseReason? pauseReason,
    bool clearPause = false,
    DateTime? pausedAt,
    List<PauseInterval>? pauseHistory,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? completedAt,
    CompletionOutcome? completionOutcome,
    String? proudAccomplishment,
    String? biggestLesson,
  }) {
    return Journey(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      resource: resource ?? this.resource,
      startDate: startDate ?? this.startDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      originalTargetDate: originalTargetDate ?? this.originalTargetDate,
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      commitmentSignedAt: commitmentSignedAt,
      createdAt: createdAt,
      groupId: groupId ?? this.groupId,
      pauseReason: clearPause ? null : (pauseReason ?? this.pauseReason),
      pausedAt: clearPause ? null : (pausedAt ?? this.pausedAt),
      pauseHistory: pauseHistory ?? this.pauseHistory,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      completionOutcome: completionOutcome ?? this.completionOutcome,
      proudAccomplishment: proudAccomplishment ?? this.proudAccomplishment,
      biggestLesson: biggestLesson ?? this.biggestLesson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category.name,
    'resource': resource.toJson(),
    'startDate': startDate.toIso8601String(),
    'targetCompletionDate': targetCompletionDate.toIso8601String(),
    'originalTargetDate': originalTargetDate.toIso8601String(),
    'status': status.name,
    'schedule': schedule.toJson(),
    'commitmentSignedAt': commitmentSignedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'groupId': groupId,
    'pauseReason': pauseReason?.name,
    'pausedAt': pausedAt?.toIso8601String(),
    'pauseHistory': pauseHistory.map((p) => p.toJson()).toList(),
    'cancelReason': cancelReason,
    'cancelledAt': cancelledAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'completionOutcome': completionOutcome?.name,
    'proudAccomplishment': proudAccomplishment,
    'biggestLesson': biggestLesson,
  };

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    category: JourneyCategory.values.byName(json['category'] as String),
    resource: LearningResource.fromJson(
      json['resource'] as Map<String, dynamic>,
    ),
    startDate: DateTime.parse(json['startDate'] as String),
    targetCompletionDate: DateTime.parse(
      json['targetCompletionDate'] as String,
    ),
    originalTargetDate: DateTime.parse(json['originalTargetDate'] as String),
    status: JourneyStatus.values.byName(json['status'] as String),
    schedule: CommitmentSchedule.fromJson(
      json['schedule'] as Map<String, dynamic>,
    ),
    commitmentSignedAt: DateTime.parse(json['commitmentSignedAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    groupId: json['groupId'] as String?,
    pauseReason: json['pauseReason'] != null
        ? PauseReason.values.byName(json['pauseReason'] as String)
        : null,
    pausedAt: json['pausedAt'] != null
        ? DateTime.parse(json['pausedAt'] as String)
        : null,
    pauseHistory: (json['pauseHistory'] as List<dynamic>? ?? [])
        .map((e) => PauseInterval.fromJson(e as Map<String, dynamic>))
        .toList(),
    cancelReason: json['cancelReason'] as String?,
    cancelledAt: json['cancelledAt'] != null
        ? DateTime.parse(json['cancelledAt'] as String)
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    completionOutcome: json['completionOutcome'] != null
        ? CompletionOutcome.values.byName(json['completionOutcome'] as String)
        : null,
    proudAccomplishment: json['proudAccomplishment'] as String?,
    biggestLesson: json['biggestLesson'] as String?,
  );
}
