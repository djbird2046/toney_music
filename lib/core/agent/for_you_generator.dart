import 'dart:async';

import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';

import 'app_tool.dart';
import 'app_util.dart';
import 'dto.dart';
import 'liteagent_util.dart';
import 'prompts/for_you_prompt.dart';

class ForYouGenerateResult {
  const ForYouGenerateResult({required this.playlist, required this.trace});

  final ForYouPlaylistDto playlist;
  final List<String> trace;
}

class ForYouGenerationException implements Exception {
  ForYouGenerationException(this.cause, this.trace);

  final Object cause;
  final List<String> trace;

  @override
  String toString() => 'ForYouGenerationException($cause)';
}

class ForYouGenerator {
  ForYouGenerator({
    required this.appUtil,
    required this.liteAgent,
    this.defaultLimit = 20,
  }) : _tool = AppTool(appUtil: appUtil);

  final AppUtil appUtil;
  final LiteAgentSDK liteAgent;
  final int defaultLimit;
  final AppTool _tool;

  Future<ForYouGenerateResult> refresh({
    int? limit,
    required String localeCode,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final targetLimit = limit ?? defaultLimit;
    ForYouGenerationException? firstError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await _runGeneration(
          targetLimit: targetLimit,
          localeCode: localeCode,
          timeout: timeout,
        );
        if (attempt == 1 && firstError != null) {
          return ForYouGenerateResult(
            playlist: result.playlist,
            trace: [
              ...firstError.trace,
              'retry_success_after_error:${firstError.cause}',
              ...result.trace,
            ],
          );
        }
        return result;
      } on ForYouGenerationException catch (e) {
        final cause = '${e.cause}'.toLowerCase();
        final shouldRetry =
            attempt == 0 &&
            (cause.contains('tracks must be an array') ||
                cause.contains('invalid arguments') ||
                cause.contains('too_few_tracks'));
        if (shouldRetry) {
          firstError = e;
          continue;
        }
        rethrow;
      }
    }
    throw firstError ??
        ForYouGenerationException('unknown_failure', const <String>[]);
  }

  Future<ForYouGenerateResult> _runGeneration({
    required int targetLimit,
    required String localeCode,
    required Duration timeout,
  }) async {
    final moodSignals = await _safeMoodSignals();
    final libraryLimit = (targetLimit * 2).clamp(20, 60);
    final favoritesLimit = (targetLimit * 2).clamp(10, 40);
    final library = await _safeLibrarySummary(limit: libraryLimit);
    final favorites = await _safeFavorites(limit: favoritesLimit);
    final trace = <String>[];

    final userTask = buildForYouTask(
      moodSignals: moodSignals,
      librarySummary: library,
      favorites: favorites?.favorites,
      recents: null,
      limit: targetLimit,
      localeCode: localeCode,
    );
    trace.add('payload: ${_safeEncode(userTask)}');
    trace.add(
      'limits: target=$targetLimit libraryLimit=$libraryLimit favoritesLimit=$favoritesLimit',
    );

    final session = await liteAgent.initSession();
    final handlerCompleter = Completer<void>();
    Timer? timer;

    void _bumpTimer() {
      timer?.cancel();
      timer = Timer(timeout, () {
        if (!handlerCompleter.isCompleted) {
          handlerCompleter.completeError('timeout');
        }
      });
    }

    final handler = AppAgentHandler(
      tool: _tool,
      onFullText: (_, full) {
        trace.add(full);
        _bumpTimer();
      },
      onTextChunk: (_, __) {
        // Skip partial text chunks to avoid duplication; full text will arrive.
        _bumpTimer();
      },
      onExtension: (_, extension) {
        trace.add(extension);
        _bumpTimer();
      },
      onMessageLog: (_, jsonLine) {
        trace.add(jsonLine);
        _bumpTimer();
      },
      onMessageStart: (_) => _bumpTimer(),
      onDoneCallback: () {
        timer?.cancel();
        if (!handlerCompleter.isCompleted) {
          handlerCompleter.complete();
        }
      },
      onErrorCallback: (e) {
        trace.add('agent_error: $e');
        timer?.cancel();
        if (!handlerCompleter.isCompleted) {
          handlerCompleter.completeError(e);
        }
      },
    )..reset();

    try {
      final chatFuture = liteAgent.chat(session, userTask, handler);
      chatFuture.catchError((e) {
        trace.add('chat_error: $e');
        timer?.cancel();
        if (!handlerCompleter.isCompleted) {
          handlerCompleter.completeError(e);
        }
      });
      _bumpTimer();
      await handlerCompleter.future;
      final playlist = await appUtil.getForYouPlaylist(limit: targetLimit);
      final minAcceptable = targetLimit.clamp(5, targetLimit);
      ForYouPlaylistDto effective = playlist;
      if (playlist.tracks.length < minAcceptable) {
        final filled = _fillTracks(
          existing: playlist.tracks,
          library: library.tracks,
          targetLimit: targetLimit,
        );
        trace.add(
          'too_few_tracks:${playlist.tracks.length}, min:$minAcceptable; filled_with_library:${filled.length}',
        );
        final filledDto = ForYouPlaylistDto(
          tracks: filled,
          note: playlist.note,
          generatedAt: DateTime.now(),
          moodSignals: moodSignals.toJson(),
        );
        await appUtil.setForYouPlaylist(filledDto);
        effective = filledDto;
      }
      return ForYouGenerateResult(
        playlist: effective,
        trace: List<String>.from(trace),
      );
    } catch (e) {
      trace.add('generate_failed: $e');
      throw ForYouGenerationException(e, trace);
    }
  }

  List<SongSummaryDto> _fillTracks({
    required List<SongSummaryDto> existing,
    required List<SongSummaryDto> library,
    required int targetLimit,
  }) {
    final ids = existing.map((e) => e.id).toSet();
    final filled = List<SongSummaryDto>.from(existing);
    for (final song in library) {
      if (filled.length >= targetLimit) break;
      if (ids.contains(song.id)) continue;
      filled.add(song);
      ids.add(song.id);
    }
    return filled;
  }

  Future<MoodSignalsDto> _safeMoodSignals() async {
    try {
      return await appUtil.getMoodSignals();
    } catch (_) {
      // Fallback to neutral signals to keep generation working.
      return const MoodSignalsDto(
        hour: 12,
        weekday: 1,
        isHoliday: false,
        appearance: 'light',
        batteryLevel: 1.0,
        isCharging: false,
        isNetworkConnected: true,
        networkType: 'wifi',
        networkQuality: 'good',
        headphonesConnected: false,
      );
    }
  }

  Future<LibrarySummaryDto> _safeLibrarySummary({required int limit}) async {
    try {
      return await appUtil.getLibraryTracks(limit: limit);
    } catch (_) {
      return const LibrarySummaryDto(total: 0, tracks: []);
    }
  }

  Future<FavoritesSummaryDto?> _safeFavorites({required int limit}) async {
    try {
      return await appUtil.getFavoriteTracks(limit: limit);
    } catch (_) {
      return null;
    }
  }

  String _safeEncode(UserTask task) {
    try {
      return task.toJson().toString();
    } catch (_) {
      return '<unserializable task>';
    }
  }
}
