import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model/engine_track_models.dart';
import 'model/playback_mode.dart';
import 'model/playback_track.dart';
import 'model/playback_view_model.dart';
import 'storage/playback_state_storage.dart';

/// Shared coordinator that wraps the MethodChannel API exposed by the native
/// AudioEnginePlugin. UI layers should depend on this instead of touching
/// MethodChannels directly.
class AudioController {
  AudioController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('audio_engine') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final PlaybackStateStorage _storage = PlaybackStateStorage();
  List<PlaybackTrack> _queue = const [];
  int? _currentIndex;
  Timer? _positionTimer;
  DateTime? _lastTick;
  PlayMode _playbackMode = PlayMode.sequence;
  final Random _random = Random();

  final ValueNotifier<PlaybackViewModel> state = ValueNotifier(
    PlaybackViewModel.initial(),
  );
  final StreamController<double> _volumeSubject =
      StreamController<double>.broadcast();

  Stream<double> get volumeStream => _volumeSubject.stream;

  Future<void> init() async {
    await _storage.init();
    final snapshot = _storage.load();

    if (snapshot.queue.isNotEmpty) {
      _queue = List.unmodifiable(snapshot.queue);
      _currentIndex = snapshot.currentIndex;
      _playbackMode = snapshot.mode;

      // Restore UI state
      state.value = state.value.copyWith(
        queue: _queue,
        currentIndex: _currentIndex,
        playbackMode: _playbackMode,
        position: Duration(milliseconds: snapshot.positionMs),
      );

      // If we have a valid current track, load it into the engine
      if (_currentIndex != null &&
          _currentIndex! >= 0 &&
          _currentIndex! < _queue.length) {
        final track = _queue[_currentIndex!];

        // Optimistically set duration if available in the track model
        if (track.duration != null) {
          state.value = state.value.copyWith(duration: track.duration);
        }

        try {
          // Load the file but do not start playback
          await load(track.path);
          // Restore position
          if (state.value.hasFile && snapshot.positionMs > 0) {
            try {
              await _channel.invokeMethod('seek', {
                'positionMs': snapshot.positionMs,
              });
              state.value = state.value.copyWith(
                position: Duration(milliseconds: snapshot.positionMs),
              );
            } catch (e) {
              debugPrint('Error seeking during init: $e');
              // Silently ignore seek failures during init
            }
          }
        } on PlatformException catch (e) {
          debugPrint('PlatformException restoring playback state: $e');
          // We fail gracefully: queue and index are restored in state,
          // but 'hasFile' remains false. User can try to play again.
        } catch (e) {
          debugPrint('Generic error restoring playback state: $e');
        }
      }
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPlaybackEnded':
        _onPlaybackEnded();
        break;
    }
  }

  void _onPlaybackEnded() {
    if (_queue.isEmpty || _currentIndex == null) {
      stop();
      return;
    }

    switch (_playbackMode) {
      case PlayMode.single:
        // Loop current track
        playAt(_currentIndex!);
        break;
      case PlayMode.loop:
        // Play next or loop back to start
        final nextIndex = (_currentIndex! + 1) % _queue.length;
        playAt(nextIndex);
        break;
      case PlayMode.shuffle:
        // Pick random next track (avoiding current if possible)
        if (_queue.length > 1) {
          int nextIndex;
          do {
            nextIndex = _random.nextInt(_queue.length);
          } while (nextIndex == _currentIndex);
          playAt(nextIndex);
        } else {
          // Only one track, just replay it
          playAt(0);
        }
        break;
      case PlayMode.sequence:
        // Default behavior: play next, stop at end
        final nextIndex = _currentIndex! + 1;
        if (nextIndex < _queue.length) {
          playAt(nextIndex);
        } else {
          stop();
        }
        break;
    }
  }

  void setPlaybackMode(PlayMode mode) {
    _playbackMode = mode;
    state.value = state.value.copyWith(playbackMode: mode);
    _saveState();
  }

  Future<void> load(String path) async {
    state.value = state.value.copyWith(
      updateEngineMetadata: true,
      engineMetadata: null,
    );
    await _run('load', () => _channel.invokeMethod('load', {'path': path}));
    _markLoaded();
    await _refreshEngineMetadata();
  }

  Future<void> play() async {
    await _run('play', () => _channel.invokeMethod('play'));
    _setPlaying(true);
    _startPositionTicker();
  }

  Future<void> pause() async {
    await _run('pause', () => _channel.invokeMethod('pause'));
    _setPlaying(false);
    _stopPositionTicker();
    _saveState();
  }

  Future<void> stop() async {
    await _run('stop', () => _channel.invokeMethod('stop'));
    state.value = state.value.copyWith(
      hasFile: false,
      isPlaying: false,
      position: Duration.zero,
      updateEngineMetadata: true,
      engineMetadata: null,
    );
    _stopPositionTicker();
    _saveState();
  }

  Future<void> seek(int positionMs) async {
    await _run(
      'seek',
      () => _channel.invokeMethod('seek', {'positionMs': positionMs}),
    );
    state.value = state.value.copyWith(
      position: Duration(milliseconds: positionMs),
    );
    _lastTick = DateTime.now();
    _saveState();
  }

  Future<void> setBitPerfectMode(bool enabled) async {
    await _channel.invokeMethod('setBitPerfectMode', {'enabled': enabled});
  }

  Future<void> setAutoSampleRateSwitching(bool enabled) async {
    await _channel.invokeMethod('setAutoSampleRateSwitching', {
      'enabled': enabled,
    });
  }

  Future<double> getVolume() async {
    // Always fetch from native to ensure sync.
    final value = await _channel.invokeMethod<double>('getVolume');
    return value ?? 1.0;
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    _volumeSubject.add(clamped);
    await _channel.invokeMethod('setVolume', {'value': clamped});
  }

  Future<Map<String, dynamic>> extractMetadata(String path) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'extractMetadata',
        {'path': path},
      );
      return result ?? {};
    } on MissingPluginException {
      return {};
    } catch (e) {
      debugPrint('Error extracting metadata for $path: $e');
      return {};
    }
  }

  void setQueue(List<PlaybackTrack> tracks, {int? startIndex}) {
    _queue = List.unmodifiable(tracks);
    if (startIndex != null) {
      _currentIndex = startIndex;
    }
    state.value = state.value.copyWith(
      queue: _queue,
      currentIndex: _currentIndex,
    );
    _saveState();
  }

  Future<void> playAt(int index, {String? overridePath}) async {
    await stop();
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    final track = _queue[index];
    final pathToLoad = overridePath ?? track.path;
    await load(pathToLoad);
    state.value = state.value.copyWith(
      queue: _queue,
      currentIndex: _currentIndex,
      duration: track.duration ?? Duration.zero,
      position: Duration.zero,
    );
    await play();
    _saveState();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;

    int nextIndex;
    if (_playbackMode == PlayMode.shuffle) {
      if (_queue.length > 1) {
        do {
          nextIndex = _random.nextInt(_queue.length);
        } while (nextIndex == _currentIndex);
      } else {
        nextIndex = 0;
      }
    } else {
      nextIndex = _currentIndex == null
          ? 0
          : (_currentIndex! + 1) % _queue.length;
    }

    await playAt(nextIndex);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    final previousIndex = _currentIndex == null
        ? 0
        : (_currentIndex! - 1 + _queue.length) % _queue.length;
    await playAt(previousIndex);
  }

  Future<void> togglePlayPause() async {
    try {
      if (state.value.isPlaying) {
        await pause();
        return;
      }
      if (!state.value.hasFile) {
        if (_queue.isEmpty) return;
        await playAt(_currentIndex ?? 0);
        return;
      }
      await play();
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  void dispose() {
    state.dispose();
    _stopPositionTicker();
    _volumeSubject.close();
  }

  void _markLoaded() {
    state.value = state.value.copyWith(hasFile: true, position: Duration.zero);
    _lastTick = DateTime.now();
  }

  void _setPlaying(bool value) {
    state.value = state.value.copyWith(isPlaying: value);
  }

  void _startPositionTicker() {
    _lastTick = DateTime.now();
    _positionTimer ??= Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _tickPosition(),
    );
  }

  void _stopPositionTicker() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _lastTick = null;
  }

  void _tickPosition() {
    final current = state.value;
    if (!current.isPlaying) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTick ?? now);
    _lastTick = now;
    var newPosition = current.position + elapsed;
    final duration = current.duration;
    final hasDuration = duration > Duration.zero;
    final reachedEnd = hasDuration && newPosition >= duration;
    if (reachedEnd) {
      newPosition = duration;
    }
    state.value = current.copyWith(
      position: newPosition,
      isPlaying: reachedEnd ? false : null,
    );
    if (reachedEnd) {
      _stopPositionTicker();
    }
  }

  Future<void> _run(String method, Future<void> Function() operation) async {
    state.value = state.value.copyWith(
      isBusy: true,
      statusMessage: 'Running $method…',
    );
    try {
      await operation();
      state.value = state.value.copyWith(
        isBusy: false,
        statusMessage: 'Success: $method',
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isBusy: false,
        statusMessage: 'Error during $method: $error',
      );
      rethrow;
    }
  }

  Future<void> _refreshEngineMetadata() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'trackMetadata',
      );
      EngineTrackMetadata? metadata;
      Duration? duration;
      if (raw != null) {
        metadata = EngineTrackMetadata.fromJson(raw);
        if (metadata.durationMs > 0) {
          duration = Duration(milliseconds: metadata.durationMs);
        }
      }
      state.value = state.value.copyWith(
        updateEngineMetadata: true,
        engineMetadata: metadata,
        duration: duration ?? state.value.duration,
      );
    } on MissingPluginException {
      // Platform does not expose metadata; ignore.
    } catch (error) {
      debugPrint('Failed to refresh engine metadata: $error');
    }
  }

  Future<void> _saveState() async {
    await _storage.save(
      queue: _queue,
      index: _currentIndex,
      positionMs: state.value.position.inMilliseconds,
      mode: _playbackMode,
    );
  }
}
