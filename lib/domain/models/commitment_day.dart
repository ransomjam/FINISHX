/// Represents a recurring weekly session commitment on a specific day of week.
class CommitmentDay {
  const CommitmentDay({
    required this.weekday,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  }) : assert(weekday >= 1 && weekday <= 7);

  /// ISO weekday: 1 (Monday) through 7 (Sunday).
  final int weekday;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  int get startTotalMinutes => startHour * 60 + startMinute;
  int get endTotalMinutes => endHour * 60 + endMinute;

  /// Duration in minutes. Supports commitments crossing midnight if end < start,
  /// though wizard validation encourages same-day end > start.
  int get durationMinutes {
    final diff = endTotalMinutes - startTotalMinutes;
    if (diff > 0) return diff;
    return (24 * 60 - startTotalMinutes) + endTotalMinutes;
  }

  bool get isValidSameDayRange => endTotalMinutes > startTotalMinutes;

  CommitmentDay copyWith({
    int? weekday,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return CommitmentDay(
      weekday: weekday ?? this.weekday,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
  };

  factory CommitmentDay.fromJson(Map<String, dynamic> json) => CommitmentDay(
    weekday: json['weekday'] as int,
    startHour: json['startHour'] as int,
    startMinute: json['startMinute'] as int,
    endHour: json['endHour'] as int,
    endMinute: json['endMinute'] as int,
  );
}
