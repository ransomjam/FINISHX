import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/wizard_draft_provider.dart';
import '../../../core/theme/finishx_colors.dart';
import '../../../core/theme/finishx_spacing.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/finishx_buttons.dart';
import '../../../core/widgets/finishx_card.dart';
import '../../../domain/enums/app_enums.dart';

/// Step 1 — Journey Name (Exact layout from Screen 4 in mockup)
class WizardStepName extends ConsumerStatefulWidget {
  const WizardStepName({super.key});

  @override
  ConsumerState<WizardStepName> createState() => _WizardStepNameState();
}

class _WizardStepNameState extends ConsumerState<WizardStepName> {
  late final TextEditingController _controller;

  static const List<({String name, IconData icon})> _popularExamples = [
    (name: 'Become a Data Scientist', icon: Icons.bar_chart_rounded),
    (name: 'Learn Python', icon: Icons.code_rounded),
    (name: 'Pass AWS Certification', icon: Icons.cloud_outlined),
    (name: 'Start a Business', icon: Icons.work_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(journeyWizardProvider).journeyName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What journey are you starting?',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          onChanged: notifier.setJourneyName,
          decoration: InputDecoration(
            hintText: 'e.g. Learn Python, Start a Business',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: FinishXColors.textSecondary,
            ),
            filled: true,
            fillColor: FinishXColors.cardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
              borderSide: const BorderSide(color: FinishXColors.cardBorder),
            ),
          ),
        ),
        const SizedBox(height: FinishXSpacing.xl),
        Text(
          'Popular examples',
          style: textTheme.labelMedium?.copyWith(
            color: FinishXColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FinishXSpacing.sm),
        ..._popularExamples.map((item) {
          final isSelected = draft.journeyName.trim() == item.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinishXCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              onTap: () {
                _controller.text = item.name;
                _controller.selection = TextSelection.collapsed(
                  offset: item.name.length,
                );
                notifier.setJourneyName(item.name);
              },
              variant: isSelected
                  ? FinishXCardVariant.mintTint
                  : FinishXCardVariant.surface,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FinishXColors.kineticMint.withValues(alpha: 0.2)
                          : FinishXColors.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: isSelected
                          ? FinishXColors.kineticMint
                          : FinishXColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? FinishXColors.kineticMint
                            : FinishXColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: FinishXColors.kineticMint,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Step 2 — Journey Category
class WizardStepCategory extends ConsumerWidget {
  const WizardStepCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a journey category',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.xs),
        Text(
          'Your category matches you with a dedicated peer accountability group.',
          style: textTheme.bodyMedium?.copyWith(
            color: FinishXColors.textSecondary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),
        ...JourneyCategory.values.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinishXSelectableTile(
              title: cat.label,
              leadingIcon: cat.icon,
              selected: draft.category == cat,
              onTap: () => notifier.setCategory(cat),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 3 — Learning Resource
class WizardStepResource extends ConsumerStatefulWidget {
  const WizardStepResource({super.key});

  @override
  ConsumerState<WizardStepResource> createState() => _WizardStepResourceState();
}

class _WizardStepResourceState extends ConsumerState<WizardStepResource> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(journeyWizardProvider);
    _nameCtrl = TextEditingController(text: draft.resourceName);
    _urlCtrl = TextEditingController(text: draft.resourceUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What resource will you use for this journey?',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.xs),
        Text(
          'FinishX helps you consistently complete the resource you already have.',
          style: textTheme.bodyMedium?.copyWith(
            color: FinishXColors.textSecondary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),
        ...ResourceType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinishXSelectableTile(
              title: type.label,
              leadingIcon: type.icon,
              selected: draft.resourceType == type,
              onTap: () => notifier.setResourceType(type),
            ),
          ),
        ),
        const SizedBox(height: FinishXSpacing.md),
        FinishXCard(
          padding: const EdgeInsets.all(FinishXSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPTIONAL DETAILS',
                style: textTheme.labelSmall?.copyWith(
                  color: FinishXColors.textSecondary,
                ),
              ),
              const SizedBox(height: FinishXSpacing.sm),
              TextField(
                controller: _nameCtrl,
                onChanged: notifier.setResourceName,
                decoration: const InputDecoration(
                  labelText: 'Resource title (optional)',
                  hintText: 'e.g. Applied Data Science Specialization',
                ),
              ),
              const SizedBox(height: FinishXSpacing.sm),
              TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                onChanged: notifier.setResourceUrl,
                decoration: const InputDecoration(
                  labelText: 'Resource URL (optional)',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step 4 — Journey Timeline
class WizardStepTimeline extends ConsumerWidget {
  const WizardStepTimeline({super.key});

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 1095)),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final today = DateTimeUtils.dateOnly(DateTime.now());
    final durationDays = DateTimeUtils.dateOnly(
      draft.targetCompletionDate,
    ).difference(DateTimeUtils.dateOnly(draft.startDate)).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your journey timeline',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.xs),
        Text(
          'Define a clear start date and a realistic finish date.',
          style: textTheme.bodyMedium?.copyWith(
            color: FinishXColors.textSecondary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),
        FinishXSelectableTile(
          title: 'Start Today',
          subtitle: DateTimeUtils.formatMediumDate(today),
          leadingIcon: Icons.bolt_rounded,
          selected: draft.startsToday,
          onTap: () => notifier.setStartsToday(true),
        ),
        const SizedBox(height: 10),
        FinishXSelectableTile(
          title: 'Pick a Future Date',
          subtitle: !draft.startsToday
              ? 'Scheduled for ${DateTimeUtils.formatMediumDate(draft.startDate)}'
              : 'Schedule your journey to activate on its start date',
          leadingIcon: Icons.event_available_rounded,
          selected: !draft.startsToday,
          onTap: () async {
            notifier.setStartsToday(false);
            await _pickDate(
              context: context,
              initialDate: draft.startDate.isAfter(today)
                  ? draft.startDate
                  : today.add(const Duration(days: 7)),
              firstDate: today.add(const Duration(days: 1)),
              onPicked: notifier.setStartDate,
            );
          },
        ),
        const SizedBox(height: FinishXSpacing.lg),
        FinishXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TARGET COMPLETION DATE',
                style: textTheme.labelSmall?.copyWith(
                  color: FinishXColors.textSecondary,
                ),
              ),
              const SizedBox(height: FinishXSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      DateTimeUtils.formatMediumDate(
                        draft.targetCompletionDate,
                      ),
                      style: textTheme.headlineMedium?.copyWith(
                        color: FinishXColors.textPrimary,
                      ),
                    ),
                  ),
                  FinishXSecondaryButton(
                    label: 'Change Date',
                    compact: true,
                    icon: Icons.calendar_today_outlined,
                    onPressed: () => _pickDate(
                      context: context,
                      initialDate: draft.targetCompletionDate,
                      firstDate: draft.startDate.add(const Duration(days: 1)),
                      onPicked: notifier.setTargetDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FinishXSpacing.sm),
              if (!draft.isValidTimeline)
                Text(
                  'Target completion date must be after your start date.',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.mutedBrick,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  '$durationDays-day horizon from ${DateTimeUtils.formatShortDate(draft.startDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step 5 — Commitment Days
class WizardStepDays extends ConsumerWidget {
  const WizardStepDays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your commitment days',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.xs),
        Text(
          'Select the days of the week you will consistently show up.',
          style: textTheme.bodyMedium?.copyWith(
            color: FinishXColors.textSecondary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),
        ...List.generate(7, (index) {
          final weekday = index + 1;
          final selected = draft.selectedWeekdays.contains(weekday);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinishXSelectableTile(
              title: DateTimeUtils.weekdayFullName(weekday),
              selected: selected,
              onTap: () => notifier.toggleWeekday(weekday),
            ),
          );
        }),
      ],
    );
  }
}

/// Step 6 — Commitment Schedule (Exact layout matching Screen 5 in mockup)
class WizardStepSchedule extends ConsumerWidget {
  const WizardStepSchedule({super.key});

  Future<void> _pickTime({
    required BuildContext context,
    required int initialHour,
    required int initialMinute,
    required void Function(int hour, int minute) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) {
      onSelected(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final summary = notifier.computeSummaryMetrics();
    final days = draft.orderedCommitmentDays;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your commitment schedule',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FinishXColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set a time for each selected day',
          style: textTheme.bodyMedium?.copyWith(
            color: FinishXColors.textSecondary,
          ),
        ),
        const SizedBox(height: FinishXSpacing.lg),

        // Day rows matching Screen 5 in mockup
        ...days.map((day) {
          final dayNameShort = DateTimeUtils.weekdayShortName(day.weekday);
          final timeRangeStr = DateTimeUtils.formatTimeRange(
            day.startHour,
            day.startMinute,
            day.endHour,
            day.endMinute,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinishXCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _pickTime(
                context: context,
                initialHour: day.startHour,
                initialMinute: day.startMinute,
                onSelected: (h, m) => notifier.updateDayTime(
                  weekday: day.weekday,
                  startHour: h,
                  startMinute: m,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FinishXColors.kineticMint.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FinishXColors.kineticMint.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      dayNameShort,
                      style: const TextStyle(
                        color: FinishXColors.kineticMint,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: FinishXColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeRangeStr,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FinishXColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: FinishXColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: FinishXSpacing.lg),

        // Metrics summary matching Screen 5 in mockup
        FinishXCard(
          padding: const EdgeInsets.all(FinishXSpacing.md),
          child: Column(
            children: [
              _MetricRow(
                icon: Icons.access_time_rounded,
                label: 'Session duration',
                value: days.isNotEmpty
                    ? '${(days.first.durationMinutes / 60.0).toStringAsFixed(days.first.durationMinutes % 60 == 0 ? 0 : 1)} hour'
                    : '1 hour',
              ),
              const Divider(height: 20),
              _MetricRow(
                icon: Icons.calendar_today_rounded,
                label: 'Weekly sessions',
                value: '${summary.weeklySessionCount}',
              ),
              const Divider(height: 20),
              _MetricRow(
                icon: Icons.timelapse_rounded,
                label: 'Weekly commitment',
                value:
                    '${summary.totalWeeklyHours.toStringAsFixed(summary.totalWeeklyHours % 1 == 0 ? 0 : 1)} hours',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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
      children: [
        Icon(icon, size: 18, color: FinishXColors.kineticMint),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FinishXColors.textSecondary,
                ),
              ),
              Semantics(
                label: label.toUpperCase(),
                child: ExcludeSemantics(
                  excluding: false,
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 0,
                      height: 0,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: FinishXColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Step 7 — Review & Sign (Exact layout matching Screen 6 in mockup)
class WizardStepConfirmation extends ConsumerStatefulWidget {
  const WizardStepConfirmation({super.key});

  @override
  ConsumerState<WizardStepConfirmation> createState() =>
      _WizardStepConfirmationState();
}

class _WizardStepConfirmationState
    extends ConsumerState<WizardStepConfirmation> {
  bool _pledgeAgreed = true;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(journeyWizardProvider);
    final summary = ref
        .read(journeyWizardProvider.notifier)
        .computeSummaryMetrics();
    final days = draft.orderedCommitmentDays;
    final textTheme = Theme.of(context).textTheme;

    final daysStr = days
        .map((d) => DateTimeUtils.weekdayShortName(d.weekday))
        .join(', ');
    final timesStr = days.isNotEmpty
        ? DateTimeUtils.formatTimeRange(
            days.first.startHour,
            days.first.startMinute,
            days.first.endHour,
            days.first.endMinute,
          )
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Review & sign your commitment',
          child: ExcludeSemantics(
            excluding: false,
            child: const Text(
              'Review & sign your commitment',
              style: TextStyle(
                fontSize: 0,
                height: 0,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        // Hero card with icon and journey name
        FinishXCard(
          padding: const EdgeInsets.all(FinishXSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FinishXColors.kineticMint.withValues(alpha: 0.18),
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
                      draft.journeyName.trim().isEmpty
                          ? 'Become a Data Scientist'
                          : draft.journeyName.trim(),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: FinishXColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FinishXSpacing.md),

        // Summary details card
        FinishXCard(
          padding: const EdgeInsets.all(FinishXSpacing.md),
          child: Column(
            children: [
              _ReviewLine(label: 'Category', value: draft.category.label),
              const Divider(height: 20),
              _ReviewLine(
                label: 'Resource',
                value: draft.learningResource.displayTitle,
              ),
              const Divider(height: 20),
              _ReviewLine(
                label: 'Start date',
                value: DateTimeUtils.formatMediumDate(draft.startDate),
              ),
              const Divider(height: 20),
              _ReviewLine(
                label: 'Target date',
                value: DateTimeUtils.formatMediumDate(
                  draft.targetCompletionDate,
                ),
              ),
              const Divider(height: 20),
              _ReviewLine(
                label: 'Commitment',
                value: '$daysStr\n$timesStr',
                isMultiLine: true,
              ),
              const Divider(height: 20),
              _ReviewLine(
                label: 'Weekly time',
                value:
                    '${summary.totalWeeklyHours.toStringAsFixed(summary.totalWeeklyHours % 1 == 0 ? 0 : 1)} hours',
              ),
            ],
          ),
        ),
        const SizedBox(height: FinishXSpacing.md),

        // Checkbox commitment statement matching Screen 6
        GestureDetector(
          onTap: () => setState(() => _pledgeAgreed = !_pledgeAgreed),
          child: Container(
            padding: const EdgeInsets.all(FinishXSpacing.md),
            decoration: BoxDecoration(
              color: FinishXColors.cardSurface,
              borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
              border: Border.all(
                color: _pledgeAgreed
                    ? FinishXColors.kineticMint.withValues(alpha: 0.5)
                    : FinishXColors.cardBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _pledgeAgreed
                        ? FinishXColors.kineticMint
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _pledgeAgreed
                          ? FinishXColors.kineticMint
                          : FinishXColors.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: _pledgeAgreed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: FinishXColors.darkBg,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I commit to completing my journey by honoring the schedule I have chosen.',
                    style: textTheme.bodySmall?.copyWith(
                      color: FinishXColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.label,
    required this.value,
    this.isMultiLine = false,
  });

  final String label;
  final String value;
  final bool isMultiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: FinishXColors.textSecondary),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: FinishXColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
