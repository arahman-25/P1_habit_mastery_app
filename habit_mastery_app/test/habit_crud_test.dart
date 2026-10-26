import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/check_in.dart';
import 'package:habit_mastery_app/models/habit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Habit Model Unit Tests', () {
    test('creates Habit and converts to/from Map correctly', () {
      const habit = Habit(
        id: 1,
        title: 'Morning Run',
        category: 'Health',
        weeklyTarget: 4,
        startedLocalDate: '2026-10-20',
        motivation: 'Boost stamina and energy',
      );

      final map = habit.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Morning Run');
      expect(map['category'], 'Health');
      expect(map['weeklyTarget'], 4);
      expect(map['startedLocalDate'], '2026-10-20');
      expect(map['motivation'], 'Boost stamina and energy');

      final reconstructed = Habit.fromMap(map);
      expect(reconstructed, equals(habit));
      expect(reconstructed.id, 1);
      expect(reconstructed.title, 'Morning Run');
      expect(reconstructed.category, 'Health');
      expect(reconstructed.weeklyTarget, 4);
      expect(reconstructed.startedLocalDate, '2026-10-20');
      expect(reconstructed.motivation, 'Boost stamina and energy');
    });

    test('Habit toMap omits id when null for newly created entities', () {
      const habit = Habit(
        title: 'Reading',
        category: 'Study',
        weeklyTarget: 5,
        startedLocalDate: '2026-10-21',
      );

      final map = habit.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['title'], 'Reading');
      expect(map['category'], 'Study');
      expect(map['weeklyTarget'], 5);
      expect(map['startedLocalDate'], '2026-10-21');
      expect(map['motivation'], isNull);
    });

    test('Habit copyWith returns updated copy', () {
      const habit = Habit(
        id: 10,
        title: 'Meditation',
        category: 'Mindfulness',
        weeklyTarget: 3,
        startedLocalDate: '2026-10-15',
      );

      final updated = habit.copyWith(
        title: 'Deep Meditation',
        weeklyTarget: 4,
      );

      expect(updated.id, 10);
      expect(updated.title, 'Deep Meditation');
      expect(updated.weeklyTarget, 4);
      expect(updated.category, 'Mindfulness');
      expect(updated.startedLocalDate, '2026-10-15');
      expect(updated, isNot(equals(habit)));
    });
  });

  group('CheckIn Model Unit Tests', () {
    test('creates CheckIn and converts to/from Map correctly', () {
      const checkIn = CheckIn(
        id: 42,
        habitId: 1,
        localDate: '2026-10-26',
        note: 'Completed 5km jog',
      );

      final map = checkIn.toMap();
      expect(map['id'], 42);
      expect(map['habitId'], 1);
      expect(map['localDate'], '2026-10-26');
      expect(map['note'], 'Completed 5km jog');

      final reconstructed = CheckIn.fromMap(map);
      expect(reconstructed, equals(checkIn));
    });

    test('CheckIn toMap omits id when null for unpersisted check-in', () {
      const checkIn = CheckIn(
        habitId: 2,
        localDate: '2026-10-26',
      );

      final map = checkIn.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['habitId'], 2);
      expect(map['localDate'], '2026-10-26');
      expect(map['note'], isNull);
    });

    test('CheckIn copyWith updates fields correctly', () {
      const checkIn = CheckIn(
        id: 7,
        habitId: 1,
        localDate: '2026-10-25',
      );

      final updated = checkIn.copyWith(note: 'Felt great!');
      expect(updated.id, 7);
      expect(updated.habitId, 1);
      expect(updated.localDate, '2026-10-25');
      expect(updated.note, 'Felt great!');
    });
  });

  group('SQLite Schema & Constraint Integration Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('inserts valid habit and retrieves with auto-incremented id', () async {
      final db = await dbHelper.database;

      const newHabit = Habit(
        title: 'Study Flutter',
        category: 'Study',
        weeklyTarget: 5,
        startedLocalDate: '2026-10-22',
        motivation: 'Build awesome apps',
      );

      final id = await db.insert(
        DatabaseHelper.tableHabits,
        newHabit.toMap(),
      );
      expect(id, isPositive);

      final rows = await db.query(
        DatabaseHelper.tableHabits,
        where: '${DatabaseHelper.columnHabitId} = ?',
        whereArgs: [id],
      );
      expect(rows, hasLength(1));
      final loaded = Habit.fromMap(rows.first);
      expect(loaded.id, id);
      expect(loaded.title, 'Study Flutter');
      expect(loaded.category, 'Study');
      expect(loaded.weeklyTarget, 5);
      expect(loaded.startedLocalDate, '2026-10-22');
      expect(loaded.motivation, 'Build awesome apps');
    });

    test('enforces weeklyTarget CHECK constraint between 1 and 7', () async {
      final db = await dbHelper.database;

      // Lower bound: weeklyTarget = 0 must fail
      expect(
        () async => await db.insert(
          DatabaseHelper.tableHabits,
          {
            DatabaseHelper.columnHabitTitle: 'Invalid Low Target',
            DatabaseHelper.columnHabitCategory: 'Health',
            DatabaseHelper.columnHabitWeeklyTarget: 0,
            DatabaseHelper.columnHabitStartedLocalDate: '2026-10-22',
          },
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Upper bound: weeklyTarget = 8 must fail
      expect(
        () async => await db.insert(
          DatabaseHelper.tableHabits,
          {
            DatabaseHelper.columnHabitTitle: 'Invalid High Target',
            DatabaseHelper.columnHabitCategory: 'Health',
            DatabaseHelper.columnHabitWeeklyTarget: 8,
            DatabaseHelper.columnHabitStartedLocalDate: '2026-10-22',
          },
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Boundary values: 1 and 7 must succeed
      final idMin = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Min Target Habit',
          category: 'Creative',
          weeklyTarget: 1,
          startedLocalDate: '2026-10-22',
        ).toMap(),
      );
      expect(idMin, isPositive);

      final idMax = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Max Target Habit',
          category: 'Creative',
          weeklyTarget: 7,
          startedLocalDate: '2026-10-22',
        ).toMap(),
      );
      expect(idMax, isPositive);
    });

    test('enforces foreign key constraint when inserting check-ins', () async {
      final db = await dbHelper.database;

      // Non-existent habitId: 99999 must violate foreign key
      expect(
        () async => await db.insert(
          DatabaseHelper.tableCheckIns,
          const CheckIn(
            habitId: 99999,
            localDate: '2026-10-26',
          ).toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('enforces strict same-day policy: UNIQUE(habitId, localDate)', () async {
      final db = await dbHelper.database;

      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Journaling',
          category: 'Mindfulness',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );

      // First check-in on 2026-10-26 succeeds
      final firstCheckInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(
          habitId: habitId,
          localDate: '2026-10-26',
          note: 'First check-in',
        ).toMap(),
      );
      expect(firstCheckInId, isPositive);

      // Attempting duplicate check-in on the exact same date for the same habit must fail
      expect(
        () async => await db.insert(
          DatabaseHelper.tableCheckIns,
          CheckIn(
            habitId: habitId,
            localDate: '2026-10-26',
            note: 'Duplicate check-in',
          ).toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Different date for the same habit succeeds
      final nextDayCheckInId = await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(
          habitId: habitId,
          localDate: '2026-10-27',
        ).toMap(),
      );
      expect(nextDayCheckInId, isPositive);
    });

    test('deleting a habit cascade-deletes all associated check-ins', () async {
      final db = await dbHelper.database;

      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Stretching',
          category: 'Health',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-18',
        ).toMap(),
      );

      // Add two check-ins
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-20').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-21').toMap(),
      );

      final checkInsBefore = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(checkInsBefore, hasLength(2));

      // Delete the habit
      final deletedCount = await db.delete(
        DatabaseHelper.tableHabits,
        where: '${DatabaseHelper.columnHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(deletedCount, 1);

      // Foreign key CASCADE should have deleted all associated check-ins
      final checkInsAfter = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habitId],
      );
      expect(checkInsAfter, isEmpty);
    });

    test('table row counts accurately reflect added and cleared rows', () async {
      final db = await dbHelper.database;

      var counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 0);
      expect(counts[DatabaseHelper.tableCheckIns], 0);
      expect(counts[DatabaseHelper.tableSettings], greaterThan(0));

      final habitId = await db.insert(
        DatabaseHelper.tableHabits,
        const Habit(
          title: 'Hydration',
          category: 'Health',
          weeklyTarget: 7,
          startedLocalDate: '2026-10-20',
        ).toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habitId, localDate: '2026-10-26').toMap(),
      );

      counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 1);
      expect(counts[DatabaseHelper.tableCheckIns], 1);

      await dbHelper.clearAllData();
      counts = await dbHelper.getTableRowCounts();
      expect(counts[DatabaseHelper.tableHabits], 0);
      expect(counts[DatabaseHelper.tableCheckIns], 0);
    });
  });
}
