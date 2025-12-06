import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toney_music/core/model/chat_message.dart';

import 'app.dart';
import 'core/remote/services/cache_manager.dart';
import 'core/remote/services/config_manager.dart';
import 'core/storage/liteagent_config_storage.dart';

late File _appLogFile;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logDir = Directory('${Directory.current.path}/log');
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await _initLogging(logDir);
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(SenderAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  // Initialize remote configuration manager
  await ConfigManager().init();

  // Initialize cache manager
  await CacheManager().init();

  // Initialize LiteAgent config storage
  await LiteAgentConfigStorage().init();

  runApp(const ToneyApp());
}

Future<void> _initLogging(Directory logDir) async {
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  _appLogFile = File('${logDir.path}/app_debug.log');
  if (!await _appLogFile.exists()) {
    await _appLogFile.create(recursive: true);
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      _appendLog(
        'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
      ),
    );
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    unawaited(_appendLog('Uncaught: $error\n$stack'));
    return false; // allow default crash/propagation behavior
  };
}

Future<void> _appendLog(String message) async {
  final timestamp = DateTime.now().toIso8601String();
  final formatted = '[$timestamp] $message\n';
  try {
    await _appLogFile.writeAsString(formatted, mode: FileMode.append);
  } catch (_) {
    // Swallow logging failures to avoid crashing the app.
  }
}
