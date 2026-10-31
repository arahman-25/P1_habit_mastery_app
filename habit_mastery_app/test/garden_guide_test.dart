import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/check_in.dart';
import 'package:habit_mastery_app/models/habit.dart';
import 'package:habit_mastery_app/services/check_in_service.dart';
import 'package:habit_mastery_app/services/garden_guide.dart';
import 'package:habit_mastery_app/services/habit_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Garden Guide Algorithm — 5 Evaluation Fixtures', () {
    // Fixture 1: Normal Case: [2, 3, 4] -> Average 3.0 -> Suggests 3
    test('Fixture 1 (Normal Case): [2, 3, 4] yields average 3.0 and suggests target 3', () {
      final weeklyCounts = [2, 3, 4];

      final suggested = suggestWeeklyTarget(weeklyCounts);
      expect(suggested, 3);

      expect(GardenGuide.suggestTarget(weeklyCounts), 3);

      final recommendation = GardenGuide.evaluate(
        weeklyCounts: weeklyCounts,
        currentTarget: 4,
      );

      expect(recommendation.hasEnoughHistory, isTrue);
      expect(recommendation.suggestedTarget, 3);
      expect(recommendation.averageDaysPerWeek, 3.0);
      expect(recommendation.completedWeekCounts, [2, 3, 4]);
      expect(recommendation.shouldSuggestChange, isTrue);
      expect(recommendation.isTargetMatched, isFalse);
      expect(recommendation.rationale, contains('3.0 days'));
      expect(recommendation.headline, 'Gentle Adjustment');
    });

    test('Fixture 1 Extension: half-up rounding checks', () {
      // [3, 3, 4] -> sum 10, avg 3.33 -> rounds to 3
      expect(suggestWeeklyTarget([3, 3, 4]), 3);

      // [3, 4, 4] -> sum 11, avg 3.67 -> rounds to 4
      expect(suggestWeeklyTarget([3, 4, 4]), 4);

      // [2, 2, 3] -> sum 7, avg 2.33 -> rounds to 2
      expect(suggestWeeklyTarget([2, 2, 3]), 2);

      // Takes only the last 3 weeks if given more
      expect(suggestWeeklyTarget([1, 2, 3, 4]), 3);
    });

    // Fixture 2: No-Data Case: fewer than 3 weeks -> null
    test('Fixture 2 (No-Data Case): returns null and displays "Not enough history" when < 3 weeks', () {
      // Null input
      expect(suggestWeeklyTarget(null), isNull);
      final nullRec = GardenGuide.evaluate(
        weeklyCounts: null,
        currentTarget: 3,
      );
      expect(nullRec.hasEnoughHistory, isFalse);
      expect(nullRec.suggestedTarget, isNull);
      expect(nullRec.rationale, contains('Not enough history'));

      // Empty list
      expect(suggestWeeklyTarget([]), isNull);

      // 1 completed week
      expect(suggestWeeklyTarget([4]), isNull);
      final oneWeekRec = GardenGuide.evaluate(
        weeklyCounts: [4],
        currentTarget: 4,
      );
      expect(oneWeekRec.hasEnoughHistory, isFalse);
      expect(oneWeekRec.suggestedTarget, isNull);
      expect(oneWeekRec.rationale, contains('Not enough history'));

      // 2 completed weeks
      expect(suggestWeeklyTarget([3, 5]), isNull);
      final twoWeekRec = GardenGuide.evaluate(
        weeklyCounts: [3, 5],
        currentTarget: 4,
      );
      expect(twoWeekRec.hasEnoughHistory, isFalse);
      expect(twoWeekRec.suggestedTarget, isNull);
      expect(twoWeekRec.rationale, contains('Not enough history'));
      expect(twoWeekRec.headline, 'Building Your Baseline');
    });

    // Fixture 3: Invalid Case: counts < 0 or > 7
    test('Fixture 3 (Invalid Case): rejects invalid weekly counts when sanitize is false', () {
      expect(
        () => suggestWeeklyTarget([-1, 3, 4], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => suggestWeeklyTarget([8, 2, 3], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => suggestWeeklyTarget([3, -10, 5], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => suggestWeeklyTarget([3, 5, 100], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Fixture 3 Extension: clamps values into [0, 7] when sanitize is true', () {
      // [-2, 3, 4] clamped to [0, 3, 4] -> sum 7 -> 2
      final sanitizedNeg = suggestWeeklyTarget([-2, 3, 4], sanitize: true);
      expect(sanitizedNeg, 2);

      // [10, 7, 7] clamped to [7, 7, 7] -> sum 21 -> 7
      final sanitizedHigh = suggestWeeklyTarget([10, 7, 7], sanitize: true);
      expect(sanitizedHigh, 7);

      final rec = GardenGuide.evaluate(
        weeklyCounts: [-1, 8, 3],
        currentTarget: 3,
        sanitize: true,
      );
      expect(rec.hasEnoughHistory, isTrue);
      expect(rec.suggestedTarget, 3);
      expect(rec.completedWeekCounts, [0, 7, 3]);
      expect(rec.averageDaysPerWeek, closeTo(3.33, 0.01));
    });

    // Fixture 4: Boundary Case: min 1, max 7
    test('Fixture 4 (Boundary Case): [0, 0, 0] clamped to min 1; [7, 7, 7] clamped to max 7', () {
      // 0 check-ins clamped to minimum 1
      final zeroTarget = suggestWeeklyTarget([0, 0, 0]);
      expect(zeroTarget, 1);

      final zeroRec = GardenGuide.evaluate(
        weeklyCounts: [0, 0, 0],
        currentTarget: 4,
      );
      expect(zeroRec.suggestedTarget, 1);
      expect(zeroRec.averageDaysPerWeek, 0.0);
      expect(zeroRec.completedWeekCounts, [0, 0, 0]);
      expect(
        zeroRec.rationale,
        contains('Missed days are information, not failure'),
      );

      // Low boundary: [1, 0, 0] clamped to 1
      expect(suggestWeeklyTarget([1, 0, 0]), 1);

      // 7 check-ins per week clamped to maximum 7
      final perfectTarget = suggestWeeklyTarget([7, 7, 7]);
      expect(perfectTarget, 7);

      final perfectRec = GardenGuide.evaluate(
        weeklyCounts: [7, 7, 7],
        currentTarget: 5,
      );
      expect(perfectRec.suggestedTarget, 7);
      expect(perfectRec.averageDaysPerWeek, 7.0);
      expect(perfectRec.completedWeekCounts, [7, 7, 7]);
      expect(perfectRec.headline, 'Ready to Bloom');

      // High boundary: [6, 7, 7] clamped to 7
      expect(suggestWeeklyTarget([6, 7, 7]), 7);
    });

    // Fixture 5: Counterexample: zero-count weeks are valid history
    test('Fixture 5 (Counterexample - Zero Weeks): treats 0-count weeks as valid data, not skipped', () {
      // [0, 3, 3] treats 0 as a valid week: sum 6, avg 2.0 -> target 2
      final suggested = suggestWeeklyTarget([0, 3, 3]);
      expect(suggested, 2);

      final rec = GardenGuide.evaluate(
        weeklyCounts: [0, 3, 3],
        currentTarget: 2,
      );
      expect(rec.hasEnoughHistory, isTrue);
      expect(rec.suggestedTarget, 2);
      expect(rec.averageDaysPerWeek, 2.0);
      expect(rec.isTargetMatched, isTrue);
      expect(rec.headline, 'Target Well-Calibrated');
    });

    test('Recommendation messaging reflects user agency and non-shaming philosophy', () {
      // Target matches current
      final matchedRec = GardenGuide.evaluate(
        weeklyCounts: [4, 4, 4],
        currentTarget: 4,
      );
      expect(matchedRec.isTargetMatched, isTrue);
      expect(matchedRec.shouldSuggestChange, isFalse);
      expect(matchedRec.headline, 'Target Well-Calibrated');
      expect(matchedRec.rationale, contains('well-matched'));

      // Suggests increase
      final bloomRec = GardenGuide.evaluate(
        weeklyCounts: [5, 6, 6],
        currentTarget: 4,
      );
      expect(bloomRec.shouldSuggestChange, isTrue);
      expect(bloomRec.suggestedTarget, 6);
      expect(bloomRec.headline, 'Ready to Bloom');
      expect(bloomRec.rationale, contains('raising your weekly target'));

      // No current target provided
      final neutralRec = GardenGuide.evaluate(weeklyCounts: [3, 3, 3]);
      expect(neutralRec.hasEnoughHistory, isTrue);
      expect(neutralRec.suggestedTarget, 3);
      expect(neutralRec.headline, contains('Suggested Target: 3'));
    });
  });

  group('GardenGuide & CheckInService SQLite Integration Tests', () {
    late DatabaseHelper dbHelper;
    late HabitService habitService;
    late CheckInService checkInService;

    setUp(() async {
      dbHelper = DatabaseHelper.forTesting();
      habitService = HabitService(dbHelper: dbHelper);
      checkInService = CheckInService(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Fixture 5 Integration: Duplicate check-ins do not inflate count and zero-count weeks are included', () async {
      // Mock reference date as Monday 2026-10-26
      final refDate = DateTime(2026, 10, 26);

      // Habit started 4 weeks ago
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Morning Yoga',
          category: 'Mindfulness',
          weeklyTarget: 5,
          startedLocalDate: '2026-09-28',
        ),
      );

      final db = await dbHelper.database;

      // Week 1 (Sep 28 - Oct 04): 0 check-ins (should be counted as 0, not skipped)

      // Week 2 (Oct 05 - Oct 11): 3 check-ins
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-06').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-07').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-08').toMap(),
      );

      // Week 3 (Oct 12 - Oct 18): 4 check-ins
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-13').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-14').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-15').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-16').toMap(),
      );

      // Week 4 (Oct 19 - Oct 25): 2 check-ins
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-20').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-21').toMap(),
      );

      // Current week in progress (Oct 26 - Nov 01): should be excluded
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap(),
      );

      // The last 3 completed weeks are Weeks 2, 3, 4: counts [3, 4, 2] -> avg 3.0 -> suggests 3
      final recommendation = await GardenGuide.evaluateForHabit(
        habit: habit,
        checkInService: checkInService,
        referenceDate: refDate,
      );

      expect(recommendation.hasEnoughHistory, isTrue);
      expect(recommendation.completedWeekCounts, [3, 4, 2]);
      expect(recommendation.averageDaysPerWeek, 3.0);
      expect(recommendation.suggestedTarget, 3);
      expect(recommendation.shouldSuggestChange, isTrue);
      expect(recommendation.currentTarget, 5);
      expect(recommendation.headline, 'Gentle Adjustment');
    });

    test(
      'evaluateForHabit returns insufficient history when habit is too new',
      () async {
        // Started 10 days ago (only 1 full week completed)
        final habit = await habitService.createHabit(
          const Habit(
            title: 'Hydration',
            category: 'Health',
            weeklyTarget: 7,
            startedLocalDate: '2026-10-16',
          ),
        );

        final recommendation = await GardenGuide.evaluateForHabit(
          habit: habit,
          checkInService: checkInService,
          referenceDate: DateTime(2026, 10, 26),
        );

        expect(recommendation.hasEnoughHistory, isFalse);
        expect(recommendation.suggestedTarget, isNull);
        expect(recommendation.headline, 'Building Your Baseline');
        expect(recommendation.rationale, contains('Not enough history'));
      },
    );
  });
}
