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

  group('Garden Guide Pure Dart Algorithm — 5 Mandatory Evaluation Fixtures', () {
    // -------------------------------------------------------------------------
    // Fixture 1: Normal Case
    // AGENTS.md Section 7: Completed week counts [2, 3, 4] -> Average 3.0 -> Suggests 3.
    // -------------------------------------------------------------------------
    test('Fixture 1 (Normal Case): [2, 3, 4] yields average 3.0 and suggests target 3', () {
      final weeklyCounts = [2, 3, 4];

      // Pure function call
      final suggested = suggestWeeklyTarget(weeklyCounts);
      expect(suggested, 3);

      // Delegated call on GardenGuide
      expect(GardenGuide.suggestTarget(weeklyCounts), 3);

      // Recommendation details
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

    test('Fixture 1 Extension (Normal Rounding): half-up rounding checks', () {
      // Counts [3, 3, 4] -> Sum = 10, Avg = 3.33 -> floor((10+1)/3) = floor(3.67) = 3
      expect(suggestWeeklyTarget([3, 3, 4]), 3);

      // Counts [3, 4, 4] -> Sum = 11, Avg = 3.67 -> floor((11+1)/3) = floor(4.0) = 4
      expect(suggestWeeklyTarget([3, 4, 4]), 4);

      // Counts [2, 2, 3] -> Sum = 7, Avg = 2.33 -> floor((7+1)/3) = floor(2.67) = 2
      expect(suggestWeeklyTarget([2, 2, 3]), 2);

      // Uses last 3 weeks if more than 3 are passed
      expect(suggestWeeklyTarget([1, 2, 3, 4]), 3); // last 3 are [2, 3, 4]
    });

    // -------------------------------------------------------------------------
    // Fixture 2: No-Data / Insufficient History Case
    // AGENTS.md Section 7: Habit created last week (< 3 completed weeks) -> returns null / "Not enough history"
    // -------------------------------------------------------------------------
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

      // Empty list (0 completed weeks)
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

    // -------------------------------------------------------------------------
    // Fixture 3: Invalid Case
    // AGENTS.md Section 7: Counts containing negative numbers or values > 7 are rejected or sanitized.
    // -------------------------------------------------------------------------
    test('Fixture 3 (Invalid Case): rejects invalid weekly counts when sanitize is false', () {
      // Negative count rejected
      expect(
        () => suggestWeeklyTarget([-1, 3, 4], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );

      // Value > 7 rejected
      expect(
        () => suggestWeeklyTarget([8, 2, 3], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );

      // Extreme values rejected
      expect(
        () => suggestWeeklyTarget([3, -10, 5], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => suggestWeeklyTarget([3, 5, 100], sanitize: false),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Fixture 3 Extension (Invalid Sanitization): clamps values into [0, 7] when sanitize is true', () {
      // Negative count [-2, 3, 4] sanitized to [0, 3, 4] -> Sum = 7 -> floor((7+1)/3) = 2
      final sanitizedNeg = suggestWeeklyTarget([-2, 3, 4], sanitize: true);
      expect(sanitizedNeg, 2);

      // Value > 7 [10, 7, 7] sanitized to [7, 7, 7] -> Sum = 21 -> floor((21+1)/3) = 7
      final sanitizedHigh = suggestWeeklyTarget([10, 7, 7], sanitize: true);
      expect(sanitizedHigh, 7);

      // Recommendation with sanitization
      final rec = GardenGuide.evaluate(
        weeklyCounts: [-1, 8, 3],
        currentTarget: 3,
        sanitize: true,
      );
      // Sanitized to [0, 7, 3] -> sum = 10 -> (10+1)~/3 = 3
      expect(rec.hasEnoughHistory, isTrue);
      expect(rec.suggestedTarget, 3);
      expect(rec.completedWeekCounts, [0, 7, 3]);
      expect(rec.averageDaysPerWeek, closeTo(3.33, 0.01));
    });

    // -------------------------------------------------------------------------
    // Fixture 4: Boundary Case
    // AGENTS.md Section 7: Three zero-practice weeks [0, 0, 0] -> clamped to 1.
    //                      Three perfect weeks [7, 7, 7] -> clamped to 7.
    // -------------------------------------------------------------------------
    test('Fixture 4 (Boundary Case): [0, 0, 0] clamped to min 1; [7, 7, 7] clamped to max 7', () {
      // Three zero-practice weeks: Sum = 0, floor((0+1)/3) = 0 -> clamped to minimum 1
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

      // Low boundary: [1, 0, 0] -> Sum = 1, floor((1+1)/3) = 0 -> clamped to 1
      expect(suggestWeeklyTarget([1, 0, 0]), 1);

      // Three perfect practice weeks: Sum = 21, floor((21+1)/3) = 7 -> clamped to maximum 7
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

      // High boundary near max: [6, 7, 7] -> Sum = 20, floor((20+1)/3) = 7 -> clamped to 7
      expect(suggestWeeklyTarget([6, 7, 7]), 7);
    });

    // -------------------------------------------------------------------------
    // Fixture 5: Counterexample & Data Integrity Case
    // AGENTS.md Section 7: Accidental duplicate date on a single day does not increase the week count;
    //                      Zero-count weeks are treated as valid data (not skipped).
    // -------------------------------------------------------------------------
    test('Fixture 5 (Counterexample - Zero Weeks): treats 0-count weeks as valid data, not skipped', () {
      // [0, 3, 3] treats 0 as a valid completed week:
      // Sum = 6, Avg = 2.0 -> floor((6+1)/3) = 2.
      // (If 0 were skipped, it would be insufficient history or average of [3, 3] = 3)
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

    test('Fixture 5 Integration: Duplicate check-in attempts on same day do not inflate week count and zero-count weeks count as valid data', () async {
      // Reference date: Monday 2026-10-26
      final refDate = DateTime(2026, 10, 26);

      // Habit started 4 weeks ago: Monday 2026-09-28
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Morning Yoga',
          category: 'Mindfulness',
          weeklyTarget: 5,
          startedLocalDate: '2026-09-28',
        ),
      );

      final db = await dbHelper.database;

      // Week 1 completed (2026-09-28 to 2026-10-04): 0 check-ins (ZERO-COUNT WEEK)
      // (No entries inserted for Week 1 — it should be treated as 0, not skipped!)

      // Week 2 completed (2026-10-05 to 2026-10-11): 3 distinct check-in dates
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

      // Week 3 completed (2026-10-12 to 2026-10-18): 4 distinct check-in dates
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

      // Week 4 completed (2026-10-19 to 2026-10-25): 2 distinct check-in dates
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-20').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-21').toMap(),
      );

      // Current in-progress week (2026-10-26 to 2026-11-01): 1 check-in (MUST BE EXCLUDED)
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap(),
      );

      // Test evaluateForHabit:
      // The last 3 completed weeks are:
      // - Week 2 (Oct 05-11): 3 check-ins
      // - Week 3 (Oct 12-18): 4 check-ins
      // - Week 4 (Oct 19-25): 2 check-ins
      // Counts = [3, 4, 2] -> Sum = 9, Avg = 3.0 -> Suggests target 3
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
        // Habit started 10 days ago (only 1 full week completed)
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
