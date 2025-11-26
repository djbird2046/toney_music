import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'playback/engine_track_models.dart';
import 'playback/playback_track.dart';
import 'playback_view_model.dart';

/// Shared coordinator that wraps the MethodChannel API exposed by the native
/// AudioEnginePlugin. UI layers should depend on this instead of touching
/// MethodChannels directly.
class AudioController {
  AudioController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('audio_engine');

  final MethodChannel _channel;
  List<PlaybackTrack> _queue = const [];
  int? _currentIndex;
  Timer? _positionTimer;
  DateTime? _lastTick;

  final ValueNotifier<PlaybackViewModel> state = ValueNotifier(
    PlaybackViewModel.initial(),
  );

  Future<void> load(String path, {Uint8List? bookmark}) async {
    state.value = state.value.copyWith(
      updateEngineMetadata: true,
      engineMetadata: null,
    );
    await _run(
      'load',
      () => _channel.invokeMethod('load', {
        'path': path,
        if (bookmark != null) 'bookmark': bookmark,
      }),
    );
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
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    final track = _queue[index];
    await load(track.path, bookmark: track.bookmark);
    state.value = state.value.copyWith(
      queue: _queue,
      currentIndex: _currentIndex,
      duration: track.duration ?? Duration.zero,
      position: Duration.zero,
    );
    await play();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    final nextIndex = _currentIndex == null
        ? 0
        : (_currentIndex! + 1) % _queue.length;
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
  }

  Future<Uint8List?> createBookmark(String path) async {
    final result = await _channel.invokeMethod('createBookmark', {
      'path': path,
    });
    if (result is Uint8List) return result;
    if (result is ByteData) {
      return result.buffer.asUint8List();
    }
    return null;
  }

  void dispose() {
    state.dispose();
    _stopPositionTicker();
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
}
