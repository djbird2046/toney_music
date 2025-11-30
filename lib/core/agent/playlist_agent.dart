import '../storage/favorites_storage.dart';
import '../storage/for_you_playlist_storage.dart';
import '../storage/playlist_storage.dart';
import 'dto.dart';
import 'song_mapper.dart';

class PlaylistAgent {
  PlaylistAgent({
    required PlaylistStorage playlistStorage,
    required FavoritesStorage favoritesStorage,
    required ForYouPlaylistStorage forYouPlaylistStorage,
  }) : _playlistStorage = playlistStorage,
       _favoritesStorage = favoritesStorage,
       _forYouPlaylistStorage = forYouPlaylistStorage;

  final PlaylistStorage _playlistStorage;
  final FavoritesStorage _favoritesStorage;
  final ForYouPlaylistStorage _forYouPlaylistStorage;

  bool _playlistReady = false;
  bool _favoritesReady = false;
  bool _forYouReady = false;

  Future<List<PlaylistSummaryDto>> listPlaylists() async {
    await _ensurePlaylists();
    final snapshot = _playlistStorage.load();
    final names = snapshot.names.isEmpty
        ? snapshot.entries.keys.toList()
        : snapshot.names;
    final result = <PlaylistSummaryDto>[];
    for (final name in names) {
      final entries = snapshot.entries[name] ?? const <PlaylistReference>[];
      result.add(PlaylistSummaryDto(name: name, trackCount: entries.length));
    }
    return result;
  }

  Future<PlaylistDetailDto?> getPlaylist(String name, {int? limit}) async {
    await _ensurePlaylists();
    final snapshot = _playlistStorage.load();
    final entries = snapshot.entries[name];
    if (entries == null) {
      return null;
    }
    final tracks = entries
        .take(limit ?? entries.length)
        .map(SongMapper.fromPlaylistReference)
        .toList();
    return PlaylistDetailDto(name: name, tracks: tracks);
  }

  Future<FavoritesSummaryDto> getFavorites({int? limit}) async {
    await _ensureFavorites();
    final list = _favoritesStorage.load();
    final tracks = list
        .take(limit ?? list.length)
        .map(SongMapper.fromPlaylistReference)
        .toList();
    return FavoritesSummaryDto(total: list.length, favorites: tracks);
  }

  Future<ResultStringDto> createPlaylist(
    String name,
    List<SongSummaryDto> tracks,
  ) async {
    if (name.trim().isEmpty) {
      return const ResultStringDto(result: 'error:empty_name');
    }
    await _ensurePlaylists();
    final snapshot = _playlistStorage.load();
    final names = snapshot.names.isEmpty
        ? snapshot.entries.keys.toList()
        : snapshot.names;
    final newNames = [...names.where((n) => n != name), name];
    final map = Map<String, List<PlaylistReference>>.from(snapshot.entries);
    map[name] = tracks
        .map(SongMapper.playlistReferenceFromSummary)
        .toList(growable: false);
    await _playlistStorage.save(
      PlaylistSnapshot(names: newNames, entries: map),
    );
    return ResultStringDto(result: 'playlist_saved:$name:${map[name]!.length}');
  }

  Future<ResultStringDto> setForYouPlaylist({
    required List<SongSummaryDto> tracks,
    String? note,
  }) async {
    await _ensureForYou();
    await _forYouPlaylistStorage.save(
      ForYouPlaylistSnapshot(
        entries: tracks
            .map(SongMapper.playlistReferenceFromSummary)
            .toList(growable: false),
        note: note,
      ),
    );
    return ResultStringDto(result: 'for_you_saved:${tracks.length}');
  }

  Future<ForYouPlaylistDto> getForYouPlaylist({int? limit}) async {
    await _ensureForYou();
    final snapshot = _forYouPlaylistStorage.load();
    final entries = snapshot.entries
        .take(limit ?? snapshot.entries.length)
        .map(SongMapper.fromPlaylistReference)
        .toList();
    return ForYouPlaylistDto(tracks: entries, note: snapshot.note);
  }

  Future<void> _ensurePlaylists() async {
    if (_playlistReady) return;
    await _playlistStorage.init();
    _playlistReady = true;
  }

  Future<void> _ensureFavorites() async {
    if (_favoritesReady) return;
    await _favoritesStorage.init();
    _favoritesReady = true;
  }

  Future<void> _ensureForYou() async {
    if (_forYouReady) return;
    await _forYouPlaylistStorage.init();
    _forYouReady = true;
  }
}
