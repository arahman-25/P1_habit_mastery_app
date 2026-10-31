import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_app/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default values', () {
      const settings = AppSettings();
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.reminderTime, '09:00');
      expect(settings.darkMode, isFalse);
      expect(settings.reducedMotion, isFalse);
      expect(settings.soundEffects, isTrue);
      expect(settings.hapticFeedback, isTrue);
      expect(settings.weeklyGoal, 5);
    });

    test('fromMap and toMap roundtrip', () {
      const original = AppSettings(
        notificationsEnabled: false,
        reminderTime: '18:30',
        darkMode: true,
        reducedMotion: true,
        soundEffects: false,
        hapticFeedback: false,
        weeklyGoal: 4,
      );

      final map = original.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.reminderTime, original.reminderTime);
      expect(restored.darkMode, original.darkMode);
      expect(restored.reducedMotion, original.reducedMotion);
      expect(restored.soundEffects, original.soundEffects);
      expect(restored.hapticFeedback, original.hapticFeedback);
      expect(restored.weeklyGoal, original.weeklyGoal);
    });

    test('copyWith updates individual fields', () {
      const settings = AppSettings();
      final updated = settings.copyWith(reminderTime: '07:15', weeklyGoal: 6);

      expect(updated.reminderTime, '07:15');
      expect(updated.weeklyGoal, 6);
      expect(updated.notificationsEnabled, isTrue);
      expect(updated.darkMode, isFalse);
    });
  });
}
