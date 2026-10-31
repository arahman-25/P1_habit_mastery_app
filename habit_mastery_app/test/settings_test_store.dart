import 'package:habit_mastery_app/services/settings_service.dart';

class MemoryPreferencesStore implements AppPreferencesStore {
  final Map<String, Object> values;

  MemoryPreferencesStore([Map<String, Object>? initial])
    : values = Map<String, Object>.from(initial ?? {});

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<int?> getInt(String key) async => values[key] as int?;
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> clear(Set<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}
