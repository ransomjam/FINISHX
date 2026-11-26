import '../enums/app_enums.dart';
import 'commitment_schedule.dart';
import 'learning_resource.dart';

class JourneyQueueItem {
  const JourneyQueueItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.resource,
    required this.plannedStartDate,
    required this.targetCompletionDate,
    required this.schedule,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final JourneyCategory category;
  final LearningResource resource;
  final DateTime plannedStartDate;
  final DateTime targetCompletionDate;
  final CommitmentSchedule schedule;
  final QueueItemStatus status;
  final DateTime createdAt;

  JourneyQueueItem copyWith({
    String? name,
    JourneyCategory? category,
    LearningResource? resource,
    DateTime? plannedStartDate,
    DateTime? targetCompletionDate,
    CommitmentSchedule? schedule,
    QueueItemStatus? status,
  }) {
    return JourneyQueueItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      resource: resource ?? this.resource,
      plannedStartDate: plannedStartDate ?? this.plannedStartDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      schedule: schedule ?? this.schedule,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category.name,
    'resource': resource.toJson(),
    'plannedStartDate': plannedStartDate.toIso8601String(),
    'targetCompletionDate': targetCompletionDate.toIso8601String(),
    'schedule': schedule.toJson(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory JourneyQueueItem.fromJson(Map<String, dynamic> json) =>
      JourneyQueueItem(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        category: JourneyCategory.values.byName(json['category'] as String),
        resource: LearningResource.fromJson(
          json['resource'] as Map<String, dynamic>,
        ),
        plannedStartDate: DateTime.parse(json['plannedStartDate'] as String),
        targetCompletionDate: DateTime.parse(
          json['targetCompletionDate'] as String,
        ),
        schedule: CommitmentSchedule.fromJson(
          json['schedule'] as Map<String, dynamic>,
        ),
        status: QueueItemStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
