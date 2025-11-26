import 'package:flutter/cupertino.dart';

import '../../core/audio_controller.dart';
import '../shared/typography.dart';
import 'ios_player_screen.dart';

class IosApp extends StatelessWidget {
  const IosApp({super.key, required this.controller});

  final AudioController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Toney iOS',
      theme: CupertinoThemeData(
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: appFontFamily),
        ),
      ),
      home: IosPlayerScreen(controller: controller),
    );
  }
}
