import 'package:path/path.dart' as p;

import '../library/library_source.dart';
import '../model/song_metadata.dart';
import '../model/playback_track.dart';
import '../storage/library_storage.dart';
import '../storage/playlist_storage.dart';
import 'dto.dart';

class SongMapper {
  const SongMapper._();

  static SongSummaryDto fromLibraryEntry(LibraryEntry entry) {
    return fromMetadata(
      path: entry.path,
      metadata: entry.metadata,
      sourceType: entry.sourceType,
    );
  }

  static SongSummaryDto fromPlaylistReference(PlaylistReference reference) {
    final metadata =
        reference.metadata ??
        SongMetadata.unknown(p.basenameWithoutExtension(reference.path));
    return fromMetadata(
      path: reference.path,
      metadata: metadata,
      sourceType: reference.sourceType,
    );
  }

  static SongSummaryDto fromMetadata({
    required String path,
    required SongMetadata metadata,
    LibrarySourceType? sourceType,
  }) {
    return SongSummaryDto(
      id: path,
      title: metadata.title,
      artist: _cleanValue(metadata.artist),
      album: _cleanValue(metadata.album),
      durationSec: _durationSecondsFromMetadata(metadata),
      format: _formatFromExtras(metadata, path),
      source: sourceType?.name,
    );
  }

  static SongMetadata metadataFromSummary(SongSummaryDto summary) {
    final extras = <String, String>{};
    if (summary.format != null) {
      extras['Format'] = summary.format!;
    }
    if (summary.durationSec != null) {
      extras['duration_ms'] = (summary.durationSec! * 1000).toString();
      extras['Duration'] = _formatDurationLabel(
        Duration(seconds: summary.durationSec!),
      );
    }
    if (summary.source != null) {
      extras['Source'] = summary.source!;
    }
    return SongMetadata(
      title: summary.title,
      artist: summary.artist ?? 'Unknown Artist',
      album: summary.album ?? 'Unknown Album',
      extras: extras,
    );
  }

  static PlaylistReference playlistReferenceFromSummary(
    SongSummaryDto summary,
  ) {
    return PlaylistReference(
      path: summary.id,
      metadata: metadataFromSummary(summary),
      sourceType: _sourceTypeFromString(summary.source),
    );
  }

  static PlaybackTrack playbackTrackFromSummary(SongSummaryDto summary) {
    return PlaybackTrack(
      path: summary.id,
      metadata: metadataFromSummary(summary),
      duration: summary.durationSec != null
          ? Duration(seconds: summary.durationSec!)
          : null,
    );
  }

  static LibrarySourceType? _sourceTypeFromString(String? raw) {
    if (raw == null) return null;
    final normalized = raw.toLowerCase();
    for (final type in LibrarySourceType.values) {
      if (type.name.toLowerCase() == normalized ||
          type.label.toLowerCase() == normalized) {
        return type;
      }
    }
    return null;
  }

  static String? _cleanValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (normalized.toLowerCase().startsWith('unknown')) {
      return null;
    }
    return normalized;
  }

  static int? _durationSecondsFromMetadata(SongMetadata metadata) {
    final durationMs = metadata.extras['duration_ms'];
    if (durationMs != null) {
      final parsed = int.tryParse(durationMs);
      if (parsed != null && parsed > 0) {
        return (parsed / 1000).round();
      }
    }
    final duration = metadata.extras['Duration'];
    if (duration != null && duration.contains(':')) {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]);
        final seconds = int.tryParse(parts[1]);
        if (minutes != null && seconds != null) {
          return minutes * 60 + seconds;
        }
      }
    }
    return null;
  }

  static String? _formatFromExtras(SongMetadata metadata, String path) {
    final fromExtras = metadata.extras['Format'] ?? metadata.extras['format'];
    if (fromExtras != null && fromExtras.trim().isNotEmpty) {
      return fromExtras.trim();
    }
    final extension = p.extension(path).replaceFirst('.', '').toUpperCase();
    return extension.isEmpty ? null : extension;
  }

  static String _formatDurationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
