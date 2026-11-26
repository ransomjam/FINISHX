import '../enums/app_enums.dart';
import 'feed_reaction.dart';

class FeedActivity {
  const FeedActivity({
    required this.id,
    required this.groupId,
    required this.actorName,
    required this.actorInitials,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.reactions,
    this.detailText,
    this.isCurrentUser = false,
  });

  final String id;
  final String groupId;
  final String actorName;
  final String actorInitials;
  final FeedActivityType type;
  final String message;
  final String? detailText;
  final DateTime createdAt;
  final List<FeedReaction> reactions;
  final bool isCurrentUser;

  FeedActivity copyWith({List<FeedReaction>? reactions}) => FeedActivity(
    id: id,
    groupId: groupId,
    actorName: actorName,
    actorInitials: actorInitials,
    type: type,
    message: message,
    detailText: detailText,
    createdAt: createdAt,
    reactions: reactions ?? this.reactions,
    isCurrentUser: isCurrentUser,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'actorName': actorName,
    'actorInitials': actorInitials,
    'type': type.name,
    'message': message,
    'detailText': detailText,
    'createdAt': createdAt.toIso8601String(),
    'reactions': reactions.map((r) => r.toJson()).toList(),
    'isCurrentUser': isCurrentUser,
  };

  factory FeedActivity.fromJson(Map<String, dynamic> json) => FeedActivity(
    id: json['id'] as String,
    groupId: json['groupId'] as String,
    actorName: json['actorName'] as String,
    actorInitials: json['actorInitials'] as String,
    type: FeedActivityType.values.byName(json['type'] as String),
    message: json['message'] as String,
    detailText: json['detailText'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reactions: (json['reactions'] as List<dynamic>? ?? [])
        .map((e) => FeedReaction.fromJson(e as Map<String, dynamic>))
        .toList(),
    isCurrentUser: json['isCurrentUser'] as bool? ?? false,
  );
}
