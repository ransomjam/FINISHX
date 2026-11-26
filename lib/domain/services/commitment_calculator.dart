import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../enums/app_enums.dart';
import '../models/commitment_day.dart';
import '../models/journey.dart';
import '../models/session.dart';

class ScheduleSummaryMetrics {
  const ScheduleSummaryMetrics({
    required this.weeklySessionCount,
    required this.totalWeeklyMinutes,
    required this.totalWeeklyHours,
  });

  final int weeklySessionCount;
  final int totalWeeklyMinutes;
  final double totalWeeklyHours;
}

/// Pure business service for commitment schedule calculations and session generation.
class CommitmentCalculator {
  const CommitmentCalculator();

  ScheduleSummaryMetrics calculateScheduleMetrics(List<CommitmentDay> days) {
    final totalMinutes = days.fold<int>(0, (sum, d) => sum + d.durationMinutes);
    return ScheduleSummaryMetrics(
      weeklySessionCount: days.length,
      totalWeeklyMinutes: totalMinutes,
      totalWeeklyHours: totalMinutes / 60.0,
    );
  }

  /// Generates scheduled sessions for a journey through a rolling 42-day horizon,
  /// bounded by [journey.targetCompletionDate].
  List<Session> generateSessionsForJourney({
    required Journey journey,
    required DateTime now,
    List<Session> existingSessions = const [],
    SyncState defaultSyncState = SyncState.synced,
  }) {
    final startDay = DateTimeUtils.dateOnly(journey.startDate);
    final targetDay = DateTimeUtils.dateOnly(journey.targetCompletionDate);
    final horizonEnd = DateTimeUtils.dateOnly(
      now.add(const Duration(days: 42)),
    );
    final generationEnd = horizonEnd.isBefore(targetDay)
        ? horizonEnd
        : targetDay;

    if (generationEnd.isBefore(startDay)) {
      return List<Session>.from(existingSessions);
    }

    final existingKeys = <String>{
      for (final s in existingSessions) _dateKey(s.scheduledDate),
    };

    final result = List<Session>.from(existingSessions);
    var cursor = startDay;

    while (!cursor.isAfter(generationEnd)) {
      final key = _dateKey(cursor);
      if (!existingKeys.contains(key)) {
        final matchingDay = journey.schedule.dayForWeekday(cursor.weekday);
        if (matchingDay != null) {
          final status = journey.status == JourneyStatus.paused
              ? SessionStatus.suspended
              : SessionStatus.planned;
          result.add(
            Session(
              id: IdGenerator.next('ses'),
              journeyId: journey.id,
              scheduledDate: cursor,
              plannedStartHour: matchingDay.startHour,
              plannedStartMinute: matchingDay.startMinute,
              plannedEndHour: matchingDay.endHour,
              plannedEndMinute: matchingDay.endMinute,
              status: status,
              syncState: defaultSyncState,
            ),
          );
        }
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    result.sort(
      (a, b) => a.plannedStartDateTime.compareTo(b.plannedStartDateTime),
    );
    return result;
  }

  /// Applies a revised schedule from [now] forward while preserving all completed,
  /// missed, in-progress, and past session records.
  List<Session> applyScheduleChangePreservingHistory({
    required Journey updatedJourney,
    required List<Session> currentSessions,
    required DateTime now,
    SyncState defaultSyncState = SyncState.synced,
  }) {
    final today = DateTimeUtils.dateOnly(now);

    final preserved = currentSessions.where((session) {
      if (session.status == SessionStatus.completed ||
          session.status == SessionStatus.missed ||
          session.status == SessionStatus.inProgress) {
        return true;
      }
      if (DateTimeUtils.dateOnly(session.scheduledDate).isBefore(today)) {
        return true;
      }
      return false;
    }).toList();

    final effectiveStart =
        today.isAfter(DateTimeUtils.dateOnly(updatedJourney.startDate))
        ? today
        : DateTimeUtils.dateOnly(updatedJourney.startDate);

    final targetDay = DateTimeUtils.dateOnly(
      updatedJourney.targetCompletionDate,
    );
    final horizonEnd = DateTimeUtils.dateOnly(
      now.add(const Duration(days: 42)),
    );
    final generationEnd = horizonEnd.isBefore(targetDay)
        ? horizonEnd
        : targetDay;

    final preservedKeys = <String>{
      for (final s in preserved) _dateKey(s.scheduledDate),
    };

    var cursor = effectiveStart;
    while (!cursor.isAfter(generationEnd)) {
      final key = _dateKey(cursor);
      if (!preservedKeys.contains(key)) {
        final dayConfig = updatedJourney.schedule.dayForWeekday(cursor.weekday);
        if (dayConfig != null) {
          preserved.add(
            Session(
              id: IdGenerator.next('ses'),
              journeyId: updatedJourney.id,
              scheduledDate: cursor,
              plannedStartHour: dayConfig.startHour,
              plannedStartMinute: dayConfig.startMinute,
              plannedEndHour: dayConfig.endHour,
              plannedEndMinute: dayConfig.endMinute,
              status: updatedJourney.status == JourneyStatus.paused
                  ? SessionStatus.suspended
                  : SessionStatus.planned,
              syncState: defaultSyncState,
            ),
          );
        }
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    preserved.sort(
      (a, b) => a.plannedStartDateTime.compareTo(b.plannedStartDateTime),
    );
    return preserved;
  }

  int countTotalPlannedCommitmentsForTimeline(
    Journey journey,
    List<Session> sessions,
  ) {
    final start = DateTimeUtils.dateOnly(journey.startDate);
    final end = DateTimeUtils.dateOnly(journey.targetCompletionDate);
    if (end.isBefore(start)) return sessions.length;

    final byDate = <String, Session>{
      for (final s in sessions) _dateKey(s.scheduledDate): s,
    };

    var total = 0;
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final existing = byDate[_dateKey(cursor)];
      if (existing != null) {
        if (existing.status != SessionStatus.suspended) {
          total++;
        }
      } else if (journey.schedule.dayForWeekday(cursor.weekday) != null) {
        total++;
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return total;
  }

  String _dateKey(DateTime dt) {
    final d = DateTimeUtils.dateOnly(dt);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
