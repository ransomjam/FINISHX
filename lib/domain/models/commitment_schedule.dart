import 'commitment_day.dart';

class CommitmentSchedule {
  const CommitmentSchedule({
    required this.id,
    required this.days,
    required this.effectiveFrom,
  });

  final String id;
  final List<CommitmentDay> days;
  final DateTime effectiveFrom;

  List<CommitmentDay> get sortedDays {
    final copy = List<CommitmentDay>.from(days);
    copy.sort((a, b) => a.weekday.compareTo(b.weekday));
    return copy;
  }

  int get weeklySessionsCount => days.length;

  int get totalWeeklyMinutes =>
      days.fold(0, (sum, day) => sum + day.durationMinutes);

  double get totalWeeklyHours => totalWeeklyMinutes / 60.0;

  CommitmentDay? dayForWeekday(int weekday) {
    for (final d in days) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }

  CommitmentSchedule copyWith({
    String? id,
    List<CommitmentDay>? days,
    DateTime? effectiveFrom,
  }) {
    return CommitmentSchedule(
      id: id ?? this.id,
      days: days ?? this.days,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'days': days.map((d) => d.toJson()).toList(),
    'effectiveFrom': effectiveFrom.toIso8601String(),
  };

  factory CommitmentSchedule.fromJson(Map<String, dynamic> json) =>
      CommitmentSchedule(
        id: json['id'] as String,
        days: (json['days'] as List<dynamic>)
            .map((e) => CommitmentDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      );
}
