import 'package:flutter/widgets.dart';

import '../storage/language_preference_storage.dart';
import 'app_language.dart';

class LocaleController {
  LocaleController({LanguagePreferenceStorage? storage})
    : _storage = storage ?? LanguagePreferenceStorage();

  final LanguagePreferenceStorage _storage;
  final ValueNotifier<AppLanguage> preference = ValueNotifier<AppLanguage>(
    AppLanguage.system,
  );

  AppLanguage get currentPreference => preference.value;
  Locale? get overrideLocale => currentPreference.locale;

  Future<void> init() async {
    await _storage.init();
    preference.value = _storage.load();
  }

  Future<void> setPreference(AppLanguage newPreference) async {
    if (preference.value == newPreference) return;
    preference.value = newPreference;
    await _storage.save(newPreference);
  }

  Locale resolveDeviceLocale(Locale? deviceLocale) {
    final override = overrideLocale;
    if (override != null) {
      return override;
    }
    if (deviceLocale == null) {
      return const Locale('en');
    }
    if (deviceLocale.languageCode.toLowerCase() == 'zh') {
      return const Locale('zh');
    }
    return const Locale('en');
  }

  void dispose() {
    preference.dispose();
  }
}
