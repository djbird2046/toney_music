import '../audio_controller.dart';
import '../media/song_metadata_util.dart';
import '../mood/mood_engine.dart';
import '../storage/favorites_storage.dart';
import '../storage/for_you_playlist_storage.dart';
import '../storage/library_storage.dart';
import '../storage/playlist_storage.dart';
import 'dto.dart';
import 'library_agent.dart';
import 'playback_agent.dart';
import 'playlist_agent.dart';

class AppUtil {
  AppUtil({
    required AudioController audioController,
    SongMetadataUtil? metadataUtil,
    PlaylistStorage? playlistStorage,
    FavoritesStorage? favoritesStorage,
    LibraryStorage? libraryStorage,
    ForYouPlaylistStorage? forYouPlaylistStorage,
    MoodEngineClient? moodEngine,
  }) : _playbackAgent = PlaybackAgent(controller: audioController),
       _playlistAgent = PlaylistAgent(
         playlistStorage: playlistStorage ?? PlaylistStorage(),
         favoritesStorage: favoritesStorage ?? FavoritesStorage(),
         forYouPlaylistStorage:
             forYouPlaylistStorage ?? ForYouPlaylistStorage(),
       ),
       _libraryAgent = LibraryAgent(
         libraryStorage: libraryStorage ?? LibraryStorage(),
         metadataUtil:
             metadataUtil ??
             SongMetadataUtil(metadataFetcher: audioController.extractMetadata),
       ),
       _moodEngine = moodEngine ?? MoodEngineClient();

  final PlaybackAgent _playbackAgent;
  final PlaylistAgent _playlistAgent;
  final LibraryAgent _libraryAgent;
  final MoodEngineClient _moodEngine;

  Future<PlaybackInfoDto> getPlayback() async {
    return _playbackAgent.getPlaybackInfo();
  }

  Future<PlaylistDetailDto> getCurrentPlaylist({int? limit}) async {
    return _playbackAgent.getCurrentQueue(limit: limit);
  }

  Future<List<PlaylistSummaryDto>> getPlaylistSummaries() async {
    return _playlistAgent.listPlaylists();
  }

  Future<PlaylistDetailDto?> getPlaylistDetail(
    String name, {
    int? limit,
  }) async {
    return _playlistAgent.getPlaylist(name, limit: limit);
  }

  Future<LibrarySummaryDto> getLibraryTracks({
    int? limit,
    int offset = 0,
    String? filter,
  }) async {
    return _libraryAgent.getLibrary(
      limit: limit,
      offset: offset,
      filter: filter,
    );
  }

  Future<FavoritesSummaryDto> getFavoriteTracks({int? limit}) async {
    return _playlistAgent.getFavorites(limit: limit);
  }

  Future<SongMetadataInfoDto> getSongMetadata(String path) async {
    return _libraryAgent.getSongMetadata(path);
  }

  Future<ForYouPlaylistDto> getForYouPlaylist({int? limit}) async {
    return _playlistAgent.getForYouPlaylist(limit: limit);
  }

  Future<ResultStringDto> setForYouPlaylist(ForYouPlaylistDto payload) async {
    return _playlistAgent.setForYouPlaylist(
      tracks: payload.tracks,
      note: payload.note,
    );
  }

  Future<ResultStringDto> setCurrentPlaylist(
    List<SongSummaryDto> tracks,
  ) async {
    return _playbackAgent.setQueue(tracks);
  }

  Future<ResultStringDto> createPlaylist(
    String name,
    List<SongSummaryDto> tracks,
  ) async {
    return _playlistAgent.createPlaylist(name, tracks);
  }

  Future<ResultStringDto> addSongToCurrentAndPlay(SongSummaryDto song) async {
    return _playbackAgent.addSongAndPlay(song);
  }

  Future<MoodSignalsDto> getMoodSignals() async {
    final signals = await _moodEngine.collectSignals();
    return MoodSignalsDto.fromMoodSignals(signals);
  }
}
