import 'package:hive/hive.dart';

import '../localization/app_language.dart';

class LanguagePreferenceStorage {
  static const _boxName = 'toney_language_preferences';
  static const _keyPreference = 'preferred_language';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> save(AppLanguage preference) async {
    final box = _box;
    if (box == null) return;
    await box.put(_keyPreference, preference.storageKey);
  }

  AppLanguage load() {
    final box = _box;
    if (box == null) {
      return AppLanguage.system;
    }
    final raw = box.get(_keyPreference) as String?;
    return AppLanguageX.fromStorageKey(raw);
  }
}
