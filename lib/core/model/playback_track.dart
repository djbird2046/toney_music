import 'song_metadata.dart';

/// Represents a track ready for playback.
class PlaybackTrack {
  const PlaybackTrack({
    required this.path,
    required this.metadata,
    this.duration,
  });

  final String path;
  final SongMetadata metadata;
  final Duration? duration;
}
