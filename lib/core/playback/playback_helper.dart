import 'dart:typed_data';

import '../storage/library_storage.dart';
import '../remote/services/cache_manager.dart';

/// Playback helper service
/// 
/// Responsible for pre-playback preparation including cache detection and automatic download
class PlaybackHelper {
  /// Singleton instance
  static final PlaybackHelper _instance = PlaybackHelper._internal();
  
  /// Get singleton instance
  factory PlaybackHelper() => _instance;
  
  /// Private constructor
  PlaybackHelper._internal();
  
  /// Cache manager
  final CacheManager _cacheManager = CacheManager();
  
  /// Prepare file for playback
  /// 
  /// For remote files, checks cache and downloads automatically if needed
  /// 
  /// Parameters:
  /// - [entry] Library entry
  /// - [onDownloadProgress] Download progress callback (optional)
  /// 
  /// Returns:
  /// - Playable local file path and bookmark
  Future<PlayableFile> prepareForPlayback(
    LibraryEntry entry, {
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    // If local file, return directly
    if (!entry.isRemote) {
      return PlayableFile(
        path: entry.path,
        bookmark: entry.bookmark,
        isFromCache: false,
      );
    }
    
    // Remote file needs cache check
    if (entry.remoteInfo == null) {
      throw StateError('Remote file missing remoteInfo');
    }
    
    final configId = entry.remoteInfo!.configId;
    final remotePath = entry.remoteInfo!.remotePath;
    
    // Check if already cached
    final cachedPath = await _cacheManager.getCachedFilePath(
      configId,
      remotePath,
    );
    
    if (cachedPath != null) {
      // Already cached, use cache file directly
      return PlayableFile(
        path: cachedPath,
        bookmark: null, // Cache file doesn't need bookmark
        isFromCache: true,
      );
    }
    
    // Not cached, need to download
    final downloadedPath = await _cacheManager.downloadToCache(
      configId,
      remotePath,
      onProgress: onDownloadProgress,
    );
    
    return PlayableFile(
      path: downloadedPath,
      bookmark: null, // Cache file doesn't need bookmark
      isFromCache: true,
    );
  }
  
  /// Batch prepare files for playback
  /// 
  /// Can pre-check which files need to be downloaded
  /// 
  /// Parameters:
  /// - [entries] Library entry list
  /// 
  /// Returns:
  /// - Cache status for each entry
  Future<List<CacheStatus>> checkCacheStatus(
    List<LibraryEntry> entries,
  ) async {
    final statuses = <CacheStatus>[];
    
    for (final entry in entries) {
      if (!entry.isRemote) {
        statuses.add(CacheStatus(
          entry: entry,
          isCached: true,
          isLocal: true,
        ));
        continue;
      }
      
      if (entry.remoteInfo == null) {
        statuses.add(CacheStatus(
          entry: entry,
          isCached: false,
          isLocal: false,
          error: 'Missing remote configuration info',
        ));
        continue;
      }
      
      final isCached = await _cacheManager.isCached(
        entry.remoteInfo!.configId,
        entry.remoteInfo!.remotePath,
      );
      
      statuses.add(CacheStatus(
        entry: entry,
        isCached: isCached,
        isLocal: false,
      ));
    }
    
    return statuses;
  }
  
  /// Get cache info
  Future<CacheInfo> getCacheInfo() async {
    final size = await _cacheManager.getCacheSize();
    final sizeString = await _cacheManager.getCacheSizeString();
    final fileCount = await _cacheManager.getCacheFileCount();
    
    return CacheInfo(
      totalSize: size,
      sizeString: sizeString,
      fileCount: fileCount,
    );
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    await _cacheManager.clearAllCache();
  }
  
  /// Clear cache for specific file
  Future<void> clearCache(LibraryEntry entry) async {
    if (!entry.isRemote || entry.remoteInfo == null) {
      return;
    }
    
    await _cacheManager.clearCache(
      entry.remoteInfo!.configId,
      entry.remoteInfo!.remotePath,
    );
  }
}

/// Playable file info
class PlayableFile {
  const PlayableFile({
    required this.path,
    required this.bookmark,
    required this.isFromCache,
  });
  
  /// File path
  final String path;
  
  /// File bookmark (for accessing protected files)
  final Uint8List? bookmark;
  
  /// Whether from cache
  final bool isFromCache;
}

/// Cache status
class CacheStatus {
  const CacheStatus({
    required this.entry,
    required this.isCached,
    required this.isLocal,
    this.error,
  });
  
  /// Library entry
  final LibraryEntry entry;
  
  /// Whether cached
  final bool isCached;
  
  /// Whether local file
  final bool isLocal;
  
  /// Error message (if any)
  final String? error;
  
  /// Whether needs download
  bool get needsDownload => !isLocal && !isCached && error == null;
}

/// Cache info
class CacheInfo {
  const CacheInfo({
    required this.totalSize,
    required this.sizeString,
    required this.fileCount,
  });
  
  /// Total size (bytes)
  final int totalSize;
  
  /// Human-readable size string
  final String sizeString;
  
  /// File count
  final int fileCount;
}
