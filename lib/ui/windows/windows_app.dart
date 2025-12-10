import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../core/audio_controller.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/theme/theme_controller.dart';
import '../macos/macos_colors.dart';
import '../macos/macos_player_screen.dart';
import '../macos/theme/macos_dark_colors.dart';
import '../macos/theme/macos_light_colors.dart';
import '../shared/typography.dart';
import 'windows_frame.dart';

class WindowsApp extends StatelessWidget {
  const WindowsApp({
    super.key,
    required this.controller,
    required this.locale,
    required this.localeResolver,
    required this.localeController,
    required this.themeController,
  });

  final AudioController controller;
  final Locale? locale;
  final Locale Function(Locale?, Iterable<Locale>) localeResolver;
  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePreference>(
      valueListenable: themeController.preference,
      builder: (_, preference, __) {
        final lightTheme = _buildTheme(macosLightColors);
        final darkTheme = _buildTheme(macosDarkColors);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: localeResolver,
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.macosAppTitle ?? 'Toney Music',
          themeMode: preference.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: WindowsFrame(
            child: MacosPlayerScreen(
              controller: controller,
              localeController: localeController,
              themeController: themeController,
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(MacosColors colors) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.accentBlue,
      brightness: colors.brightness,
      background: colors.background,
    );
    return ThemeData(
      fontFamily: appFontFamily,
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.contentBackground,
      dividerColor: colors.divider,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
