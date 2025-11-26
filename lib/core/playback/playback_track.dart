import 'dart:typed_data';

import '../media/song_metadata.dart';

/// Represents a track ready for playback.
class PlaybackTrack {
  const PlaybackTrack({
    required this.path,
    required this.metadata,
    this.bookmark,
    this.duration,
  });

  final String path;
  final SongMetadata metadata;
  final Uint8List? bookmark;
  final Duration? duration;
}
