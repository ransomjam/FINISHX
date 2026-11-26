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
import '../../core/widgets/finishx_sync_banner.dart';
import 'widgets/dashboard_cards.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final workspace = ref.watch(journeyWorkspaceProvider);
    final groupState = ref.watch(groupControllerProvider);
    final archiveQueue = ref.watch(archiveQueueControllerProvider);
    final notifications = ref.watch(notificationsControllerProvider);
    final syncStatus = ref.watch(syncControllerProvider);

    final rules = ref.watch(journeyRulesServiceProvider);
    final metrics = ref.watch(progressMetricsServiceProvider);
    final now = ref.watch(clockProvider)();

    final user = auth.user;
    final journey = workspace.openJourney;
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final textTheme = Theme.of(context).textTheme;

    final nextSession = journey != null
        ? rules.findNextCommitmentSession(workspace.sessions, now)
        : null;
    final unresolvedMissed = journey != null
        ? rules.findUnresolvedMissedSession(workspace.sessions)
        : null;
    final showMissedBanner =
        unresolvedMissed != null &&
        unresolvedMissed.id != workspace.dismissedMissedSessionId;

    final sundayCheckInPending =
        journey != null &&
        rules.isSundayCheckInPending(
          journey: journey,
          weeklyReflections: workspace.weeklyReflections,
          now: now,
        );

    final weeklyMetrics = journey != null
        ? metrics.evaluateWeeklyCommitment(
            journey: journey,
            sessions: workspace.sessions,
            now: now,
          )
        : null;

    final consistencyMetrics = metrics.evaluateConsistency(
      sessions: workspace.sessions,
    );

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: FinishXColors.kineticMint,
          backgroundColor: FinishXColors.cardSurface,
          onRefresh: () async {
            await ref
                .read(journeyWorkspaceProvider.notifier)
                .reconcileTimeline();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: FinishXSpacing.md),
            child: ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header matching Screen 8 in mockup
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Good morning, ',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: FinishXColors.textPrimary,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    user?.displayName ?? 'Finisher',
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: FinishXColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Text(
                                  ' 👋',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateTimeUtils.formatFullDayDate(now),
                              style: textTheme.bodySmall?.copyWith(
                                color: FinishXColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification bell in circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FinishXColors.cardSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: FinishXColors.cardBorder),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            backgroundColor: FinishXColors.kineticMint,
                            textColor: FinishXColors.darkBg,
                            label: Text('$unreadCount'),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar with golden/orange ring
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => context.push('/profile'),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: FinishXColors.cardSurfaceLight,
                            child: Text(
                              user?.initials ?? 'FX',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: FinishXColors.kineticMint,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FinishXSpacing.sm),

                  // Sync Pill & Queue status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FinishXSyncPill(
                          status: syncStatus,
                          onTap: () => context.push('/profile'),
                        ),
                      ),
                      if (archiveQueue.queue.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => context.push('/queue'),
                          icon: const Icon(
                            Icons.layers_outlined,
                            size: 16,
                            color: FinishXColors.kineticMint,
                          ),
                          label: Text(
                            'Queue (${archiveQueue.queue.length})',
                            style: const TextStyle(
                              color: FinishXColors.kineticMint,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: FinishXSpacing.md),

                  // Welcome Back supportive banner after >=3 days inactivity
                  if (auth.showWelcomeBackBanner && journey != null) ...[
                    FinishXCard(
                      variant: FinishXCardVariant.mintTint,
                      padding: const EdgeInsets.all(FinishXSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.waving_hand_outlined,
                            size: 20,
                            color: FinishXColors.kineticMint,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user?.firstName ?? 'friend'}.',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: FinishXColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pick up calmly from your next scheduled commitment below.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: FinishXColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .dismissWelcomeBack(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FinishXSpacing.md),
                  ],

                  // Empty state if no active journey is running
                  if (journey == null) ...[
                    FinishXEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Ready for your next commitment',
                      description: archiveQueue.queue.isNotEmpty
                          ? 'You have ${archiveQueue.queue.length} planned ${archiveQueue.queue.length == 1 ? 'journey' : 'journeys'} waiting in your Journey Queue.'
                          : 'Start one meaningful journey and give it your full focus.',
                      actionLabel: archiveQueue.queue.isNotEmpty
                          ? 'Open Journey Queue'
                          : 'Create New Journey',
                      onAction: () {
                        if (archiveQueue.queue.isNotEmpty) {
                          context.push('/queue');
                        } else {
                          ref
                              .read(journeyWizardProvider.notifier)
                              .reset(isQueueMode: false);
                          context.push('/wizard');
                        }
                      },
                    ),
                  ] else ...[
                    // Missed session recovery card
                    if (showMissedBanner) ...[
                      SupportiveMissedSessionBanner(
                        missedSession: unresolvedMissed,
                        onResumeMyJourney: () {
                          ref
                              .read(journeyWorkspaceProvider.notifier)
                              .acknowledgeMissedSession(unresolvedMissed.id);
                        },
                      ),
                      const SizedBox(height: FinishXSpacing.md),
                    ],

                    // Sunday Weekly Check-In invitation banner
                    if (sundayCheckInPending) ...[
                      FinishXCard(
                        variant: FinishXCardVariant.mintTint,
                        onTap: () => context.push('/weekly-checkin'),
                        padding: const EdgeInsets.all(FinishXSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: FinishXColors.kineticMint.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.auto_stories_outlined,
                                size: 20,
                                color: FinishXColors.kineticMint,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sunday Weekly Check-In',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: FinishXColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Reflect on your week in under 1 minute.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: FinishXColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: FinishXColors.kineticMint,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.md),
                    ],

                    // 1. My Active Journey Card (matching Screen 8 in mockup)
                    ActiveJourneyDashboardCard(
                      journey: journey,
                      progress: metrics.evaluateJourneyProgress(
                        journey: journey,
                        sessions: workspace.sessions,
                      ),
                      onTap: () => context.go('/journey'),
                    ),
                    const SizedBox(height: FinishXSpacing.md),

                    // 2. Next Commitment Hero Card (matching Screen 8 in mockup)
                    NextCommitmentHeroCard(
                      journey: journey,
                      nextSession: nextSession,
                      now: now,
                      onStartSession: () async {
                        await ref
                            .read(journeyWorkspaceProvider.notifier)
                            .startSession(sessionId: nextSession?.id);
                        if (context.mounted) {
                          context.push('/focus');
                        }
                      },
                      onResumeJourney: () => context.go('/journey'),
                      onAdjustSchedule: () => context.go('/journey'),
                    ),
                    const SizedBox(height: FinishXSpacing.md),

                    // 3. Side-by-Side: This Week & Consistency (matching Screen 8 in mockup)
                    Row(
                      children: [
                        Expanded(
                          child: ThisWeekDashboardCard(
                            completedCount:
                                weeklyMetrics?.completedThisWeek ?? 0,
                            targetCount: weeklyMetrics?.targetThisWeek ?? 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ConsistencyDashboardCard(
                            consistencyPercentage:
                                consistencyMetrics.consistencyPercentage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FinishXSpacing.md),

                    // 4. Accountability Group Summary
                    if (groupState.group != null)
                      GroupSummaryDashboardCard(
                        group: groupState.group!,
                        health: metrics.evaluateGroupHealth(groupState.group!),
                        onViewGroup: () => context.go('/group'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
