import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';

/// Typed preference operations used by [SettingsService].
/// Tests inject an in-memory store to avoid a native platform channel.
abstract interface class AppPreferencesStore {
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
  Future<void> clear(Set<String> keys);
}

class SharedPreferencesStore implements AppPreferencesStore {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<bool?> getBool(String key) => _preferences.getBool(key);

  @override
  Future<int?> getInt(String key) => _preferences.getInt(key);

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> setInt(String key, int value) => _preferences.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> clear(Set<String> keys) => _preferences.clear(allowList: keys);
}

/// Persists app preferences through SharedPreferences.
class SettingsService {
  final DatabaseHelper? _customDbHelper;
  final AppPreferencesStore? _customPreferences;
  late final AppPreferencesStore _preferences =
      _customPreferences ?? SharedPreferencesStore();

  SettingsService({DatabaseHelper? dbHelper, AppPreferencesStore? preferences})
    : _customDbHelper = dbHelper,
      _customPreferences = preferences;

  DatabaseHelper get _dbHelper => _customDbHelper ?? DatabaseHelper.instance;

  static SettingsService _instance = SettingsService();
  static SettingsService get instance => _instance;

  /// Replaces the app singleton in tests so no native preferences are needed.
  static void setInstanceForTesting(SettingsService? service) {
    _instance = service ?? SettingsService();
  }

  static const Set<String> _preferenceKeys = {
    'notifications_enabled',
    'reminder_time',
    'dark_mode',
    'reduced_motion',
    'sound_effects',
    'haptic_feedback',
    'weekly_goal',
  };

  Future<AppSettings> loadSettings() async {
    return AppSettings(
      notificationsEnabled:
          await _preferences.getBool('notifications_enabled') ?? true,
      reminderTime: await _preferences.getString('reminder_time') ?? '09:00',
      darkMode: await _preferences.getBool('dark_mode') ?? false,
      reducedMotion: await _preferences.getBool('reduced_motion') ?? false,
      soundEffects: await _preferences.getBool('sound_effects') ?? true,
      hapticFeedback: await _preferences.getBool('haptic_feedback') ?? true,
      weeklyGoal: (await _preferences.getInt('weekly_goal') ?? 5)
          .clamp(1, 7)
          .toInt(),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _writeSettings(settings);
  }

  Future<void> updateSetting(String key, String value) async {
    final current = await loadSettings();
    final AppSettings updated;
    switch (key) {
      case 'notifications_enabled':
        updated = current.copyWith(notificationsEnabled: value == 'true');
        break;
      case 'reminder_time':
        updated = current.copyWith(reminderTime: value);
        break;
      case 'dark_mode':
        updated = current.copyWith(darkMode: value == 'true');
        break;
      case 'reduced_motion':
        updated = current.copyWith(reducedMotion: value == 'true');
        break;
      case 'sound_effects':
        updated = current.copyWith(soundEffects: value == 'true');
        break;
      case 'haptic_feedback':
        updated = current.copyWith(hapticFeedback: value == 'true');
        break;
      case 'weekly_goal':
        final parsed = int.tryParse(value);
        if (parsed == null || parsed < 1 || parsed > 7) {
          throw ArgumentError.value(
            value,
            'weekly_goal',
            'Expected 1 through 7.',
          );
        }
        updated = current.copyWith(weeklyGoal: parsed);
        break;
      default:
        throw ArgumentError.value(key, 'key', 'Unknown app setting.');
    }
    await saveSettings(updated);
  }

  Future<AppSettings> resetToDefaults() async {
    const defaults = AppSettings();
    await saveSettings(defaults);
    return defaults;
  }

  /// Clears local habit records and this app's SharedPreferences keys.
  Future<void> clearAllAppData() async {
    await _dbHelper.clearAllData();
    await _preferences.clear(_preferenceKeys);
    await _writeSettings(const AppSettings());
  }

  /// Kept as a compatibility alias for existing screen/test call sites.
  Future<void> clearAllDatabaseData() => clearAllAppData();

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
      'settingsStore': 'SharedPreferences',
      'rowCounts': rowCounts,
    };
  }

  Future<void> _writeSettings(AppSettings settings) async {
    await _preferences.setBool(
      'notifications_enabled',
      settings.notificationsEnabled,
    );
    await _preferences.setString('reminder_time', settings.reminderTime);
    await _preferences.setBool('dark_mode', settings.darkMode);
    await _preferences.setBool('reduced_motion', settings.reducedMotion);
    await _preferences.setBool('sound_effects', settings.soundEffects);
    await _preferences.setBool('haptic_feedback', settings.hapticFeedback);
    await _preferences.setInt(
      'weekly_goal',
      settings.weeklyGoal.clamp(1, 7).toInt(),
    );
  }
}
