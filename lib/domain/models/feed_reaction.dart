import '../enums/app_enums.dart';

class FeedReaction {
  const FeedReaction({
    required this.type,
    required this.count,
    this.reactedByCurrentUser = false,
  });

  final ReactionType type;
  final int count;
  final bool reactedByCurrentUser;

  FeedReaction toggleCurrentUser() {
    if (reactedByCurrentUser) {
      return FeedReaction(
        type: type,
        count: (count - 1).clamp(0, 999999),
        reactedByCurrentUser: false,
      );
    }
    return FeedReaction(
      type: type,
      count: count + 1,
      reactedByCurrentUser: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'count': count,
    'reactedByCurrentUser': reactedByCurrentUser,
  };

  factory FeedReaction.fromJson(Map<String, dynamic> json) => FeedReaction(
    type: ReactionType.values.byName(json['type'] as String),
    count: json['count'] as int,
    reactedByCurrentUser: json['reactedByCurrentUser'] as bool? ?? false,
  );
}
