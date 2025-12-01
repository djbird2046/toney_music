import 'package:flutter/cupertino.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../core/audio_controller.dart';
import '../shared/typography.dart';
import 'ios_player_screen.dart';

class IosApp extends StatelessWidget {
  const IosApp({
    super.key,
    required this.controller,
    required this.locale,
    required this.localeResolver,
  });

  final AudioController controller;
  final Locale? locale;
  final Locale Function(Locale?, Iterable<Locale>) localeResolver;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: localeResolver,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.iosAppTitle ?? 'Toney iOS',
      theme: CupertinoThemeData(
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: appFontFamily),
        ),
      ),
      home: IosPlayerScreen(controller: controller),
    );
  }
}
