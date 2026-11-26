import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_empty_state.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/feed_activity.dart';

class AccountabilityGroupScreen extends ConsumerStatefulWidget {
  const AccountabilityGroupScreen({super.key});

  @override
  ConsumerState<AccountabilityGroupScreen> createState() =>
      _AccountabilityGroupScreenState();
}

class _AccountabilityGroupScreenState
    extends ConsumerState<AccountabilityGroupScreen> {
  int _selectedTabIndex = 0; // 0: Activity, 1: Members

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupControllerProvider);
    final now = ref.watch(clockProvider)();
    final group = groupState.group;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group?.name ?? 'Accountability Group',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            if (group != null)
              Row(
                children: [
                  Text(
                    '${group.category.label} · ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FinishXColors.textSecondary,
                    ),
                  ),
                  const Text(
                    'Accountability Group',
                    style: TextStyle(
                      fontSize: 12,
                      color: FinishXColors.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: group == null
                ? const FinishXEmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'No group assigned yet',
                    description:
                        'Sign your first journey commitment to be matched automatically with peers in your category.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3 stats columns matching Screen 10 in mockup
                      FinishXCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GroupMetricColumn(
                                icon: Icons.person_outline_rounded,
                                value: '${group.memberCount}',
                                label: 'Members',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: FinishXColors.cardBorder,
                            ),
                            Expanded(
                              child: _GroupMetricColumn(
                                icon: Icons.military_tech_outlined,
                                value: group.league.label.replaceFirst(
                                  ' League',
                                  '',
                                ),
                                label: 'League',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: FinishXColors.cardBorder,
                            ),
                            Expanded(
                              child: _GroupMetricColumn(
                                icon: Icons.insights_rounded,
                                value: '${group.sampleHealthScore}%',
                                label: 'Group Health',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Avatars row matching Screen 10 in mockup
                      Row(
                        children: [
                          ...group.members.take(5).map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: m.isCurrentUser
                                    ? FinishXColors.kineticMint
                                    : FinishXColors.cardSurfaceLight,
                                child: Text(
                                  m.initials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: m.isCurrentUser
                                        ? FinishXColors.darkBg
                                        : FinishXColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }),
                          if (group.memberCount > 5)
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: FinishXColors.cardSurfaceLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FinishXColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                '+${group.memberCount - 5}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FinishXColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Segmented Tab bar: [Activity] [Members]
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: FinishXColors.cardSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FinishXColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            _GroupTabPill(
                              label: 'Activity',
                              isSelected: _selectedTabIndex == 0,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 0),
                            ),
                            _GroupTabPill(
                              label: 'Members',
                              isSelected: _selectedTabIndex == 1,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Tab Content
                      if (_selectedTabIndex == 0) ...[
                        ...groupState.feed.map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FeedActivityCard(
                              activity: activity,
                              now: now,
                              onToggleReaction: (type) {
                                ref
                                    .read(groupControllerProvider.notifier)
                                    .toggleReaction(activity.id, type);
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        FinishXCard(
                          padding: const EdgeInsets.all(FinishXSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: group.members.map((m) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: m.isCurrentUser
                                          ? FinishXColors.kineticMint
                                          : FinishXColors.cardSurfaceLight,
                                      child: Text(
                                        m.initials,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: m.isCurrentUser
                                              ? FinishXColors.darkBg
                                              : FinishXColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        m.displayName,
                                        style: textTheme.titleSmall?.copyWith(
                                          color: FinishXColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (m.isCurrentUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: FinishXColors.mintSurface,
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            color: FinishXColors.kineticMint,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GroupMetricColumn extends StatelessWidget {
  const _GroupMetricColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: FinishXColors.kineticMint),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: FinishXColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GroupTabPill extends StatelessWidget {
  const _GroupTabPill({
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

class _FeedActivityCard extends StatelessWidget {
  const _FeedActivityCard({
    required this.activity,
    required this.now,
    required this.onToggleReaction,
  });

  final FeedActivity activity;
  final DateTime now;
  final ValueChanged<ReactionType> onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final (icon, iconBg) = switch (activity.type) {
      FeedActivityType.sessionCompleted => (
        Icons.check_rounded,
        FinishXColors.kineticMint.withValues(alpha: 0.18),
      ),
      FeedActivityType.consistencyStreak => (
        Icons.local_fire_department_rounded,
        const Color(0xFFF59E0B).withValues(alpha: 0.18),
      ),
      FeedActivityType.weeklyCommitmentCompleted => (
        Icons.verified_rounded,
        FinishXColors.kineticMint.withValues(alpha: 0.18),
      ),
      FeedActivityType.progressShared => (
        Icons.article_outlined,
        FinishXColors.cardSurfaceLight,
      ),
      FeedActivityType.journeyCompleted => (
        Icons.emoji_events_rounded,
        const Color(0xFFF59E0B).withValues(alpha: 0.25),
      ),
    };

    return FinishXCard(
      padding: const EdgeInsets.all(FinishXSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: FinishXColors.kineticMint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.message,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FinishXColors.textPrimary,
                      ),
                    ),
                    if (activity.detailText != null &&
                        activity.detailText!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FinishXColors.cardSurfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '“${activity.detailText!}”',
                          style: textTheme.bodySmall?.copyWith(
                            color: FinishXColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateTimeUtils.formatRelativeDateTime(
                        activity.createdAt,
                        now,
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: FinishXColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reaction pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activity.reactions.map((reaction) {
              final active = reaction.reactedByCurrentUser;
              return InkWell(
                onTap: () => onToggleReaction(reaction.type),
                borderRadius: BorderRadius.circular(99),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? FinishXColors.kineticMint.withValues(alpha: 0.18)
                        : FinishXColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: active
                          ? FinishXColors.kineticMint
                          : FinishXColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reaction.type.symbol,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (reaction.count > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${reaction.count}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? FinishXColors.kineticMint
                                : FinishXColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
