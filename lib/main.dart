import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/remote/services/config_manager.dart';
import 'core/remote/services/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  try {
    await ConfigManager().init();
    await CacheManager().init();
    runApp(const ToneyApp());
  } catch (e) {
    runApp(ErrorApp(error: e));
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AlertDialog(
          title: const Text('Initialization Failed'),
          content: Text(
              'Failed to initialize the application: $error. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => exit(0),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
