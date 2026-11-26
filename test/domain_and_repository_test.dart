import 'package:finishx/data/datasources/local_storage_datasource.dart';
import 'package:finishx/data/repositories/auth_repository.dart';
import 'package:finishx/data/repositories/group_repository.dart';
import 'package:finishx/data/repositories/journey_repository.dart';
import 'package:finishx/data/repositories/sync_repository.dart';
import 'package:finishx/domain/enums/app_enums.dart';
import 'package:finishx/domain/models/commitment_day.dart';
import 'package:finishx/domain/models/learning_resource.dart';
import 'package:finishx/domain/services/commitment_calculator.dart';
import 'package:finishx/domain/services/journey_rules_service.dart';
import 'package:finishx/domain/services/progress_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageDataSource storage;
  late SyncRepository syncRepo;
  late JourneyRepository journeyRepo;
  late GroupRepository groupRepo;
  late AuthRepository authRepo;
  const calculator = CommitmentCalculator();
  const rules = JourneyRulesService();
  const metrics = ProgressMetricsService();

  final baseNow = DateTime(2026, 11, 25, 9, 0); // Wednesday

  List<CommitmentDay> sampleDays() => const [
    CommitmentDay(
      weekday: DateTime.monday,
      startHour: 19,
      startMinute: 0,
      endHour: 20,
      endMinute: 30,
    ),
    CommitmentDay(
      weekday: DateTime.wednesday,
      startHour: 19,
      startMinute: 0,
      endHour: 20,
      endMinute: 30,
    ),
    CommitmentDay(
      weekday: DateTime.saturday,
      startHour: 10,
      startMinute: 0,
      endHour: 12,
      endMinute: 0,
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageDataSource(prefs);
    syncRepo = SyncRepository(storage: storage);
    journeyRepo = JourneyRepository(storage: storage, syncRepository: syncRepo);
    groupRepo = LocalDemoGroupRepository(storage: storage);
    authRepo = LocalDemoAuthRepository(storage);
  });

  test(
    '1. Commitment schedule calculations compute duration, count, and weekly hours accurately',
    () {
      final summary = calculator.calculateScheduleMetrics(sampleDays());
      expect(summary.weeklySessionCount, 3);
      // 90m + 90m + 120m = 300m = 5.0 hours
      expect(summary.totalWeeklyMinutes, 300);
      expect(summary.totalWeeklyHours, 5.0);
    },
  );

  test(
    '2. Journey creation, category group assignment, and single-active-journey restriction',
    () async {
      final user = await authRepo.signInWithProvider(
        provider: AuthProviderType.email,
        displayName: 'Alex Mercer',
        email: 'alex@example.com',
      );
      final group = await groupRepo.assignGroupForCategory(
        category: JourneyCategory.dataScience,
        user: user,
        now: baseNow,
      );
      expect(group.name, contains('Data Science'));

      final journey = await journeyRepo.createAndSignJourney(
        userId: user.id,
        name: 'Become a Data Scientist',
        category: JourneyCategory.dataScience,
        resource: const LearningResource(
          type: ResourceType.coursera,
          name: 'Applied Data Science',
        ),
        startDate: baseNow,
        targetCompletionDate: baseNow.add(const Duration(days: 60)),
        commitmentDays: sampleDays(),
        groupId: group.id,
        now: baseNow,
      );

      expect(journey.status, JourneyStatus.active);
      expect(journeyRepo.getOpenJourney()?.name, 'Become a Data Scientist');
      expect(journeyRepo.getSessions(), isNotEmpty);

      // Attempting a second active journey must throw SingleActiveJourneyException
      expect(
        () => journeyRepo.createAndSignJourney(
          userId: user.id,
          name: 'Learn French',
          category: JourneyCategory.languages,
          resource: const LearningResource(type: ResourceType.book),
          startDate: baseNow,
          targetCompletionDate: baseNow.add(const Duration(days: 45)),
          commitmentDays: sampleDays(),
          groupId: group.id,
          now: baseNow,
        ),
        throwsA(isA<SingleActiveJourneyException>()),
      );
    },
  );

  test(
    '3. Future journey scheduling and automatic activation on start date',
    () async {
      final futureStart = baseNow.add(const Duration(days: 5));
      final futureTarget = futureStart.add(const Duration(days: 60));

      final scheduled = await journeyRepo.createAndSignJourney(
        userId: 'usr_1',
        name: 'Pass AWS Certification',
        category: JourneyCategory.softwareEngineering,
        resource: const LearningResource(type: ResourceType.udemy),
        startDate: futureStart,
        targetCompletionDate: futureTarget,
        commitmentDays: sampleDays(),
        groupId: 'grp_aws',
        now: baseNow,
      );
      expect(scheduled.status, JourneyStatus.planned);

      // Advance clock to start day: reconcile automatically activates journey
      await journeyRepo.reconcileAndPersist(futureStart);
      expect(journeyRepo.getOpenJourney()?.status, JourneyStatus.active);
    },
  );

  test(
    '4. Session start, end, reflection, optional update, and schedule edit preserving history',
    () async {
      await journeyRepo.createAndSignJourney(
        userId: 'usr_1',
        name: 'Learn Python',
        category: JourneyCategory.softwareEngineering,
        resource: const LearningResource(type: ResourceType.youtube),
        startDate: baseNow,
        targetCompletionDate: baseNow.add(const Duration(days: 60)),
        commitmentDays: sampleDays(),
        groupId: 'grp_py',
        now: baseNow,
      );

      final started = await journeyRepo.startSession(now: baseNow);
      expect(started.status, SessionStatus.inProgress);

      final completed = await journeyRepo.endSession(
        sessionId: started.id,
        now: baseNow.add(const Duration(minutes: 75)),
      );
      expect(completed.status, SessionStatus.completed);

      final reflection = await journeyRepo.saveSessionReflection(
        sessionId: completed.id,
        feeling: SessionFeeling.excellent,
        now: baseNow.add(const Duration(minutes: 76)),
      );
      expect(reflection.feeling, SessionFeeling.excellent);

      final update = await journeyRepo.createJourneyUpdate(
        text: 'Solved 10 Coding Problems',
        sessionId: completed.id,
        now: baseNow.add(const Duration(minutes: 77)),
      );
      expect(journeyRepo.getJourneyUpdates().first.text, update.text);

      // Change future commitment schedule to Tuesday & Thursday only
      await journeyRepo.updateSchedule(
        newDays: const [
          CommitmentDay(
            weekday: DateTime.tuesday,
            startHour: 18,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
          ),
          CommitmentDay(
            weekday: DateTime.thursday,
            startHour: 18,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
          ),
        ],
        now: baseNow.add(const Duration(days: 1)),
      );

      // Completed session record must be preserved intact
      final afterEdit = journeyRepo.getSessions();
      expect(
        afterEdit.any(
          (s) => s.id == completed.id && s.status == SessionStatus.completed,
        ),
        isTrue,
      );
    },
  );

  test('5. Missed session behaviour vs Pause and Resume protection', () async {
    await journeyRepo.createAndSignJourney(
      userId: 'usr_1',
      name: 'Write a Book',
      category: JourneyCategory.personalDevelopment,
      resource: const LearningResource(type: ResourceType.personalStudyPlan),
      startDate: baseNow,
      targetCompletionDate: baseNow.add(const Duration(days: 60)),
      commitmentDays: sampleDays(),
      groupId: 'grp_book',
      now: baseNow,
    );

    // Advance past Wednesday 20:30 session without completing -> marked Missed, journey stays Active
    final thursdayMorning = DateTime(2026, 11, 26, 9, 0);
    await journeyRepo.reconcileAndPersist(thursdayMorning);
    expect(journeyRepo.getOpenJourney()?.status, JourneyStatus.active);
    final missedCountBeforePause = journeyRepo
        .getSessions()
        .where((s) => s.status == SessionStatus.missed)
        .length;
    expect(missedCountBeforePause, 1);

    // Pause journey on Friday before Saturday's session
    final friday = DateTime(2026, 11, 27, 12, 0);
    await journeyRepo.pauseJourney(reason: PauseReason.vacation, now: friday);
    expect(journeyRepo.getOpenJourney()?.status, JourneyStatus.paused);

    // Advance past Saturday & Monday while paused -> NO additional missed sessions!
    final nextTuesday = DateTime(2026, 12, 1, 12, 0);
    await journeyRepo.reconcileAndPersist(nextTuesday);
    final missedCountDuringPause = journeyRepo
        .getSessions()
        .where((s) => s.status == SessionStatus.missed)
        .length;
    expect(missedCountDuringPause, missedCountBeforePause);

    // Resume journey on Tuesday
    final resumed = await journeyRepo.resumeJourney(now: nextTuesday);
    expect(resumed.status, JourneyStatus.active);
  });

  test(
    '6. Extend, Weekly reflection, Journey completion, Archive, Cancel, and Queue promotion',
    () async {
      final originalTarget = baseNow.add(const Duration(days: 45));
      await journeyRepo.createAndSignJourney(
        userId: 'usr_1',
        name: 'Start a Business',
        category: JourneyCategory.entrepreneurship,
        resource: const LearningResource(type: ResourceType.coachOrMentor),
        startDate: baseNow,
        targetCompletionDate: originalTarget,
        commitmentDays: sampleDays(),
        groupId: 'grp_biz',
        now: baseNow,
      );

      // Queue a future journey while active journey is running
      final queued = await journeyRepo.enqueueJourney(
        userId: 'usr_1',
        name: 'Build a Fitness Habit',
        category: JourneyCategory.fitness,
        resource: const LearningResource(type: ResourceType.personalStudyPlan),
        plannedStartDate: baseNow.add(const Duration(days: 50)),
        targetCompletionDate: baseNow.add(const Duration(days: 110)),
        commitmentDays: sampleDays(),
        now: baseNow,
      );
      expect(queued.status, QueueItemStatus.queued);

      // Cannot start queued journey while active journey is open
      expect(
        () => journeyRepo.startQueuedJourney(
          queueItemId: queued.id,
          groupId: 'grp_fit',
          now: baseNow,
        ),
        throwsA(isA<SingleActiveJourneyException>()),
      );

      // Extend journey preserves originalTargetDate
      final revisedTarget = originalTarget.add(const Duration(days: 15));
      final extended = await journeyRepo.extendJourney(
        revisedTargetDate: revisedTarget,
        now: baseNow,
      );
      expect(extended.wasExtended, isTrue);
      expect(extended.originalTargetDate.year, originalTarget.year);
      expect(extended.originalTargetDate.day, originalTarget.day);

      // Weekly Sunday check-in
      final sunday = DateTime(2026, 11, 29, 18, 0);
      expect(
        rules.isSundayCheckInPending(
          journey: extended,
          weeklyReflections: const [],
          now: sunday,
        ),
        isTrue,
      );
      await journeyRepo.submitWeeklyReflection(
        completedCommitments: WeeklyCompletionAnswer.yes,
        biggestWin: 'Launched landing page',
        biggestChallenge: 'Time blocking around meetings',
        nextWeekFocus: 'Speak to 5 customers',
        now: sunday,
      );
      expect(journeyRepo.getWeeklyReflections().length, 1);

      // Complete journey -> moves to Archive
      final completedSession = await journeyRepo.startSession(now: baseNow);
      await journeyRepo.endSession(
        sessionId: completedSession.id,
        now: baseNow.add(const Duration(hours: 1)),
      );
      final archive = await journeyRepo.completeJourney(
        outcome: CompletionOutcome.yes,
        proudAccomplishment: 'Validated first paying customer',
        biggestLesson: 'Consistency beats intensity',
        now: sunday,
      );
      expect(archive.finalStatus, JourneyStatus.completed);
      expect(journeyRepo.getOpenJourney(), isNull);
      expect(journeyRepo.getArchives().length, 1);

      // Now queued journey can be started!
      final promoted = await journeyRepo.startQueuedJourney(
        queueItemId: queued.id,
        groupId: 'grp_fit',
        now: sunday,
      );
      expect(promoted.name, 'Build a Fitness Habit');
      expect(journeyRepo.getQueueItems(), isEmpty);

      // Cancelling this second journey keeps it in Archive marked Cancelled
      final cancelledArchive = await journeyRepo.cancelJourney(
        reason: 'Priorities shifted',
        now: sunday.add(const Duration(days: 2)),
      );
      expect(cancelledArchive.isCancelled, isTrue);
      expect(journeyRepo.getArchives().length, 2);
    },
  );

  test(
    '7. Offline local session operations and honest sync state tracking',
    () async {
      await syncRepo.setOfflineMode(true);
      expect(syncRepo.getCurrentStatus().state, SyncState.offline);

      await journeyRepo.createAndSignJourney(
        userId: 'usr_offline',
        name: 'Learn French',
        category: JourneyCategory.languages,
        resource: const LearningResource(type: ResourceType.book),
        startDate: baseNow,
        targetCompletionDate: baseNow.add(const Duration(days: 30)),
        commitmentDays: sampleDays(),
        groupId: 'grp_fr',
        now: baseNow,
      );

      final started = await journeyRepo.startSession(now: baseNow);
      expect(started.syncState, SyncState.offline);

      final ended = await journeyRepo.endSession(
        sessionId: started.id,
        now: baseNow.add(const Duration(minutes: 45)),
      );
      expect(ended.status, SessionStatus.completed);
      expect(ended.syncState, SyncState.offline);

      await journeyRepo.saveSessionReflection(
        sessionId: ended.id,
        feeling: SessionFeeling.good,
        now: baseNow.add(const Duration(minutes: 46)),
      );
      await journeyRepo.createJourneyUpdate(
        text: 'Practised French Conversation',
        sessionId: ended.id,
        now: baseNow.add(const Duration(minutes: 47)),
      );

      // Reconnect while remote backend is unconfigured -> never fakes Synced! Marks PendingSync.
      final statusAfterOnline = await syncRepo.setOfflineMode(false);
      expect(statusAfterOnline.isRemoteBackendConfigured, isFalse);
      expect(statusAfterOnline.state, SyncState.pendingSync);
      expect(statusAfterOnline.pendingOperationsCount, greaterThan(0));

      final consistency = metrics.evaluateConsistency(
        sessions: journeyRepo.getSessions(),
      );
      expect(consistency.completedSessions, 1);
      expect(consistency.consistencyPercentage, 100);
    },
  );
}
