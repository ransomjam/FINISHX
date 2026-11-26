import 'package:flutter/material.dart';

import '../../../core/theme/finishx_colors.dart';
import '../../../core/theme/finishx_spacing.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/finishx_buttons.dart';
import '../../../core/widgets/finishx_card.dart';
import '../../../domain/enums/app_enums.dart';
import '../../../domain/models/commitment_day.dart';
import '../../../domain/models/journey.dart';

abstract final class JourneyDialogs {
  /// Modal sheet for editing commitment days and times while preserving history.
  static Future<List<CommitmentDay>?> showEditScheduleSheet({
    required BuildContext context,
    required List<CommitmentDay> initialDays,
    String title = 'Edit Commitment Schedule',
    String primaryLabel = 'Save Schedule',
  }) {
    return showModalBottomSheet<List<CommitmentDay>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditScheduleSheetContent(
        initialDays: initialDays,
        title: title,
        primaryLabel: primaryLabel,
      ),
    );
  }

  /// Pause Journey dialog asking why the user is pausing.
  static Future<PauseReason?> showPauseDialog(BuildContext context) {
    PauseReason selected = PauseReason.workCommitments;
    return showDialog<PauseReason>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Pause Journey'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life happens. While paused, scheduled sessions are suspended — none will be marked missed, and your accountability group membership stays intact.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: FinishXSpacing.md),
                Text(
                  'WHY ARE YOU PAUSING?',
                  style: Theme.of(ctx).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                ...PauseReason.values.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FinishXSelectableTile(
                      title: reason.label,
                      selected: selected == reason,
                      onTap: () => setState(() => selected = reason),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Active'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(124, 44)),
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Pause Journey'),
            ),
          ],
        ),
      ),
    );
  }

  /// Extend Journey date picker preserving originalTargetDate.
  static Future<DateTime?> showExtendDialog({
    required BuildContext context,
    required Journey journey,
  }) async {
    final currentTarget = DateTimeUtils.dateOnly(journey.targetCompletionDate);
    final suggested = currentTarget.add(const Duration(days: 14));
    return showDatePicker(
      context: context,
      helpText: 'SELECT REVISED COMPLETION DATE',
      initialDate: suggested,
      firstDate: DateTimeUtils.dateOnly(
        journey.startDate,
      ).add(const Duration(days: 1)),
      lastDate: currentTarget.add(const Duration(days: 730)),
    );
  }

  /// Cancel Journey confirmation dialog with optional cancellation reasons.
  static Future<(bool confirmed, String? reason)> showCancelDialog(
    BuildContext context,
  ) async {
    const presetReasons = [
      'Priorities shifted',
      'Timeline no longer realistic',
      'Switching to a different goal',
      'Personal circumstances',
    ];
    String? chosenReason;
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cancel Journey?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consider pausing or extending first if you only need breathing room. '
                  'If cancelled, this journey will remain permanently accessible in your Archive.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: FinishXSpacing.md),
                Text(
                  'OPTIONAL REASON',
                  style: Theme.of(ctx).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetReasons.map((r) {
                    final selected = chosenReason == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => chosenReason = selected ? null : r);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: FinishXSpacing.sm),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Additional note (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Journey'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FinishXColors.mutedBrick,
                minimumSize: const Size(132, 44),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cancel Journey'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return (false, null);
    final extra = notesCtrl.text.trim();
    final combined = [
      if (chosenReason != null) chosenReason!,
      if (extra.isNotEmpty) extra,
    ].join(' — ');
    return (true, combined.isEmpty ? null : combined);
  }
}

class _EditScheduleSheetContent extends StatefulWidget {
  const _EditScheduleSheetContent({
    required this.initialDays,
    required this.title,
    required this.primaryLabel,
  });

  final List<CommitmentDay> initialDays;
  final String title;
  final String primaryLabel;

  @override
  State<_EditScheduleSheetContent> createState() =>
      _EditScheduleSheetContentState();
}

class _EditScheduleSheetContentState extends State<_EditScheduleSheetContent> {
  late Set<int> _weekdays;
  late Map<int, CommitmentDay> _daysByWeekday;

  @override
  void initState() {
    super.initState();
    _weekdays = widget.initialDays.map((d) => d.weekday).toSet();
    _daysByWeekday = {for (final d in widget.initialDays) d.weekday: d};
  }

  List<CommitmentDay> get _orderedDays {
    final sorted = _weekdays.toList()..sort();
    return sorted
        .map(
          (w) =>
              _daysByWeekday[w] ??
              CommitmentDay(
                weekday: w,
                startHour: 19,
                startMinute: 0,
                endHour: 20,
                endMinute: 0,
              ),
        )
        .toList();
  }

  bool get _canSave =>
      _orderedDays.isNotEmpty &&
      _orderedDays.every((d) => d.isValidSameDayRange);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          FinishXSpacing.lg,
          FinishXSpacing.lg,
          FinishXSpacing.lg,
          FinishXSpacing.lg + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.title, style: textTheme.headlineMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Completed and historical session records are always preserved.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: FinishXSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (idx) {
                  final w = idx + 1;
                  final selected = _weekdays.contains(w);
                  return FilterChip(
                    label: Text(DateTimeUtils.weekdayShortName(w)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _weekdays.remove(w);
                        } else {
                          _weekdays.add(w);
                          _daysByWeekday.putIfAbsent(
                            w,
                            () => CommitmentDay(
                              weekday: w,
                              startHour: 19,
                              startMinute: 0,
                              endHour: 20,
                              endMinute: 0,
                            ),
                          );
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: FinishXSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _orderedDays.map((day) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FinishXCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateTimeUtils.weekdayFullName(day.weekday),
                                style: textTheme.titleMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: day.startHour,
                                    minute: day.startMinute,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _daysByWeekday[day.weekday] = day.copyWith(
                                      startHour: picked.hour,
                                      startMinute: picked.minute,
                                    );
                                  });
                                }
                              },
                              child: Text(
                                DateTimeUtils.formatTimeOfDayMinutes(
                                  day.startHour,
                                  day.startMinute,
                                ),
                              ),
                            ),
                            const Text('–'),
                            TextButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: day.endHour,
                                    minute: day.endMinute,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _daysByWeekday[day.weekday] = day.copyWith(
                                      endHour: picked.hour,
                                      endMinute: picked.minute,
                                    );
                                  });
                                }
                              },
                              child: Text(
                                DateTimeUtils.formatTimeOfDayMinutes(
                                  day.endHour,
                                  day.endMinute,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: FinishXSpacing.md),
              FinishXPrimaryButton(
                label: widget.primaryLabel,
                onPressed: _canSave
                    ? () => Navigator.of(context).pop(_orderedDays)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
