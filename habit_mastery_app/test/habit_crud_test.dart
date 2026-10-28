import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/check_in.dart';
import 'package:habit_mastery_app/models/habit.dart';
import 'package:habit_mastery_app/services/check_in_service.dart';
import 'package:habit_mastery_app/services/habit_service.dart';
import 'package:habit_mastery_app/services/service_exceptions.dart';
import 'package:habit_mastery_app/utils/calendar_utils.dart';
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

  group('CalendarUtils Unit Tests', () {
    test('formats DateTime into local YYYY-MM-DD correctly', () {
      final dt = DateTime(2026, 10, 26, 15, 30);
      expect(CalendarUtils.formatLocalDate(dt), '2026-10-26');
    });

    test('parses valid YYYY-MM-DD into DateTime local', () {
      final dt = CalendarUtils.parseLocalDate('2026-10-26');
      expect(dt.year, 2026);
      expect(dt.month, 10);
      expect(dt.day, 26);
    });

    test('rejects invalid date strings and invalid calendar days', () {
      expect(CalendarUtils.isValidLocalDate('not-a-date'), isFalse);
      expect(CalendarUtils.isValidLocalDate('2026-02-31'), isFalse);
      expect(CalendarUtils.isValidLocalDate('2026-13-01'), isFalse);
      expect(CalendarUtils.isValidLocalDate('2026-10-26'), isTrue);
      expect(() => CalendarUtils.parseLocalDate('2026-02-31'), throwsFormatException);
    });

    test('computes Monday and Sunday correctly for Monday, Wednesday, and Sunday', () {
      // 2026-10-26 is a Monday
      final monday = DateTime(2026, 10, 26);
      expect(CalendarUtils.getMondayString(monday), '2026-10-26');
      expect(CalendarUtils.getSundayString(monday), '2026-11-01');

      // 2026-10-28 is a Wednesday in the same week
      final wednesday = DateTime(2026, 10, 28);
      expect(CalendarUtils.getMondayString(wednesday), '2026-10-26');
      expect(CalendarUtils.getSundayString(wednesday), '2026-11-01');

      // 2026-11-01 is Sunday (last day of the week)
      final sunday = DateTime(2026, 11, 1);
      expect(CalendarUtils.getMondayString(sunday), '2026-10-26');
      expect(CalendarUtils.getSundayString(sunday), '2026-11-01');
    });

    test('calculates plant tiers according to Section 5 specs', () {
      expect(CalendarUtils.calculatePlantTier(0.0), 0); // Seed in soil
      expect(CalendarUtils.calculatePlantTier(0.25), 1); // Sprout (1% - 49%)
      expect(CalendarUtils.calculatePlantTier(0.50), 2); // Growing bud (50% - 99%)
      expect(CalendarUtils.calculatePlantTier(0.99), 2); // Growing bud
      expect(CalendarUtils.calculatePlantTier(1.0), 3); // Full bloom (>= 100%)
      expect(CalendarUtils.calculatePlantTier(1.25), 3); // Full bloom capped
    });

    test('returns correct plant stage names', () {
      expect(CalendarUtils.getPlantStageName(0), 'Seed in soil');
      expect(CalendarUtils.getPlantStageName(1), 'Sprout');
      expect(CalendarUtils.getPlantStageName(2), 'Growing bud');
      expect(CalendarUtils.getPlantStageName(3), 'Full bloom');
    });
  });

  group('HabitService CRUD & Invariant Integration Tests', () {
    late DatabaseHelper dbHelper;
    late HabitService habitService;
    final fixedClock = DateTime(2026, 10, 26, 12, 0); // Monday

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
      habitService = HabitService(
        dbHelper: dbHelper,
        nowProvider: () => fixedClock,
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('creates valid habit and returns persisted entity with id', () async {
      const habit = Habit(
        title: 'Morning Yoga',
        category: 'Health',
        weeklyTarget: 5,
        startedLocalDate: '2026-10-20',
        motivation: 'Improve flexibility',
      );

      final created = await habitService.createHabit(habit);
      expect(created.id, isNotNull);
      expect(created.id, isPositive);
      expect(created.title, 'Morning Yoga');
      expect(created.category, 'Health');
      expect(created.weeklyTarget, 5);
      expect(created.startedLocalDate, '2026-10-20');
      expect(created.motivation, 'Improve flexibility');

      final fetched = await habitService.getHabitById(created.id!);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Morning Yoga');
    });

    test('rejects blank title and blank category with ValidationException', () async {
      expect(
        () => habitService.createHabit(
          const Habit(
            title: '   ',
            category: 'Health',
            weeklyTarget: 4,
            startedLocalDate: '2026-10-20',
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('title cannot be empty'))),
      );

      expect(
        () => habitService.createHabit(
          const Habit(
            title: 'Valid Title',
            category: '   ',
            weeklyTarget: 4,
            startedLocalDate: '2026-10-20',
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('category cannot be empty'))),
      );
    });

    test('rejects weeklyTarget outside 1..7 bounds with ValidationException', () async {
      expect(
        () => habitService.createHabit(
          const Habit(
            title: 'Zero Target',
            category: 'Study',
            weeklyTarget: 0,
            startedLocalDate: '2026-10-20',
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('between 1 and 7'))),
      );

      expect(
        () => habitService.createHabit(
          const Habit(
            title: 'Eight Target',
            category: 'Study',
            weeklyTarget: 8,
            startedLocalDate: '2026-10-20',
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('between 1 and 7'))),
      );
    });

    test('rejects future startedLocalDate with ValidationException', () async {
      // fixedClock is 2026-10-26
      expect(
        () => habitService.createHabit(
          const Habit(
            title: 'Future Habit',
            category: 'Health',
            weeklyTarget: 3,
            startedLocalDate: '2026-10-27', // Tomorrow relative to fixedClock
          ),
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('cannot be in the future'))),
      );
    });

    test('allows habit start date equal to today or in the past', () async {
      final todayHabit = await habitService.createHabit(
        const Habit(
          title: 'Today Habit',
          category: 'Mindfulness',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-26',
        ),
      );
      expect(todayHabit.id, isPositive);

      final pastHabit = await habitService.createHabit(
        const Habit(
          title: 'Past Habit',
          category: 'Creative',
          weeklyTarget: 2,
          startedLocalDate: '2026-10-01',
        ),
      );
      expect(pastHabit.id, isPositive);
    });

    test('getAllHabits and getHabitsByCategory retrieve and filter properly', () async {
      await habitService.createHabit(
        const Habit(
          title: 'Read Book',
          category: 'Study',
          weeklyTarget: 5,
          startedLocalDate: '2026-10-15',
        ),
      );
      await habitService.createHabit(
        const Habit(
          title: 'Write Essay',
          category: 'Study',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-16',
        ),
      );
      await habitService.createHabit(
        const Habit(
          title: 'Meditation',
          category: 'Mindfulness',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-17',
        ),
      );

      final allHabits = await habitService.getAllHabits();
      expect(allHabits, hasLength(3));

      final studyHabits = await habitService.getHabitsByCategory('Study');
      expect(studyHabits, hasLength(2));

      final mindfulnessHabits = await habitService.getHabitsByCategory('mindfulness');
      expect(mindfulnessHabits, hasLength(1));

      final allFilter = await habitService.getHabitsByCategory('All');
      expect(allFilter, hasLength(3));
    });

    test('updateHabit updates details when valid', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Old Title',
          category: 'Health',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ),
      );

      final updated = await habitService.updateHabit(
        habit.copyWith(
          title: 'New Title',
          weeklyTarget: 6,
          motivation: 'New motivation',
        ),
      );

      expect(updated.title, 'New Title');
      expect(updated.weeklyTarget, 6);
      expect(updated.motivation, 'New motivation');

      final reloaded = await habitService.getHabitById(habit.id!);
      expect(reloaded!.title, 'New Title');
      expect(reloaded.weeklyTarget, 6);
      expect(reloaded.motivation, 'New motivation');
    });

    test('updateHabit throws EntityNotFoundException for non-existent habit', () async {
      expect(
        () => habitService.updateHabit(
          const Habit(
            id: 9999,
            title: 'Ghost',
            category: 'Health',
            weeklyTarget: 3,
            startedLocalDate: '2026-10-20',
          ),
        ),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('updateHabit blocks moving startedLocalDate later if check-ins predate the proposed date', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Coding',
          category: 'Study',
          weeklyTarget: 5,
          startedLocalDate: '2026-10-15',
        ),
      );

      // Add check-ins on 2026-10-18 and 2026-10-22 directly to DB
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-18').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-22').toMap(),
      );

      // Attempting to move start date forward to 2026-10-20 must be BLOCKED because of check-in on 2026-10-18
      expect(
        () => habitService.updateHabit(
          habit.copyWith(startedLocalDate: '2026-10-20'),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Cannot change start date to 2026-10-20 because check-in records exist prior'),
        )),
      );

      // Moving start date forward to 2026-10-17 must SUCCEED because no check-ins exist before 2026-10-17
      final updated = await habitService.updateHabit(
        habit.copyWith(startedLocalDate: '2026-10-17'),
      );
      expect(updated.startedLocalDate, '2026-10-17');
    });

    test('deleteHabit removes habit and cascade deletes check-ins', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Piano',
          category: 'Creative',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-15',
        ),
      );

      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-20').toMap(),
      );

      final deleted = await habitService.deleteHabit(habit.id!);
      expect(deleted, 1);

      expect(await habitService.getHabitById(habit.id!), isNull);
      final checkIns = await db.query(
        DatabaseHelper.tableCheckIns,
        where: '${DatabaseHelper.columnCheckInHabitId} = ?',
        whereArgs: [habit.id],
      );
      expect(checkIns, isEmpty);
    });
  });

  group('CheckInService CRUD & Invariant Integration Tests', () {
    late DatabaseHelper dbHelper;
    late HabitService habitService;
    late CheckInService checkInService;
    late Habit testHabit;
    final fixedClock = DateTime(2026, 10, 26, 12, 0); // Monday

    setUp(() async {
      dbHelper = DatabaseHelper.forTesting();
      habitService = HabitService(
        dbHelper: dbHelper,
        nowProvider: () => fixedClock,
      );
      checkInService = CheckInService(
        dbHelper: dbHelper,
        nowProvider: () => fixedClock,
      );

      testHabit = await habitService.createHabit(
        const Habit(
          title: 'Running',
          category: 'Health',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('creates valid check-in and returns persisted entity with id', () async {
      final checkIn = await checkInService.createCheckIn(
        CheckIn(
          habitId: testHabit.id!,
          localDate: '2026-10-22',
          note: 'Easy 3 miles',
        ),
      );

      expect(checkIn.id, isNotNull);
      expect(checkIn.id, isPositive);
      expect(checkIn.habitId, testHabit.id);
      expect(checkIn.localDate, '2026-10-22');
      expect(checkIn.note, 'Easy 3 miles');

      final fetched = await checkInService.getCheckInById(checkIn.id!);
      expect(fetched, isNotNull);
      expect(fetched!.note, 'Easy 3 miles');
    });

    test('rejects check-in for non-existent habit with EntityNotFoundException', () async {
      expect(
        () => checkInService.createCheckIn(
          const CheckIn(
            habitId: 9999,
            localDate: '2026-10-22',
          ),
        ),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test('rejects check-in that predates habit startedLocalDate with ValidationException', () async {
      // testHabit started on 2026-10-20
      expect(
        () => checkInService.createCheckIn(
          CheckIn(
            habitId: testHabit.id!,
            localDate: '2026-10-19', // 1 day before habit started
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('cannot precede habit start date'),
        )),
      );
    });

    test('rejects check-in on future dates with ValidationException', () async {
      // fixedClock is 2026-10-26
      expect(
        () => checkInService.createCheckIn(
          CheckIn(
            habitId: testHabit.id!,
            localDate: '2026-10-27', // tomorrow relative to fixedClock
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('cannot be in the future'),
        )),
      );
    });

    test('Strict Same-Day Policy: rejects duplicate check-in with DuplicateCheckInException', () async {
      await checkInService.createCheckIn(
        CheckIn(
          habitId: testHabit.id!,
          localDate: '2026-10-25',
          note: 'First check-in',
        ),
      );

      expect(
        () => checkInService.createCheckIn(
          CheckIn(
            habitId: testHabit.id!,
            localDate: '2026-10-25',
            note: 'Duplicate attempt',
          ),
        ),
        throwsA(isA<DuplicateCheckInException>().having(
          (e) => e.message,
          'message',
          contains('already exists for habit #${testHabit.id} on 2026-10-25'),
        )),
      );
    });

    test('checkInToday records check-in for today and prevents second tap', () async {
      expect(await checkInService.hasCheckedInToday(testHabit.id!), isFalse);

      final checkIn = await checkInService.checkInToday(testHabit.id!, note: 'Done today');
      expect(checkIn.localDate, '2026-10-26');
      expect(checkIn.note, 'Done today');

      expect(await checkInService.hasCheckedInToday(testHabit.id!), isTrue);

      // Attempting checkInToday a second time throws DuplicateCheckInException
      expect(
        () => checkInService.checkInToday(testHabit.id!),
        throwsA(isA<DuplicateCheckInException>()),
      );
    });

    test('queries check-ins: for habit, for date, and date range', () async {
      await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-21'),
      );
      await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-23'),
      );
      await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-26'),
      );

      final allCheckIns = await checkInService.getCheckInsForHabit(testHabit.id!);
      expect(allCheckIns, hasLength(3));
      // Verify descending order
      expect(allCheckIns[0].localDate, '2026-10-26');
      expect(allCheckIns[1].localDate, '2026-10-23');
      expect(allCheckIns[2].localDate, '2026-10-21');

      final onDate = await checkInService.getCheckInForDate(testHabit.id!, '2026-10-23');
      expect(onDate, isNotNull);
      expect(onDate!.localDate, '2026-10-23');

      final range = await checkInService.getCheckInsForDateRange(
        testHabit.id!,
        '2026-10-22',
        '2026-10-25',
      );
      expect(range, hasLength(1));
      expect(range.first.localDate, '2026-10-23');
    });

    test('updateCheckIn updates note and date correctly', () async {
      final created = await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-21', note: 'Initial'),
      );

      final updated = await checkInService.updateCheckIn(
        created.copyWith(localDate: '2026-10-22', note: 'Updated note'),
      );

      expect(updated.localDate, '2026-10-22');
      expect(updated.note, 'Updated note');

      final fetched = await checkInService.getCheckInById(created.id!);
      expect(fetched!.localDate, '2026-10-22');
      expect(fetched.note, 'Updated note');
    });

    test('updateCheckIn blocks duplicate date when conflicting with another check-in', () async {
      final checkIn1 = await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-21'),
      );
      expect(checkIn1.id, isPositive);
      final checkIn2 = await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-22'),
      );

      // Attempting to change checkIn2 date to 2026-10-21 (conflicts with checkIn1)
      expect(
        () => checkInService.updateCheckIn(
          checkIn2.copyWith(localDate: '2026-10-21'),
        ),
        throwsA(isA<DuplicateCheckInException>()),
      );

      // Changing checkIn2 to 2026-10-23 succeeds
      final updated2 = await checkInService.updateCheckIn(
        checkIn2.copyWith(localDate: '2026-10-23'),
      );
      expect(updated2.localDate, '2026-10-23');
    });

    test('deleteCheckIn removes check-in', () async {
      final created = await checkInService.createCheckIn(
        CheckIn(habitId: testHabit.id!, localDate: '2026-10-21'),
      );

      final deleted = await checkInService.deleteCheckIn(created.id!);
      expect(deleted, 1);
      expect(await checkInService.getCheckInById(created.id!), isNull);
    });
  });

  group('Weekly Cycle & Dynamic Completion Rate Tests', () {
    late DatabaseHelper dbHelper;
    late HabitService habitService;
    late CheckInService checkInService;

    // Week of Mon Oct 26, 2026 to Sun Nov 1, 2026
    final monday = DateTime(2026, 10, 26, 12, 0);

    setUp(() {
      dbHelper = DatabaseHelper.forTesting();
      habitService = HabitService(
        dbHelper: dbHelper,
        nowProvider: () => monday,
      );
      checkInService = CheckInService(
        dbHelper: dbHelper,
        nowProvider: () => monday,
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('computes Tier 0 (Seed in soil) when 0 days completed', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Drink Water',
          category: 'Health',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      final progress = await habitService.getWeeklyProgress(habit.id!);
      expect(progress.completedDays, 0);
      expect(progress.targetDays, 4);
      expect(progress.completionRate, 0.0);
      expect(progress.plantTier, 0);
      expect(progress.plantStageName, 'Seed in soil');
      expect(progress.displayProgress, '0/4 days (0%)');
      expect(progress.isGoalMet, isFalse);
    });

    test('computes Tier 1 (Sprout) when rate is between 1% and 49%', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Read 20 pages',
          category: 'Study',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      // Check-in on Monday 2026-10-26 -> 1/4 = 25%
      await checkInService.createCheckIn(
        CheckIn(habitId: habit.id!, localDate: '2026-10-26'),
      );

      final progress = await habitService.getWeeklyProgress(habit.id!);
      expect(progress.completedDays, 1);
      expect(progress.targetDays, 4);
      expect(progress.completionRate, 0.25);
      expect(progress.plantTier, 1);
      expect(progress.plantStageName, 'Sprout');
      expect(progress.displayProgress, '1/4 days (25%)');
      expect(progress.isGoalMet, isFalse);
    });

    test('computes Tier 2 (Growing bud) when rate is between 50% and 99%', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Exercise',
          category: 'Health',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      // Directly insert 2 check-ins in the week (e.g. Mon Oct 26, Tue Oct 27)
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap(),
      );
      await db.insert(
        DatabaseHelper.tableCheckIns,
        CheckIn(habitId: habit.id!, localDate: '2026-10-27').toMap(),
      );

      final progress = await habitService.getWeeklyProgress(habit.id!);
      expect(progress.completedDays, 2);
      expect(progress.targetDays, 4);
      expect(progress.completionRate, 0.50);
      expect(progress.plantTier, 2);
      expect(progress.plantStageName, 'Growing bud');
      expect(progress.displayProgress, '2/4 days (50%)');
      expect(progress.isGoalMet, isFalse);
    });

    test('computes Tier 3 (Full bloom) when rate reaches 100%', () async {
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Morning Walk',
          category: 'Health',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ),
      );

      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-27').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-28').toMap());

      final progress = await habitService.getWeeklyProgress(habit.id!);
      expect(progress.completedDays, 3);
      expect(progress.targetDays, 3);
      expect(progress.completionRate, 1.0);
      expect(progress.plantTier, 3);
      expect(progress.plantStageName, 'Full bloom');
      expect(progress.displayProgress, '3/3 days (100%)');
      expect(progress.isGoalMet, isTrue);
    });

    test('over-target completion (125%) caps plant at Tier 3 but displays 125% faithfully', () async {
      // Example from AGENTS.md Section 5: Target = 4, 5 check-ins -> 5/4 = 125%
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Guitar Practice',
          category: 'Creative',
          weeklyTarget: 4,
          startedLocalDate: '2026-10-20',
        ),
      );

      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-27').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-28').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-29').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-30').toMap());

      final progress = await habitService.getWeeklyProgress(habit.id!);
      expect(progress.completedDays, 5);
      expect(progress.targetDays, 4);
      expect(progress.completionRate, 1.25);
      expect(progress.plantTier, 3); // Visual tier caps at Tier 3 bloom
      expect(progress.plantStageName, 'Full bloom');
      expect(progress.displayProgress, '5/4 days (125%)'); // Numeric faithful display
      expect(progress.isGoalMet, isTrue);
    });

    test('getAllHabitsWeeklyProgress computes progress across all habits', () async {
      final h1 = await habitService.createHabit(
        const Habit(
          title: 'H1',
          category: 'Health',
          weeklyTarget: 3,
          startedLocalDate: '2026-10-20',
        ),
      );
      final h2 = await habitService.createHabit(
        const Habit(
          title: 'H2',
          category: 'Study',
          weeklyTarget: 5,
          startedLocalDate: '2026-10-20',
        ),
      );

      final list = await habitService.getAllHabitsWeeklyProgress();
      expect(list, hasLength(2));
      expect(list[0].habit.id, h1.id);
      expect(list[1].habit.id, h2.id);
    });

    test('getPastCompletedWeeksCheckInCounts excludes current week and returns whole weeks', () async {
      // Habit started 4 weeks ago: Monday 2026-09-28
      final habit = await habitService.createHabit(
        const Habit(
          title: 'Language Practice',
          category: 'Study',
          weeklyTarget: 4,
          startedLocalDate: '2026-09-28',
        ),
      );

      final db = await dbHelper.database;
      // Week 1 completed: Oct 05 to Oct 11 -> 2 check-ins
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-06').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-08').toMap());

      // Week 2 completed: Oct 12 to Oct 18 -> 3 check-ins
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-13').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-14').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-15').toMap());

      // Week 3 completed: Oct 19 to Oct 25 -> 4 check-ins
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-20').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-21').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-22').toMap());
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-23').toMap());

      // Current week (in-progress): Oct 26 to Nov 01 -> 1 check-in (MUST BE EXCLUDED)
      await db.insert(DatabaseHelper.tableCheckIns, CheckIn(habitId: habit.id!, localDate: '2026-10-26').toMap());

      final counts = await checkInService.getPastCompletedWeeksCheckInCounts(
        habit,
        weekCount: 3,
        referenceDate: monday,
      );

      // Should return chronological counts of the 3 completed weeks: [2, 3, 4]
      expect(counts, [2, 3, 4]);
    });
  });
}
