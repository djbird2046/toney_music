import 'dart:async';

import 'package:hive/hive.dart';
import '../models/connection_config.dart';
import '../exceptions/protocol_exceptions.dart';

/// Connection configuration manager
/// 
/// Responsible for persistent storage and management of all connection configurations
class ConfigManager {
  /// Hive Box instance
  Box<dynamic>? _box;

  /// Box name
  static const String _boxName = 'remote_connections';

  /// Storage key
  static const String _storageKey = 'configs';

  /// Singleton instance
  static final ConfigManager _instance = ConfigManager._internal();
  
  /// Initialization completer (to prevent concurrent initialization)
  Completer<void>? _initCompleter;
  
  /// Whether initialized
  bool _isInitialized = false;

  /// Private constructor
  ConfigManager._internal();

  /// Get singleton instance
  factory ConfigManager() => _instance;

  /// Initialize configuration manager
  /// 
  /// Must be called before using other methods
  /// Uses lock mechanism to prevent file lock errors from concurrent initialization
  Future<void> init() async {
    // If already initialized, return directly
    if (_isInitialized && _box != null) {
      return;
    }
    
    // If initializing, wait for completion
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    
    // Start initialization
    _initCompleter = Completer<void>();
    
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      throw ConfigurationException(
        'Failed to initialize configuration manager',
        originalError: e,
      );
    }
  }
  
  /// Release resources
  Future<void> dispose() async {
    if (_box != null) {
      await _box!.close();
      _box = null;
      _isInitialized = false;
      _initCompleter = null;
    }
  }

  /// Ensure initialized
  void _ensureInitialized() {
    if (_box == null) {
      throw ConfigurationException('Configuration manager not initialized, please call init() first');
    }
  }

  /// Get all connection configurations
  /// 
  /// Returns:
  /// - List of all saved connection configurations
  Future<List<ConnectionConfig>> getAllConfigs() async {
    _ensureInitialized();

    try {
      final raw = _box!.get(_storageKey);
      if (raw is! List) {
        return [];
      }

      final configs = <ConnectionConfig>[];
      for (final item in raw) {
        try {
          if (item is Map) {
            configs.add(ConnectionConfig.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (_) {
          // Skip invalid configuration items
          continue;
        }
      }
      return configs;
    } catch (e) {
      throw ConfigurationException(
        'Failed to read configuration',
        originalError: e,
      );
    }
  }

  /// Save connection configuration
  /// 
  /// If configuration ID already exists, update; otherwise add new
  /// 
  /// Parameters:
  /// - [config] The connection configuration to save
  Future<void> saveConfig(ConnectionConfig config) async {
    _ensureInitialized();

    try {
      final configs = await getAllConfigs();
      
      // Find if configuration with same ID exists
      final index = configs.indexWhere((c) => c.id == config.id);
      
      if (index >= 0) {
        // Update existing configuration
        configs[index] = config.copyWith(updatedAt: DateTime.now());
      } else {
        // Add new configuration
        configs.add(config);
      }

      // Save to Hive
      final jsonList = configs.map((c) => c.toJson()).toList();
      await _box!.put(_storageKey, jsonList);
    } catch (e) {
      throw ConfigurationException(
        'Failed to save configuration',
        originalError: e,
      );
    }
  }

  /// Delete connection configuration
  /// 
  /// Parameters:
  /// - [id] The configuration ID to delete
  /// 
  /// Returns:
  /// - true: Deletion successful
  /// - false: Configuration with specified ID not found
  Future<bool> deleteConfig(String id) async {
    _ensureInitialized();

    try {
      final configs = await getAllConfigs();
      final initialLength = configs.length;
      
      configs.removeWhere((c) => c.id == id);
      
      if (configs.length == initialLength) {
        return false; // Configuration to delete not found
      }

      // Save to Hive
      final jsonList = configs.map((c) => c.toJson()).toList();
      await _box!.put(_storageKey, jsonList);
      
      return true;
    } catch (e) {
      throw ConfigurationException(
        'Failed to delete configuration',
        originalError: e,
      );
    }
  }

  /// Get single connection configuration
  /// 
  /// Parameters:
  /// - [id] Configuration ID
  /// 
  /// Returns:
  /// - Found configuration, or null if not exists
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
        'Failed to read configuration',
        originalError: e,
      );
    }
  }

  /// Clear all configurations
  /// 
  /// Note: This operation is irreversible
  Future<void> clearAllConfigs() async {
    _ensureInitialized();

    try {
      await _box!.delete(_storageKey);
    } catch (e) {
      throw ConfigurationException(
        'Failed to clear configurations',
        originalError: e,
      );
    }
  }

  /// Get configuration count
  Future<int> getConfigCount() async {
    final configs = await getAllConfigs();
    return configs.length;
  }

  /// Check if configuration ID already exists
  Future<bool> configExists(String id) async {
    final config = await getConfig(id);
    return config != null;
  }

  /// Get configurations by protocol type
  Future<List<ConnectionConfig>> getConfigsByType(
    dynamic protocolType,
  ) async {
    final configs = await getAllConfigs();
    return configs.where((c) => c.type == protocolType).toList();
  }
}
