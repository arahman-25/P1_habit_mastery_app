import 'package:flutter/foundation.dart';

/// Calendar and date utility functions adhering to local device time policies.
///
/// Section 5 of AGENTS.md:
/// - Dates are formatted strictly as 'YYYY-MM-DD' strings in local device time.
/// - Calendar weeks are defined from Monday 00:00:00 to Sunday 23:59:59.
/// - For any date D, Monday = D - (D.weekday - 1) days, Sunday = Monday + 6 days.
@immutable
class CalendarUtils {
  const CalendarUtils._();

  static final RegExp _isoDateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Formats a [DateTime] into a local 'YYYY-MM-DD' string.
  /// Uses local device time fields directly to avoid UTC day boundary shifts.
  static String formatLocalDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses a 'YYYY-MM-DD' string into a local [DateTime] at 00:00:00 local time.
  /// Throws [FormatException] if the string is not a valid ISO date.
  static DateTime parseLocalDate(String dateString) {
    if (!_isoDateRegex.hasMatch(dateString)) {
      throw FormatException('Invalid date format. Expected YYYY-MM-DD: $dateString');
    }
    final parts = dateString.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) {
      throw FormatException('Invalid calendar date: $dateString');
    }
    return dt;
  }

  /// Validates if a string is a valid 'YYYY-MM-DD' calendar date.
  static bool isValidLocalDate(String dateString) {
    if (!_isoDateRegex.hasMatch(dateString)) return false;
    try {
      final parts = dateString.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final dt = DateTime(year, month, day);
      return dt.year == year && dt.month == month && dt.day == day;
    } catch (_) {
      return false;
    }
  }

  /// Returns the Monday of the calendar week containing [date].
  /// Monday is day 1 of the calendar week (Monday–Sunday) per ISO 8601 & AGENTS.md.
  /// Uses integer date arithmetic to remain immune to daylight saving shifts.
  static DateTime getMondayOfWeek(DateTime date) {
    final offset = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - offset);
  }

  /// Returns the Sunday of the calendar week containing [date].
  static DateTime getSundayOfWeek(DateTime date) {
    final monday = getMondayOfWeek(date);
    return DateTime(monday.year, monday.month, monday.day + 6);
  }

  /// Returns the Monday date string ('YYYY-MM-DD') for the week containing [date].
  static String getMondayString(DateTime date) {
    return formatLocalDate(getMondayOfWeek(date));
  }

  /// Returns the Sunday date string ('YYYY-MM-DD') for the week containing [date].
  static String getSundayString(DateTime date) {
    return formatLocalDate(getSundayOfWeek(date));
  }

  /// Checks if [dateStr] is within the inclusive range [startStr] .. [endStr].
  static bool isDateInRange(String dateStr, String startStr, String endStr) {
    return dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0;
  }

  /// Calculates the visual plant tier based on the completion rate.
  /// - Tier 0 (0%): Seed in soil
  /// - Tier 1 (1% – 49%): Sprout
  /// - Tier 2 (50% – 99%): Growing bud
  /// - Tier 3 (>= 100%): Full bloom
  static int calculatePlantTier(double completionRate) {
    if (completionRate <= 0.0) return 0;
    if (completionRate < 0.50) return 1;
    if (completionRate < 1.0) return 2;
    return 3;
  }

  /// Returns the friendly plant stage label for a given plant tier.
  static String getPlantStageName(int tier) {
    switch (tier) {
      case 0:
        return 'Seed in soil';
      case 1:
        return 'Sprout';
      case 2:
        return 'Growing bud';
      case 3:
        return 'Full bloom';
      default:
        return 'Unknown';
    }
  }
}
