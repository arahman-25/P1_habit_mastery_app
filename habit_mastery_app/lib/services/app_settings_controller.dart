import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'settings_service.dart';

/// App-wide view of persisted settings used to apply theme/accessibility choices.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    try {
      _settings = await SettingsService.instance.loadSettings();
    } catch (_) {
      // Keep safe defaults if local preference storage cannot be read.
    }
    notifyListeners();
  }

  void update(AppSettings settings) {
    _settings = settings;
    notifyListeners();
  }
}
