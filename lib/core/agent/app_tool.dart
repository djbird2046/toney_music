import 'package:opentool_dart/opentool_client.dart';

import 'app_tool_models.dart';
import 'app_tool_spec.dart';
import 'app_util.dart';
import 'dto.dart';

class AppTool extends Tool {
  AppTool({required AppUtil appUtil}) : _appUtil = appUtil;

  final AppUtil _appUtil;

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>> call(
      String name,
      Map<String, dynamic>? arguments,
      ) async {
    try {
      switch (name) {
        case 'getPlayback':
          _parseArguments(arguments, EmptyArguments.fromJson);
          final playback = await _appUtil.getPlayback();
          return playback.toJson();
        case 'getCurrentPlaylist':
          final payload = _parseArguments(arguments, LimitArguments.fromJson);
          final current = await _appUtil.getCurrentPlaylist(
            limit: payload.limit,
          );
          return current.toJson();
        case 'getPlaylistSummaries':
          _parseArguments(arguments, EmptyArguments.fromJson);
          final playlists = await _appUtil.getPlaylistSummaries();
          return {'playlists': playlists.map((e) => e.toJson()).toList()};
        case 'getPlaylistDetail':
          final payload = _parseArguments(
            arguments,
            PlaylistDetailArguments.fromJson,
          );
          final detail = await _appUtil.getPlaylistDetail(
            payload.name,
            limit: payload.limit,
          );
          if (detail == null) {
            return const ResultStringDto(result: 'playlist_not_found').toJson();
          }
          return detail.toJson();
        case 'getLibraryTracks':
          final payload = _parseArguments(
            arguments,
            LibraryTracksArguments.fromJson,
          );
          final library = await _appUtil.getLibraryTracks(
            limit: payload.limit,
            offset: payload.offset ?? 0,
          );
          return library.toJson();
        case 'getFavoriteTracks':
          final payload = _parseArguments(arguments, LimitArguments.fromJson);
          final favorites = await _appUtil.getFavoriteTracks(
            limit: payload.limit,
          );
          return favorites.toJson();
        case 'getSongMetadata':
          final payload = _parseArguments(
            arguments,
            SongMetadataArguments.fromJson,
          );
          final metadata = await _appUtil.getSongMetadata(payload.path);
          return metadata.toJson();
        case 'getForYouPlaylist':
          final payload = _parseArguments(arguments, LimitArguments.fromJson);
          final result = await _appUtil.getForYouPlaylist(limit: payload.limit);
          return result.toJson();
        case 'setForYouPlaylist':
          final payload = _parseArguments(
            arguments,
            ForYouPlaylistDto.fromJson,
          );
          final response = await _appUtil.setForYouPlaylist(payload);
          return response.toJson();
        case 'setCurrentPlaylist':
          final payload = _parseArguments(
            arguments,
            SetCurrentPlaylistArguments.fromJson,
          );
          final response = await _appUtil.setCurrentPlaylist(payload.tracks);
          return response.toJson();
        case 'createPlaylist':
          final payload = _parseArguments(
            arguments,
            CreatePlaylistArguments.fromJson,
          );
          final response = await _appUtil.createPlaylist(
            payload.name,
            payload.tracks,
          );
          return response.toJson();
        case 'addSongToCurrentAndPlay':
          final payload = _parseArguments(arguments, AddSongArguments.fromJson);
          final response = await _appUtil.addSongToCurrentAndPlay(payload.song);
          return response.toJson();
        case 'getMoodSignals':
          _parseArguments(arguments, EmptyArguments.fromJson);
          final signals = await _appUtil.getMoodSignals();
          return signals.toJson();
        default:
          return FunctionNotSupportedException(functionName: name).toJson();
      }
    } on InvalidArgumentsException catch (error) {
      return error.toJson();
    } catch (error) {
      return ToolBreakException(error.toString()).toJson();
    }
  }

  @override
  Future<void> streamCall(
      String name,
      Map<String, dynamic>? arguments,
      void Function(String event, Map<String, dynamic> data) onEvent,
      ) async {}

  @override
  Future<OpenTool?> load() async => AppTool.specification();

  static OpenTool specification() => buildAppToolSpecification();

  T _parseArguments<T>(
      Map<String, dynamic>? arguments,
      T Function(Map<String, dynamic> json) factory,
      ) {
    final map = _argumentsOrEmpty(arguments);
    try {
      return factory(map);
    } catch (_) {
      throw InvalidArgumentsException(arguments: arguments);
    }
  }

  Map<String, dynamic> _argumentsOrEmpty(Map<String, dynamic>? arguments) {
    return arguments ?? const <String, dynamic>{};
  }
}
