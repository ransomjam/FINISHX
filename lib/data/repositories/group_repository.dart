import '../../core/utils/id_generator.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/accountability_group.dart';
import '../../domain/models/feed_activity.dart';
import '../../domain/models/feed_reaction.dart';
import '../../domain/models/user.dart';
import '../datasources/demo_seed_datasource.dart';
import '../datasources/local_storage_datasource.dart';

abstract interface class GroupRepository {
  AccountabilityGroup? getAssignedGroup();
  List<FeedActivity> getGroupFeed();
  Future<AccountabilityGroup> assignGroupForCategory({
    required JourneyCategory category,
    required User user,
    required DateTime now,
  });
  Future<List<FeedActivity>> recordSystemMilestone({
    required User user,
    required FeedActivityType type,
    required String message,
    String? detailText,
    required DateTime now,
  });
  Future<List<FeedActivity>> toggleReaction({
    required String activityId,
    required ReactionType reactionType,
  });
}

class LocalDemoGroupRepository implements GroupRepository {
  LocalDemoGroupRepository({
    required LocalStorageDataSource storage,
    DemoSeedDataSource demoSeed = const DemoSeedDataSource(),
  }) : _storage = storage,
       _demoSeed = demoSeed;

  final LocalStorageDataSource _storage;
  final DemoSeedDataSource _demoSeed;

  @override
  AccountabilityGroup? getAssignedGroup() {
    final json = _storage.readObject(LocalStorageDataSource.keyGroup);
    if (json == null) return null;
    return AccountabilityGroup.fromJson(json);
  }

  @override
  List<FeedActivity> getGroupFeed() {
    final items =
        _storage
            .readList(LocalStorageDataSource.keyFeed)
            .map(FeedActivity.fromJson)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<AccountabilityGroup> assignGroupForCategory({
    required JourneyCategory category,
    required User user,
    required DateTime now,
  }) async {
    final existing = getAssignedGroup();
    if (existing != null && existing.category == category) {
      return existing;
    }

    final group = _demoSeed.buildSampleGroupForCategory(
      category: category,
      currentUser: user,
      now: now,
    );
    final seedFeed = _demoSeed.buildInitialFeedForGroup(group: group, now: now);

    await _storage.writeObject(LocalStorageDataSource.keyGroup, group.toJson());
    await _storage.writeList(
      LocalStorageDataSource.keyFeed,
      seedFeed.map((f) => f.toJson()).toList(),
    );
    return group;
  }

  @override
  Future<List<FeedActivity>> recordSystemMilestone({
    required User user,
    required FeedActivityType type,
    required String message,
    String? detailText,
    required DateTime now,
  }) async {
    final group = getAssignedGroup();
    if (group == null) return getGroupFeed();

    final current = getGroupFeed();
    final activity = FeedActivity(
      id: IdGenerator.next('feed'),
      groupId: group.id,
      actorName: user.firstName,
      actorInitials: user.initials,
      type: type,
      message: message,
      detailText: detailText,
      createdAt: now,
      isCurrentUser: true,
      reactions: const [
        FeedReaction(type: ReactionType.applause, count: 0),
        FeedReaction(type: ReactionType.fire, count: 0),
        FeedReaction(type: ReactionType.strength, count: 0),
        FeedReaction(type: ReactionType.celebration, count: 0),
      ],
    );

    final updated = [activity, ...current];
    await _storage.writeList(
      LocalStorageDataSource.keyFeed,
      updated.map((e) => e.toJson()).toList(),
    );
    return updated;
  }

  @override
  Future<List<FeedActivity>> toggleReaction({
    required String activityId,
    required ReactionType reactionType,
  }) async {
    final current = getGroupFeed();
    final updated = current.map((activity) {
      if (activity.id != activityId) return activity;
      final reactions = activity.reactions.map((r) {
        if (r.type != reactionType) return r;
        return r.toggleCurrentUser();
      }).toList();
      return activity.copyWith(reactions: reactions);
    }).toList();

    await _storage.writeList(
      LocalStorageDataSource.keyFeed,
      updated.map((e) => e.toJson()).toList(),
    );
    return updated;
  }
}
