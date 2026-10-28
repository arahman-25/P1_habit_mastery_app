import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/app_settings.dart';
import 'package:habit_mastery_app/models/check_in.dart';
import 'package:habit_mastery_app/models/habit.dart';
import 'package:habit_mastery_app/services/check_in_service.dart';
import 'package:habit_mastery_app/services/habit_service.dart';
import 'package:habit_mastery_app/services/service_exceptions.dart';
import 'package:habit_mastery_app/services/settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Group 1: SQLite Schema & DDL Invariants', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('verifies PRAGMA foreign_keys is enabled on database connection', () async {
      final db = await dbHelper.database;
      final result = await db.rawQuery('PRAGMA foreign_keys;');
      expect(result, isNotEmpty);
      expect(result.first.values.first, equals(1));
    });

    test('verifies all required tables exist in sqlite_master', () async {
      final db = await dbHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tables.map((r) => r['name'] as String).toSet();

      expect(tableNames, contains(DatabaseHelper.tableSettings));
      expect(tableNames, contains(DatabaseHelper.tableHabits));
      expect(tableNames, contains(DatabaseHelper.tableCheckIns));
    });

    test('enforces NOT NULL constraints on habits table', () async {
      final db = await dbHelper.database;

      // Null title must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableHabits, {
          DatabaseHelper.columnHabitCategory: 'Health',
          DatabaseHelper.columnHabitWeeklyTarget: 4,
          DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Null category must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableHabits, {
          DatabaseHelper.columnHabitTitle: 'Read',
          DatabaseHelper.columnHabitWeeklyTarget: 4,
          DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Null weeklyTarget must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableHabits, {
          DatabaseHelper.columnHabitTitle: 'Read',
          DatabaseHelper.columnHabitCategory: 'Study',
          DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Null startedLocalDate must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableHabits, {
          DatabaseHelper.columnHabitTitle: 'Read',
          DatabaseHelper.columnHabitCategory: 'Study',
          DatabaseHelper.columnHabitWeeklyTarget: 4,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('enforces NOT NULL constraints on check_ins table', () async {
      final db = await dbHelper.database;

      // Null habitId must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableCheckIns, {
          DatabaseHelper.columnCheckInLocalDate: '2026-10-26',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Null localDate must fail
      expect(
        () async => await db.insert(DatabaseHelper.tableCheckIns, {
          DatabaseHelper.columnCheckInHabitId: 1,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('Group 2: Relational Constraints & Foreign Key CASCADE', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('enforces foreign key constraint: inserting check_in for non-existent habitId throws DatabaseException', () async {
      final db = await dbHelper.database;

      expect(
        () async => await db.insert(
          DatabaseHelper.tableCheckIns,
          const CheckIn(
            habitId: 99999, // Non-existent habit ID
            localDate: '2026-10-26',
          ).toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('cascade-deletes all associated check-ins when parent habit is deleted', () async {
      final db = await dbHelper.database;

      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Daily Meditation',
          category: 'Mindfulness',
          weeklyTarget: 5,
          startedLocalDate: '2026-10-15',
        ).toMap(),
      );

      // Insert 3 check-ins across distinct dates
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-20', note: 'Session 1').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-21', note: 'Session 2').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-22', note: 'Session 3').toMap(),
      );

      final beforeDelete = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(beforeDelete, hasLength(3));

      // Delete parent habit
      final rowsDeleted = await db.delete(
        DatabaseHelper.tableHabits,
        where: '${DatabaseHelper.columnHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(rowsDeleted, equals(1));

      // Verify that SQLite ON DELETE CASCADE deleted all associated check-ins
      final afterDelete = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(afterDelete, isEmpty);
    });

    test('foreign key cascade does not delete check-ins of sibling habits', () async {
      final db = await dbHelper.database;

      final habitIdA = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Habit A',
          category: 'Study',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );
      final habitIdB = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Habit B',
          category: 'Health',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );

      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitIdA, localDate: '2026-10-25').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitIdB, localDate: '2026-10-25').toMap());

      // Delete habit A
      await db.delete(
        DatabaseHelper.tableHabits,
        where: '${DatabaseHelper.columnHabitId} = ?',
        whereArgs: [habitIdA],
      );

      // Check-in for A is gone, Check-in for B remains intact
      final checkInsA = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitIdA],
      );
      expect(checkInsA, isEmpty);

      final checkInsB = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitIdB],
      );
      expect(checkInsB, hasLength(1));
    });
  });

  group('Group 3: Value Domain Constraints (weeklyTarget & Strict Same-Day Policy)', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('enforces weeklyTarget CHECK(weeklyTarget BETWEEN 1 AND 7) boundaries', () async {
      final db = await dbHelper.database;

      // Lower violations
      for (final invalidLow in [-10, -1, 0]) {
        expect(
          () async => await db.insert(DatabaseHelper.tableHabits, {
            DatabaseHelper.columnHabitTitle: 'Invalid Low',
            DatabaseHelper.columnHabitCategory: 'Health',
            DatabaseHelper.columnHabitWeeklyTarget: invalidLow,
            DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
          }),
          throwsA(isA<DatabaseException>()),
          reason: 'weeklyTarget = $invalidLow must violate CHECK constraint',
        );
      }

      // Upper violations
      for (final invalidHigh in [8, 9, 100]) {
        expect(
          () async => await db.insert(DatabaseHelper.tableHabits, {
            DatabaseHelper.columnHabitTitle: 'Invalid High',
            DatabaseHelper.columnHabitCategory: 'Health',
            DatabaseHelper.columnHabitWeeklyTarget: invalidHigh,
            DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
          }),
          throwsA(isA<DatabaseException>()),
          reason: 'weeklyTarget = $invalidHigh must violate CHECK constraint',
        );
      }

      // Valid boundary values (1 and 7) and intermediate values (2, 3, 4, 5, 6)
      for (int validTarget = 1; validTarget <= 7; validTarget++) {
        final id = await db.insert(DatabaseHelper.tableHabits, {
          DatabaseHelper.columnHabitTitle: 'Valid Target $validTarget',
          DatabaseHelper.columnHabitCategory: 'Health',
          DatabaseHelper.columnHabitWeeklyTarget: validTarget,
          DatabaseHelper.columnHabitStartedLocalDate: '2026-10-20',
        });
        expect(id, isPositive);
      }
    });

    test('enforces strict same-day policy: UNIQUE(habitId, localDate)', () async {
      final db = await dbHelper.database;

      final habitId1 = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Morning Walk',
          category: 'Health',
          weeklyTarget: 5,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );

      final habitId2 = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Read Book',
          category: 'Study',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );

      // Initial check-in on 2026-10-26 succeeds
      final firstCheckInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId1, localDate: '2026-10-26', note: 'Lap 1').toMap(),
      );
      expect(firstCheckInId, isPositive);

      // Duplicate check-in on the exact same date for habit 1 MUST fail at SQLite level
      expect(
        () async => await db.insert(
          DatabaseHelper.tableCheckIns,
          CheckIn(habitId: habitId1, localDate: '2026-10-26', note: 'Accidental duplicate tap').toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Distinct date for habit 1 succeeds
      final secondDateCheckInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId1, localDate: '2026-10-27', note: 'Lap 2').toMap(),
      );
      expect(secondDateCheckInId, isPositive);

      // Same date (2026-10-26) for different habit (habit 2) succeeds
      final habit2CheckInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId2, localDate: '2026-10-26', note: 'Chapter 1').toMap(),
      );
      expect(habit2CheckInId, isPositive);
    });
  });

  group('Group 4: Service-to-Storage Boundary Guards & Invariants', () {
    late DatabaseHelper dbHelper;
    late HabitService habitService;
    late CheckInService checkInService;
    final fixedClock = DateTime(2026, 10, 26, 12, 0); // Monday

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
      habitService = HabitService(
        dbHelper: dbHelper,
        nowProvider: () => fixedClock,
      );
      checkInService = CheckInService(
        dbHelper: dbHelper,
        nowProvider: () => fixedClock,
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('HabitService blocks future startedLocalDate before database insert', () async {
      expect(
        () => habitService.createHabit(
          const Habit(
            title: 'Future Habit',
            category: 'Creative',
            weeklyTarget: 3,
            startedLocalDate: '2026-10-27', // Tomorrow relative to fixedClock
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('cannot be in the future'))),
      );
    });

    test('CheckInService rejects check-in date predating habit startedLocalDate', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Guitar Practice',
          category: 'Creative',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      expect(
        () => checkInService.createCheckIn(
          CheckIn(
            habitId: habit.id!,
            localDate: '2026-10-19', // 1 day before habit started
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('cannot precede habit start date'))),
      );
    });

    test('CheckInService rejects future check-in dates', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Guitar Practice',
          category: 'Creative',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      expect(
        () => checkInService.createCheckIn(
          CheckIn(
            habitId: habit.id!,
            localDate: '2026-10-27', // Future relative to fixedClock 2026-10-26
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('cannot be in the future'))),
      );
    });

    test('HabitService blocks moving startedLocalDate forward when saved check-ins exist prior', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Daily Writing',
          category: 'Creative',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-15',
        ),
      );

      // Check-in on 2026-10-18
      await checkInService.createCheckIn(
        CheckIn(habitId: habit.id!, localDate: '2026-10-18'),
      );

      // Attempting to advance startedLocalDate to 2026-10-20 must be blocked
      expect(
        () => habitService.updateHabit(
          habit.copyWith(startedLocalDate: '2026-10-20'),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('check-in records exist prior'),
        )),
      );

      // Advancing startedLocalDate to 2026-10-17 (still before check-in 2026-10-18) succeeds
      final updated = await habitService.updateHabit(
        habit.copyWith(startedLocalDate: '2026-10-17'),
      );
      expect(updated.startedLocalDate, '2026-10-17');
    });

    test('CheckInService pre-check intercepts duplicate check-in with DuplicateCheckInException', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Water Intake',
          category: 'Health',
          weeklyTarget: 7,
          startedLocalDate: '2026-10-20',
        ),
      );

      await checkInService.checkInToday(habit.id!);

      expect(
        () => checkInService.checkInToday(habit.id!),
        throwsA(isA<DuplicateCheckInException>().having(
          (e) => e.message,
          'message',
          contains('already exists for habit'),
        )),
      );
    });
  });

  group('Group 5: Storage Lifecycle, Row Auditing & Atomic Reset', () {
    late DatabaseHelper dbHelper;
    late SettingsService settingsService;

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
      settingsService = SettingsService(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('seeds default settings on initial database creation', () async {
      final settings = await dbHelper.getAllSettings();
      expect(settings['notifications_enabled'], 'true');
      expect(settings['reminder_time'], '09:00');
      expect(settings['dark_mode'], 'false');
      expect(settings['sound_effects'], 'true');
      expect(settings['haptic_feedback'], 'true');
      expect(settings['weekly_goal'], '5');
    });

    test('SettingsService loads and updates settings in SQLite', () async {
      final initial = await settingsService.loadSettings();
      expect(initial.notificationsEnabled, isTrue);

      const modified = AppSettings(
        notificationsEnabled: false,
        reminderTime: '21:15',
        darkMode: true,
        soundEffects: false,
        hapticFeedback: false,
        weeklyGoal: 6,
      );

      await settingsService.saveSettings(modified);

      final reloaded = await settingsService.loadSettings();
      expect(reloaded.notificationsEnabled, isFalse);
      expect(reloaded.reminderTime, '21:15');
      expect(reloaded.darkMode, isTrue);
      expect(reloaded.soundEffects, isFalse);
      expect(reloaded.hapticFeedback, isFalse);
      expect(reloaded.weeklyGoal, 6);
    });

    test('getTableRowCounts tracks row count mutations across CRUD and cascade operations', () async {
      final db = await dbHelper.database;

      // Initial state
      var counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 0);
      expect(counts[DatabaseHelper.tableCheckIns], 0);
      expect(counts[DatabaseHelper.tableSettings], greaterThan(0));

      // Insert 2 habits
      final habitId1 = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(title: 'Habit 1', category: 'Health', weeklyTarget: 4, startedLocalDate: '2026-10-20').toMap(),
      );
      final habitId2 = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(title: 'Habit 2', category: 'Study', weeklyTarget: 5, startedLocalDate: '2026-10-20').toMap(),
      );

      // Insert 3 check-ins
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitId1, localDate: '2026-10-24').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitId1, localDate: '2026-10-25').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitId2, localDate: '2026-10-25').toMap());

      counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 2);
      expect(counts[DatabaseHelper.tableCheckIns], 3);

      // Delete habit 1 -> cascade deletes 2 check-ins
      await db.delete(DatabaseHelper.tableHabits, where: 'id = ?', whereArgs: [habitId1]);

      counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 1);
      expect(counts[DatabaseHelper.tableCheckIns], 1);
    });

    test('clearAllData executes atomic transaction resetting all user data while re-seeding default settings', () async {
      final db = await dbHelper.database;

      // Populate data
      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(title: 'Temporary Habit', category: 'Health', weeklyTarget: 3, startedLocalDate: '2026-10-20').toMap(),
      );
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habitId, localDate: '2026-10-25').toMap());

      // Alter settings
      await settingsService.saveSettings(
        const AppSettings(
          notificationsEnabled: false,
          reminderTime: '18:00',
          darkMode: true,
          weeklyGoal: 2,
        ),
      );

      var counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 1);
      expect(counts[DatabaseHelper.tableCheckIns], 1);

      // Clear all data
      await dbHelper.clearAllData();

      counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 0);
      expect(counts[DatabaseHelper.tableCheckIns], 0);
      expect(counts[DatabaseHelper.tableSettings], greaterThan(0));

      final resetSettings = await settingsService.loadSettings();
      expect(resetSettings.notificationsEnabled, isTrue);
      expect(resetSettings.reminderTime, '09:00');
      expect(resetSettings.darkMode, isFalse);
      expect(resetSettings.weeklyGoal, 5);
    });

    test('parameterized queries prevent SQL injection and handle special characters safely', () async {
      final db = await dbHelper.database;

      const maliciousTitle = "Robert'); DROP TABLE habits;--";
      const specialNote = "Quotes: 'single' and \"double\" -- semicolons; and symbols &%#@";

      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: maliciousTitle,
          category: "Cat'egory",
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
          motivation: "Don't stop believing!",
        ).toMap(),
      );

      final checkInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(
          habitId: habitId,
          localDate: '2026-10-26',
          note: specialNote,
        ).toMap(),
      );

      // Verify records are intact and table was not dropped
      final habitRows = await db.query(
        DatabaseHelper.tableHabits,
        where: '${DatabaseHelper.columnHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(habitRows, hasLength(1));
      expect(habitRows.first[DatabaseHelper.columnHabitTitle], maliciousTitle);
      expect(habitRows.first[DatabaseHelper.columnHabitMotivation], "Don't stop believing!");

      final checkInRows = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInId} = ?',
        whereArgs: [checkInId],
      );
      expect(checkInRows, hasLength(1));
      expect(checkInRows.first[DatabaseHelper.columnCheckInNote], specialNote);
    });

    test('verifies storage info reports database status and row counts', () async {
      final info = await settingsService.getStorageInfo();

      expect(info['isOpen'], isTrue);
      expect(info['databaseName'], DatabaseHelper.databaseName);
      expect(info['version'], 1);
      expect(info['path'], isNotEmpty);
      expect(info['rowCounts'], isNotNull);
      final rowCounts = info['rowCounts'] as Map<String, int>;
      expect(rowCounts[DatabaseHelper.tableSettings], greaterThan(0));
      expect(rowCounts[DatabaseHelper.tableHabits], equals(0));
      expect(rowCounts[DatabaseHelper.tableCheckIns], equals(0));
    });
  });
}
