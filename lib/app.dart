import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/audio_controller.dart';
import 'ui/ios/ios_app.dart';
import 'ui/macos/macos_app.dart';
import 'ui/shared/typography.dart';

class ToneyApp extends StatefulWidget {
  const ToneyApp({super.key});

  @override
  State<ToneyApp> createState() => _ToneyAppState();
}

class _ToneyAppState extends State<ToneyApp> {
  late final AudioController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return IosApp(controller: _controller);
      case TargetPlatform.macOS:
        return MacosApp(controller: _controller);
      default:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: appFontFamily),
          home: Scaffold(
            body: Center(
              child: Text(
                'Unsupported platform: ${defaultTargetPlatform.name}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }
}
