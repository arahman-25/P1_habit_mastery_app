import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/database/database_helper.dart';
import 'package:habit_mastery_app/models/app_settings.dart';
import 'package:habit_mastery_app/services/settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('SQLite Storage Layer & SettingsService', () {
    test('initializes database and seeds default settings', () async {
      final helper = DatabaseHelper.instance;
      final settingsMap = await helper.getAllSettings();

      expect(settingsMap, isNotEmpty);
      expect(settingsMap['notifications_enabled'], 'true');
      expect(settingsMap['reminder_time'], '09:00');
      expect(settingsMap['dark_mode'], 'false');
      expect(settingsMap['sound_effects'], 'true');
      expect(settingsMap['haptic_feedback'], 'true');
      expect(settingsMap['weekly_goal'], '5');
    });

    test('SettingsService loads and updates settings in SQLite', () async {
      final service = SettingsService();

      final initial = await service.loadSettings();
      expect(initial.notificationsEnabled, isTrue);

      const modified = AppSettings(
        notificationsEnabled: false,
        reminderTime: '20:45',
        darkMode: true,
        soundEffects: false,
        hapticFeedback: false,
        weeklyGoal: 7,
      );

      await service.saveSettings(modified);

      final reloaded = await service.loadSettings();
      expect(reloaded.notificationsEnabled, isFalse);
      expect(reloaded.reminderTime, '20:45');
      expect(reloaded.darkMode, isTrue);
      expect(reloaded.soundEffects, isFalse);
      expect(reloaded.hapticFeedback, isFalse);
      expect(reloaded.weeklyGoal, 7);
    });

    test('clearAllDatabaseData resets settings to default in SQLite', () async {
      final service = SettingsService();

      await service.saveSettings(
        const AppSettings(
          notificationsEnabled: false,
          reminderTime: '23:00',
          darkMode: true,
          weeklyGoal: 3,
        ),
      );

      await service.clearAllDatabaseData();

      final settingsAfterReset = await service.loadSettings();
      expect(settingsAfterReset.notificationsEnabled, isTrue);
      expect(settingsAfterReset.reminderTime, '09:00');
      expect(settingsAfterReset.darkMode, isFalse);
      expect(settingsAfterReset.weeklyGoal, 5);
    });

    test('verifies storage info reports database status and row counts', () async {
      final service = SettingsService();
      final info = await service.getStorageInfo();

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
