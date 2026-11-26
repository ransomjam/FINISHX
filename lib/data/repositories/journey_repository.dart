import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/commitment_day.dart';
import '../../domain/models/commitment_schedule.dart';
import '../../domain/models/journey.dart';
import '../../domain/models/journey_archive.dart';
import '../../domain/models/journey_queue_item.dart';
import '../../domain/models/journey_update.dart';
import '../../domain/models/learning_resource.dart';
import '../../domain/models/session.dart';
import '../../domain/models/session_reflection.dart';
import '../../domain/models/weekly_reflection.dart';
import '../../domain/services/commitment_calculator.dart';
import '../../domain/services/journey_rules_service.dart';
import '../../domain/services/progress_metrics_service.dart';
import '../datasources/local_storage_datasource.dart';
import 'sync_repository.dart';

class SingleActiveJourneyException implements Exception {
  const SingleActiveJourneyException(this.message);
  final String message;

  @override
  String toString() => message;
}

class JourneyRepository {
  JourneyRepository({
    required LocalStorageDataSource storage,
    required SyncRepository syncRepository,
    CommitmentCalculator calculator = const CommitmentCalculator(),
    JourneyRulesService rules = const JourneyRulesService(),
    ProgressMetricsService metrics = const ProgressMetricsService(),
  }) : _storage = storage,
       _sync = syncRepository,
       _calculator = calculator,
       _rules = rules,
       _metrics = metrics;

  final LocalStorageDataSource _storage;
  final SyncRepository _sync;
  final CommitmentCalculator _calculator;
  final JourneyRulesService _rules;
  final ProgressMetricsService _metrics;

  Journey? getOpenJourney() {
    final json = _storage.readObject(LocalStorageDataSource.keyOpenJourney);
    if (json == null) return null;
    return Journey.fromJson(json);
  }

  List<Session> getSessions() {
    return _storage
        .readList(LocalStorageDataSource.keySessions)
        .map(Session.fromJson)
        .toList()
      ..sort(
        (a, b) => a.plannedStartDateTime.compareTo(b.plannedStartDateTime),
      );
  }

  List<SessionReflection> getSessionReflections() {
    return _storage
        .readList(LocalStorageDataSource.keyReflections)
        .map(SessionReflection.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<JourneyUpdate> getJourneyUpdates() {
    return _storage
        .readList(LocalStorageDataSource.keyUpdates)
        .map(JourneyUpdate.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<WeeklyReflection> getWeeklyReflections() {
    return _storage
        .readList(LocalStorageDataSource.keyWeeklyReflections)
        .map(WeeklyReflection.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<JourneyArchive> getArchives() {
    return _storage
        .readList(LocalStorageDataSource.keyArchives)
        .map(JourneyArchive.fromJson)
        .toList()
      ..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
  }

  List<JourneyQueueItem> getQueueItems() {
    return _storage
        .readList(LocalStorageDataSource.keyQueue)
        .map(JourneyQueueItem.fromJson)
        .toList()
      ..sort((a, b) => a.plannedStartDate.compareTo(b.plannedStartDate));
  }

  List<AppNotification> getNotifications() {
    return _storage
        .readList(LocalStorageDataSource.keyNotifications)
        .map(AppNotification.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> reconcileAndPersist(DateTime now) async {
    final current = getOpenJourney();
    if (current == null) return;

    final generated = _calculator.generateSessionsForJourney(
      journey: current,
      now: now,
      existingSessions: getSessions(),
      defaultSyncState: _sync.stateForNewMutation(),
    );

    final reconciled = _rules.reconcile(
      journey: current,
      sessions: generated,
      now: now,
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      reconciled.journey.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      reconciled.sessions.map((s) => s.toJson()).toList(),
    );

    if (reconciled.autoActivatedFromPlanned) {
      await addNotification(
        title: 'Your journey begins today',
        body:
            '"${reconciled.journey.name}" is now active. Honour your first scheduled commitment.',
        now: now,
        actionRoute: '/home',
      );
    }
  }

  /// Creates and activates (or schedules if future-dated) a primary journey.
  /// Enforces the One Journey. Full Focus rule.
  Future<Journey> createAndSignJourney({
    required String userId,
    required String name,
    required JourneyCategory category,
    required LearningResource resource,
    required DateTime startDate,
    required DateTime targetCompletionDate,
    required List<CommitmentDay> commitmentDays,
    required String groupId,
    required DateTime now,
  }) async {
    final existingOpen = getOpenJourney();
    if (!_rules.canActivateNewJourney(existingOpen)) {
      throw const SingleActiveJourneyException(
        'Only one journey can be active at a time. Add additional journeys to your Journey Queue.',
      );
    }

    final startDay = DateTimeUtils.dateOnly(startDate);
    final targetDay = DateTimeUtils.dateOnly(targetCompletionDate);
    if (!targetDay.isAfter(startDay)) {
      throw ArgumentError('Target completion date must be after start date.');
    }
    if (commitmentDays.isEmpty) {
      throw ArgumentError('At least one commitment day must be selected.');
    }

    final today = DateTimeUtils.dateOnly(now);
    final initialStatus = startDay.isAfter(today)
        ? JourneyStatus.planned
        : JourneyStatus.active;

    final schedule = CommitmentSchedule(
      id: IdGenerator.next('sch'),
      days: commitmentDays,
      effectiveFrom: startDay,
    );

    final journey = Journey(
      id: IdGenerator.next('jrn'),
      userId: userId,
      name: name.trim(),
      category: category,
      resource: resource,
      startDate: startDay,
      targetCompletionDate: targetDay,
      originalTargetDate: targetDay,
      status: initialStatus,
      schedule: schedule,
      commitmentSignedAt: now,
      createdAt: now,
      groupId: groupId,
    );

    final sessions = _calculator.generateSessionsForJourney(
      journey: journey,
      now: now,
      defaultSyncState: _sync.stateForNewMutation(),
    );
    final reconciled = _rules.reconcile(
      journey: journey,
      sessions: sessions,
      now: now,
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      reconciled.journey.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      reconciled.sessions.map((s) => s.toJson()).toList(),
    );
    await _storage.writeList(LocalStorageDataSource.keyReflections, []);
    await _storage.writeList(LocalStorageDataSource.keyUpdates, []);
    await _storage.writeList(LocalStorageDataSource.keyWeeklyReflections, []);

    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: journey.id,
      operation: 'create',
      now: now,
    );

    await addNotification(
      title: 'Commitment signed',
      body: 'You committed to "${journey.name}". One session at a time.',
      now: now,
      actionRoute: '/journey',
    );

    return reconciled.journey;
  }

  /// Adds a planned journey to the Journey Queue without violating single-active-journey.
  Future<JourneyQueueItem> enqueueJourney({
    required String userId,
    required String name,
    required JourneyCategory category,
    required LearningResource resource,
    required DateTime plannedStartDate,
    required DateTime targetCompletionDate,
    required List<CommitmentDay> commitmentDays,
    required DateTime now,
  }) async {
    final startDay = DateTimeUtils.dateOnly(plannedStartDate);
    final targetDay = DateTimeUtils.dateOnly(targetCompletionDate);
    if (!targetDay.isAfter(startDay)) {
      throw ArgumentError('Target completion date must be after start date.');
    }

    final hasOpen = !_rules.canActivateNewJourney(getOpenJourney());
    final item = JourneyQueueItem(
      id: IdGenerator.next('que'),
      userId: userId,
      name: name.trim(),
      category: category,
      resource: resource,
      plannedStartDate: startDay,
      targetCompletionDate: targetDay,
      schedule: CommitmentSchedule(
        id: IdGenerator.next('sch'),
        days: commitmentDays,
        effectiveFrom: startDay,
      ),
      status: hasOpen ? QueueItemStatus.queued : QueueItemStatus.readyToStart,
      createdAt: now,
    );

    final queue = getQueueItems()..add(item);
    await _storage.writeList(
      LocalStorageDataSource.keyQueue,
      queue.map((q) => q.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'queue_item',
      entityId: item.id,
      operation: 'enqueue',
      now: now,
    );
    return item;
  }

  Future<void> removeQueueItem(String queueItemId) async {
    final queue = getQueueItems()
      ..removeWhere((item) => item.id == queueItemId);
    await _storage.writeList(
      LocalStorageDataSource.keyQueue,
      queue.map((q) => q.toJson()).toList(),
    );
  }

  /// Promotes a queued journey to the active journey, strictly enforcing the single-active-journey rule.
  Future<Journey> startQueuedJourney({
    required String queueItemId,
    required String groupId,
    required DateTime now,
  }) async {
    if (!_rules.canActivateNewJourney(getOpenJourney())) {
      throw const SingleActiveJourneyException(
        'Finish or close your current journey before starting a queued journey.',
      );
    }
    final queue = getQueueItems();
    final item = queue.firstWhere((q) => q.id == queueItemId);

    final today = DateTimeUtils.dateOnly(now);
    final effectiveStart = item.plannedStartDate.isAfter(today)
        ? item.plannedStartDate
        : today;
    var effectiveTarget = item.targetCompletionDate;
    if (!effectiveTarget.isAfter(effectiveStart)) {
      effectiveTarget = effectiveStart.add(const Duration(days: 60));
    }

    final journey = await createAndSignJourney(
      userId: item.userId,
      name: item.name,
      category: item.category,
      resource: item.resource,
      startDate: effectiveStart,
      targetCompletionDate: effectiveTarget,
      commitmentDays: item.schedule.days,
      groupId: groupId,
      now: now,
    );

    await removeQueueItem(queueItemId);
    return journey;
  }

  /// Starts a session (either an upcoming scheduled session or an ad-hoc commitment session for today).
  Future<Session> startSession({
    String? sessionId,
    required DateTime now,
  }) async {
    final journey = getOpenJourney();
    if (journey == null) {
      throw StateError('No active journey found.');
    }
    if (journey.status == JourneyStatus.paused) {
      throw StateError('Resume your journey before starting a session.');
    }

    final sessions = getSessions();
    // Return existing in-progress session if already started.
    for (final s in sessions) {
      if (s.status == SessionStatus.inProgress) return s;
    }

    final syncStamp = _sync.stateForNewMutation();
    Session? target;

    if (sessionId != null) {
      for (final s in sessions) {
        if (s.id == sessionId) {
          target = s;
          break;
        }
      }
    } else {
      target = _rules.findNextCommitmentSession(sessions, now);
    }

    List<Session> updatedSessions;
    Session startedSession;

    if (target != null) {
      startedSession = target.copyWith(
        status: SessionStatus.inProgress,
        startedAt: now,
        syncState: syncStamp,
      );
      updatedSessions = sessions
          .map((s) => s.id == startedSession.id ? startedSession : s)
          .toList();
    } else {
      final endHour = (now.hour + 1) % 24;
      startedSession = Session(
        id: IdGenerator.next('ses'),
        journeyId: journey.id,
        scheduledDate: DateTimeUtils.dateOnly(now),
        plannedStartHour: now.hour,
        plannedStartMinute: now.minute,
        plannedEndHour: endHour,
        plannedEndMinute: now.minute,
        status: SessionStatus.inProgress,
        syncState: syncStamp,
        startedAt: now,
      );
      updatedSessions = [...sessions, startedSession]
        ..sort(
          (a, b) => a.plannedStartDateTime.compareTo(b.plannedStartDateTime),
        );
    }

    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      updatedSessions.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'session',
      entityId: startedSession.id,
      operation: 'start',
      now: now,
    );
    return startedSession;
  }

  Future<Session> endSession({
    required String sessionId,
    required DateTime now,
  }) async {
    final sessions = getSessions();
    final syncStamp = _sync.stateForNewMutation();
    Session? completed;

    final updated = sessions.map((s) {
      if (s.id == sessionId) {
        completed = s.copyWith(
          status: SessionStatus.completed,
          endedAt: now,
          syncState: syncStamp,
        );
        return completed!;
      }
      return s;
    }).toList();

    if (completed == null) {
      throw StateError('Session not found: $sessionId');
    }

    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      updated.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'session',
      entityId: sessionId,
      operation: 'complete',
      now: now,
    );
    return completed!;
  }

  Future<SessionReflection> saveSessionReflection({
    required String sessionId,
    required SessionFeeling feeling,
    required DateTime now,
  }) async {
    final journey = getOpenJourney();
    if (journey == null) {
      throw StateError('No open journey for reflection.');
    }

    final reflection = SessionReflection(
      id: IdGenerator.next('ref'),
      sessionId: sessionId,
      journeyId: journey.id,
      feeling: feeling,
      createdAt: now,
      syncState: _sync.stateForNewMutation(),
    );

    final reflections = [reflection, ...getSessionReflections()];
    await _storage.writeList(
      LocalStorageDataSource.keyReflections,
      reflections.map((r) => r.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'session_reflection',
      entityId: reflection.id,
      operation: 'create',
      now: now,
    );
    return reflection;
  }

  Future<JourneyUpdate> createJourneyUpdate({
    required String text,
    String? sessionId,
    required DateTime now,
  }) async {
    final journey = getOpenJourney();
    if (journey == null) {
      throw StateError('No open journey for update.');
    }
    final update = JourneyUpdate(
      id: IdGenerator.next('upd'),
      journeyId: journey.id,
      sessionId: sessionId,
      text: text.trim(),
      createdAt: now,
      syncState: _sync.stateForNewMutation(),
    );
    final updates = [update, ...getJourneyUpdates()];
    await _storage.writeList(
      LocalStorageDataSource.keyUpdates,
      updates.map((u) => u.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'journey_update',
      entityId: update.id,
      operation: 'create',
      now: now,
    );
    return update;
  }

  Future<WeeklyReflection> submitWeeklyReflection({
    required WeeklyCompletionAnswer completedCommitments,
    required String biggestWin,
    required String biggestChallenge,
    required String nextWeekFocus,
    required DateTime now,
  }) async {
    final journey = getOpenJourney();
    if (journey == null) {
      throw StateError('No active journey for weekly check-in.');
    }
    final reflection = WeeklyReflection(
      id: IdGenerator.next('wk'),
      journeyId: journey.id,
      weekStartDate: DateTimeUtils.startOfWeek(now),
      completedCommitments: completedCommitments,
      biggestWin: biggestWin.trim(),
      biggestChallenge: biggestChallenge.trim(),
      nextWeekFocus: nextWeekFocus.trim(),
      createdAt: now,
      syncState: _sync.stateForNewMutation(),
    );
    final list = [reflection, ...getWeeklyReflections()];
    await _storage.writeList(
      LocalStorageDataSource.keyWeeklyReflections,
      list.map((w) => w.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'weekly_reflection',
      entityId: reflection.id,
      operation: 'create',
      now: now,
    );
    return reflection;
  }

  Future<Journey> updateSchedule({
    required List<CommitmentDay> newDays,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) {
      throw StateError('No open journey to update.');
    }
    if (newDays.isEmpty) {
      throw ArgumentError('Select at least one commitment day.');
    }

    final updatedSchedule = CommitmentSchedule(
      id: IdGenerator.next('sch'),
      days: newDays,
      effectiveFrom: DateTimeUtils.dateOnly(now),
    );
    final updatedJourney = current.copyWith(schedule: updatedSchedule);
    final updatedSessions = _calculator.applyScheduleChangePreservingHistory(
      updatedJourney: updatedJourney,
      currentSessions: getSessions(),
      now: now,
      defaultSyncState: _sync.stateForNewMutation(),
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      updatedJourney.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      updatedSessions.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: updatedJourney.id,
      operation: 'update_schedule',
      now: now,
    );
    return updatedJourney;
  }

  Future<Journey> updateFutureStartDate({
    required DateTime newStartDate,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No open journey.');
    final startDay = DateTimeUtils.dateOnly(newStartDate);
    if (!DateTimeUtils.dateOnly(
      current.targetCompletionDate,
    ).isAfter(startDay)) {
      throw ArgumentError('Start date must be before target completion date.');
    }
    final status = startDay.isAfter(DateTimeUtils.dateOnly(now))
        ? JourneyStatus.planned
        : JourneyStatus.active;
    final updated = current.copyWith(startDate: startDay, status: status);
    final sessions = _calculator.applyScheduleChangePreservingHistory(
      updatedJourney: updated,
      currentSessions: getSessions(),
      now: now,
      defaultSyncState: _sync.stateForNewMutation(),
    );
    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      updated.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      sessions.map((s) => s.toJson()).toList(),
    );
    return updated;
  }

  Future<Journey> pauseJourney({
    required PauseReason reason,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No journey to pause.');

    final history = [
      ...current.pauseHistory,
      PauseInterval(pausedAt: now, reason: reason),
    ];

    final paused = current.copyWith(
      status: JourneyStatus.paused,
      pauseReason: reason,
      pausedAt: now,
      pauseHistory: history,
    );

    // Suspend upcoming planned sessions so none are marked missed during the pause.
    final sessions = getSessions().map((s) {
      if (s.status == SessionStatus.planned) {
        return s.copyWith(status: SessionStatus.suspended);
      }
      return s;
    }).toList();

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      paused.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      sessions.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: paused.id,
      operation: 'pause',
      now: now,
    );
    return paused;
  }

  Future<Journey> resumeJourney({
    List<CommitmentDay>? updatedDays,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No journey to resume.');

    final updatedHistory = current.pauseHistory.map((interval) {
      if (interval.resumedAt == null) {
        return interval.copyWith(resumedAt: now);
      }
      return interval;
    }).toList();

    final schedule = updatedDays != null && updatedDays.isNotEmpty
        ? CommitmentSchedule(
            id: IdGenerator.next('sch'),
            days: updatedDays,
            effectiveFrom: DateTimeUtils.dateOnly(now),
          )
        : current.schedule;

    final resumedStatus =
        DateTimeUtils.dateOnly(
          current.startDate,
        ).isAfter(DateTimeUtils.dateOnly(now))
        ? JourneyStatus.planned
        : JourneyStatus.active;

    final resumed = current.copyWith(
      status: resumedStatus,
      schedule: schedule,
      clearPause: true,
      pauseHistory: updatedHistory,
    );

    final regenerated = _calculator.applyScheduleChangePreservingHistory(
      updatedJourney: resumed,
      currentSessions: getSessions(),
      now: now,
      defaultSyncState: _sync.stateForNewMutation(),
    );
    final reconciled = _rules.reconcile(
      journey: resumed,
      sessions: regenerated,
      now: now,
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      reconciled.journey.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      reconciled.sessions.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: resumed.id,
      operation: 'resume',
      now: now,
    );
    return reconciled.journey;
  }

  /// Extends target completion date while strictly preserving [originalTargetDate].
  Future<Journey> extendJourney({
    required DateTime revisedTargetDate,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No journey to extend.');

    final revisedDay = DateTimeUtils.dateOnly(revisedTargetDate);
    if (!revisedDay.isAfter(DateTimeUtils.dateOnly(current.startDate))) {
      throw ArgumentError('Revised completion date must be after start date.');
    }

    final extended = current.copyWith(
      targetCompletionDate: revisedDay,
      // Explicitly preserve originalTargetDate untouched:
      originalTargetDate: current.originalTargetDate,
    );

    final sessions = _calculator.generateSessionsForJourney(
      journey: extended,
      now: now,
      existingSessions: getSessions(),
      defaultSyncState: _sync.stateForNewMutation(),
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyOpenJourney,
      extended.toJson(),
    );
    await _storage.writeList(
      LocalStorageDataSource.keySessions,
      sessions.map((s) => s.toJson()).toList(),
    );
    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: extended.id,
      operation: 'extend',
      now: now,
    );
    return extended;
  }

  Future<JourneyArchive> completeJourney({
    required CompletionOutcome outcome,
    required String proudAccomplishment,
    required String biggestLesson,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No active journey to complete.');

    final sessions = getSessions();
    final reflections = getSessionReflections();
    final updates = getJourneyUpdates();
    final weekly = getWeeklyReflections();
    final consistency = _metrics.evaluateConsistency(sessions: sessions);

    final completedJourney = current.copyWith(
      status: JourneyStatus.completed,
      completedAt: now,
      completionOutcome: outcome,
      proudAccomplishment: proudAccomplishment.trim(),
      biggestLesson: biggestLesson.trim(),
      clearPause: true,
    );

    final durationDays =
        DateTimeUtils.dateOnly(now)
            .difference(DateTimeUtils.dateOnly(current.startDate))
            .inDays
            .clamp(0, 36500) +
        1;

    final archive = JourneyArchive(
      id: IdGenerator.next('arc'),
      journey: completedJourney,
      finalStatus: JourneyStatus.completed,
      completedSessionsCount: consistency.completedSessions,
      totalScheduledCount: consistency.evaluatedSessions,
      consistencyPercentage: consistency.consistencyPercentage,
      updatesCount: updates.length,
      durationDays: durationDays,
      archivedAt: now,
      sessions: sessions,
      reflections: reflections,
      updates: updates,
      weeklyReflections: weekly,
    );

    final archives = [archive, ...getArchives()];
    await _storage.writeList(
      LocalStorageDataSource.keyArchives,
      archives.map((a) => a.toJson()).toList(),
    );
    await _clearOpenJourneyWorkspace();
    await _refreshQueueStatusesAfterClosingJourney();

    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: completedJourney.id,
      operation: 'complete',
      now: now,
    );
    return archive;
  }

  Future<JourneyArchive> cancelJourney({
    String? reason,
    required DateTime now,
  }) async {
    final current = getOpenJourney();
    if (current == null) throw StateError('No open journey to cancel.');

    final sessions = getSessions();
    final reflections = getSessionReflections();
    final updates = getJourneyUpdates();
    final weekly = getWeeklyReflections();
    final consistency = _metrics.evaluateConsistency(sessions: sessions);

    final cancelledJourney = current.copyWith(
      status: JourneyStatus.cancelled,
      cancelReason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      cancelledAt: now,
      clearPause: true,
    );

    final durationDays =
        DateTimeUtils.dateOnly(now)
            .difference(DateTimeUtils.dateOnly(current.startDate))
            .inDays
            .clamp(0, 36500) +
        1;

    final archive = JourneyArchive(
      id: IdGenerator.next('arc'),
      journey: cancelledJourney,
      finalStatus: JourneyStatus.cancelled,
      completedSessionsCount: consistency.completedSessions,
      totalScheduledCount: consistency.evaluatedSessions,
      consistencyPercentage: consistency.consistencyPercentage,
      updatesCount: updates.length,
      durationDays: durationDays,
      archivedAt: now,
      sessions: sessions,
      reflections: reflections,
      updates: updates,
      weeklyReflections: weekly,
    );

    final archives = [archive, ...getArchives()];
    await _storage.writeList(
      LocalStorageDataSource.keyArchives,
      archives.map((a) => a.toJson()).toList(),
    );
    await _clearOpenJourneyWorkspace();
    await _refreshQueueStatusesAfterClosingJourney();

    await _sync.enqueueMutation(
      entityType: 'journey',
      entityId: cancelledJourney.id,
      operation: 'cancel',
      now: now,
    );
    return archive;
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required DateTime now,
    String? actionRoute,
  }) async {
    final list = [
      AppNotification(
        id: IdGenerator.next('ntf'),
        title: title,
        body: body,
        createdAt: now,
        actionRoute: actionRoute,
      ),
      ...getNotifications(),
    ];
    await _storage.writeList(
      LocalStorageDataSource.keyNotifications,
      list.take(40).map((n) => n.toJson()).toList(),
    );
  }

  Future<void> markAllNotificationsRead() async {
    final updated = getNotifications()
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _storage.writeList(
      LocalStorageDataSource.keyNotifications,
      updated.map((n) => n.toJson()).toList(),
    );
  }

  Future<void> _clearOpenJourneyWorkspace() async {
    await _storage.writeObject(LocalStorageDataSource.keyOpenJourney, null);
    await _storage.writeList(LocalStorageDataSource.keySessions, []);
    await _storage.writeList(LocalStorageDataSource.keyReflections, []);
    await _storage.writeList(LocalStorageDataSource.keyUpdates, []);
    await _storage.writeList(LocalStorageDataSource.keyWeeklyReflections, []);
  }

  Future<void> _refreshQueueStatusesAfterClosingJourney() async {
    final queue = getQueueItems()
        .map((item) => item.copyWith(status: QueueItemStatus.readyToStart))
        .toList();
    await _storage.writeList(
      LocalStorageDataSource.keyQueue,
      queue.map((q) => q.toJson()).toList(),
    );
  }
}
