import '../../domain/enums/app_enums.dart';
import '../../domain/models/accountability_group.dart';
import '../../domain/models/feed_activity.dart';
import '../../domain/models/feed_reaction.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/user.dart';

/// Strictly separated sample data generator used only when no remote backend is configured.
class DemoSeedDataSource {
  const DemoSeedDataSource();

  static const List<String> journeyNameSuggestions = [
    'Become a Data Scientist',
    'Learn Python',
    'Learn French',
    'Write a Book',
    'Pass AWS Certification',
    'Start a Business',
    'Prepare for Medical School',
    'Build a Fitness Habit',
  ];

  static const List<String> updateInspirationExamples = [
    'Completed Module 4',
    'Finished Chapter 6',
    'Built Login Screen',
    'Solved 10 Coding Problems',
    'Practised French Conversation',
  ];

  AccountabilityGroup buildSampleGroupForCategory({
    required JourneyCategory category,
    required User currentUser,
    required DateTime now,
  }) {
    final (groupNumber, memberCount, league, sampleHealth) = switch (category) {
      JourneyCategory.dataScience => (28, 8, LeagueTier.momentum, 81),
      JourneyCategory.softwareEngineering => (42, 22, LeagueTier.vanguard, 94),
      JourneyCategory.cybersecurity => (14, 15, LeagueTier.resolute, 89),
      JourneyCategory.productManagement => (19, 16, LeagueTier.momentum, 88),
      JourneyCategory.marketing => (11, 14, LeagueTier.momentum, 86),
      JourneyCategory.entrepreneurship => (31, 20, LeagueTier.vanguard, 92),
      JourneyCategory.personalDevelopment => (24, 19, LeagueTier.resolute, 90),
      JourneyCategory.languages => (37, 21, LeagueTier.resolute, 93),
      JourneyCategory.fitness => (53, 24, LeagueTier.vanguard, 95),
      JourneyCategory.other => (9, 12, LeagueTier.foundation, 87),
    };

    final peers = <GroupMember>[
      GroupMember(
        id: 'member_${currentUser.id}',
        displayName: '${currentUser.firstName} (You)',
        initials: currentUser.initials,
        joinedAt: now,
        isCurrentUser: true,
      ),
      GroupMember(
        id: 'peer_sarah',
        displayName: 'Sarah K.',
        initials: 'SK',
        joinedAt: now.subtract(const Duration(days: 26)),
      ),
      GroupMember(
        id: 'peer_james',
        displayName: 'James M.',
        initials: 'JM',
        joinedAt: now.subtract(const Duration(days: 34)),
      ),
      GroupMember(
        id: 'peer_ahmed',
        displayName: 'Ahmed R.',
        initials: 'AR',
        joinedAt: now.subtract(const Duration(days: 19)),
      ),
      GroupMember(
        id: 'peer_valery',
        displayName: 'Valery T.',
        initials: 'VT',
        joinedAt: now.subtract(const Duration(days: 12)),
      ),
      GroupMember(
        id: 'peer_elena',
        displayName: 'Elena P.',
        initials: 'EP',
        joinedAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    return AccountabilityGroup(
      id: 'grp_${category.name}_$groupNumber',
      name: '${category.label} Group #$groupNumber',
      category: category,
      memberCount: memberCount,
      league: league,
      sampleHealthScore: sampleHealth,
      members: peers,
      isDemoGroup: true,
    );
  }

  List<FeedActivity> buildInitialFeedForGroup({
    required AccountabilityGroup group,
    required DateTime now,
  }) {
    List<FeedReaction> defaultReactions({
      int applause = 3,
      int fire = 2,
      int strength = 1,
      int celebration = 1,
    }) => [
      FeedReaction(type: ReactionType.applause, count: applause),
      FeedReaction(type: ReactionType.fire, count: fire),
      FeedReaction(type: ReactionType.strength, count: strength),
      FeedReaction(type: ReactionType.celebration, count: celebration),
    ];

    return [
      FeedActivity(
        id: 'feed_${group.id}_1',
        groupId: group.id,
        actorName: 'Sarah',
        actorInitials: 'SK',
        type: FeedActivityType.sessionCompleted,
        message: 'Sarah completed her scheduled session.',
        createdAt: now.subtract(const Duration(minutes: 42)),
        reactions: defaultReactions(
          applause: 5,
          fire: 2,
          strength: 3,
          celebration: 0,
        ),
      ),
      FeedActivity(
        id: 'feed_${group.id}_2',
        groupId: group.id,
        actorName: 'James',
        actorInitials: 'JM',
        type: FeedActivityType.consistencyStreak,
        message: 'James reached a 14-session consistency streak.',
        createdAt: now.subtract(const Duration(hours: 3)),
        reactions: defaultReactions(
          applause: 7,
          fire: 6,
          strength: 4,
          celebration: 3,
        ),
      ),
      FeedActivity(
        id: 'feed_${group.id}_3',
        groupId: group.id,
        actorName: 'Ahmed',
        actorInitials: 'AR',
        type: FeedActivityType.weeklyCommitmentCompleted,
        message: 'Ahmed completed his weekly commitment.',
        createdAt: now.subtract(const Duration(hours: 9)),
        reactions: defaultReactions(
          applause: 6,
          fire: 3,
          strength: 2,
          celebration: 4,
        ),
      ),
      FeedActivity(
        id: 'feed_${group.id}_4',
        groupId: group.id,
        actorName: 'Valery',
        actorInitials: 'VT',
        type: FeedActivityType.progressShared,
        message: 'Valery shared progress on their journey.',
        detailText:
            'Completed core practice exercises ahead of weekend review.',
        createdAt: now.subtract(const Duration(hours: 18)),
        reactions: defaultReactions(
          applause: 4,
          fire: 2,
          strength: 3,
          celebration: 1,
        ),
      ),
    ];
  }
}
