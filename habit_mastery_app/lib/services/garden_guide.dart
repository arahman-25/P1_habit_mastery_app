import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import 'check_in_service.dart';

/// Suggests a weekly habit target (1-7 days) based on the last 3 completed weeks.
/// Returns null if there are fewer than 3 completed weeks of history.
int? suggestWeeklyTarget(List<int>? weeklyCounts, {bool sanitize = false}) {
  if (weeklyCounts == null || weeklyCounts.length < 3) {
    return null;
  }

  // Look at the last 3 full weeks
  final recentCounts = weeklyCounts.sublist(weeklyCounts.length - 3);

  final List<int> processedCounts;
  if (sanitize) {
    processedCounts = recentCounts.map((c) => c.clamp(0, 7)).toList();
  } else {
    for (final c in recentCounts) {
      if (c < 0 || c > 7) {
        throw ArgumentError.value(
          c,
          'weeklyCounts',
          'Weekly check-in count must be between 0 and 7 days (received $c).',
        );
      }
    }
    processedCounts = recentCounts;
  }

  final sum = processedCounts.fold<int>(0, (acc, val) => acc + val);
  final rawTarget = ((sum + 1) / 3).floor();
  return rawTarget.clamp(1, 7);
}

/// Holds the suggested target and explanation copy for the recommendation card.
@immutable
class GardenGuideRecommendation {
  final int? suggestedTarget;
  final int? currentTarget;
  final double? averageDaysPerWeek;
  final List<int> completedWeekCounts;
  final bool hasEnoughHistory;
  final String headline;
  final String rationale;

  const GardenGuideRecommendation({
    required this.suggestedTarget,
    required this.currentTarget,
    required this.averageDaysPerWeek,
    required this.completedWeekCounts,
    required this.hasEnoughHistory,
    required this.headline,
    required this.rationale,
  });

  bool get shouldSuggestChange =>
      hasEnoughHistory &&
      suggestedTarget != null &&
      currentTarget != null &&
      suggestedTarget != currentTarget;

  bool get isTargetMatched =>
      hasEnoughHistory &&
      suggestedTarget != null &&
      currentTarget != null &&
      suggestedTarget == currentTarget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GardenGuideRecommendation &&
          runtimeType == other.runtimeType &&
          suggestedTarget == other.suggestedTarget &&
          currentTarget == other.currentTarget &&
          averageDaysPerWeek == other.averageDaysPerWeek &&
          listEquals(completedWeekCounts, other.completedWeekCounts) &&
          hasEnoughHistory == other.hasEnoughHistory &&
          headline == other.headline &&
          rationale == other.rationale;

  @override
  int get hashCode => Object.hash(
    suggestedTarget,
    currentTarget,
    averageDaysPerWeek,
    Object.hashAll(completedWeekCounts),
    hasEnoughHistory,
    headline,
    rationale,
  );

  @override
  String toString() =>
      'GardenGuideRecommendation(suggestedTarget: $suggestedTarget, currentTarget: $currentTarget, '
      'average: $averageDaysPerWeek, hasEnoughHistory: $hasEnoughHistory)';
}

/// Evaluates weekly check-in trends to suggest target adjustments.
class GardenGuide {
  const GardenGuide._();

  static const int requiredCompletedWeeks = 3;

  /// Pure helper calculation for weekly target.
  static int? suggestTarget(List<int>? weeklyCounts, {bool sanitize = false}) {
    return suggestWeeklyTarget(weeklyCounts, sanitize: sanitize);
  }

  /// Calculates a target recommendation from a list of weekly check-in counts.
  static GardenGuideRecommendation evaluate({
    required List<int>? weeklyCounts,
    int? currentTarget,
    bool sanitize = false,
  }) {
    final suggested = suggestWeeklyTarget(weeklyCounts, sanitize: sanitize);

    if (suggested == null ||
        weeklyCounts == null ||
        weeklyCounts.length < requiredCompletedWeeks) {
      return GardenGuideRecommendation(
        suggestedTarget: null,
        currentTarget: currentTarget,
        averageDaysPerWeek: null,
        completedWeekCounts: weeklyCounts ?? const [],
        hasEnoughHistory: false,
        headline: 'Building Your Baseline',
        rationale: 'Not enough history. Practice for at least 3 full calendar weeks to receive smart target recommendations.',
      );
    }

    final recentCounts = weeklyCounts.sublist(
      weeklyCounts.length - requiredCompletedWeeks,
    );
    final processedCounts = sanitize
        ? recentCounts.map((c) => c.clamp(0, 7)).toList()
        : recentCounts;

    final sum = processedCounts.fold<int>(0, (acc, val) => acc + val);
    final average = sum / requiredCompletedWeeks;
    final averageStr = average.toStringAsFixed(1);

    final String headline;
    final String rationale;

    if (currentTarget != null && suggested == currentTarget) {
      headline = 'Target Well-Calibrated';
      rationale =
          'You practiced an average of $averageStr days over the last 3 full weeks. '
          'Your current target of $currentTarget days is well-matched to your routine.';
    } else if (currentTarget != null && suggested > currentTarget) {
      headline = 'Ready to Bloom';
      rationale =
          'You practiced an average of $averageStr days over the last 3 full weeks. '
          'Consider raising your weekly target to $suggested days to match your momentum.';
    } else if (currentTarget != null && suggested < currentTarget) {
      headline = 'Gentle Adjustment';
      rationale =
          'You practiced an average of $averageStr days over the last 3 full weeks. '
          'Adjusting your target to $suggested days can help maintain steady rhythm without burnout. '
          'Missed days are information, not failure.';
    } else {
      headline = 'Suggested Target: $suggested days/week';
      rationale =
          'Based on an average of $averageStr practice days over the last 3 full weeks, '
          'a target of $suggested days per week fits your current momentum.';
    }

    return GardenGuideRecommendation(
      suggestedTarget: suggested,
      currentTarget: currentTarget,
      averageDaysPerWeek: average,
      completedWeekCounts: List.unmodifiable(processedCounts),
      hasEnoughHistory: true,
      headline: headline,
      rationale: rationale,
    );
  }

  /// Pulls the last 3 completed weeks of check-ins for a habit and evaluates them.
  static Future<GardenGuideRecommendation> evaluateForHabit({
    required Habit habit,
    required CheckInService checkInService,
    DateTime? referenceDate,
    bool sanitize = false,
  }) async {
    final counts = await checkInService.getPastCompletedWeeksCheckInCounts(
      habit,
      weekCount: requiredCompletedWeeks,
      referenceDate: referenceDate,
    );

    return evaluate(
      weeklyCounts: counts,
      currentTarget: habit.weeklyTarget,
      sanitize: sanitize,
    );
  }
}
