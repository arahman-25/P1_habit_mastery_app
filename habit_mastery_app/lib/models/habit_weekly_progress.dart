import 'package:flutter/foundation.dart';
import 'habit.dart';

/// Holds computed weekly progress for a habit.
@immutable
class HabitWeeklyProgress {
  final Habit habit;
  final String weekStartLocalDate; // Monday YYYY-MM-DD
  final String weekEndLocalDate;   // Sunday YYYY-MM-DD
  final int completedDays;
  final int targetDays;
  final double completionRate;
  final int plantTier;             // 0..3
  final String plantStageName;
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

  /// Display string like "3/4 days (75%)"
  String get displayProgress {
    final percent = (completionRate * 100).round();
    return '$completedDays/$targetDays days ($percent%)';
  }

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
