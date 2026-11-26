import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_card.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/commitment_day.dart';
import '../../domain/models/commitment_schedule.dart';
import '../../domain/models/journey.dart';
import '../../domain/models/journey_archive.dart';
import '../../domain/models/learning_resource.dart';

/// Journey Archive Screen — exact match to Screen 13 in media_1795599304928_c0a38770.jpg
class JourneyArchiveScreen extends ConsumerStatefulWidget {
  const JourneyArchiveScreen({super.key});

  @override
  ConsumerState<JourneyArchiveScreen> createState() =>
      _JourneyArchiveScreenState();
}

class _JourneyArchiveScreenState extends ConsumerState<JourneyArchiveScreen> {
  int _filterIndex = 0; // 0: Completed, 1: Cancelled, 2: All

  static final _defaultSchedule = CommitmentSchedule(
    id: 'sched_demo',
    days: const [
      CommitmentDay(
        weekday: DateTime.monday,
        startHour: 17,
        startMinute: 0,
        endHour: 19,
        endMinute: 0,
      ),
      CommitmentDay(
        weekday: DateTime.wednesday,
        startHour: 17,
        startMinute: 0,
        endHour: 19,
        endMinute: 0,
      ),
      CommitmentDay(
        weekday: DateTime.friday,
        startHour: 17,
        startMinute: 0,
        endHour: 19,
        endMinute: 0,
      ),
    ],
    effectiveFrom: DateTime(2025, 1, 1),
  );

  static final List<JourneyArchive> _defaultMockArchives = [
    JourneyArchive(
      id: 'arch_demo_1',
      journey: Journey(
        id: 'j_demo_1',
        userId: 'u_1',
        name: 'Become a Data Scientist',
        category: JourneyCategory.dataScience,
        resource: const LearningResource(
          type: ResourceType.coursera,
          name: 'Coursera - IBM DS',
        ),
        startDate: DateTime(2026, 7, 1),
        targetCompletionDate: DateTime(2026, 12, 31),
        originalTargetDate: DateTime(2026, 12, 31),
        commitmentSignedAt: DateTime(2026, 7, 1),
        schedule: _defaultSchedule,
        groupId: 'grp_ds_28',
        status: JourneyStatus.completed,
        createdAt: DateTime(2026, 7, 1),
      ),
      finalStatus: JourneyStatus.completed,
      completedSessionsCount: 52,
      totalScheduledCount: 60,
      consistencyPercentage: 86,
      updatesCount: 28,
      durationDays: 183,
      archivedAt: DateTime(2026, 12, 31),
    ),
    JourneyArchive(
      id: 'arch_demo_2',
      journey: Journey(
        id: 'j_demo_2',
        userId: 'u_1',
        name: 'Learn French',
        category: JourneyCategory.languages,
        resource: const LearningResource(
          type: ResourceType.other,
          name: 'Alliance Française',
        ),
        startDate: DateTime(2026, 1, 10),
        targetCompletionDate: DateTime(2026, 4, 30),
        originalTargetDate: DateTime(2026, 4, 30),
        commitmentSignedAt: DateTime(2026, 1, 10),
        schedule: _defaultSchedule,
        groupId: 'grp_lang_37',
        status: JourneyStatus.completed,
        createdAt: DateTime(2026, 1, 10),
      ),
      finalStatus: JourneyStatus.completed,
      completedSessionsCount: 31,
      totalScheduledCount: 43,
      consistencyPercentage: 72,
      updatesCount: 16,
      durationDays: 110,
      archivedAt: DateTime(2026, 4, 30),
    ),
    JourneyArchive(
      id: 'arch_demo_3',
      journey: Journey(
        id: 'j_demo_3',
        userId: 'u_1',
        name: 'Start a Business',
        category: JourneyCategory.entrepreneurship,
        resource: const LearningResource(
          type: ResourceType.book,
          name: 'The Lean Startup',
        ),
        startDate: DateTime(2025, 8, 12),
        targetCompletionDate: DateTime(2025, 11, 10),
        originalTargetDate: DateTime(2025, 11, 10),
        commitmentSignedAt: DateTime(2025, 8, 12),
        schedule: _defaultSchedule,
        groupId: 'grp_ent_31',
        status: JourneyStatus.completed,
        createdAt: DateTime(2025, 8, 12),
      ),
      finalStatus: JourneyStatus.completed,
      completedSessionsCount: 24,
      totalScheduledCount: 35,
      consistencyPercentage: 68,
      updatesCount: 12,
      durationDays: 90,
      archivedAt: DateTime(2025, 11, 10),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(archiveQueueControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    // Use stored archives if available; otherwise use mockup default sample archives
    final allArchives = state.archives.isNotEmpty
        ? state.archives
        : _defaultMockArchives;

    final filtered = allArchives.where((a) {
      if (_filterIndex == 0) return !a.isCancelled;
      if (_filterIndex == 1) return a.isCancelled;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        title: const Text(
          'Journey Archive',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Queue',
            icon: const Icon(Icons.layers_outlined, color: Colors.white),
            onPressed: () => context.push('/queue'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: FinishXSpacing.xl,
            vertical: FinishXSpacing.sm,
          ),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter pills: [ Completed ]  [ Cancelled ]  [ All ]
                Row(
                  children: [
                    _buildFilterPill('Completed', 0),
                    const SizedBox(width: 8),
                    _buildFilterPill('Cancelled', 1),
                    const SizedBox(width: 8),
                    _buildFilterPill('All', 2),
                  ],
                ),
                const SizedBox(height: FinishXSpacing.lg),

                // List of archive cards
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No archives in this category',
                        style: textTheme.bodyMedium?.copyWith(
                          color: FinishXColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (archive) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ArchiveCard(
                        archive: archive,
                        onTap: () => context.push('/archive/${archive.id}'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int index) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterIndex = index),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? FinishXColors.kineticMint
                : FinishXColors.cardSurface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected
                  ? FinishXColors.kineticMint
                  : FinishXColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF091815)
                  : FinishXColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.archive, required this.onTap});

  final JourneyArchive archive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FinishXCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Green category icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FinishXColors.kineticMint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              archive.journey.category.icon,
              color: FinishXColors.kineticMint,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        archive.journey.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: FinishXColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateTimeUtils.formatMediumDate(archive.journey.startDate)} – ${DateTimeUtils.formatMediumDate(archive.archivedAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${archive.durationDays} days',
                      style: const TextStyle(
                        color: FinishXColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${archive.completedSessionsCount} sessions',
                      style: const TextStyle(
                        color: FinishXColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${archive.consistencyPercentage}%',
                      style: const TextStyle(
                        color: FinishXColors.kineticMint,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArchiveDetailScreen extends ConsumerWidget {
  const ArchiveDetailScreen({super.key, required this.archiveId});

  final String archiveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archives = ref.watch(archiveQueueControllerProvider).archives;
    final archive = archives.cast<JourneyArchive?>().firstWhere(
      (a) => a?.id == archiveId,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        title: Text(archive?.journey.name ?? 'Archived Journey'),
      ),
      body: SafeArea(
        child: Center(
          child: Text(
            archive?.journey.name ?? 'Archive detail',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
