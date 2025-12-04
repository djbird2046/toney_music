import 'package:opentool_dart/opentool_client.dart';
import 'package:path/path.dart' as p;

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
          final normalizedArgs = _coerceStringPayload(
            arguments,
            fieldName: 'name',
          );
          final payload = _parseArguments(
            normalizedArgs,
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
            filter: payload.filter,
          );
          return library.toJson();
        case 'getFavoriteTracks':
          final payload = _parseArguments(arguments, LimitArguments.fromJson);
          final favorites = await _appUtil.getFavoriteTracks(
            limit: payload.limit,
          );
          return favorites.toJson();
        case 'getSongMetadata':
          final normalizedArgs = _coerceStringPayload(
            arguments,
            fieldName: 'path',
          );
          final payload = _parseArguments(
            normalizedArgs,
            SongMetadataArguments.fromJson,
          );
          final metadata = await _appUtil.getSongMetadata(payload.path);
          return metadata.toJson();
        case 'getForYouPlaylist':
          final payload = _parseArguments(arguments, LimitArguments.fromJson);
          final result = await _appUtil.getForYouPlaylist(limit: payload.limit);
          return result.toJson();
        case 'setForYouPlaylist':
          final normalizedForYouArgs = _normalizeForYouTracks(arguments);
          final tracks = normalizedForYouArgs?['tracks'];
          if (tracks is! List || tracks.isEmpty) {
            throw InvalidArgumentsException(
              arguments: {'error': 'tracks must be a non-empty array'},
            );
          }
          final payload = _parseArguments(
            normalizedForYouArgs,
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
      final payloadRaw = map['payload'];
      if (payloadRaw is Map<String, dynamic>) {
        try {
          return factory(payloadRaw);
        } catch (_) {
          throw InvalidArgumentsException(arguments: arguments);
        }
      }
      if (payloadRaw is Map) {
        try {
          return factory(Map<String, dynamic>.from(payloadRaw));
        } catch (_) {
          throw InvalidArgumentsException(arguments: arguments);
        }
      }
      throw InvalidArgumentsException(arguments: arguments);
    }
  }

  Map<String, dynamic> _argumentsOrEmpty(Map<String, dynamic>? arguments) {
    return arguments ?? const <String, dynamic>{};
  }

  Map<String, dynamic>? _coerceStringPayload(
    Map<String, dynamic>? arguments, {
    required String fieldName,
  }) {
    if (arguments == null) return null;
    final payload = arguments['payload'];
    if (payload is String && payload.isNotEmpty) {
      return {fieldName: payload};
    }
    return arguments;
  }

  Map<String, dynamic>? _normalizeForYouTracks(
    Map<String, dynamic>? arguments,
  ) {
    if (arguments == null) return null;
    final payload = Map<String, dynamic>.from(arguments);
    final tracks = payload['tracks'];
    if (tracks is String) {
      payload['tracks'] = [
        {'id': tracks, 'title': p.basenameWithoutExtension(tracks)},
      ];
    } else if (tracks is Map) {
      payload['tracks'] = [Map<String, dynamic>.from(tracks)];
    }
    return payload;
  }
}
