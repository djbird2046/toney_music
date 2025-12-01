import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../core/audio_controller.dart';
import '../../core/localization/locale_controller.dart';
import '../shared/typography.dart';
import 'macos_player_screen.dart';

class MacosApp extends StatelessWidget {
  const MacosApp({
    super.key,
    required this.controller,
    required this.locale,
    required this.localeResolver,
    required this.localeController,
  });

  final AudioController controller;
  final Locale? locale;
  final Locale Function(Locale?, Iterable<Locale>) localeResolver;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: localeResolver,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.macosAppTitle ?? 'Toney for macOS',
      theme: ThemeData(
        fontFamily: appFontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: MacosPlayerScreen(
        controller: controller,
        localeController: localeController,
      ),
    );
  }
}
