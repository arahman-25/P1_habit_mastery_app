import '../database/database_helper.dart';
import '../models/habit.dart';
import '../models/habit_weekly_progress.dart';
import '../utils/calendar_utils.dart';
import 'service_exceptions.dart';

/// Service for creating, updating, deleting, and calculating progress for habits.
class HabitService {
  final DatabaseHelper _dbHelper;
  final DateTime Function() _nowProvider;

  HabitService({
    DatabaseHelper? dbHelper,
    DateTime Function()? nowProvider,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _nowProvider = nowProvider ?? DateTime.now;

  static final HabitService instance = HabitService();

  /// Saves a new habit after checking required fields and target limits.
  Future<Habit> createHabit(Habit habit) async {
    _validateHabitFields(habit);

    final db = await _dbHelper.database;
    final sanitized = habit.copyWith(
      title: habit.title.trim(),
      category: habit.category.trim(),
      motivation: habit.motivation?.trim(),
    );

    final map = sanitized.toMap()..remove(DatabaseHelper.columnHabitId);
    final id = await db.insert(
      DatabaseHelper.tableHabits,
      map,
    );

    return sanitized.copyWith(id: id);
  }

  /// Retrieves all habits ordered by ID ascending.
  Future<List<Habit>> getAllHabits() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableHabits,
      orderBy: '${DatabaseHelper.columnHabitId} ASC',
    );
    return results.map((row) => Habit.fromMap(row)).toList();
  }

  /// Retrieves a specific habit by its primary key [id].
  /// Returns `null` if no habit with [id] exists.
  Future<Habit?> getHabitById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableHabits,
      where: '${DatabaseHelper.columnHabitId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Habit.fromMap(results.first);
  }

  /// Retrieves habits belonging to [category].
  /// If [category] is 'All' (case-insensitive), returns all habits.
  Future<List<Habit>> getHabitsByCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') {
      return getAllHabits();
    }

    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableHabits,
      where: 'LOWER(${DatabaseHelper.columnHabitCategory}) = LOWER(?)',
      whereArgs: [trimmed],
      orderBy: '${DatabaseHelper.columnHabitId} ASC',
    );
    return results.map((row) => Habit.fromMap(row)).toList();
  }

  /// Updates an existing habit.
  Future<Habit> updateHabit(Habit habit) async {
    if (habit.id == null) {
      throw const ValidationException('Cannot update a habit without a valid ID.');
    }

    final existing = await getHabitById(habit.id!);
    if (existing == null) {
      throw EntityNotFoundException('Habit #${habit.id} not found.');
    }

    _validateHabitFields(habit);

    final db = await _dbHelper.database;

    // Don't allow changing start date to after existing check-ins
    final conflictingCheckIns = await db.query(
      DatabaseHelper.tableCheckIns,
      columns: [DatabaseHelper.columnCheckInLocalDate],
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} < ?',
      whereArgs: [habit.id, habit.startedLocalDate],
      orderBy: '${DatabaseHelper.columnCheckInLocalDate} ASC',
      limit: 1,
    );

    if (conflictingCheckIns.isNotEmpty) {
      final earliestDate = conflictingCheckIns.first[DatabaseHelper.columnCheckInLocalDate];
      throw ValidationException(
        'Cannot change start date to ${habit.startedLocalDate} because check-in records exist prior to this date (e.g. $earliestDate). Please adjust or delete those check-in entries first.',
      );
    }

    final sanitized = habit.copyWith(
      title: habit.title.trim(),
      category: habit.category.trim(),
      motivation: habit.motivation?.trim(),
    );

    await db.update(
      DatabaseHelper.tableHabits,
      sanitized.toMap(),
      where: '${DatabaseHelper.columnHabitId} = ?',
      whereArgs: [habit.id],
    );

    return sanitized;
  }

  /// Deletes a habit and its check-ins.
  Future<int> deleteHabit(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableHabits,
      where: '${DatabaseHelper.columnHabitId} = ?',
      whereArgs: [id],
    );
  }

  /// Calculates weekly completion rate and plant stage for the given week.
  Future<HabitWeeklyProgress> getWeeklyProgress(
    int habitId, {
    DateTime? referenceDate,
  }) async {
    final habit = await getHabitById(habitId);
    if (habit == null) {
      throw EntityNotFoundException('Habit #$habitId not found.');
    }

    final ref = referenceDate ?? _nowProvider();
    final mondayStr = CalendarUtils.getMondayString(ref);
    final sundayStr = CalendarUtils.getSundayString(ref);

    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCheckIns,
      columns: [DatabaseHelper.columnCheckInLocalDate],
      where: '${DatabaseHelper.columnCheckInHabitId} = ? AND ${DatabaseHelper.columnCheckInLocalDate} >= ? AND ${DatabaseHelper.columnCheckInLocalDate} <= ?',
      whereArgs: [habitId, mondayStr, sundayStr],
      orderBy: '${DatabaseHelper.columnCheckInLocalDate} ASC',
    );

    // Count distinct dates completed within the Monday-Sunday week
    final distinctDates = rows
        .map((r) => r[DatabaseHelper.columnCheckInLocalDate] as String)
        .toSet()
        .toList()
      ..sort();

    final completedDays = distinctDates.length;
    final rate = habit.weeklyTarget > 0 ? (completedDays / habit.weeklyTarget) : 0.0;
    final plantTier = CalendarUtils.calculatePlantTier(rate);
    final plantStageName = CalendarUtils.getPlantStageName(plantTier);

    return HabitWeeklyProgress(
      habit: habit,
      weekStartLocalDate: mondayStr,
      weekEndLocalDate: sundayStr,
      completedDays: completedDays,
      targetDays: habit.weeklyTarget,
      completionRate: rate,
      plantTier: plantTier,
      plantStageName: plantStageName,
      completedDates: distinctDates,
    );
  }

  /// Returns weekly progress for all habits (optionally filtered by [category]).
  Future<List<HabitWeeklyProgress>> getAllHabitsWeeklyProgress({
    DateTime? referenceDate,
    String? category,
  }) async {
    final habits = category != null
        ? await getHabitsByCategory(category)
        : await getAllHabits();

    final List<HabitWeeklyProgress> progressList = [];
    for (final habit in habits) {
      final progress = await getWeeklyProgress(
        habit.id!,
        referenceDate: referenceDate,
      );
      progressList.add(progress);
    }
    return progressList;
  }

  /// Basic validation for habit fields.
  void _validateHabitFields(Habit habit) {
    if (habit.title.trim().isEmpty) {
      throw const ValidationException('Habit title cannot be empty.');
    }
    if (habit.category.trim().isEmpty) {
      throw const ValidationException('Habit category cannot be empty.');
    }
    if (habit.weeklyTarget < 1 || habit.weeklyTarget > 7) {
      throw ValidationException(
        'Weekly target must be between 1 and 7 days (received ${habit.weeklyTarget}).',
      );
    }
    if (!CalendarUtils.isValidLocalDate(habit.startedLocalDate)) {
      throw ValidationException(
        'Invalid habit start date format: ${habit.startedLocalDate}. Expected YYYY-MM-DD.',
      );
    }

    final todayStr = CalendarUtils.formatLocalDate(_nowProvider());
    if (habit.startedLocalDate.compareTo(todayStr) > 0) {
      throw ValidationException(
        'Habit start date (${habit.startedLocalDate}) cannot be in the future (today is $todayStr).',
      );
    }
  }
}
