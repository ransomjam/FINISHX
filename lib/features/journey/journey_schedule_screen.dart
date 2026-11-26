import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/theme/finishx_typography.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_empty_state.dart';
import '../../core/widgets/finishx_progress.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/session.dart';

class JourneyScheduleScreen extends ConsumerStatefulWidget {
  const JourneyScheduleScreen({super.key});

  @override
  ConsumerState<JourneyScheduleScreen> createState() =>
      _JourneyScheduleScreenState();
}

class _JourneyScheduleScreenState extends ConsumerState<JourneyScheduleScreen> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(journeyWorkspaceProvider);
    final now = ref.watch(clockProvider)();
    final journey = workspace.openJourney;
    final textTheme = Theme.of(context).textTheme;

    final baseWeekStart = DateTimeUtils.startOfWeek(now);
    final viewedWeekStart = baseWeekStart.add(Duration(days: _weekOffset * 7));
    final viewedWeekEnd = viewedWeekStart.add(const Duration(days: 6));

    final weekDays = List.generate(
      7,
      (i) => DateTime(
        viewedWeekStart.year,
        viewedWeekStart.month,
        viewedWeekStart.day + i,
      ),
    );

    final weekSessions = workspace.sessions.where((s) {
      final d = DateTimeUtils.dateOnly(s.scheduledDate);
      return !d.isBefore(viewedWeekStart) && !d.isAfter(viewedWeekEnd);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Commitment Schedule')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: journey == null
                ? const FinishXEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No scheduled commitments',
                    description:
                        'Create an active journey to view your weekly commitment calendar.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week selector & calendar strip
                      FinishXCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'Previous week',
                                  onPressed: () =>
                                      setState(() => _weekOffset--),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${DateTimeUtils.formatShortDate(viewedWeekStart)} – ${DateTimeUtils.formatMediumDate(viewedWeekEnd)}',
                                      style: textTheme.titleLarge,
                                    ),
                                    if (_weekOffset != 0)
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _weekOffset = 0),
                                        child: Text(
                                          'Return to current week',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: FinishXColors.deepSpruce,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Next week',
                                  onPressed: () =>
                                      setState(() => _weekOffset++),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: FinishXSpacing.md),
                            Row(
                              children: weekDays.map((day) {
                                final isToday = DateTimeUtils.isSameDay(
                                  day,
                                  now,
                                );
                                Session? daySession;
                                for (final s in weekSessions) {
                                  if (DateTimeUtils.isSameDay(
                                    s.scheduledDate,
                                    day,
                                  )) {
                                    daySession = s;
                                    break;
                                  }
                                }
                                return Expanded(
                                  child: _DayCalendarCell(
                                    day: day,
                                    isToday: isToday,
                                    session: daySession,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: FinishXSpacing.md),
                            const Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _LegendDot(
                                  label: 'Completed',
                                  color: FinishXColors.kineticMint,
                                ),
                                _LegendDot(
                                  label: 'Planned',
                                  color: FinishXColors.forestInk,
                                ),
                                _LegendDot(
                                  label: 'Missed',
                                  color: FinishXColors.mutedBrick,
                                ),
                                _LegendDot(
                                  label: 'Suspended',
                                  color: FinishXColors.sageBorder,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.lg),
                      Text('SESSIONS THIS WEEK', style: textTheme.labelSmall),
                      const SizedBox(height: FinishXSpacing.sm),
                      if (weekSessions.isEmpty)
                        FinishXCard(
                          variant: FinishXCardVariant.softSage,
                          child: Text(
                            'No sessions scheduled in this week window.',
                            style: textTheme.bodyMedium,
                          ),
                        )
                      else
                        ...weekSessions.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SessionScheduleRow(session: session),
                          ),
                        ),
                      const SizedBox(height: FinishXSpacing.lg),
                      Text(
                        'ALL HISTORICAL & UPCOMING SESSIONS',
                        style: textTheme.labelSmall,
                      ),
                      const SizedBox(height: FinishXSpacing.sm),
                      ...workspace.sessions.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SessionScheduleRow(session: s),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DayCalendarCell extends StatelessWidget {
  const _DayCalendarCell({
    required this.day,
    required this.isToday,
    required this.session,
  });

  final DateTime day;
  final bool isToday;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (session?.status) {
      SessionStatus.completed => FinishXColors.kineticMint,
      SessionStatus.planned ||
      SessionStatus.inProgress => FinishXColors.forestInk,
      SessionStatus.missed => FinishXColors.mutedBrick,
      SessionStatus.suspended => FinishXColors.sageBorder,
      null => Colors.transparent,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? FinishXColors.forestInk : FinishXColors.warmChalk,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            DateTimeUtils.weekdayShortName(day.weekday),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? FinishXColors.softSage
                  : FinishXColors.carbonSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontFamily: FinishXTypography.headingFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isToday ? FinishXColors.pureSurface : FinishXColors.carbon,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SessionScheduleRow extends StatelessWidget {
  const _SessionScheduleRow({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final badge = switch (session.status) {
      SessionStatus.completed => FinishXBadge.mint(
        'Completed',
        icon: Icons.check_rounded,
      ),
      SessionStatus.inProgress => FinishXBadge.forest(
        'In Session',
        icon: Icons.bolt_rounded,
      ),
      SessionStatus.planned => const FinishXBadge(
        label: 'Planned',
        backgroundColor: FinishXColors.softSage,
        foregroundColor: FinishXColors.forestInk,
      ),
      SessionStatus.missed => FinishXBadge.brick(
        'Missed',
        icon: Icons.history_toggle_off_rounded,
      ),
      SessionStatus.suspended => const FinishXBadge(
        label: 'Suspended',
        backgroundColor: FinishXColors.warmChalk,
        foregroundColor: FinishXColors.carbonSecondary,
      ),
    };

    return FinishXCard(
      padding: const EdgeInsets.symmetric(
        horizontal: FinishXSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTimeUtils.formatFullDayDate(session.scheduledDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateTimeUtils.formatTimeRange(session.plannedStartHour, session.plannedStartMinute, session.plannedEndHour, session.plannedEndMinute)} · ${DateTimeUtils.formatDurationMinutes(session.plannedDurationMinutes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          badge,
        ],
      ),
    );
  }
}
