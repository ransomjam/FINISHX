import '../enums/app_enums.dart';
import 'group_member.dart';

class AccountabilityGroup {
  const AccountabilityGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.memberCount,
    required this.league,
    required this.sampleHealthScore,
    required this.members,
    this.isDemoGroup = true,
  });

  final String id;
  final String name;
  final JourneyCategory category;
  final int memberCount;
  final LeagueTier league;

  /// Demo-only sample value. Real Group Health calculation is intentionally
  /// isolated in ProgressMetricsService pending authoritative product rules.
  final int sampleHealthScore;
  final List<GroupMember> members;
  final bool isDemoGroup;

  AccountabilityGroup copyWith({int? memberCount, List<GroupMember>? members}) {
    return AccountabilityGroup(
      id: id,
      name: name,
      category: category,
      memberCount: memberCount ?? this.memberCount,
      league: league,
      sampleHealthScore: sampleHealthScore,
      members: members ?? this.members,
      isDemoGroup: isDemoGroup,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'memberCount': memberCount,
    'league': league.name,
    'sampleHealthScore': sampleHealthScore,
    'members': members.map((m) => m.toJson()).toList(),
    'isDemoGroup': isDemoGroup,
  };

  factory AccountabilityGroup.fromJson(Map<String, dynamic> json) =>
      AccountabilityGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        category: JourneyCategory.values.byName(json['category'] as String),
        memberCount: json['memberCount'] as int,
        league: LeagueTier.values.byName(json['league'] as String),
        sampleHealthScore: json['sampleHealthScore'] as int,
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        isDemoGroup: json['isDemoGroup'] as bool? ?? true,
      );
}
