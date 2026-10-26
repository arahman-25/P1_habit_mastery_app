import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'habit_mastery.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableSettings = 'app_settings';
  static const String tableHabits = 'habits';
  static const String tableHabitLogs = 'habit_logs';

  // Settings column names
  static const String columnKey = 'key';
  static const String columnValue = 'value';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Settings table for persistent configuration
    await db.execute('''
      CREATE TABLE $tableSettings (
        $columnKey TEXT PRIMARY KEY,
        $columnValue TEXT NOT NULL
      )
    ''');

    // Seed default settings
    final defaultSettings = {
      'notifications_enabled': 'true',
      'reminder_time': '09:00',
      'dark_mode': 'false',
      'sound_effects': 'true',
      'haptic_feedback': 'true',
      'weekly_goal': '5',
    };

    final batch = db.batch();
    for (final entry in defaultSettings.entries) {
      batch.insert(
        tableSettings,
        {
          columnKey: entry.key,
          columnValue: entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Habits table ready for the rest of the application
    await db.execute('''
      CREATE TABLE $tableHabits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        frequency TEXT NOT NULL DEFAULT 'daily',
        target_days INTEGER NOT NULL DEFAULT 7,
        created_at TEXT NOT NULL,
        color INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Habit completion logs table
    await db.execute('''
      CREATE TABLE $tableHabitLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
  }

  // Habit Management
  

  // Settings operations
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final results = await db.query(tableSettings);
    final Map<String, String> map = {};
    for (final row in results) {
      final key = row[columnKey] as String?;
      final value = row[columnValue] as String?;
      if (key != null && value != null) {
        map[key] = value;
      }
    }
    return map;
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      tableSettings,
      columns: [columnValue],
      where: '$columnKey = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first[columnValue] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {
        columnKey: key,
        columnValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setAllSettings(Map<String, String> settings) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in settings.entries) {
      batch.insert(
        tableSettings,
        {
          columnKey: entry.key,
          columnValue: entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Database info & maintenance
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, databaseName);
  }

  Future<int> getDatabaseVersion() async {
    final db = await database;
    final results = await db.rawQuery('PRAGMA user_version;');
    if (results.isNotEmpty && results.first.values.isNotEmpty) {
      return (results.first.values.first as int?) ?? databaseVersion;
    }
    return databaseVersion;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableHabitLogs);
      await txn.delete(tableHabits);
      await txn.delete(tableSettings);

      // Re-seed default settings
      final defaultSettings = {
        'notifications_enabled': 'true',
        'reminder_time': '09:00',
        'dark_mode': 'false',
        'sound_effects': 'true',
        'haptic_feedback': 'true',
        'weekly_goal': '5',
      };

      for (final entry in defaultSettings.entries) {
        await txn.insert(
          tableSettings,
          {
            columnKey: entry.key,
            columnValue: entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
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
