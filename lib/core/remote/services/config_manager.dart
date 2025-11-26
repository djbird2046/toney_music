import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_config.dart';
import '../exceptions/protocol_exceptions.dart';

/// 连接配置管理器
/// 
/// 负责持久化存储和管理所有的连接配置
class ConfigManager {
  /// SharedPreferences实例
  SharedPreferences? _prefs;

  /// 存储键名
  static const String _storageKey = 'remote_file_connections';

  /// 单例实例
  static final ConfigManager _instance = ConfigManager._internal();

  /// 私有构造函数
  ConfigManager._internal();

  /// 获取单例实例
  factory ConfigManager() => _instance;

  /// 初始化配置管理器
  /// 
  /// 必须在使用其他方法之前调用此方法
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw ConfigurationException(
        '初始化配置管理器失败',
        originalError: e,
      );
    }
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw ConfigurationException('配置管理器未初始化，请先调用init()方法');
    }
  }

  /// 获取所有连接配置
  /// 
  /// 返回：
  /// - 所有已保存的连接配置列表
  Future<List<ConnectionConfig>> getAllConfigs() async {
    _ensureInitialized();

    try {
      final jsonString = _prefs!.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => ConnectionConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ConfigurationException(
        '读取配置失败',
        originalError: e,
      );
    }
  }

  /// 保存连接配置
  /// 
  /// 如果配置ID已存在，则更新；否则新增
  /// 
  /// 参数：
  /// - [config] 要保存的连接配置
  Future<void> saveConfig(ConnectionConfig config) async {
    _ensureInitialized();

    try {
      final configs = await getAllConfigs();
      
      // 查找是否存在相同ID的配置
      final index = configs.indexWhere((c) => c.id == config.id);
      
      if (index >= 0) {
        // 更新现有配置
        configs[index] = config.copyWith(updatedAt: DateTime.now());
      } else {
        // 添加新配置
        configs.add(config);
      }

      // 保存到SharedPreferences
      final jsonList = configs.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs!.setString(_storageKey, jsonString);
    } catch (e) {
      throw ConfigurationException(
        '保存配置失败',
        originalError: e,
      );
    }
  }

  /// 删除连接配置
  /// 
  /// 参数：
  /// - [id] 要删除的配置ID
  /// 
  /// 返回：
  /// - true: 删除成功
  /// - false: 未找到指定ID的配置
  Future<bool> deleteConfig(String id) async {
    _ensureInitialized();

    try {
      final configs = await getAllConfigs();
      final initialLength = configs.length;
      
      configs.removeWhere((c) => c.id == id);
      
      if (configs.length == initialLength) {
        return false; // 未找到要删除的配置
      }

      // 保存到SharedPreferences
      final jsonList = configs.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs!.setString(_storageKey, jsonString);
      
      return true;
    } catch (e) {
      throw ConfigurationException(
        '删除配置失败',
        originalError: e,
      );
    }
  }

  /// 获取单个连接配置
  /// 
  /// 参数：
  /// - [id] 配置ID
  /// 
  /// 返回：
  /// - 找到的配置，如果不存在则返回null
  Future<ConnectionConfig?> getConfig(String id) async {
    _ensureInitialized();

    try {
      final configs = await getAllConfigs();
      for (final config in configs) {
        if (config.id == id) {
          return config;
        }
      }
      return null;
    } catch (e) {
      throw ConfigurationException(
        '读取配置失败',
        originalError: e,
      );
    }
  }

  /// 清除所有配置
  /// 
  /// 注意：此操作不可恢复
  Future<void> clearAllConfigs() async {
    _ensureInitialized();

    try {
      await _prefs!.remove(_storageKey);
    } catch (e) {
      throw ConfigurationException(
        '清除配置失败',
        originalError: e,
      );
    }
  }

  /// 获取配置数量
  Future<int> getConfigCount() async {
    final configs = await getAllConfigs();
    return configs.length;
  }

  /// 检查配置ID是否已存在
  Future<bool> configExists(String id) async {
    final config = await getConfig(id);
    return config != null;
  }

  /// 按协议类型获取配置列表
  Future<List<ConnectionConfig>> getConfigsByType(
    dynamic protocolType,
  ) async {
    final configs = await getAllConfigs();
    return configs.where((c) => c.type == protocolType).toList();
  }
}

