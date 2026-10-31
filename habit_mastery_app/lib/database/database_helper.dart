import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'habit_mastery.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableHabits = 'habits';
  static const String tableCheckIns = 'check_ins';

  // Habit column names
  static const String columnHabitId = 'id';
  static const String columnHabitTitle = 'title';
  static const String columnHabitCategory = 'category';
  static const String columnHabitWeeklyTarget = 'weeklyTarget';
  static const String columnHabitStartedLocalDate = 'startedLocalDate';
  static const String columnHabitMotivation = 'motivation';

  // CheckIn column names
  static const String columnCheckInId = 'id';
  static const String columnCheckInHabitId = 'habitId';
  static const String columnCheckInLocalDate = 'localDate';
  static const String columnCheckInNote = 'note';

  final String _dbName;
  Database? _database;

  // Singleton instance for app usage
  DatabaseHelper._internal({String name = databaseName}) : _dbName = name;
  static DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  /// Injects an isolated DatabaseHelper instance for tests
  static void setTestInstance(DatabaseHelper? helper) {
    _instance = helper ?? DatabaseHelper._internal();
  }

  /// Factory constructor for isolated test databases
  factory DatabaseHelper.forTesting({String? name}) {
    return DatabaseHelper._internal(name: name ?? inMemoryDatabasePath);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (_dbName == inMemoryDatabasePath || _dbName.startsWith(':memory:')) {
      path = inMemoryDatabasePath;
    } else {
      final databasesPath = await databaseFactory.getDatabasesPath();
      path = join(databasesPath, _dbName);
    }

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Habits table
    await db.execute('''
      CREATE TABLE $tableHabits (
        $columnHabitId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnHabitTitle TEXT NOT NULL,
        $columnHabitCategory TEXT NOT NULL,
        $columnHabitWeeklyTarget INTEGER NOT NULL CHECK($columnHabitWeeklyTarget BETWEEN 1 AND 7),
        $columnHabitStartedLocalDate TEXT NOT NULL,
        $columnHabitMotivation TEXT
      )
    ''');

    // Check-ins table (cascades when habit deleted, 1 check-in per day)
    await db.execute('''
      CREATE TABLE $tableCheckIns (
        $columnCheckInId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCheckInHabitId INTEGER NOT NULL,
        $columnCheckInLocalDate TEXT NOT NULL,
        $columnCheckInNote TEXT,
        FOREIGN KEY ($columnCheckInHabitId) REFERENCES $tableHabits ($columnHabitId) ON DELETE CASCADE,
        CONSTRAINT uq_habit_date UNIQUE ($columnCheckInHabitId, $columnCheckInLocalDate)
      )
    ''');

  }

  // Database info & maintenance
  Future<String> getDatabasePath() async {
    if (_dbName == inMemoryDatabasePath || _dbName.startsWith(':memory:')) {
      return inMemoryDatabasePath;
    }
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _dbName);
  }

  Future<int> getDatabaseVersion() async {
    final db = await database;
    final results = await db.rawQuery('PRAGMA user_version;');
    if (results.isNotEmpty && results.first.values.isNotEmpty) {
      return (results.first.values.first as int?) ?? databaseVersion;
    }
    return databaseVersion;
  }

  Future<Map<String, int>> getTableRowCounts() async {
    final db = await database;
    final habitsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableHabits'),
        ) ??
        0;
    final checkInsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableCheckIns'),
        ) ??
        0;
    return {
      tableHabits: habitsCount,
      tableCheckIns: checkInsCount,
    };
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableCheckIns);
      await txn.delete(tableHabits);
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
