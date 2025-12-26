import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MediaSessionPlaybackStatus { playing, paused, stopped }

@immutable
class MediaSessionMetadata {
  const MediaSessionMetadata({
    this.title,
    this.artist,
    this.album,
    this.artworkFilePath,
    this.artworkBase64,
  });

  final String? title;
  final String? artist;
  final String? album;

  /// Local image file path (Windows only for now).：
  final String? artworkFilePath;

  /// Base64-encoded image bytes (no data URI prefix).
  final String? artworkBase64;

  Map<String, Object?> toMap() => <String, Object?>{
        'title': title,
        'artist': artist,
        'album': album,
        'artworkFilePath': artworkFilePath,
        'artworkBase64': artworkBase64,
      };
}

@immutable
class MediaSessionPlaybackState {
  const MediaSessionPlaybackState({
    required this.status,
    this.durationMs,
    this.playbackRate,
  });

  final MediaSessionPlaybackStatus status;
  final int? durationMs;
  final double? playbackRate;

  Map<String, Object?> toMap() => <String, Object?>{
        'status': status.name,
        'durationMs': durationMs,
        'playbackRate': playbackRate,
      };
}

typedef MediaSessionActionCallback = void Function();

class MediaSession {
  MediaSession._({
    required MethodChannel? channel,
  }) : _channel = channel {
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  static MediaSession get instance => _instance ??= _create();
  static MediaSession? _instance;

  static MediaSession _create() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return MediaSession._(channel: const MethodChannel('media_session'));
    }
    return MediaSession._(channel: null);
  }

  final MethodChannel? _channel;

  MediaSessionActionCallback? onPlay;
  MediaSessionActionCallback? onPause;
  MediaSessionActionCallback? onNext;
  MediaSessionActionCallback? onPrevious;

  Future<void> updateMetadata(MediaSessionMetadata metadata) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod<void>('updateMetadata', metadata.toMap());
  }

  Future<void> updatePlaybackState(MediaSessionPlaybackState state) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod<void>('updatePlaybackState', state.toMap());
  }

  Future<void> setPosition(int positionMs) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod<void>('setPosition', <String, Object?>{
      'positionMs': positionMs,
    });
  }

  Future<void> dispose() async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod<void>('dispose');
    channel.setMethodCallHandler(null);
    onPlay = null;
    onPause = null;
    onNext = null;
    onPrevious = null;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPlay':
        onPlay?.call();
        break;
      case 'onPause':
        onPause?.call();
        break;
      case 'onNext':
        onNext?.call();
        break;
      case 'onPrevious':
        onPrevious?.call();
        break;
      default:
        throw MissingPluginException();
    }
  }
}
