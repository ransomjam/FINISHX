import '../../core/utils/date_time_utils.dart';
import '../enums/app_enums.dart';
import '../models/journey.dart';
import '../models/session.dart';
import '../models/weekly_reflection.dart';

class ReconciledJourneyState {
  const ReconciledJourneyState({
    required this.journey,
    required this.sessions,
    required this.newlyMissedCount,
    required this.autoActivatedFromPlanned,
  });

  final Journey journey;
  final List<Session> sessions;
  final int newlyMissedCount;
  final bool autoActivatedFromPlanned;
}

/// Enforces FinishX domain business rules:
/// - Single-active-journey ("One Journey. Full Focus.")
/// - Future start date auto-activation
/// - Overdue session -> Missed transition (excluding paused periods)
/// - Paused journey session suspension
/// - Sunday Weekly Check-In eligibility & Welcome-Back detection
class JourneyRulesService {
  const JourneyRulesService();

  /// Returns true only when no open (active, paused, or scheduled primary) journey exists.
  bool canActivateNewJourney(Journey? currentOpenJourney) {
    if (currentOpenJourney == null) return true;
    return !currentOpenJourney.status.isOpen;
  }

  /// Reconciles journey lifecycle and session statuses against current local time [now].
  ReconciledJourneyState reconcile({
    required Journey journey,
    required List<Session> sessions,
    required DateTime now,
  }) {
    var updatedJourney = journey;
    var autoActivated = false;

    final today = DateTimeUtils.dateOnly(now);
    final startDay = DateTimeUtils.dateOnly(journey.startDate);

    // Automatically activate a future-scheduled journey once its start date arrives.
    if (updatedJourney.status == JourneyStatus.planned &&
        !today.isBefore(startDay)) {
      updatedJourney = updatedJourney.copyWith(status: JourneyStatus.active);
      autoActivated = true;
    }

    var newlyMissed = 0;
    final reconciledSessions = sessions.map((session) {
      // Completed, missed, and active in-progress sessions keep their state.
      if (session.status == SessionStatus.completed ||
          session.status == SessionStatus.missed ||
          session.status == SessionStatus.inProgress) {
        return session;
      }

      // If journey is currently paused, future/current planned sessions are suspended, never missed.
      if (updatedJourney.status == JourneyStatus.paused) {
        if (session.status == SessionStatus.planned) {
          return session.copyWith(status: SessionStatus.suspended);
        }
        return session;
      }

      // If journey is active (or resumed), restore future suspended sessions to planned.
      var candidate = session;
      if (updatedJourney.status == JourneyStatus.active &&
          candidate.status == SessionStatus.suspended &&
          candidate.plannedEndDateTime.isAfter(now)) {
        candidate = candidate.copyWith(status: SessionStatus.planned);
      }

      // Check overdue planned sessions while active, skipping any session that fell inside a pause interval.
      if (updatedJourney.status == JourneyStatus.active &&
          candidate.status == SessionStatus.planned &&
          candidate.plannedEndDateTime.isBefore(now)) {
        if (_fellDuringPauseInterval(candidate, updatedJourney.pauseHistory)) {
          return candidate.copyWith(status: SessionStatus.suspended);
        }
        newlyMissed++;
        return candidate.copyWith(status: SessionStatus.missed);
      }

      return candidate;
    }).toList();

    return ReconciledJourneyState(
      journey: updatedJourney,
      sessions: reconciledSessions,
      newlyMissedCount: newlyMissed,
      autoActivatedFromPlanned: autoActivated,
    );
  }

  bool _fellDuringPauseInterval(
    Session session,
    List<PauseInterval> pauseHistory,
  ) {
    final end = session.plannedEndDateTime;
    for (final interval in pauseHistory) {
      final resumed = interval.resumedAt;
      if (!end.isBefore(interval.pausedAt) &&
          (resumed == null || !end.isAfter(resumed))) {
        return true;
      }
    }
    return false;
  }

  /// Finds the next actionable session (in-progress first, otherwise earliest upcoming planned session).
  Session? findNextCommitmentSession(List<Session> sessions, DateTime now) {
    for (final s in sessions) {
      if (s.status == SessionStatus.inProgress) return s;
    }
    final upcoming =
        sessions
            .where(
              (s) =>
                  s.status == SessionStatus.planned &&
                  !s.plannedEndDateTime.isBefore(now),
            )
            .toList()
          ..sort(
            (a, b) => a.plannedStartDateTime.compareTo(b.plannedStartDateTime),
          );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Finds the most recent missed session if no subsequent session has been completed yet.
  Session? findUnresolvedMissedSession(List<Session> sessions) {
    final missed =
        sessions.where((s) => s.status == SessionStatus.missed).toList()..sort(
          (a, b) => b.plannedStartDateTime.compareTo(a.plannedStartDateTime),
        );
    if (missed.isEmpty) return null;

    final latestMissed = missed.first;
    final completedAfter = sessions.any(
      (s) =>
          s.status == SessionStatus.completed &&
          (s.endedAt ?? s.plannedEndDateTime).isAfter(
            latestMissed.plannedEndDateTime,
          ),
    );
    return completedAfter ? null : latestMissed;
  }

  /// Weekly Check-In invitation is highlighted on Sundays when not yet submitted for the week.
  bool isSundayCheckInPending({
    required Journey journey,
    required List<WeeklyReflection> weeklyReflections,
    required DateTime now,
  }) {
    if (journey.status != JourneyStatus.active) return false;
    if (now.toLocal().weekday != DateTime.sunday) return false;
    return !hasCompletedCheckInForWeek(weeklyReflections, now);
  }

  bool hasCompletedCheckInForWeek(
    List<WeeklyReflection> weeklyReflections,
    DateTime now,
  ) {
    final weekStart = DateTimeUtils.startOfWeek(now);
    return weeklyReflections.any(
      (r) => DateTimeUtils.isSameDay(r.weekStartDate, weekStart),
    );
  }

  /// Detects returning user after >= 3 days of inactivity for supportive Welcome Back banner.
  bool shouldShowWelcomeBack({
    required DateTime? previousLastActiveAt,
    required DateTime now,
  }) {
    if (previousLastActiveAt == null) return false;
    return now.difference(previousLastActiveAt).inHours >= 72;
  }
}
