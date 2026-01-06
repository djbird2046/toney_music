import '../storage/library_storage.dart';
import '../model/playback_track.dart';
import '../playback/playback_helper.dart';
import '../audio_controller.dart';

/// Library playback service
///
/// Responsible for converting library entries to playable tracks and handling remote file caching and download
class LibraryPlaybackService {
  /// Singleton instance
  static final LibraryPlaybackService _instance =
      LibraryPlaybackService._internal();

  /// Get singleton instance
  factory LibraryPlaybackService() => _instance;

  /// Private constructor
  LibraryPlaybackService._internal();

  /// Playback helper service
  final PlaybackHelper _playbackHelper = PlaybackHelper();

  /// Play single library entry
  ///
  /// Parameters:
  /// - [controller] Audio controller
  /// - [entry] Library entry
  /// - [onDownloadProgress] Download progress callback (optional)
  Future<void> playEntry(
    AudioController controller,
    LibraryEntry entry, {
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    // Prepare playback file (auto downloads if remote)
    final playableFile = await _playbackHelper.prepareForPlayback(
      entry,
      onDownloadProgress: onDownloadProgress,
    );

    // Load and play
    await controller.load(playableFile.path, bookmark: entry.bookmark);
    await controller.play();
  }

  /// Create playback queue
  ///
  /// Convert library entry list to playback track list
  /// Note: This method does not pre-download remote files, only creates track info
  /// Download is triggered during actual playback
  ///
  /// Parameters:
  /// - [entries] Library entry list
  ///
  /// Returns:
  /// - Playback track list
  List<PlaybackTrack> createPlaybackQueue(List<LibraryEntry> entries) {
    return entries
        .map(
          (entry) => PlaybackTrack(
            path: entry.path,
            metadata: entry.metadata,
            duration: null,
            bookmark: entry.bookmark,
          ),
        )
        .toList();
  }

  /// Play queue
  ///
  /// Set playback queue and start playing track at specified index
  ///
  /// Parameters:
  /// - [controller] Audio controller
  /// - [entries] Library entry list
  /// - [startIndex] Starting playback index (default 0)
  /// - [onDownloadProgress] Download progress callback (optional)
  Future<void> playQueue(
    AudioController controller,
    List<LibraryEntry> entries, {
    int startIndex = 0,
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    if (entries.isEmpty) return;

    // Create playback queue
    final tracks = createPlaybackQueue(entries);
    controller.setQueue(tracks, startIndex: startIndex);

    // Play first track (triggers remote file download)
    await playEntryAt(
      controller,
      entries,
      startIndex,
      onDownloadProgress: onDownloadProgress,
    );
  }

  /// Play library entry at specified index
  ///
  /// Parameters:
  /// - [controller] Audio controller
  /// - [entries] Library entry list
  /// - [index] Index
  /// - [onDownloadProgress] Download progress callback (optional)
  Future<void> playEntryAt(
    AudioController controller,
    List<LibraryEntry> entries,
    int index, {
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    if (index < 0 || index >= entries.length) return;

    final entry = entries[index];

    // Prepare playback file
    final playableFile = await _playbackHelper.prepareForPlayback(
      entry,
      onDownloadProgress: onDownloadProgress,
    );

    // Update controller current index and play
    await controller.load(playableFile.path, bookmark: entry.bookmark);

    // Update state
    final tracks = createPlaybackQueue(entries);
    controller.setQueue(tracks, startIndex: index);

    await controller.play();
  }

  /// Check queue cache status
  ///
  /// Can be used to show which tracks are cached and which need download
  ///
  /// Parameters:
  /// - [entries] Library entry list
  ///
  /// Returns:
  /// - Cache status list
  Future<List<CacheStatus>> checkQueueCacheStatus(
    List<LibraryEntry> entries,
  ) async {
    return await _playbackHelper.checkCacheStatus(entries);
  }

  /// Pre-download remote files in queue
  ///
  /// Can pre-download all remote files before playback to improve experience
  ///
  /// Parameters:
  /// - [entries] Library entry list
  /// - [onProgress] Download progress callback (optional)
  Future<void> predownloadQueue(
    List<LibraryEntry> entries, {
    void Function(int current, int total, String filename)? onProgress,
  }) async {
    final remoteEntries = entries.where((e) => e.isRemote).toList();

    for (int i = 0; i < remoteEntries.length; i++) {
      final entry = remoteEntries[i];

      if (onProgress != null) {
        onProgress(i + 1, remoteEntries.length, entry.metadata.title);
      }

      await _playbackHelper.prepareForPlayback(entry);
    }
  }

  /// Get cache info
  Future<CacheInfo> getCacheInfo() async {
    return await _playbackHelper.getCacheInfo();
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _playbackHelper.clearAllCache();
  }

  /// Clear cache for specific entry
  Future<void> clearEntryCache(LibraryEntry entry) async {
    await _playbackHelper.clearCache(entry);
  }
}
