import 'package:flutter/widgets.dart';

import '../storage/theme_preference_storage.dart';
import 'app_theme_mode.dart';

class ThemeController {
  ThemeController({ThemePreferenceStorage? storage})
    : _storage = storage ?? ThemePreferenceStorage();

  final ThemePreferenceStorage _storage;
  final ValueNotifier<AppThemePreference> preference =
      ValueNotifier<AppThemePreference>(AppThemePreference.system);

  AppThemePreference get currentPreference => preference.value;

  Future<void> init() async {
    await _storage.init();
    preference.value = _storage.load();
  }

  Future<void> setPreference(AppThemePreference newPreference) async {
    if (preference.value == newPreference) return;
    preference.value = newPreference;
    await _storage.save(newPreference);
  }

  void dispose() {
    preference.dispose();
  }
}
