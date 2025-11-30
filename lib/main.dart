import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toney_music/core/model/chat_message.dart';

import 'app.dart';
import 'core/remote/services/config_manager.dart';
import 'core/remote/services/cache_manager.dart';
import 'core/storage/liteagent_config_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
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
