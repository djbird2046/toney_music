import 'dart:typed_data';

import '../../../core/library/library_source.dart';
import '../../../core/media/song_metadata.dart';

class TrackRow {
  const TrackRow({
    required this.title,
    required this.artist,
    required this.path,
    required this.format,
    required this.sampleRate,
    required this.bitDepth,
    required this.duration,
    this.aiConfidence,
    this.sourceType = LibrarySourceType.local,
  });

  final String title;
  final String artist;
  final String path;
  final String format;
  final String sampleRate;
  final String bitDepth;
  final String duration;
  final double? aiConfidence;
  final LibrarySourceType sourceType;
}

class LibraryImportState {
  const LibraryImportState({
    required this.isActive,
    required this.message,
    this.progress,
    required this.canCancel,
  });

  const LibraryImportState.idle()
    : isActive = false,
      message = '',
      progress = null,
      canCancel = false;

  final bool isActive;
  final String message;
  final double? progress;
  final bool canCancel;

  bool get hasStatus => message.trim().isNotEmpty;
}

class AiCategory {
  const AiCategory({required this.name, required this.tracks});

  final String name;
  final int tracks;
}

class PlaylistEntry {
  const PlaylistEntry({
    required this.path,
    required this.metadata,
    this.bookmark,
  });

  final String path;
  final SongMetadata metadata;
  final Uint8List? bookmark;

  PlaylistEntry copyWith({
    String? path,
    SongMetadata? metadata,
    Uint8List? bookmark,
    bool clearBookmark = false,
  }) {
    return PlaylistEntry(
      path: path ?? this.path,
      metadata: metadata ?? this.metadata,
      bookmark: clearBookmark ? null : (bookmark ?? this.bookmark),
    );
  }
}
