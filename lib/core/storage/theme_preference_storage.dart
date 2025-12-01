import 'package:hive/hive.dart';

import '../theme/app_theme_mode.dart';

class ThemePreferenceStorage {
  static const _boxName = 'toney_theme_preferences';
  static const _keyPreference = 'preferred_theme';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> save(AppThemePreference preference) async {
    final box = _box;
    if (box == null) return;
    await box.put(_keyPreference, preference.storageKey);
  }

  AppThemePreference load() {
    final box = _box;
    if (box == null) {
      return AppThemePreference.system;
    }
    final raw = box.get(_keyPreference) as String?;
    return AppThemePreference.fromStorageKey(raw);
  }
}
