import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Timezone-aware local date and time formatting utilities.
abstract final class DateTimeUtils {
  static DateTime dateOnly(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Start of the ISO week (Monday 00:00 local time).
  static DateTime startOfWeek(DateTime dt) {
    final day = dateOnly(dt);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// End of the ISO week (Sunday 23:59:59 local time).
  static DateTime endOfWeek(DateTime dt) {
    final start = startOfWeek(dt);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
  }

  static String greetingForTime(DateTime now) {
    final hour = now.toLocal().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatMediumDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('MMM d').format(dt.toLocal());
  }

  static String formatFullDayDate(DateTime dt) {
    return DateFormat('EEEE, MMM d').format(dt.toLocal());
  }

  static String formatRelativeDateTime(DateTime dt, DateTime now) {
    final local = dt.toLocal();
    final localNow = now.toLocal();
    final diff = localNow.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatMediumDate(local);
  }

  static String formatTimeOfDayMinutes(int hour, int minute) {
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  static String formatTimeRange(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    return '${formatTimeOfDayMinutes(startHour, startMinute)} – '
        '${formatTimeOfDayMinutes(endHour, endMinute)}';
  }

  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  static String formatCountdown(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Ready now';
    }
    if (remaining.inDays >= 2) {
      return 'In ${remaining.inDays} days';
    }
    if (remaining.inHours >= 24) {
      final hours = remaining.inHours - 24;
      return hours > 0 ? 'In 1d ${hours}h' : 'Tomorrow';
    }
    if (remaining.inHours >= 1) {
      final mins = remaining.inMinutes % 60;
      return mins > 0
          ? 'Starts in ${remaining.inHours}h ${mins}m'
          : 'Starts in ${remaining.inHours}h';
    }
    final mins = remaining.inMinutes;
    return mins <= 1 ? 'Starting in <1 min' : 'Starts in $mins min';
  }

  static String weekdayFullName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Day',
    };
  }

  static String weekdayShortName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => 'Day',
    };
  }

  static TimeOfDay toTimeOfDay(int hour, int minute) =>
      TimeOfDay(hour: hour, minute: minute);
}
