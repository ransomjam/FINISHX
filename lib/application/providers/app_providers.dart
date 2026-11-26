import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_storage_datasource.dart';
import '../../data/datasources/remote_sync_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/accountability_group.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/commitment_day.dart';
import '../../domain/models/feed_activity.dart';
import '../../domain/models/journey.dart';
import '../../domain/models/journey_archive.dart';
import '../../domain/models/journey_queue_item.dart';
import '../../domain/models/journey_update.dart';
import '../../domain/models/learning_resource.dart';
import '../../domain/models/session.dart';
import '../../domain/models/session_reflection.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/user.dart';
import '../../domain/models/weekly_reflection.dart';
import '../../domain/services/commitment_calculator.dart';
import '../../domain/services/journey_rules_service.dart';
import '../../domain/services/progress_metrics_service.dart';

// --- Infrastructure & Services ---

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  );
});

/// Injectable clock function so time-sensitive rules are deterministic in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final localStorageProvider = Provider<LocalStorageDataSource>((ref) {
  return LocalStorageDataSource(ref.watch(sharedPreferencesProvider));
});

final remoteSyncDataSourceProvider = Provider<RemoteSyncDataSource>((ref) {
  return const UnconfiguredRemoteSyncDataSource();
});

final commitmentCalculatorProvider = Provider<CommitmentCalculator>((ref) {
  return const CommitmentCalculator();
});

final journeyRulesServiceProvider = Provider<JourneyRulesService>((ref) {
  return const JourneyRulesService();
});

final progressMetricsServiceProvider = Provider<ProgressMetricsService>((ref) {
  return ProgressMetricsService(
    calculator: ref.watch(commitmentCalculatorProvider),
  );
});

// --- Repositories ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalDemoAuthRepository(ref.watch(localStorageProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    storage: ref.watch(localStorageProvider),
    remote: ref.watch(remoteSyncDataSourceProvider),
  );
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return LocalDemoGroupRepository(storage: ref.watch(localStorageProvider));
});

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(
    storage: ref.watch(localStorageProvider),
    syncRepository: ref.watch(syncRepositoryProvider),
    calculator: ref.watch(commitmentCalculatorProvider),
    rules: ref.watch(journeyRulesServiceProvider),
    metrics: ref.watch(progressMetricsServiceProvider),
  );
});

// --- 1. Auth Controller ---

class AuthState {
  const AuthState({
    required this.user,
    required this.isExternalAuthConfigured,
    required this.showWelcomeBackBanner,
  });

  final User? user;
  final bool isExternalAuthConfigured;
  final bool showWelcomeBackBanner;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool clearUser = false,
    bool? showWelcomeBackBanner,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isExternalAuthConfigured: isExternalAuthConfigured,
      showWelcomeBackBanner:
          showWelcomeBackBanner ?? this.showWelcomeBackBanner,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._rules, this._clock)
    : super(
        AuthState(
          user: _repo.getCurrentUser(),
          isExternalAuthConfigured: _repo.isExternalAuthConfigured,
          showWelcomeBackBanner: _rules.shouldShowWelcomeBack(
            previousLastActiveAt:
                _repo.getPreviousLastActiveAt() ??
                _repo.getCurrentUser()?.lastActiveAt,
            now: _clock(),
          ),
        ),
      );

  final AuthRepository _repo;
  final JourneyRulesService _rules;
  final DateTime Function() _clock;

  Future<User> signIn({
    required AuthProviderType provider,
    required String displayName,
    required String email,
  }) async {
    final prevActive = _repo.getCurrentUser()?.lastActiveAt;
    final user = await _repo.signInWithProvider(
      provider: provider,
      displayName: displayName,
      email: email,
    );
    state = AuthState(
      user: user,
      isExternalAuthConfigured: _repo.isExternalAuthConfigured,
      showWelcomeBackBanner: _rules.shouldShowWelcomeBack(
        previousLastActiveAt: prevActive,
        now: _clock(),
      ),
    );
    return user;
  }

  Future<void> updateDisplayName(String name) async {
    final updated = await _repo.updateProfile(displayName: name);
    state = state.copyWith(user: updated);
  }

  void dismissWelcomeBack() {
    state = state.copyWith(showWelcomeBackBanner: false);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = state.copyWith(clearUser: true, showWelcomeBackBanner: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(journeyRulesServiceProvider),
    ref.watch(clockProvider),
  ),
);

// --- 2. Sync Controller ---

class SyncController extends StateNotifier<SyncStatus> {
  SyncController(this._repo) : super(_repo.getCurrentStatus());

  final SyncRepository _repo;

  void refresh() {
    state = _repo.getCurrentStatus();
  }

  Future<void> toggleOfflineMode(bool offline) async {
    state = await _repo.setOfflineMode(offline);
  }

  Future<void> attemptSyncNow() async {
    state = await _repo.attemptSynchronisation();
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncStatus>(
      (ref) => SyncController(ref.watch(syncRepositoryProvider)),
    );

// --- 3. Group & Community Feed Controller ---

class GroupCommunityState {
  const GroupCommunityState({required this.group, required this.feed});

  final AccountabilityGroup? group;
  final List<FeedActivity> feed;

  GroupCommunityState copyWith({
    AccountabilityGroup? group,
    List<FeedActivity>? feed,
  }) {
    return GroupCommunityState(
      group: group ?? this.group,
      feed: feed ?? this.feed,
    );
  }
}

class GroupController extends StateNotifier<GroupCommunityState> {
  GroupController(this._repo)
    : super(
        GroupCommunityState(
          group: _repo.getAssignedGroup(),
          feed: _repo.getGroupFeed(),
        ),
      );

  final GroupRepository _repo;

  void reload() {
    state = GroupCommunityState(
      group: _repo.getAssignedGroup(),
      feed: _repo.getGroupFeed(),
    );
  }

  Future<AccountabilityGroup> assignForCategory({
    required JourneyCategory category,
    required User user,
    required DateTime now,
  }) async {
    final group = await _repo.assignGroupForCategory(
      category: category,
      user: user,
      now: now,
    );
    state = GroupCommunityState(group: group, feed: _repo.getGroupFeed());
    return group;
  }

  Future<void> publishMilestone({
    required User user,
    required FeedActivityType type,
    required String message,
    String? detailText,
    required DateTime now,
  }) async {
    final updatedFeed = await _repo.recordSystemMilestone(
      user: user,
      type: type,
      message: message,
      detailText: detailText,
      now: now,
    );
    state = state.copyWith(feed: updatedFeed);
  }

  Future<void> toggleReaction(
    String activityId,
    ReactionType reactionType,
  ) async {
    final updatedFeed = await _repo.toggleReaction(
      activityId: activityId,
      reactionType: reactionType,
    );
    state = state.copyWith(feed: updatedFeed);
  }
}

final groupControllerProvider =
    StateNotifierProvider<GroupController, GroupCommunityState>(
      (ref) => GroupController(ref.watch(groupRepositoryProvider)),
    );

// --- 4. Archive & Queue Controller ---

class ArchiveAndQueueState {
  const ArchiveAndQueueState({
    required this.archives,
    required this.queue,
    this.latestCompletedArchive,
  });

  final List<JourneyArchive> archives;
  final List<JourneyQueueItem> queue;
  final JourneyArchive? latestCompletedArchive;

  ArchiveAndQueueState copyWith({
    List<JourneyArchive>? archives,
    List<JourneyQueueItem>? queue,
    JourneyArchive? latestCompletedArchive,
  }) {
    return ArchiveAndQueueState(
      archives: archives ?? this.archives,
      queue: queue ?? this.queue,
      latestCompletedArchive:
          latestCompletedArchive ?? this.latestCompletedArchive,
    );
  }
}

class ArchiveQueueController extends StateNotifier<ArchiveAndQueueState> {
  ArchiveQueueController(this._journeyRepo)
    : super(
        ArchiveAndQueueState(
          archives: _journeyRepo.getArchives(),
          queue: _journeyRepo.getQueueItems(),
        ),
      );

  final JourneyRepository _journeyRepo;

  void reload({JourneyArchive? latestCompleted}) {
    state = ArchiveAndQueueState(
      archives: _journeyRepo.getArchives(),
      queue: _journeyRepo.getQueueItems(),
      latestCompletedArchive: latestCompleted ?? state.latestCompletedArchive,
    );
  }

  Future<void> removeQueuedJourney(String queueItemId) async {
    await _journeyRepo.removeQueueItem(queueItemId);
    reload();
  }
}

final archiveQueueControllerProvider =
    StateNotifierProvider<ArchiveQueueController, ArchiveAndQueueState>(
      (ref) => ArchiveQueueController(ref.watch(journeyRepositoryProvider)),
    );

// --- 5. Notifications Controller ---

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController(this._repo) : super(_repo.getNotifications());

  final JourneyRepository _repo;

  void reload() {
    state = _repo.getNotifications();
  }

  Future<void> markAllRead() async {
    await _repo.markAllNotificationsRead();
    reload();
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
      (ref) => NotificationsController(ref.watch(journeyRepositoryProvider)),
    );

// --- 6. Active Journey Workspace Controller ---

class ActiveJourneyWorkspaceState {
  const ActiveJourneyWorkspaceState({
    required this.openJourney,
    required this.sessions,
    required this.reflections,
    required this.updates,
    required this.weeklyReflections,
    this.dismissedMissedSessionId,
  });

  final Journey? openJourney;
  final List<Session> sessions;
  final List<SessionReflection> reflections;
  final List<JourneyUpdate> updates;
  final List<WeeklyReflection> weeklyReflections;
  final String? dismissedMissedSessionId;

  bool get hasOpenJourney => openJourney != null && openJourney!.status.isOpen;

  Session? get activeInProgressSession {
    for (final s in sessions) {
      if (s.status == SessionStatus.inProgress) return s;
    }
    return null;
  }

  ActiveJourneyWorkspaceState copyWith({
    Journey? openJourney,
    bool clearJourney = false,
    List<Session>? sessions,
    List<SessionReflection>? reflections,
    List<JourneyUpdate>? updates,
    List<WeeklyReflection>? weeklyReflections,
    String? dismissedMissedSessionId,
  }) {
    return ActiveJourneyWorkspaceState(
      openJourney: clearJourney ? null : (openJourney ?? this.openJourney),
      sessions: sessions ?? this.sessions,
      reflections: reflections ?? this.reflections,
      updates: updates ?? this.updates,
      weeklyReflections: weeklyReflections ?? this.weeklyReflections,
      dismissedMissedSessionId:
          dismissedMissedSessionId ?? this.dismissedMissedSessionId,
    );
  }
}

class JourneyWorkspaceController
    extends StateNotifier<ActiveJourneyWorkspaceState> {
  JourneyWorkspaceController(this._ref)
    : super(
        ActiveJourneyWorkspaceState(
          openJourney: _ref.read(journeyRepositoryProvider).getOpenJourney(),
          sessions: _ref.read(journeyRepositoryProvider).getSessions(),
          reflections: _ref
              .read(journeyRepositoryProvider)
              .getSessionReflections(),
          updates: _ref.read(journeyRepositoryProvider).getJourneyUpdates(),
          weeklyReflections: _ref
              .read(journeyRepositoryProvider)
              .getWeeklyReflections(),
        ),
      );

  final Ref _ref;

  JourneyRepository get _repo => _ref.read(journeyRepositoryProvider);
  DateTime _now() => _ref.read(clockProvider)();

  void _syncDownstream({JourneyArchive? latestCompleted}) {
    final repo = _repo;
    state = ActiveJourneyWorkspaceState(
      openJourney: repo.getOpenJourney(),
      sessions: repo.getSessions(),
      reflections: repo.getSessionReflections(),
      updates: repo.getJourneyUpdates(),
      weeklyReflections: repo.getWeeklyReflections(),
      dismissedMissedSessionId: state.dismissedMissedSessionId,
    );
    _ref.read(syncControllerProvider.notifier).refresh();
    _ref
        .read(archiveQueueControllerProvider.notifier)
        .reload(latestCompleted: latestCompleted);
    _ref.read(notificationsControllerProvider.notifier).reload();
  }

  Future<void> reconcileTimeline() async {
    await _repo.reconcileAndPersist(_now());
    _syncDownstream();
  }

  Future<Journey> createAndSignJourney({
    required String name,
    required JourneyCategory category,
    required LearningResource resource,
    required DateTime startDate,
    required DateTime targetCompletionDate,
    required List<CommitmentDay> commitmentDays,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) {
      throw StateError('Please sign in before signing a commitment.');
    }
    final now = _now();
    final group = await _ref
        .read(groupControllerProvider.notifier)
        .assignForCategory(category: category, user: user, now: now);

    final journey = await _repo.createAndSignJourney(
      userId: user.id,
      name: name,
      category: category,
      resource: resource,
      startDate: startDate,
      targetCompletionDate: targetCompletionDate,
      commitmentDays: commitmentDays,
      groupId: group.id,
      now: now,
    );
    _syncDownstream();
    return journey;
  }

  Future<JourneyQueueItem> enqueueFutureJourney({
    required String name,
    required JourneyCategory category,
    required LearningResource resource,
    required DateTime plannedStartDate,
    required DateTime targetCompletionDate,
    required List<CommitmentDay> commitmentDays,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) {
      throw StateError('Please sign in first.');
    }
    final item = await _repo.enqueueJourney(
      userId: user.id,
      name: name,
      category: category,
      resource: resource,
      plannedStartDate: plannedStartDate,
      targetCompletionDate: targetCompletionDate,
      commitmentDays: commitmentDays,
      now: _now(),
    );
    _syncDownstream();
    return item;
  }

  Future<Journey> startQueuedJourney(JourneyQueueItem item) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) throw StateError('Please sign in first.');
    final now = _now();
    final group = await _ref
        .read(groupControllerProvider.notifier)
        .assignForCategory(category: item.category, user: user, now: now);
    final journey = await _repo.startQueuedJourney(
      queueItemId: item.id,
      groupId: group.id,
      now: now,
    );
    _syncDownstream();
    return journey;
  }

  Future<Session> startSession({String? sessionId}) async {
    final session = await _repo.startSession(sessionId: sessionId, now: _now());
    _syncDownstream();
    return session;
  }

  Future<Session> endSession(String sessionId) async {
    final now = _now();
    final completed = await _repo.endSession(sessionId: sessionId, now: now);
    _syncDownstream();

    final user = _ref.read(authControllerProvider).user;
    final journey = state.openJourney;
    if (user != null && journey != null) {
      await _ref
          .read(groupControllerProvider.notifier)
          .publishMilestone(
            user: user,
            type: FeedActivityType.sessionCompleted,
            message: '${user.firstName} completed their scheduled session.',
            now: now,
          );

      final weekly = _ref
          .read(progressMetricsServiceProvider)
          .evaluateWeeklyCommitment(
            journey: journey,
            sessions: state.sessions,
            now: now,
          );
      if (weekly.targetThisWeek > 0 &&
          weekly.completedThisWeek == weekly.targetThisWeek) {
        await _ref
            .read(groupControllerProvider.notifier)
            .publishMilestone(
              user: user,
              type: FeedActivityType.weeklyCommitmentCompleted,
              message: '${user.firstName} completed their weekly commitment.',
              now: now,
            );
      }
    }
    return completed;
  }

  Future<void> recordReflection({
    required String sessionId,
    required SessionFeeling feeling,
  }) async {
    await _repo.saveSessionReflection(
      sessionId: sessionId,
      feeling: feeling,
      now: _now(),
    );
    _syncDownstream();
  }

  Future<void> addJourneyUpdate({
    required String text,
    String? sessionId,
  }) async {
    if (text.trim().isEmpty) return;
    final now = _now();
    await _repo.createJourneyUpdate(text: text, sessionId: sessionId, now: now);
    _syncDownstream();

    final user = _ref.read(authControllerProvider).user;
    if (user != null) {
      await _ref
          .read(groupControllerProvider.notifier)
          .publishMilestone(
            user: user,
            type: FeedActivityType.progressShared,
            message: '${user.firstName} shared progress on their journey.',
            detailText: text.trim(),
            now: now,
          );
    }
  }

  Future<void> submitWeeklyCheckIn({
    required WeeklyCompletionAnswer completedCommitments,
    required String biggestWin,
    required String biggestChallenge,
    required String nextWeekFocus,
  }) async {
    await _repo.submitWeeklyReflection(
      completedCommitments: completedCommitments,
      biggestWin: biggestWin,
      biggestChallenge: biggestChallenge,
      nextWeekFocus: nextWeekFocus,
      now: _now(),
    );
    _syncDownstream();
  }

  Future<void> updateCommitmentSchedule(List<CommitmentDay> newDays) async {
    await _repo.updateSchedule(newDays: newDays, now: _now());
    _syncDownstream();
  }

  Future<void> updateFutureStartDate(DateTime newStartDate) async {
    await _repo.updateFutureStartDate(newStartDate: newStartDate, now: _now());
    _syncDownstream();
  }

  Future<void> pauseJourney(PauseReason reason) async {
    await _repo.pauseJourney(reason: reason, now: _now());
    _syncDownstream();
  }

  Future<void> resumeJourney({List<CommitmentDay>? updatedDays}) async {
    await _repo.resumeJourney(updatedDays: updatedDays, now: _now());
    _syncDownstream();
  }

  Future<void> extendJourney(DateTime revisedTargetDate) async {
    await _repo.extendJourney(
      revisedTargetDate: revisedTargetDate,
      now: _now(),
    );
    _syncDownstream();
  }

  Future<JourneyArchive> completeJourney({
    required CompletionOutcome outcome,
    required String proudAccomplishment,
    required String biggestLesson,
  }) async {
    final now = _now();
    final journeyName = state.openJourney?.name ?? 'their journey';
    final archive = await _repo.completeJourney(
      outcome: outcome,
      proudAccomplishment: proudAccomplishment,
      biggestLesson: biggestLesson,
      now: now,
    );
    _syncDownstream(latestCompleted: archive);

    final user = _ref.read(authControllerProvider).user;
    if (user != null) {
      await _ref
          .read(groupControllerProvider.notifier)
          .publishMilestone(
            user: user,
            type: FeedActivityType.journeyCompleted,
            message: '${user.firstName} finished "$journeyName".',
            now: now,
          );
    }
    return archive;
  }

  Future<JourneyArchive> cancelJourney({String? reason}) async {
    final archive = await _repo.cancelJourney(reason: reason, now: _now());
    _syncDownstream();
    return archive;
  }

  void acknowledgeMissedSession(String sessionId) {
    state = state.copyWith(dismissedMissedSessionId: sessionId);
  }
}

final journeyWorkspaceProvider =
    StateNotifierProvider<
      JourneyWorkspaceController,
      ActiveJourneyWorkspaceState
    >((ref) => JourneyWorkspaceController(ref));
