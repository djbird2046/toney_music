import 'package:flutter/material.dart';

/// Exposes the supported theme modes for the macOS client.
enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.storageKey);

  final String storageKey;

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemePreference fromStorageKey(String? key) {
    return AppThemePreference.values.firstWhere(
      (option) => option.storageKey == key,
      orElse: () => AppThemePreference.system,
    );
  }
}
