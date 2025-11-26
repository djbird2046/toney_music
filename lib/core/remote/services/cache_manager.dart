import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'config_manager.dart';
import 'client_factory.dart';
import 'samba_client.dart';
import 'ftp_client.dart';
import 'sftp_client.dart';
import 'webdav_client.dart';
import '../exceptions/protocol_exceptions.dart';

/// Remote audio file cache manager
/// 
/// Responsible for managing local cache of remote audio files, including download, storage and retrieval
class CacheManager {
  /// Singleton instance
  static final CacheManager _instance = CacheManager._internal();
  
  /// Get singleton instance
  factory CacheManager() => _instance;
  
  /// Private constructor
  CacheManager._internal();
  
  /// Cache directory name
  static const String _cacheDirName = 'audio_cache';
  
  /// Cache directory
  Directory? _cacheDir;
  
  /// Configuration manager
  final ConfigManager _configManager = ConfigManager();
  
  /// Initialize cache manager
  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(path.join(appDir.path, _cacheDirName));
    
    // Ensure cache directory exists
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }
  
  /// Ensure initialized
  void _ensureInitialized() {
    if (_cacheDir == null) {
      throw StateError('Cache manager not initialized, please call init() first');
    }
  }
  
  /// Generate cache file path
  /// 
  /// Uses MD5 hash of config ID and remote path as cache file name
  String _generateCacheFileName(String configId, String remotePath) {
    final key = '$configId:$remotePath';
    final hash = md5.convert(utf8.encode(key)).toString();
    final ext = path.extension(remotePath);
    return '$hash$ext';
  }
  
  /// Get cache file path
  String _getCacheFilePath(String configId, String remotePath) {
    _ensureInitialized();
    final fileName = _generateCacheFileName(configId, remotePath);
    return path.join(_cacheDir!.path, fileName);
  }
  
  /// Check if file is cached
  /// 
  /// Parameters:
  /// - [configId] Connection configuration ID
  /// - [remotePath] Remote file path
  /// 
  /// Returns:
  /// - true: File is cached
  /// - false: File is not cached
  Future<bool> isCached(String configId, String remotePath) async {
    _ensureInitialized();
    final cacheFilePath = _getCacheFilePath(configId, remotePath);
    final file = File(cacheFilePath);
    return await file.exists();
  }
  
  /// Get cached file path (if exists)
  /// 
  /// Parameters:
  /// - [configId] Connection configuration ID
  /// - [remotePath] Remote file path
  /// 
  /// Returns:
  /// - Cache file path (if exists)
  /// - null (if not exists)
  Future<String?> getCachedFilePath(String configId, String remotePath) async {
    if (await isCached(configId, remotePath)) {
      return _getCacheFilePath(configId, remotePath);
    }
    return null;
  }
  
  /// Download remote file to local cache
  /// 
  /// Parameters:
  /// - [configId] Connection configuration ID
  /// - [remotePath] Remote file path
  /// - [onProgress] Download progress callback (optional)
  /// 
  /// Returns:
  /// - Local cache file path
  Future<String> downloadToCache(
    String configId,
    String remotePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    _ensureInitialized();
    
    // Check if already cached
    final cachedPath = await getCachedFilePath(configId, remotePath);
    if (cachedPath != null) {
      return cachedPath;
    }
    
    // Get connection configuration
    final config = await _configManager.getConfig(configId);
    if (config == null) {
      throw ConfigurationException('Configuration ID not found: $configId');
    }
    
    // Create client and connect
    final client = RemoteFileClientFactory.create(config);
    
    try {
      // Connect to remote server
      final connected = await client.connect();
      if (!connected) {
        throw ConnectionException(
          'Unable to connect to remote server: ${config.host}',
          protocol: config.type,
        );
      }
      
      // Download file
      final cacheFilePath = _getCacheFilePath(configId, remotePath);
      final tempFilePath = '$cacheFilePath.tmp';
      final tempFile = File(tempFilePath);
      
      // Download file based on client type
      if (client is SambaClient) {
        await client.downloadFile(remotePath, tempFilePath, onProgress: onProgress);
      } else if (client is FTPClient) {
        await client.downloadFile(remotePath, tempFilePath, onProgress: onProgress);
      } else if (client is SFTPClient) {
        await client.downloadFile(remotePath, tempFilePath, onProgress: onProgress);
      } else if (client is WebDAVClient) {
        await client.downloadFile(remotePath, tempFilePath, onProgress: onProgress);
      } else {
        throw UnsupportedError('Download not supported for this protocol type: ${config.type.displayName}');
      }
      
      // Rename to final file after download completes
      await tempFile.rename(cacheFilePath);
      
      return cacheFilePath;
    } finally {
      // Disconnect
      await client.disconnect();
    }
  }
  
  /// Clear cache for specific file
  /// 
  /// Parameters:
  /// - [configId] Connection configuration ID
  /// - [remotePath] Remote file path
  Future<void> clearCache(String configId, String remotePath) async {
    _ensureInitialized();
    final cacheFilePath = _getCacheFilePath(configId, remotePath);
    final file = File(cacheFilePath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    _ensureInitialized();
    
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }
  
  /// Get cache size (bytes)
  Future<int> getCacheSize() async {
    _ensureInitialized();
    
    if (!await _cacheDir!.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    await for (final entity in _cacheDir!.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }
    
    return totalSize;
  }
  
  /// Get human-readable cache size string
  Future<String> getCacheSizeString() async {
    final size = await getCacheSize();
    const units = ['B', 'KB', 'MB', 'GB'];
    var fileSize = size.toDouble();
    var unitIndex = 0;
    
    while (fileSize >= 1024 && unitIndex < units.length - 1) {
      fileSize /= 1024;
      unitIndex++;
    }
    
    return '${fileSize.toStringAsFixed(2)} ${units[unitIndex]}';
  }
  
  /// Get cache file count
  Future<int> getCacheFileCount() async {
    _ensureInitialized();
    
    if (!await _cacheDir!.exists()) {
      return 0;
    }
    
    int count = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File && !entity.path.endsWith('.tmp')) {
        count++;
      }
    }
    
    return count;
  }
}
