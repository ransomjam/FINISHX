import '../../core/utils/date_time_utils.dart';
import '../enums/app_enums.dart';
import '../models/accountability_group.dart';
import '../models/journey.dart';
import '../models/session.dart';
import 'commitment_calculator.dart';

class WeeklyCommitmentSnapshot {
  const WeeklyCommitmentSnapshot({
    required this.completedThisWeek,
    required this.targetThisWeek,
    required this.percentage,
  });

  final int completedThisWeek;
  final int targetThisWeek;
  final int percentage;
}

class ConsistencySnapshot {
  const ConsistencySnapshot({
    required this.completedSessions,
    required this.missedSessions,
    required this.evaluatedSessions,
    required this.consistencyPercentage,
  });

  final int completedSessions;
  final int missedSessions;
  final int evaluatedSessions;
  final int consistencyPercentage;
}

class JourneyProgressSnapshot {
  const JourneyProgressSnapshot({
    required this.completedSessions,
    required this.totalScheduledSessions,
    required this.measurableRatio,
  });

  final int completedSessions;
  final int totalScheduledSessions;

  /// Ratio strictly derived from measurable completed commitments vs planned
  /// commitments. Authoritative weighted journey-progress formulas remain
  /// intentionally configurable behind this service.
  final double measurableRatio;

  int get percentage => (measurableRatio * 100).round().clamp(0, 100);
}

class GroupHealthDisplay {
  const GroupHealthDisplay({
    required this.scorePercentage,
    required this.isSampleDemoValue,
    required this.displayLabel,
  });

  final int scorePercentage;
  final bool isSampleDemoValue;
  final String displayLabel;
}

/// Isolated calculation service for commitment consistency, journey progress,
/// and group health display.
///
/// Per FinishX product guidelines, authoritative formulas for overall Journey
/// Progress and Group Health are not invented here: actual progress reflects
/// measurable completed commitments, and Group Health clearly marks sample
/// values when running in demo mode.
class ProgressMetricsService {
  const ProgressMetricsService({
    this.calculator = const CommitmentCalculator(),
  });

  final CommitmentCalculator calculator;

  WeeklyCommitmentSnapshot evaluateWeeklyCommitment({
    required Journey journey,
    required List<Session> sessions,
    required DateTime now,
  }) {
    final weekStart = DateTimeUtils.startOfWeek(now);
    final weekEnd = DateTimeUtils.endOfWeek(now);

    final weekSessions = sessions.where((s) {
      final d = DateTimeUtils.dateOnly(s.scheduledDate);
      return !d.isBefore(weekStart) &&
          !d.isAfter(DateTimeUtils.dateOnly(weekEnd));
    }).toList();

    final completed = weekSessions
        .where((s) => s.status == SessionStatus.completed)
        .length;

    final target = journey.schedule.weeklySessionsCount;
    final pct = target <= 0
        ? 0
        : ((completed / target) * 100).round().clamp(0, 100);

    return WeeklyCommitmentSnapshot(
      completedThisWeek: completed,
      targetThisWeek: target,
      percentage: pct,
    );
  }

  ConsistencySnapshot evaluateConsistency({required List<Session> sessions}) {
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final missed = sessions
        .where((s) => s.status == SessionStatus.missed)
        .length;
    final evaluated = completed + missed;

    final pct = evaluated == 0
        ? (completed > 0 ? 100 : 100)
        : ((completed / evaluated) * 100).round().clamp(0, 100);

    return ConsistencySnapshot(
      completedSessions: completed,
      missedSessions: missed,
      evaluatedSessions: evaluated,
      consistencyPercentage: evaluated == 0 ? 0 : pct,
    );
  }

  JourneyProgressSnapshot evaluateJourneyProgress({
    required Journey journey,
    required List<Session> sessions,
  }) {
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final totalScheduled = calculator.countTotalPlannedCommitmentsForTimeline(
      journey,
      sessions,
    );
    final ratio = totalScheduled <= 0
        ? 0.0
        : (completed / totalScheduled).clamp(0.0, 1.0);

    return JourneyProgressSnapshot(
      completedSessions: completed,
      totalScheduledSessions: totalScheduled,
      measurableRatio: ratio,
    );
  }

  GroupHealthDisplay evaluateGroupHealth(AccountabilityGroup group) {
    if (group.isDemoGroup) {
      return GroupHealthDisplay(
        scorePercentage: group.sampleHealthScore,
        isSampleDemoValue: true,
        displayLabel: '${group.sampleHealthScore}% · Sample',
      );
    }
    return GroupHealthDisplay(
      scorePercentage: group.sampleHealthScore,
      isSampleDemoValue: false,
      displayLabel: '${group.sampleHealthScore}%',
    );
  }
}
