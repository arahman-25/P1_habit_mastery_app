import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import 'check_in_service.dart';

/// Pure Dart calculation function for suggesting weekly habit targets.
///
/// Implements Section 7 of AGENTS.md ("Garden Guide" Smart Helper Specification):
/// - Method: Deterministic Rule-Based History Target Estimator.
/// - 100% offline, local, deterministic, and cloud-free.
/// - Requires at least 3 completed Monday–Sunday weeks. Returns null if fewer than 3.
/// - Uses the last 3 completed weeks:
///   Target = clamp(floor((Sum(Counts_1..3) + 1) / 3), 1, 7)
/// - When [sanitize] is true, weekly counts outside [0, 7] are clamped into [0, 7].
/// - When [sanitize] is false, weekly counts outside [0, 7] throw [ArgumentError].
int? suggestWeeklyTarget(List<int>? weeklyCounts, {bool sanitize = false}) {
  if (weeklyCounts == null || weeklyCounts.length < 3) {
    return null;
  }

  // Use the last 3 whole completed weeks
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

/// Structured outcome of a Garden Guide evaluation.
///
/// Contains the calculated suggestion, historical averages, and non-shaming,
/// transparent rationales for the UI recommendation card.
@immutable
class GardenGuideRecommendation {
  /// The recommended weekly target bounded between 1 and 7, or null if insufficient history.
  final int? suggestedTarget;

  /// The user's active habit weekly target, if provided.
  final int? currentTarget;

  /// The arithmetic mean of check-in counts over the evaluated weeks.
  final double? averageDaysPerWeek;

  /// The chronological list of weekly counts used in the calculation (last 3 completed weeks).
  final List<int> completedWeekCounts;

  /// Whether at least 3 completed weeks were available for evaluation.
  final bool hasEnoughHistory;

  /// Short summary headline for the recommendation card.
  final String headline;

  /// Detailed, transparent explanation of how the recommendation was derived.
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

  /// Whether the helper recommends a change to the user's active target.
  bool get shouldSuggestChange =>
      hasEnoughHistory &&
      suggestedTarget != null &&
      currentTarget != null &&
      suggestedTarget != currentTarget;

  /// Whether the user's current target already perfectly matches the recommendation.
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

/// Garden Guide smart helper service.
///
/// Provides evaluation algorithms and convenience bridges connecting
/// [CheckInService] historical data to transparent recommendations.
class GardenGuide {
  const GardenGuide._();

  /// The number of completed calendar weeks required before generating recommendations.
  static const int requiredCompletedWeeks = 3;

  /// Delegates to the pure calculation [suggestWeeklyTarget].
  static int? suggestTarget(List<int>? weeklyCounts, {bool sanitize = false}) {
    return suggestWeeklyTarget(weeklyCounts, sanitize: sanitize);
  }

  /// Evaluates weekly check-in counts and produces a [GardenGuideRecommendation].
  ///
  /// Adheres to Section 7 core principles:
  /// - Honest labeling as a rule-based algorithm.
  /// - Non-shaming copy: "Missed days are information, not failure."
  /// - Transparent calculation showing the 3-week average.
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

  /// Evaluates historical check-ins for a given [habit] using [checkInService].
  ///
  /// Automatically fetches distinct counts from the last 3 completed calendar weeks,
  /// excluding partial weeks and the current in-progress week.
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
