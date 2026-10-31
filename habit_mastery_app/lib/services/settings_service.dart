import '../database/database_helper.dart';
import '../models/app_settings.dart';

class SettingsService {
  final DatabaseHelper? _customDbHelper;

  SettingsService({DatabaseHelper? dbHelper}) : _customDbHelper = dbHelper;

  DatabaseHelper get _dbHelper => _customDbHelper ?? DatabaseHelper.instance;

  static final SettingsService instance = SettingsService();

  Future<AppSettings> loadSettings() async {
    final map = await _dbHelper.getAllSettings();
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _dbHelper.setAllSettings(settings.toMap());
  }

  Future<void> updateSetting(String key, String value) async {
    await _dbHelper.setSetting(key, value);
  }

  Future<AppSettings> resetToDefaults() async {
    const defaultSettings = AppSettings();
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  Future<void> clearAllDatabaseData() async {
    await _dbHelper.clearAllData();
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    final path = await _dbHelper.getDatabasePath();
    final db = await _dbHelper.database;
    final isOpen = db.isOpen;
    final version = await _dbHelper.getDatabaseVersion();
    final rowCounts = await _dbHelper.getTableRowCounts();

    return {
      'path': path,
      'isOpen': isOpen,
      'version': version,
      'databaseName': DatabaseHelper.databaseName,
      'rowCounts': rowCounts,
    };
  }
}
