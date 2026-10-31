import '../database/database_helper.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import '../utils/calendar_utils.dart';
import 'service_exceptions.dart';

/// Service for managing check-ins (create, query, update, delete).
class CheckInService {
  final DatabaseHelper? _customDbHelper;
  final DateTime Function() _nowProvider;

  CheckInService({
    DatabaseHelper? dbHelper,
    DateTime Function()? nowProvider,
  })  : _customDbHelper = dbHelper,
        _nowProvider = nowProvider ?? DateTime.now;

  DatabaseHelper get _dbHelper => _customDbHelper ?? DatabaseHelper.instance;

  static final CheckInService instance = CheckInService();

  /// Records a check-in for today.
  Future<CheckIn> checkInToday(int habitId, {String? note}) async {
    final today = CalendarUtils.formatLocalDate(_nowProvider());
    return createCheckIn(CheckIn(
      habitId: habitId,
      localDate: today,
      note: note,
    ));
  }

  /// Saves a new check-in after verifying date and habit constraints.
  Future<CheckIn> createCheckIn(CheckIn checkIn) async {
    final habit = await _getHabit(checkIn.habitId);
    if (habit == null) {
      throw EntityNotFoundException('Cannot create check-in: Habit #${checkIn.habitId} not found.');
    }

    _validateCheckInDate(checkIn.localDate, habit);

    final db = await _dbHelper.database;

    // Make sure we haven't already checked in for this day
    final existing = await db.query(
      DatabaseHelper.tableCheckIns,
      columns: [DatabaseHelper.columnCheckInId],
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} = ?',
      whereArgs: [checkIn.habitId, checkIn.localDate],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw DuplicateCheckInException(checkIn.habitId, checkIn.localDate);
    }

    final sanitized = checkIn.copyWith(
      note: checkIn.note?.trim(),
    );

    final map = sanitized.toMap()..remove(DatabaseHelper.columnCheckInId);
    final id = await db.insert(
      DatabaseHelper.tableCheckIns,
      map,
    );

    return sanitized.copyWith(id: id);
  }

  /// Retrieves all check-ins for a specific habit, ordered newest first.
  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableCheckIns,
      where: '${DatabaseHelper.columnCheckInHabitId} = ?',
      whereArgs: [habitId],
      orderBy: '${DatabaseHelper.columnCheckInLocalDate} DESC, ${DatabaseHelper.columnCheckInId} DESC',
    );
    return results.map((row) => CheckIn.fromMap(row)).toList();
  }

  /// Retrieves a single check-in by its primary key [id].
  Future<CheckIn?> getCheckInById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableCheckIns,
      where: '${DatabaseHelper.columnCheckInId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CheckIn.fromMap(results.first);
  }

  /// Retrieves the check-in for [habitId] on a specific [localDate], if any.
  Future<CheckIn?> getCheckInForDate(int habitId, String localDate) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableCheckIns,
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} = ?',
      whereArgs: [habitId, localDate],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CheckIn.fromMap(results.first);
  }

  /// Checks if a check-in exists for [habitId] on [localDate].
  Future<bool> hasCheckedInOnDate(int habitId, String localDate) async {
    final checkIn = await getCheckInForDate(habitId, localDate);
    return checkIn != null;
  }

  /// Checks if the habit has already been checked in today.
  Future<bool> hasCheckedInToday(int habitId) async {
    final today = CalendarUtils.formatLocalDate(_nowProvider());
    return hasCheckedInOnDate(habitId, today);
  }

  /// Retrieves check-ins for [habitId] within the inclusive date range [startDate]..[endDate].
  Future<List<CheckIn>> getCheckInsForDateRange(
    int habitId,
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableCheckIns,
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} >= ? AND ${DatabaseHelper.columnCheckInLocalDate} <= ?',
      whereArgs: [habitId, startDate, endDate],
      orderBy: '${DatabaseHelper.columnCheckInLocalDate} ASC',
    );
    return results.map((row) => CheckIn.fromMap(row)).toList();
  }

  /// Retrieves check-ins for [habitId] in the Monday–Sunday week containing [dateInWeek].
  Future<List<CheckIn>> getCheckInsForWeek(int habitId, DateTime dateInWeek) async {
    final mondayStr = CalendarUtils.getMondayString(dateInWeek);
    final sundayStr = CalendarUtils.getSundayString(dateInWeek);
    return getCheckInsForDateRange(habitId, mondayStr, sundayStr);
  }

  /// Updates an existing check-in date or note.
  Future<CheckIn> updateCheckIn(CheckIn checkIn) async {
    if (checkIn.id == null) {
      throw const ValidationException('Cannot update check-in without a valid ID.');
    }

    final existing = await getCheckInById(checkIn.id!);
    if (existing == null) {
      throw EntityNotFoundException('Check-in #${checkIn.id} not found.');
    }

    final habit = await _getHabit(checkIn.habitId);
    if (habit == null) {
      throw EntityNotFoundException('Habit #${checkIn.habitId} not found.');
    }

    _validateCheckInDate(checkIn.localDate, habit);

    final db = await _dbHelper.database;

    // Prevent conflicting date with another check-in for the same habit
    final duplicate = await db.query(
      DatabaseHelper.tableCheckIns,
      columns: [DatabaseHelper.columnCheckInId],
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} = ? AND ${DatabaseHelper.columnCheckInId} != ?',
      whereArgs: [checkIn.habitId, checkIn.localDate, checkIn.id],
      limit: 1,
    );

    if (duplicate.isNotEmpty) {
      throw DuplicateCheckInException(checkIn.habitId, checkIn.localDate);
    }

    final sanitized = checkIn.copyWith(
      note: checkIn.note?.trim(),
    );

    await db.update(
      DatabaseHelper.tableCheckIns,
      sanitized.toMap(),
      where: '${DatabaseHelper.columnCheckInId} = ?',
      whereArgs: [checkIn.id],
    );

    return sanitized;
  }

  /// Deletes a check-in by its [id].
  Future<int> deleteCheckIn(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableCheckIns,
      where: '${DatabaseHelper.columnCheckInId} = ?',
      whereArgs: [id],
    );
  }

  /// Returns weekly check-in counts for recent completed weeks.
  /// Skips the current week and partial starting weeks.
  Future<List<int>> getPastCompletedWeeksCheckInCounts(
    Habit habit, {
    int weekCount = 3,
    DateTime? referenceDate,
  }) async {
    final ref = referenceDate ?? _nowProvider();
    final currentWeekMonday = CalendarUtils.getMondayOfWeek(ref);

    final List<int> weeklyCounts = [];
    final db = await _dbHelper.database;

    // Work backwards through completed Monday-Sunday weeks
    for (int i = 1; i <= weekCount; i++) {
      final weekSunday = DateTime(
        currentWeekMonday.year,
        currentWeekMonday.month,
        currentWeekMonday.day - 1 - (i - 1) * 7,
      );
      final weekMonday = DateTime(
        weekSunday.year,
        weekSunday.month,
        weekSunday.day - 6,
      );

      final weekMondayStr = CalendarUtils.formatLocalDate(weekMonday);
      final weekSundayStr = CalendarUtils.formatLocalDate(weekSunday);

      // Stop if this week started before the habit was created
      if (weekMondayStr.compareTo(habit.startedLocalDate) < 0) {
        break;
      }

      final rows = await db.query(
        DatabaseHelper.tableCheckIns,
        columns: [DatabaseHelper.columnCheckInLocalDate],
        where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} >= ? AND ${DatabaseHelper.columnCheckInLocalDate} <= ?',
        whereArgs: [habit.id, weekMondayStr, weekSundayStr],
      );

      final distinctDates = rows
          .map((r) => r[DatabaseHelper.columnCheckInLocalDate] as String)
          .toSet();
      final count = distinctDates.length > 7 ? 7 : distinctDates.length;
      weeklyCounts.add(count);
    }

    // Return in chronological order (oldest to newest of the selected weeks)
    return weeklyCounts.reversed.toList();
  }

  /// Helper to fetch the parent habit.
  Future<Habit?> _getHabit(int habitId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableHabits,
      where: '${DatabaseHelper.columnHabitId} = ?',
      whereArgs: [habitId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Habit.fromMap(results.first);
  }

  /// Checks that the date is valid, on or after habit start date, and not in the future.
  void _validateCheckInDate(String localDate, Habit habit) {
    if (!CalendarUtils.isValidLocalDate(localDate)) {
      throw ValidationException(
        'Invalid check-in date format: $localDate. Expected YYYY-MM-DD.',
      );
    }

    if (localDate.compareTo(habit.startedLocalDate) < 0) {
      throw ValidationException(
        'Check-in date ($localDate) cannot precede habit start date (${habit.startedLocalDate}).',
      );
    }

    final todayStr = CalendarUtils.formatLocalDate(_nowProvider());
    if (localDate.compareTo(todayStr) > 0) {
      throw ValidationException(
        'Check-in date ($localDate) cannot be in the future (today is $todayStr).',
      );
    }
  }
}
