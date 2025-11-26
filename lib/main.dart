import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/remote/services/config_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // 初始化远程配置管理器
  await ConfigManager().init();
  
  runApp(const ToneyApp());
}
