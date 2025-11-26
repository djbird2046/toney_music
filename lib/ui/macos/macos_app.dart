import 'package:flutter/material.dart';

import '../../core/audio_controller.dart';
import '../shared/typography.dart';
import 'macos_player_screen.dart';

class MacosApp extends StatelessWidget {
  const MacosApp({super.key, required this.controller});

  final AudioController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toney for macOS',
      theme: ThemeData(
        fontFamily: appFontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: MacosPlayerScreen(controller: controller),
    );
  }
}
