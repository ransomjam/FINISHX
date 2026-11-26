class GroupMember {
  const GroupMember({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.joinedAt,
    this.isCurrentUser = false,
  });

  final String id;
  final String displayName;
  final String initials;
  final DateTime joinedAt;
  final bool isCurrentUser;

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'initials': initials,
    'joinedAt': joinedAt.toIso8601String(),
    'isCurrentUser': isCurrentUser,
  };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    initials: json['initials'] as String,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
    isCurrentUser: json['isCurrentUser'] as bool? ?? false,
  );
}
