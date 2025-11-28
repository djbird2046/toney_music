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

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'metadata': metadata.toJson(),
      'durationMs': duration?.inMilliseconds,
    };
  }

  factory PlaybackTrack.fromJson(Map<dynamic, dynamic> json) {
    final rawPath = json['path'] as String;
    final rawMetadata = json['metadata'];
    final durationMs = json['durationMs'] as int?;
    
    return PlaybackTrack(
      path: rawPath,
      metadata: SongMetadata.fromJson(Map<String, dynamic>.from(rawMetadata)),
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
    );
  }
}
