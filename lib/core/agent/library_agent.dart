import '../library/library_source.dart';
import '../media/song_metadata_util.dart';
import '../storage/library_storage.dart';
import 'dto.dart';
import 'song_mapper.dart';

class LibraryAgent {
  LibraryAgent({
    required LibraryStorage libraryStorage,
    required SongMetadataUtil metadataUtil,
  }) : _libraryStorage = libraryStorage,
       _metadataUtil = metadataUtil;

  final LibraryStorage _libraryStorage;
  final SongMetadataUtil _metadataUtil;

  bool _libraryReady = false;

  Future<LibrarySummaryDto> getLibrary({
    int? limit,
    int offset = 0,
    String? filter,
  }) async {
    await _ensureLibrary();
    final entries = _libraryStorage.load();
    final normalizedFilter = filter?.trim().toLowerCase();
    final filtered = entries.where((entry) {
      if (normalizedFilter == null || normalizedFilter.isEmpty) return true;
      final metadata = entry.metadata;
      final lower = normalizedFilter;
      final titleMatch = metadata.title.toLowerCase().contains(lower);
      final artistMatch = metadata.artist.toLowerCase().contains(lower);
      final albumMatch = metadata.album.toLowerCase().contains(lower);
      final pathMatch = entry.path.toLowerCase().contains(lower);
      return titleMatch || artistMatch || albumMatch || pathMatch;
    }).toList();
    final sliced = filtered
        .skip(offset)
        .take(limit ?? filtered.length)
        .map(SongMapper.fromLibraryEntry)
        .toList();
    return LibrarySummaryDto(total: filtered.length, tracks: sliced);
  }

  Future<SongMetadataInfoDto> getSongMetadata(String path) async {
    await _ensureLibrary();
    final entries = _libraryStorage.load();
    LibraryEntry? match;
    for (final entry in entries) {
      if (entry.path == path) {
        match = entry;
        break;
      }
    }
    final metadata = match != null
        ? match.metadata
        : await _metadataUtil.loadFromPath(path);
    final summary = SongMapper.fromMetadata(
      path: path,
      metadata: metadata,
      sourceType: match?.sourceType ?? LibrarySourceType.local,
    );
    return SongMetadataInfoDto(
      path: path,
      title: summary.title,
      artist: summary.artist,
      album: summary.album,
      durationSec: summary.durationSec,
      extras: _trimExtras(metadata.extras),
    );
  }

  Future<void> _ensureLibrary() async {
    if (_libraryReady) return;
    await _libraryStorage.init();
    _libraryReady = true;
  }

  Map<String, String>? _trimExtras(Map<String, String> extras) {
    if (extras.isEmpty) return null;
    final filtered = <String, String>{};
    extras.forEach((key, value) {
      final trimmedValue = value.trim();
      if (trimmedValue.isEmpty) return;
      if (trimmedValue.toLowerCase().startsWith('unknown')) return;
      filtered[key] = trimmedValue;
    });
    return filtered.isEmpty ? null : filtered;
  }
}
