import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../application/providers/wizard_draft_provider.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_empty_state.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/journey.dart';
import '../../domain/services/progress_metrics_service.dart';
import 'widgets/journey_dialogs.dart';

class MyJourneyScreen extends ConsumerStatefulWidget {
  const MyJourneyScreen({super.key});

  @override
  ConsumerState<MyJourneyScreen> createState() => _MyJourneyScreenState();
}

class _MyJourneyScreenState extends ConsumerState<MyJourneyScreen> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Schedule, 2: Updates

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(journeyWorkspaceProvider);
    final queueCount = ref.watch(archiveQueueControllerProvider).queue.length;
    final metrics = ref.watch(progressMetricsServiceProvider);
    final now = ref.watch(clockProvider)();
    final journey = workspace.openJourney;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        title: const Text(
          'My Journey',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/queue'),
            icon: const Icon(
              Icons.layers_outlined,
              size: 18,
              color: FinishXColors.kineticMint,
            ),
            label: Text(
              'Queue ($queueCount)',
              style: const TextStyle(color: FinishXColors.kineticMint),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: journey == null
                ? FinishXEmptyState(
                    icon: Icons.route_outlined,
                    title: 'No active journey right now',
                    description:
                        'Commit to one focused journey or launch an item from your Journey Queue.',
                    actionLabel: queueCount > 0
                        ? 'Open Journey Queue'
                        : 'Create Journey',
                    onAction: () {
                      if (queueCount > 0) {
                        context.push('/queue');
                      } else {
                        ref
                            .read(journeyWizardProvider.notifier)
                            .reset(isQueueMode: false);
                        context.push('/wizard');
                      }
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Journey Card matching Screen 9 in mockup
                      FinishXCard(
                        padding: const EdgeInsets.all(FinishXSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: FinishXColors.kineticMint.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: FinishXColors.kineticMint,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                            const Text(
                              '18%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: FinishXColors.kineticMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Segmented Tab Bar: [Overview] [Schedule] [Updates]
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: FinishXColors.cardSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FinishXColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            _JourneyTabPill(
                              label: 'Overview',
                              isSelected: _selectedTabIndex == 0,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 0),
                            ),
                            _JourneyTabPill(
                              label: 'Schedule',
                              isSelected: _selectedTabIndex == 1,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 1),
                            ),
                            _JourneyTabPill(
                              label: 'Updates',
                              isSelected: _selectedTabIndex == 2,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Tab Content
                      if (_selectedTabIndex == 0) ...[
                        _buildOverviewTab(
                          journey: journey,
                          workspace: workspace,
                          metrics: metrics,
                          textTheme: textTheme,
                        ),
                      ] else if (_selectedTabIndex == 1) ...[
                        _buildScheduleTab(
                          journey: journey,
                          workspace: workspace,
                          textTheme: textTheme,
                        ),
                      ] else ...[
                        _buildUpdatesTab(
                          workspace: workspace,
                          now: now,
                          textTheme: textTheme,
                        ),
                      ],

                      const SizedBox(height: FinishXSpacing.xl),

                      // Actions matching Screen 9 in mockup: [Pause] [Extend] [Edit] [Cancel]
                      Text(
                        'Actions',
                        style: textTheme.titleSmall?.copyWith(
                          color: FinishXColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionSquareButton(
                            icon: journey.status == JourneyStatus.paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            label: journey.status == JourneyStatus.paused
                                ? 'Resume'
                                : 'Pause',
                            onTap: () async {
                              final ctrl = ref.read(
                                journeyWorkspaceProvider.notifier,
                              );
                              if (journey.status == JourneyStatus.paused) {
                                await ctrl.resumeJourney();
                              } else {
                                final reason =
                                    await JourneyDialogs.showPauseDialog(
                                      context,
                                    );
                                if (reason != null) {
                                  await ctrl.pauseJourney(reason);
                                }
                              }
                            },
                          ),
                          _ActionSquareButton(
                            icon: Icons.update_rounded,
                            label: 'Extend',
                            onTap: () async {
                              final revised =
                                  await JourneyDialogs.showExtendDialog(
                                    context: context,
                                    journey: journey,
                                  );
                              if (revised != null) {
                                await ref
                                    .read(journeyWorkspaceProvider.notifier)
                                    .extendJourney(revised);
                              }
                            },
                          ),
                          _ActionSquareButton(
                            icon: Icons.edit_calendar_outlined,
                            label: 'Edit',
                            onTap: () async {
                              final revised =
                                  await JourneyDialogs.showEditScheduleSheet(
                                    context: context,
                                    initialDays: journey.schedule.sortedDays,
                                  );
                              if (revised != null) {
                                await ref
                                    .read(journeyWorkspaceProvider.notifier)
                                    .updateCommitmentSchedule(revised);
                              }
                            },
                          ),
                          _ActionSquareButton(
                            icon: Icons.close_rounded,
                            label: 'Cancel',
                            isDestructive: true,
                            onTap: () async {
                              final (
                                confirmed,
                                reason,
                              ) = await JourneyDialogs.showCancelDialog(
                                context,
                              );
                              if (confirmed) {
                                await ref
                                    .read(journeyWorkspaceProvider.notifier)
                                    .cancelJourney(reason: reason);
                                if (context.mounted) {
                                  context.go('/archive');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab({
    required Journey journey,
    required ActiveJourneyWorkspaceState workspace,
    required ProgressMetricsService metrics,
    required TextTheme textTheme,
  }) {
    final consistency = metrics.evaluateConsistency(
      sessions: workspace.sessions,
    );
    final daysStr = journey.schedule.sortedDays
        .map((d) => DateTimeUtils.weekdayShortName(d.weekday))
        .join(', ');
    final timesStr = journey.schedule.sortedDays.isNotEmpty
        ? DateTimeUtils.formatTimeRange(
            journey.schedule.sortedDays.first.startHour,
            journey.schedule.sortedDays.first.startMinute,
            journey.schedule.sortedDays.first.endHour,
            journey.schedule.sortedDays.first.endMinute,
          )
        : '';

    final durationDays = DateTimeUtils.dateOnly(
      journey.targetCompletionDate,
    ).difference(DateTimeUtils.dateOnly(journey.startDate)).inDays;

    final completedCount = workspace.sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final totalPlanned = metrics
        .evaluateJourneyProgress(journey: journey, sessions: workspace.sessions)
        .totalScheduledSessions;
    final remainingCount = (totalPlanned - completedCount).clamp(0, 9999);

    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        children: [
          _DetailInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Timeline',
            value:
                '${DateTimeUtils.formatShortDate(journey.startDate)} – ${DateTimeUtils.formatMediumDate(journey.targetCompletionDate)} ($durationDays days)',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Commitment',
            value: '$daysStr – $timesStr',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.timelapse_rounded,
            label: 'Sessions',
            value: '$completedCount completed · $remainingCount remaining',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.show_chart_rounded,
            label: 'Consistency',
            value: '${consistency.consistencyPercentage}% (last 4 weeks)',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab({
    required Journey journey,
    required ActiveJourneyWorkspaceState workspace,
    required TextTheme textTheme,
  }) {
    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Commitment Schedule',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FinishXColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/schedule'),
                child: const Text('Open Calendar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...journey.schedule.sortedDays.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateTimeUtils.weekdayFullName(d.weekday),
                    style: textTheme.bodyMedium?.copyWith(
                      color: FinishXColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateTimeUtils.formatTimeRange(
                      d.startHour,
                      d.startMinute,
                      d.endHour,
                      d.endMinute,
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: FinishXColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTab({
    required ActiveJourneyWorkspaceState workspace,
    required DateTime now,
    required TextTheme textTheme,
  }) {
    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journey Updates (${workspace.updates.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FinishXColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: FinishXColors.kineticMint,
                ),
                onPressed: () => context.push('/journey-update'),
              ),
            ],
          ),
          if (workspace.updates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No updates logged yet. Log brief milestones after completed sessions.',
                style: textTheme.bodySmall?.copyWith(
                  color: FinishXColors.textSecondary,
                ),
              ),
            )
          else
            ...workspace.updates.map(
              (u) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FinishXColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: FinishXColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateTimeUtils.formatRelativeDateTime(u.createdAt, now),
                        style: textTheme.labelSmall?.copyWith(
                          color: FinishXColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JourneyTabPill extends StatelessWidget {
  const _JourneyTabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? FinishXColors.kineticMint : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? FinishXColors.darkBg
                  : FinishXColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: FinishXColors.kineticMint),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: FinishXColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FinishXColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionSquareButton extends StatelessWidget {
  const _ActionSquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FinishXColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDestructive
                    ? FinishXColors.mutedBrick.withValues(alpha: 0.4)
                    : FinishXColors.cardBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDestructive
                  ? FinishXColors.mutedBrick
                  : FinishXColors.kineticMint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDestructive
                  ? FinishXColors.mutedBrick
                  : FinishXColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
