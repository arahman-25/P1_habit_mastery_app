import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/check_in.dart';
import 'package:habit_mastery_app/models/habit.dart';
import 'package:habit_mastery_app/models/habit_weekly_progress.dart';
import 'package:habit_mastery_app/screens/create_edit.dart';
import 'package:habit_mastery_app/screens/dashboard.dart';
import 'package:habit_mastery_app/screens/details.dart';
import 'package:habit_mastery_app/screens/history.dart';
import 'package:habit_mastery_app/services/check_in_service.dart';
import 'package:habit_mastery_app/services/garden_guide.dart';
import 'package:habit_mastery_app/services/habit_service.dart';
import 'package:habit_mastery_app/utils/calendar_utils.dart';
import 'package:habit_mastery_app/widgets/garden_guide_card.dart';
import 'package:habit_mastery_app/widgets/habit_card.dart';
import 'package:habit_mastery_app/widgets/plant_display.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setTestInstance(DatabaseHelper.forTesting());
  });

  tearDownAll(() {
    DatabaseHelper.setTestInstance(null);
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
    // Reset test database after each test
    await DatabaseHelper.instance.clearAllData();
  });

  Future<T> runDb<T>(WidgetTester tester, Future<T> Function() callback) async {
    T? result;
    await tester.runAsync(() async {
      result = await callback();
    });
    return result as T;
  }

  Future<void> pumpAsync(WidgetTester tester, [int times = 6]) async {
    for (int i = 0; i < times; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      final hasCpi = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (!hasCpi) {
        break;
      }
    }
    await pumpAsync(tester, 2);
  }

  group('Modular Widgets Unit Tests', () {
    testWidgets('PlantDisplay renders all 4 tiers with accessible progress strings',
        (tester) async {
      const tiers = [
        (0, 'Seed in soil', 0.0, 0, 4, '0/4 days (0%)'),
        (1, 'Sprout', 0.25, 1, 4, '1/4 days (25%)'),
        (2, 'Growing bud', 0.75, 3, 4, '3/4 days (75%)'),
        (3, 'Full bloom', 1.0, 4, 4, '4/4 days (100%)'),
      ];

      for (final t in tiers) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlantDisplay(
                plantTier: t.$1,
                plantStageName: t.$2,
                completionRate: t.$3,
                completedDays: t.$4,
                targetDays: t.$5,
              ),
            ),
          ),
        );

        expect(find.text(t.$2), findsOneWidget);
        expect(find.text(t.$6), findsOneWidget);
      }
    });

    testWidgets('HabitCard displays title, category, progress and handles tap',
        (tester) async {
      bool tapped = false;
      bool checkedIn = false;

      const habit = Habit(
        id: 1,
        title: 'Morning Yoga',
        category: 'Health',
        weeklyTarget: 5,
        startedLocalDate: '2026-10-01',
        motivation: 'Feel energetic',
      );

      const progress = HabitWeeklyProgress(
        habit: habit,
        weekStartLocalDate: '2026-10-26',
        weekEndLocalDate: '2026-11-01',
        completedDays: 2,
        targetDays: 5,
        completionRate: 0.4,
        plantTier: 1,
        plantStageName: 'Sprout',
        completedDates: ['2026-10-26', '2026-10-27'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitCard(
              progress: progress,
              isCheckedInToday: false,
              onTap: () => tapped = true,
              onQuickCheckIn: () => checkedIn = true,
            ),
          ),
        ),
      );

      expect(find.text('Morning Yoga'), findsOneWidget);
      expect(find.text('HEALTH'), findsOneWidget);
      expect(find.text('2/5 days (40%)'), findsOneWidget);
      expect(find.text('Sprout'), findsOneWidget);
      expect(find.text('Check In Today'), findsOneWidget);

      await tester.tap(find.text('Morning Yoga'));
      expect(tapped, isTrue);

      await tester.tap(find.text('Check In Today'));
      expect(checkedIn, isTrue);
    });

    testWidgets('GardenGuideCard renders rule-based badge and apply button',
        (tester) async {
      bool applied = false;

      const recommendation = GardenGuideRecommendation(
        suggestedTarget: 4,
        currentTarget: 3,
        averageDaysPerWeek: 3.7,
        completedWeekCounts: [3, 4, 4],
        hasEnoughHistory: true,
        headline: 'Ready to Bloom',
        rationale: 'You practiced an average of 3.7 days over the last 3 full weeks.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenGuideCard(
              recommendation: recommendation,
              onApplySuggestion: () => applied = true,
            ),
          ),
        ),
      );

      expect(find.text('GARDEN GUIDE'), findsOneWidget);
      expect(find.text('Rule-Based Algorithm'), findsOneWidget);
      expect(find.text('Ready to Bloom'), findsOneWidget);
      expect(find.text('3 → 4 days / week'), findsOneWidget);
      expect(find.text('Apply Suggestion'), findsOneWidget);

      await tester.tap(find.text('Apply Suggestion'));
      expect(applied, isTrue);
    });
  });

  group('Dashboard Screen Integration Tests', () {
    testWidgets('displays empty state when no habits exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Dashboard()),
      );
      await pumpUntilLoaded(tester);

      expect(find.text('Your garden is empty'), findsOneWidget);
      expect(find.text('Plant Your First Habit'), findsOneWidget);
    });

    testWidgets('loads habits from SQLite and filters by category', (tester) async {
      final habitService = HabitService.instance;
      await runDb(tester, () => habitService.createHabit(const Habit(
        title: 'Algorithms Practice',
        category: 'Study',
        weeklyTarget: 5,
        startedLocalDate: '2026-10-01',
      )));
      await runDb(tester, () => habitService.createHabit(const Habit(
        title: 'Evening Run',
        category: 'Health',
        weeklyTarget: 4,
        startedLocalDate: '2026-10-01',
      )));

      await tester.pumpWidget(
        const MaterialApp(home: Dashboard()),
      );
      await pumpUntilLoaded(tester);

      expect(find.text('Algorithms Practice'), findsOneWidget);
      expect(find.text('Evening Run'), findsOneWidget);

      // Select 'Study' filter chip
      await tester.tap(find.text('Study'));
      await pumpUntilLoaded(tester);

      expect(find.text('Algorithms Practice'), findsOneWidget);
      expect(find.text('Evening Run'), findsNothing);

      // Select 'Mindfulness' (empty category)
      await tester.tap(find.text('Mindfulness'));
      await pumpUntilLoaded(tester);

      expect(find.text('No habits in "Mindfulness"'), findsOneWidget);
    });

    testWidgets('category filter chips do not clip or fade end of label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Dashboard()),
      );
      await pumpUntilLoaded(tester);

      const categories = ['All', 'Study', 'Health', 'Creative', 'Mindfulness'];
      for (final cat in categories) {
        final textFinder = find.descendant(
          of: find.widgetWithText(ChoiceChip, cat),
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget);
        final Text textWidget = tester.widget(textFinder);
        expect(textWidget.overflow, equals(TextOverflow.visible));
        expect(textWidget.softWrap, isFalse);
      }
    });
  });

  group('Create / Edit Screen Integration Tests', () {
    testWidgets('validates required habit title and creates habit in SQLite',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CreateEdit()),
      );
      await pumpUntilLoaded(tester);

      // Tap Plant Habit without title
      await tester.tap(find.text('Plant Habit 🌱'));
      await pumpAsync(tester, 3);

      expect(find.text('Habit title is required.'), findsOneWidget);

      // Fill in title
      await tester.enterText(find.byType(TextFormField).first, 'Deep Reading');
      await tester.tap(find.text('Plant Habit 🌱'));
      await pumpAsync(tester);

      final habits = await runDb(tester, () => HabitService.instance.getAllHabits());
      expect(habits.length, 1);
      expect(habits.first.title, 'Deep Reading');
    });

    testWidgets('edits existing habit and updates in SQLite', (tester) async {
      final habit = await runDb(tester, () => HabitService.instance.createHabit(const Habit(
        title: 'Old Title',
        category: 'General',
        weeklyTarget: 3,
        startedLocalDate: '2026-10-10',
      )));

      await tester.pumpWidget(
        MaterialApp(home: CreateEdit(habit: habit)),
      );
      await pumpUntilLoaded(tester);

      expect(find.text('Old Title'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'New Updated Title');
      await tester.tap(find.text('Update Habit'));
      await pumpAsync(tester);

      final updated = await runDb(tester, () => HabitService.instance.getHabitById(habit.id!));
      expect(updated!.title, 'New Updated Title');
    });
  });

  group('Details Screen Integration Tests', () {
    testWidgets('displays active weekly progress and records check-in today',
        (tester) async {
      final today = CalendarUtils.formatLocalDate(DateTime.now());
      final habit = await runDb(tester, () => HabitService.instance.createHabit(Habit(
        title: 'Hydration Routine',
        category: 'Health',
        weeklyTarget: 4,
        startedLocalDate: today,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Details(habitId: habit.id!)),
      );
      await pumpUntilLoaded(tester);

      expect(find.text('Hydration Routine'), findsOneWidget);
      expect(find.text('0/4 days (0%)'), findsOneWidget);
      expect(find.text('Check In Today'), findsOneWidget);

      // Tap Check In Today
      await tester.tap(find.text('Check In Today'));
      await pumpAsync(tester);

      // Progress should now be 1/4 days (25%)
      expect(find.text('1/4 days (25%)'), findsOneWidget);
      expect(find.text('Checked In Today ✓'), findsOneWidget);

      // Verify recorded in SQLite
      final checkIns = await runDb(tester, () => CheckInService.instance.getCheckInsForHabit(habit.id!));
      expect(checkIns.length, 1);
      expect(checkIns.first.localDate, today);
    });
  });

  group('History Screen Integration Tests', () {
    testWidgets('displays check-in journal and performs CRUD', (tester) async {
      final today = CalendarUtils.formatLocalDate(DateTime.now());
      final habit = await runDb(tester, () => HabitService.instance.createHabit(Habit(
        title: 'Guitar Practice',
        category: 'Creative',
        weeklyTarget: 3,
        startedLocalDate: '2026-10-01',
      )));

      // Add a check-in via service
      await runDb(tester, () => CheckInService.instance.createCheckIn(CheckIn(
        habitId: habit.id!,
        localDate: today,
        note: 'Played acoustic chords',
      )));

      await tester.pumpWidget(
        MaterialApp(home: History(initialHabit: habit)),
      );
      await pumpUntilLoaded(tester);

      expect(find.text(today), findsOneWidget);
      expect(find.text('Played acoustic chords'), findsOneWidget);

      // Delete check-in via UI
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await pumpAsync(tester, 3);

      expect(find.text('Delete Check-in?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await pumpAsync(tester);

      final remaining = await runDb(tester, () => CheckInService.instance.getCheckInsForHabit(habit.id!));
      expect(remaining, isEmpty);
    });
  });
}
