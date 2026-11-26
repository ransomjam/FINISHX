import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../application/providers/wizard_draft_provider.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/commitment_day.dart';
import '../../domain/models/commitment_schedule.dart';
import '../../domain/models/journey_queue_item.dart';
import '../../domain/models/learning_resource.dart';

/// Journey Queue Screen — exact match to Screen 14 in media_1795599304928_c0a38770.jpg
class JourneyQueueScreen extends ConsumerWidget {
  const JourneyQueueScreen({super.key});

  static final _defaultSchedule = CommitmentSchedule(
    id: 'sched_queue_demo',
    days: const [
      CommitmentDay(
        weekday: DateTime.tuesday,
        startHour: 18,
        startMinute: 0,
        endHour: 19,
        endMinute: 30,
      ),
    ],
    effectiveFrom: DateTime(2027, 1, 1),
  );

  static final List<JourneyQueueItem> _defaultMockQueue = [
    JourneyQueueItem(
      id: 'q_demo_1',
      userId: 'u_1',
      name: 'Learn Python',
      category: JourneyCategory.softwareEngineering,
      resource: const LearningResource(
        type: ResourceType.udemy,
        name: 'Complete Python Bootcamp',
      ),
      plannedStartDate: DateTime(2027, 5, 1),
      targetCompletionDate: DateTime(2028, 4, 30),
      schedule: _defaultSchedule,
      status: QueueItemStatus.queued,
      createdAt: DateTime(2026, 11, 20),
    ),
    JourneyQueueItem(
      id: 'q_demo_2',
      userId: 'u_1',
      name: 'Pass AWS Certification',
      category: JourneyCategory.softwareEngineering,
      resource: const LearningResource(
        type: ResourceType.coursera,
        name: 'AWS Solutions Architect',
      ),
      plannedStartDate: DateTime(2027, 5, 1),
      targetCompletionDate: DateTime(2027, 7, 31),
      schedule: _defaultSchedule,
      status: QueueItemStatus.queued,
      createdAt: DateTime(2026, 11, 21),
    ),
    JourneyQueueItem(
      id: 'q_demo_3',
      userId: 'u_1',
      name: 'Write a Book',
      category: JourneyCategory.personalDevelopment,
      resource: const LearningResource(
        type: ResourceType.book,
        name: 'Nonfiction Book Architecture',
      ),
      plannedStartDate: DateTime(2027, 9, 1),
      targetCompletionDate: DateTime(2027, 12, 31),
      schedule: _defaultSchedule,
      status: QueueItemStatus.queued,
      createdAt: DateTime(2026, 11, 22),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveQueue = ref.watch(archiveQueueControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final items = archiveQueue.queue.isNotEmpty
        ? archiveQueue.queue
        : _defaultMockQueue;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        title: const Text(
          'Journey Queue',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add a Journey',
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            onPressed: () {
              ref.read(journeyWizardProvider.notifier).reset(isQueueMode: true);
              context.push('/wizard?mode=queue');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FinishXSpacing.xl,
                  vertical: FinishXSpacing.sm,
                ),
                child: ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle matching mockup Screen 14
                      Text(
                        'Plan your next journeys. Only one journey can be active at a time.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: FinishXColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.lg),

                      // List of queue cards
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isFirst = index == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QueueCard(item: item, isUpcoming: isFirst),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Add a Journey Mint Button
            ResponsiveContainer(
              padding: const EdgeInsets.fromLTRB(
                FinishXSpacing.xl,
                FinishXSpacing.xs,
                FinishXSpacing.xl,
                FinishXSpacing.lg,
              ),
              child: FinishXPrimaryButton(
                label: 'Add a Journey',
                useMintFill: true,
                onPressed: () {
                  ref
                      .read(journeyWizardProvider.notifier)
                      .reset(isQueueMode: true);
                  context.push('/wizard?mode=queue');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item, required this.isUpcoming});

  final JourneyQueueItem item;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FinishXColors.kineticMint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.category.icon,
              color: FinishXColors.kineticMint,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? FinishXColors.kineticMint.withValues(alpha: 0.2)
                            : FinishXColors.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isUpcoming ? 'Upcoming' : 'Planned',
                        style: TextStyle(
                          color: isUpcoming
                              ? FinishXColors.kineticMint
                              : FinishXColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Start: ${DateTimeUtils.formatMediumDate(item.plannedStartDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Target: ${DateTimeUtils.formatMediumDate(item.targetCompletionDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
