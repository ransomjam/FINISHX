import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/commitment_day.dart';
import '../../domain/models/learning_resource.dart';
import '../../domain/services/commitment_calculator.dart';
import 'app_providers.dart';

class JourneyWizardDraft {
  const JourneyWizardDraft({
    required this.stepIndex,
    required this.isQueueMode,
    required this.journeyName,
    required this.category,
    required this.resourceType,
    required this.resourceName,
    required this.resourceUrl,
    required this.startsToday,
    required this.startDate,
    required this.targetCompletionDate,
    required this.selectedWeekdays,
    required this.daySchedules,
  });

  /// 0 through 6 (7 steps total).
  final int stepIndex;
  final bool isQueueMode;
  final String journeyName;
  final JourneyCategory category;
  final ResourceType resourceType;
  final String resourceName;
  final String resourceUrl;
  final bool startsToday;
  final DateTime startDate;
  final DateTime targetCompletionDate;
  final Set<int> selectedWeekdays;
  final Map<int, CommitmentDay> daySchedules;

  factory JourneyWizardDraft.initial(DateTime now, {bool isQueueMode = false}) {
    final today = DateTimeUtils.dateOnly(now);
    final defaultStart = isQueueMode
        ? today.add(const Duration(days: 14))
        : today;
    final defaultTarget = defaultStart.add(const Duration(days: 84));
    const defaultWeekdays = {
      DateTime.monday,
      DateTime.wednesday,
      DateTime.saturday,
    };

    return JourneyWizardDraft(
      stepIndex: 0,
      isQueueMode: isQueueMode,
      journeyName: '',
      category: JourneyCategory.dataScience,
      resourceType: ResourceType.coursera,
      resourceName: '',
      resourceUrl: '',
      startsToday: !isQueueMode,
      startDate: defaultStart,
      targetCompletionDate: defaultTarget,
      selectedWeekdays: defaultWeekdays,
      daySchedules: {
        for (final w in defaultWeekdays)
          w: CommitmentDay(
            weekday: w,
            startHour: w == DateTime.saturday ? 9 : 19,
            startMinute: 0,
            endHour: w == DateTime.saturday ? 11 : 20,
            endMinute: w == DateTime.saturday ? 0 : 30,
          ),
      },
    );
  }

  List<CommitmentDay> get orderedCommitmentDays {
    final days = selectedWeekdays.toList()..sort();
    return days.map((w) {
      return daySchedules[w] ??
          CommitmentDay(
            weekday: w,
            startHour: 19,
            startMinute: 0,
            endHour: 20,
            endMinute: 0,
          );
    }).toList();
  }

  LearningResource get learningResource => LearningResource(
    type: resourceType,
    name: resourceName.trim().isEmpty ? null : resourceName.trim(),
    url: resourceUrl.trim().isEmpty ? null : resourceUrl.trim(),
  );

  bool get isValidTimeline => DateTimeUtils.dateOnly(
    targetCompletionDate,
  ).isAfter(DateTimeUtils.dateOnly(startDate));

  bool get areAllDayTimesValid =>
      orderedCommitmentDays.isNotEmpty &&
      orderedCommitmentDays.every((d) => d.isValidSameDayRange);

  bool canContinueFromStep(int step) {
    return switch (step) {
      0 => journeyName.trim().length >= 3,
      1 => true,
      2 => true,
      3 => isValidTimeline,
      4 => selectedWeekdays.isNotEmpty,
      5 => areAllDayTimesValid,
      6 =>
        journeyName.trim().length >= 3 &&
            isValidTimeline &&
            areAllDayTimesValid,
      _ => false,
    };
  }

  JourneyWizardDraft copyWith({
    int? stepIndex,
    bool? isQueueMode,
    String? journeyName,
    JourneyCategory? category,
    ResourceType? resourceType,
    String? resourceName,
    String? resourceUrl,
    bool? startsToday,
    DateTime? startDate,
    DateTime? targetCompletionDate,
    Set<int>? selectedWeekdays,
    Map<int, CommitmentDay>? daySchedules,
  }) {
    return JourneyWizardDraft(
      stepIndex: stepIndex ?? this.stepIndex,
      isQueueMode: isQueueMode ?? this.isQueueMode,
      journeyName: journeyName ?? this.journeyName,
      category: category ?? this.category,
      resourceType: resourceType ?? this.resourceType,
      resourceName: resourceName ?? this.resourceName,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      startsToday: startsToday ?? this.startsToday,
      startDate: startDate ?? this.startDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      daySchedules: daySchedules ?? this.daySchedules,
    );
  }
}

class JourneyWizardController extends StateNotifier<JourneyWizardDraft> {
  JourneyWizardController(this._clock)
    : super(JourneyWizardDraft.initial(_clock()));

  final DateTime Function() _clock;

  void reset({bool isQueueMode = false}) {
    state = JourneyWizardDraft.initial(_clock(), isQueueMode: isQueueMode);
  }

  void setStep(int step) {
    state = state.copyWith(stepIndex: step.clamp(0, 6));
  }

  void nextStep() {
    if (state.canContinueFromStep(state.stepIndex) && state.stepIndex < 6) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
    }
  }

  void previousStep() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  void setJourneyName(String value) {
    state = state.copyWith(journeyName: value);
  }

  void setCategory(JourneyCategory category) {
    state = state.copyWith(category: category);
  }

  void setResourceType(ResourceType type) {
    state = state.copyWith(resourceType: type);
  }

  void setResourceName(String value) {
    state = state.copyWith(resourceName: value);
  }

  void setResourceUrl(String value) {
    state = state.copyWith(resourceUrl: value);
  }

  void setStartsToday(bool startsToday) {
    final today = DateTimeUtils.dateOnly(_clock());
    final newStart = startsToday
        ? today
        : (state.startDate.isAfter(today)
              ? state.startDate
              : today.add(const Duration(days: 7)));
    var newTarget = state.targetCompletionDate;
    if (!newTarget.isAfter(newStart)) {
      newTarget = newStart.add(const Duration(days: 60));
    }
    state = state.copyWith(
      startsToday: startsToday,
      startDate: newStart,
      targetCompletionDate: newTarget,
    );
  }

  void setStartDate(DateTime date) {
    final clean = DateTimeUtils.dateOnly(date);
    final today = DateTimeUtils.dateOnly(_clock());
    var newTarget = state.targetCompletionDate;
    if (!newTarget.isAfter(clean)) {
      newTarget = clean.add(const Duration(days: 60));
    }
    state = state.copyWith(
      startsToday: DateTimeUtils.isSameDay(clean, today),
      startDate: clean,
      targetCompletionDate: newTarget,
    );
  }

  void setTargetDate(DateTime date) {
    state = state.copyWith(targetCompletionDate: DateTimeUtils.dateOnly(date));
  }

  void toggleWeekday(int weekday) {
    final nextSet = Set<int>.from(state.selectedWeekdays);
    final nextMap = Map<int, CommitmentDay>.from(state.daySchedules);
    if (nextSet.contains(weekday)) {
      nextSet.remove(weekday);
    } else {
      nextSet.add(weekday);
      nextMap.putIfAbsent(
        weekday,
        () => CommitmentDay(
          weekday: weekday,
          startHour: 19,
          startMinute: 0,
          endHour: 20,
          endMinute: 0,
        ),
      );
    }
    state = state.copyWith(selectedWeekdays: nextSet, daySchedules: nextMap);
  }

  void updateDayTime({
    required int weekday,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    final nextMap = Map<int, CommitmentDay>.from(state.daySchedules);
    final current =
        nextMap[weekday] ??
        CommitmentDay(
          weekday: weekday,
          startHour: 19,
          startMinute: 0,
          endHour: 20,
          endMinute: 0,
        );
    nextMap[weekday] = current.copyWith(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    state = state.copyWith(daySchedules: nextMap);
  }

  ScheduleSummaryMetrics computeSummaryMetrics() {
    return const CommitmentCalculator().calculateScheduleMetrics(
      state.orderedCommitmentDays,
    );
  }
}

final journeyWizardProvider =
    StateNotifierProvider<JourneyWizardController, JourneyWizardDraft>(
      (ref) => JourneyWizardController(ref.watch(clockProvider)),
    );
