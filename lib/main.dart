import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/remote/services/config_manager.dart';
import 'core/remote/services/cache_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Initialize remote configuration manager
  await ConfigManager().init();
  
  // Initialize cache manager
  await CacheManager().init();
  
  runApp(const ToneyApp());
}
