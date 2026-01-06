import 'song_metadata.dart';

/// Represents a track ready for playback.
class PlaybackTrack {
  const PlaybackTrack({
    required this.path,
    required this.metadata,
    this.duration,
    this.bookmark,
  });

  final String path;
  final SongMetadata metadata;
  final Duration? duration;
  final String? bookmark;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'metadata': metadata.toJson(),
      'durationMs': duration?.inMilliseconds,
      'bookmark': bookmark,
    };
  }

  factory PlaybackTrack.fromJson(Map<dynamic, dynamic> json) {
    final rawPath = json['path'] as String;
    final rawMetadata = json['metadata'];
    final durationMs = json['durationMs'] as int?;
    final bookmark = json['bookmark'] as String?;
    
    return PlaybackTrack(
      path: rawPath,
      metadata: SongMetadata.fromJson(Map<String, dynamic>.from(rawMetadata)),
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      bookmark: bookmark,
    );
  }
}
