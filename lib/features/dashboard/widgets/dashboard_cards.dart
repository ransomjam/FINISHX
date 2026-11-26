import 'package:flutter/material.dart';

import '../../../core/theme/finishx_colors.dart';
import '../../../core/theme/finishx_spacing.dart';
import '../../../core/theme/finishx_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/finishx_buttons.dart';
import '../../../core/widgets/finishx_card.dart';
import '../../../core/widgets/finishx_progress.dart';
import '../../../domain/enums/app_enums.dart';
import '../../../domain/models/accountability_group.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/session.dart';
import '../../../domain/services/progress_metrics_service.dart';

/// 1. My Active Journey Card (matching Screen 8 in mockup)
class ActiveJourneyDashboardCard extends StatelessWidget {
  const ActiveJourneyDashboardCard({
    super.key,
    required this.journey,
    required this.progress,
    required this.onTap,
  });

  final Journey journey;
  final JourneyProgressSnapshot progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      onTap: onTap,
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Active Journey',
            style: textTheme.labelSmall?.copyWith(
              color: FinishXColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FinishXColors.kineticMint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: FinishXColors.kineticMint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: FinishXColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${journey.category.label} · ${journey.resource.type.label}',
                      style: textTheme.bodySmall?.copyWith(
                        color: FinishXColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateTimeUtils.formatShortDate(journey.startDate)} – ${DateTimeUtils.formatMediumDate(journey.targetCompletionDate)}',
            style: textTheme.bodySmall?.copyWith(
              color: FinishXColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FinishXProgressBar(
                  value: progress.measurableRatio,
                  height: 6,
                  trackColor: FinishXColors.cardSurfaceLight,
                  progressColor: FinishXColors.kineticMint,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.percentage}%',
                style: const TextStyle(
                  fontFamily: FinishXTypography.headingFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: FinishXColors.kineticMint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. Next Commitment Hero Card (matching Screen 8 in mockup)
class NextCommitmentHeroCard extends StatelessWidget {
  const NextCommitmentHeroCard({
    super.key,
    required this.journey,
    required this.nextSession,
    required this.now,
    required this.onStartSession,
    required this.onResumeJourney,
    required this.onAdjustSchedule,
  });

  final Journey journey;
  final Session? nextSession;
  final DateTime now;
  final VoidCallback onStartSession;
  final VoidCallback onResumeJourney;
  final VoidCallback onAdjustSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Case 1: Journey is Paused
    if (journey.status == JourneyStatus.paused) {
      return FinishXCard(
        padding: const EdgeInsets.all(FinishXSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinishXBadge(
              label:
                  'JOURNEY PAUSED · ${(journey.pauseReason?.label ?? 'Rest').toUpperCase()}',
              backgroundColor: FinishXColors.mintSurface,
              foregroundColor: FinishXColors.kineticMint,
              icon: Icons.pause_circle_outline_rounded,
            ),
            const SizedBox(height: FinishXSpacing.md),
            Text(
              'Your commitments are safely on hold.',
              style: textTheme.headlineSmall?.copyWith(
                color: FinishXColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No sessions are marked missed while paused, and your group spot remains yours.',
              style: textTheme.bodySmall?.copyWith(
                color: FinishXColors.textSecondary,
              ),
            ),
            const SizedBox(height: FinishXSpacing.md),
            FinishXPrimaryButton(
              label: 'Resume Journey',
              useMintFill: true,
              icon: Icons.play_arrow_rounded,
              onPressed: onResumeJourney,
            ),
          ],
        ),
      );
    }

    // Active session details
    final session = nextSession;
    final isInProgress = session?.status == SessionStatus.inProgress;
    final countdown = session != null
        ? DateTimeUtils.formatCountdown(
            session.plannedStartDateTime.difference(now),
          )
        : 'Ready whenever you are';

    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Commitment',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FinishXColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: FinishXColors.kineticMint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isInProgress ? 'In Progress' : 'Upcoming',
                  style: const TextStyle(
                    color: FinishXColors.kineticMint,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: FinishXColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                session != null
                    ? DateTimeUtils.formatFullDayDate(session.scheduledDate)
                    : 'Extra Focus Session',
                style: textTheme.bodyMedium?.copyWith(
                  color: FinishXColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time range row
          if (session != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: FinishXColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateTimeUtils.formatTimeRange(
                    session.plannedStartHour,
                    session.plannedStartMinute,
                    session.plannedEndHour,
                    session.plannedEndMinute,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Countdown row
            Row(
              children: [
                const Icon(
                  Icons.timelapse_rounded,
                  size: 16,
                  color: FinishXColors.kineticMint,
                ),
                const SizedBox(width: 8),
                Text(
                  countdown,
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.kineticMint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: FinishXSpacing.lg),

          // Start Session Button matching Screen 8 in mockup
          FinishXPrimaryButton(
            label: isInProgress ? 'Return to Focus Mode' : 'Start Session',
            suffixIcon: isInProgress
                ? Icons.arrow_forward_rounded
                : Icons.play_arrow_rounded,
            useMintFill: true,
            onPressed: onStartSession,
          ),
        ],
      ),
    );
  }
}

/// 3. Side-by-Side: This Week Card (matching Screen 8 in mockup)
class ThisWeekDashboardCard extends StatelessWidget {
  const ThisWeekDashboardCard({
    super.key,
    required this.completedCount,
    required this.targetCount,
  });

  final int completedCount;
  final int targetCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: textTheme.labelSmall?.copyWith(
              color: FinishXColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount/$targetCount',
            style: textTheme.displaySmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: FinishXColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sessions',
            style: textTheme.bodySmall?.copyWith(
              color: FinishXColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Side-by-Side: Consistency Card (matching Screen 8 in mockup)
class ConsistencyDashboardCard extends StatelessWidget {
  const ConsistencyDashboardCard({
    super.key,
    required this.consistencyPercentage,
  });

  final int consistencyPercentage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency',
            style: textTheme.labelSmall?.copyWith(
              color: FinishXColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$consistencyPercentage%',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: FinishXColors.textPrimary,
                ),
              ),
              FinishXConsistencyRing(
                percentage: consistencyPercentage,
                size: 38,
                strokeWidth: 4,
                onDark: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last 4 weeks',
            style: textTheme.bodySmall?.copyWith(
              color: FinishXColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Group Summary Card
class GroupSummaryDashboardCard extends StatelessWidget {
  const GroupSummaryDashboardCard({
    super.key,
    required this.group,
    required this.health,
    required this.onViewGroup,
  });

  final AccountabilityGroup group;
  final GroupHealthDisplay health;
  final VoidCallback onViewGroup;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      onTap: onViewGroup,
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACCOUNTABILITY GROUP',
                style: textTheme.labelSmall?.copyWith(
                  color: FinishXColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FinishXBadge(
                label: group.league.label,
                backgroundColor: FinishXColors.mintSurface,
                foregroundColor: FinishXColors.kineticMint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            group.name,
            style: textTheme.headlineSmall?.copyWith(
              color: FinishXColors.textPrimary,
            ),
          ),
          const SizedBox(height: FinishXSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 17,
                color: FinishXColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${group.memberCount} members',
                style: textTheme.bodySmall?.copyWith(
                  color: FinishXColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.favorite_border_rounded,
                size: 17,
                color: FinishXColors.kineticMint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Health: ${health.displayLabel}',
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.kineticMint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FinishXSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 30,
                child: Row(
                  children: group.members.take(5).map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: m.isCurrentUser
                            ? FinishXColors.kineticMint
                            : FinishXColors.cardSurfaceLight,
                        child: Text(
                          m.initials,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: m.isCurrentUser
                                ? FinishXColors.darkBg
                                : FinishXColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              TextButton.icon(
                onPressed: onViewGroup,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: FinishXColors.kineticMint,
                ),
                label: const Text(
                  'View Group',
                  style: TextStyle(color: FinishXColors.kineticMint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Supportive Missed Session Banner
class SupportiveMissedSessionBanner extends StatelessWidget {
  const SupportiveMissedSessionBanner({
    super.key,
    required this.missedSession,
    required this.onResumeMyJourney,
  });

  final Session missedSession;
  final VoidCallback onResumeMyJourney;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      variant: FinishXCardVariant.supportiveBrick,
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_twilight_rounded,
                size: 19,
                color: FinishXColors.mutedBrick,
              ),
              const SizedBox(width: 8),
              Text(
                'MISSED SESSION · ${DateTimeUtils.formatShortDate(missedSession.scheduledDate).toUpperCase()}',
                style: textTheme.labelSmall?.copyWith(
                  color: FinishXColors.mutedBrick,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'One missed session doesn\'t define your journey. The next commitment is what matters.',
            style: textTheme.bodyMedium?.copyWith(
              color: FinishXColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FinishXSpacing.sm),
          FinishXSecondaryButton(
            label: 'Resume My Journey',
            compact: true,
            onPressed: onResumeMyJourney,
          ),
        ],
      ),
    );
  }
}
