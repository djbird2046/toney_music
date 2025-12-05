import 'package:hive/hive.dart';

class LiteAgentConfig {
  const LiteAgentConfig({required this.baseUrl, required this.apiKey});

  final String baseUrl;
  final String apiKey;

  static const empty = LiteAgentConfig(baseUrl: '', apiKey: '');

  bool get isNotEmpty => baseUrl.isNotEmpty && apiKey.isNotEmpty;
}

class LiteAgentConfigStorage {
  static const _boxName = 'toney_liteagent_config';
  static const _baseUrlKey = 'baseUrl';
  static const _apiKeyKey = 'apiKey';

  Box<String>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  LiteAgentConfig load() {
    final box = _box;
    if (box == null) {
      return LiteAgentConfig.empty;
    }
    final baseUrl = box.get(_baseUrlKey, defaultValue: '');
    final apiKey = box.get(_apiKeyKey, defaultValue: '');
    return LiteAgentConfig(baseUrl: baseUrl!, apiKey: apiKey!);
  }

  Future<void> save(LiteAgentConfig config) async {
    final box = _box;
    if (box == null) return;
    await box.put(_baseUrlKey, config.baseUrl);
    await box.put(_apiKeyKey, config.apiKey);
  }

  Future<void> clear() async {
    final box = _box;
    if (box == null) return;
    await box.delete(_baseUrlKey);
    await box.delete(_apiKeyKey);
  }
}
