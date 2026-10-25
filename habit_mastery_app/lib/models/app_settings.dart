class AppSettings {
  final bool notificationsEnabled;
  final String reminderTime;
  final bool darkMode;
  final bool soundEffects;
  final bool hapticFeedback;
  final int weeklyGoal;

  const AppSettings({
    this.notificationsEnabled = true,
    this.reminderTime = '09:00',
    this.darkMode = false,
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.weeklyGoal = 5,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? reminderTime,
    bool? darkMode,
    bool? soundEffects,
    bool? hapticFeedback,
    int? weeklyGoal,
  }) {
    return AppSettings(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      darkMode: darkMode ?? this.darkMode,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      notificationsEnabled: map['notifications_enabled'] != 'false',
      reminderTime: map['reminder_time'] ?? '09:00',
      darkMode: map['dark_mode'] == 'true',
      soundEffects: map['sound_effects'] != 'false',
      hapticFeedback: map['haptic_feedback'] != 'false',
      weeklyGoal: int.tryParse(map['weekly_goal'] ?? '5') ?? 5,
    );
  }

  Map<String, String> toMap() {
    return {
      'notifications_enabled': notificationsEnabled.toString(),
      'reminder_time': reminderTime,
      'dark_mode': darkMode.toString(),
      'sound_effects': soundEffects.toString(),
      'haptic_feedback': hapticFeedback.toString(),
      'weekly_goal': weeklyGoal.toString(),
    };
  }
}
