import 'package:flutter/foundation.dart';
import 'habit.dart';

/// Derived model representing the dynamically computed weekly progress of a habit.
///
/// Section 4 & 5 of AGENTS.md:
/// - Plant growth states and weekly percentages are derived dynamically
///   from SQLite rows and are NEVER stored as separate database entities.
/// - The numeric completion rate is always accessible (e.g. "3/4 days (75%)").
@immutable
class HabitWeeklyProgress {
  final Habit habit;
  final String weekStartLocalDate; // YYYY-MM-DD Monday
  final String weekEndLocalDate;   // YYYY-MM-DD Sunday
  final int completedDays;         // Distinct completed dates in week
  final int targetDays;            // habit.weeklyTarget
  final double completionRate;     // completedDays / targetDays
  final int plantTier;             // 0..3
  final String plantStageName;     // 'Seed in soil', 'Sprout', 'Growing bud', 'Full bloom'
  final List<String> completedDates;

  const HabitWeeklyProgress({
    required this.habit,
    required this.weekStartLocalDate,
    required this.weekEndLocalDate,
    required this.completedDays,
    required this.targetDays,
    required this.completionRate,
    required this.plantTier,
    required this.plantStageName,
    required this.completedDates,
  });

  /// Formatted numeric display string, e.g. "3/4 days (75%)"
  String get displayProgress {
    final percent = (completionRate * 100).round();
    return '$completedDays/$targetDays days ($percent%)';
  }

  /// Whether the weekly goal has been achieved or exceeded
  bool get isGoalMet => completedDays >= targetDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitWeeklyProgress &&
          runtimeType == other.runtimeType &&
          habit == other.habit &&
          weekStartLocalDate == other.weekStartLocalDate &&
          weekEndLocalDate == other.weekEndLocalDate &&
          completedDays == other.completedDays &&
          targetDays == other.targetDays &&
          completionRate == other.completionRate &&
          plantTier == other.plantTier &&
          plantStageName == other.plantStageName &&
          listEquals(completedDates, other.completedDates);

  @override
  int get hashCode =>
      habit.hashCode ^
      weekStartLocalDate.hashCode ^
      weekEndLocalDate.hashCode ^
      completedDays.hashCode ^
      targetDays.hashCode ^
      completionRate.hashCode ^
      plantTier.hashCode ^
      plantStageName.hashCode ^
      completedDates.hashCode;

  @override
  String toString() {
    return 'HabitWeeklyProgress(habit: ${habit.title}, week: $weekStartLocalDate..$weekEndLocalDate, progress: $displayProgress, tier: $plantTier)';
  }
}
