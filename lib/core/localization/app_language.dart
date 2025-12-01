import 'dart:ui';

enum AppLanguage { system, english, chinese }

extension AppLanguageX on AppLanguage {
  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.chinese:
        return const Locale('zh');
    }
  }

  String get storageKey {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.english:
        return 'english';
      case AppLanguage.chinese:
        return 'chinese';
    }
  }

  static AppLanguage fromStorageKey(String? value) {
    switch (value) {
      case 'english':
        return AppLanguage.english;
      case 'chinese':
        return AppLanguage.chinese;
      default:
        return AppLanguage.system;
    }
  }
}
