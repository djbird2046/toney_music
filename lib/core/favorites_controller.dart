import 'package:flutter/foundation.dart';
import 'model/playback_track.dart';
import 'media/song_metadata_util.dart';
import 'storage/favorites_storage.dart';
import 'storage/playlist_storage.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController({this.metadataFetcher});

  final Future<Map<String, dynamic>> Function(String path)? metadataFetcher;
  final FavoritesStorage _storage = FavoritesStorage();
  final List<PlaylistReference> _favorites = [];

  List<PlaylistReference> get favorites => List.unmodifiable(_favorites);

  Future<void> init() async {
    await _storage.init();
    _favorites.clear();
    final loaded = _storage.load();
    
    // Hydrate metadata if needed
    final metadataUtil = SongMetadataUtil(metadataFetcher: metadataFetcher);
    final hydrated = <PlaylistReference>[];
    
    for (final ref in loaded) {
      if (ref.metadata == null || ref.metadata!.extras['Duration'] == null) {
        try {
          final refreshed = await metadataUtil.loadFromPath(ref.path);
          final enriched = refreshed.copyWith(
            extras: {...refreshed.extras, 'Path': ref.path},
          );
          hydrated.add(PlaylistReference(
            path: ref.path,
            metadata: enriched,
            sourceType: ref.sourceType,
            remoteInfo: ref.remoteInfo,
            bookmark: ref.bookmark,
          ));
        } catch (_) {
           // If load fails, keep original
           hydrated.add(ref);
        }
      } else {
        hydrated.add(ref);
      }
    }

    _favorites.addAll(hydrated);
    // Save back if any changes occurred (to persist hydrated durations)
    if (loaded.length == hydrated.length) {
       await _storage.save(_favorites);
    }
    notifyListeners();
  }

  bool isFavorite(String path) {
    return _favorites.any((e) => e.path == path);
  }

  Future<void> toggleFavorite(PlaybackTrack track) async {
    final existingIndex = _favorites.indexWhere((e) => e.path == track.path);
    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
    } else {
      // Ensure we store complete metadata
      _favorites.add(PlaylistReference(
        path: track.path,
        metadata: track.metadata,
        bookmark: track.bookmark,
      ));
    }
    notifyListeners();
    await _storage.save(_favorites);
  }
}
