import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/audio_controller.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'ui/ios/ios_app.dart';
import 'ui/macos/macos_app.dart';
import 'ui/shared/typography.dart';
import 'ui/windows/windows_app.dart';

class ToneyApp extends StatefulWidget {
  const ToneyApp({super.key});

  @override
  State<ToneyApp> createState() => _ToneyAppState();
}

class _ToneyAppState extends State<ToneyApp> {
  late final AudioController _controller;
  late final LocaleController _localeController;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _controller = AudioController();
    _controller.init();
    _localeController = LocaleController();
    unawaited(_localeController.init());
    _themeController = ThemeController();
    unawaited(_themeController.init());
  }

  @override
  void dispose() {
    _themeController.dispose();
    _localeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: _localeController.preference,
      builder: (context, preference, _) {
        final locale = preference.locale;
        Locale localeResolver(
          Locale? deviceLocale,
          Iterable<Locale> supported,
        ) {
          final resolved = _localeController.resolveDeviceLocale(deviceLocale);
          return supported.firstWhere(
            (candidate) => candidate.languageCode == resolved.languageCode,
            orElse: () => supported.first,
          );
        }

        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
            return IosApp(
              controller: _controller,
              locale: locale,
              localeResolver: localeResolver,
            );
          case TargetPlatform.macOS:
            return MacosApp(
              controller: _controller,
              locale: locale,
              localeResolver: localeResolver,
              localeController: _localeController,
              themeController: _themeController,
            );
          case TargetPlatform.windows:
            return WindowsApp(
              controller: _controller,
              locale: locale,
              localeResolver: localeResolver,
              localeController: _localeController,
              themeController: _themeController,
            );
          default:
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: appFontFamily),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              localeResolutionCallback: localeResolver,
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => Text(
                      AppLocalizations.of(
                        context,
                      )!.unsupportedPlatform(defaultTargetPlatform.name),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
