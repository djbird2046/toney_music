import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_tags/dart_tags.dart';
import 'package:path/path.dart' as p;

import '../model/song_metadata.dart';

/// Parses audio metadata using [dart_tags] with sane fallbacks for missing tags.
class SongMetadataUtil {
  SongMetadataUtil({TagProcessor? processor})
    : _processor = processor ?? TagProcessor();

  static const _fallbackExtensions = {'wav', 'wave', 'aif', 'aiff', 'pcm'};

  final TagProcessor _processor;

  Future<SongMetadata> loadFromPath(String filePath) async {
    final extension = _extensionOf(filePath);
    final fallbackTitle = _deriveTitle(filePath);

    if (_fallbackExtensions.contains(extension)) {
      return SongMetadata(
        title: fallbackTitle,
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        extras: {'File Name': p.basename(filePath), 'Source': 'Filename'},
        isFallback: true,
      );
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return SongMetadata.unknown(fallbackTitle);
      }
      final bytes = await file.readAsBytes();
      final tags = await _processor.getTagsFromByteArray(Future.value(bytes));
      final metadata = _extractMetadata(tags);
      if (metadata != null) {
        return metadata.copyWith(
          extras: {...metadata.extras, 'File Name': p.basename(filePath)},
        );
      }
    } catch (_) {
      // Ignore parse errors and fall back to filename-based metadata.
    }

    return SongMetadata.unknown(
      fallbackTitle,
    ).copyWith(extras: {'File Name': p.basename(filePath)});
  }

  String _extensionOf(String path) {
    final extension = p.extension(path).replaceAll('.', '').toLowerCase();
    return extension;
  }

  String _deriveTitle(String path) {
    final name = p.basenameWithoutExtension(path);
    return name.isEmpty ? 'Unknown Title' : name;
  }

  SongMetadata? _extractMetadata(List<Tag> tags) {
    for (final tag in tags) {
      final data = tag.tags;
      final title = _firstString(data['title']) ?? _firstString(data['TIT2']);
      final artist = _firstString(data['artist']) ?? _firstString(data['TPE1']);
      final album = _firstString(data['album']) ?? _firstString(data['TALB']);
      final artwork = _extractArtwork(data);

      if (title == null && artist == null && album == null) {
        continue;
      }

      final extras = <String, String>{};
      data.forEach((key, value) {
        final normalizedKey = _normalizeKey(key);
        final normalizedValue = _firstString(value) ?? '';
        if (normalizedValue.isEmpty) return;
        if (normalizedKey == 'title' ||
            normalizedKey == 'artist' ||
            normalizedKey == 'album' ||
            normalizedKey == 'apic' ||
            normalizedKey == 'pic' ||
            normalizedKey == 'picture' ||
            normalizedKey == 'attached_picture') {
          return;
        }
        extras[_labelize(normalizedKey)] = normalizedValue;
      });

      return SongMetadata(
        title: title ?? 'Unknown Title',
        artist: artist ?? 'Unknown Artist',
        album: album ?? 'Unknown Album',
        extras: extras,
        artwork: artwork,
      );
    }
    return null;
  }

  String? _firstString(dynamic value) {
    if (value == null) return null;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first == null) return null;
      return first.toString();
    }
    return value.toString();
  }

  String _normalizeKey(String? key) => (key ?? '').toLowerCase();

  String _labelize(String key) {
    if (key.isEmpty) return 'Info';
    return key
        .split('_')
        .map(
          (segment) => segment.isEmpty
              ? segment
              : '${segment[0].toUpperCase()}${segment.substring(1)}',
        )
        .join(' ');
  }

  Uint8List? _extractArtwork(Map<dynamic, dynamic> data) {
    const artworkKeys = ['APIC', 'PIC', 'picture', 'attached_picture'];
    for (final key in artworkKeys) {
      final value = data[key];
      final bytes = _extractArtworkValue(value);
      if (bytes != null) {
        return bytes;
      }
    }
    return null;
  }

  Uint8List? _extractArtworkValue(dynamic value) {
    if (value == null) return null;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    if (value is AttachedPicture) {
      return Uint8List.fromList(value.imageData);
    }
    if (value is List) {
      for (final entry in value) {
        final candidate = _extractArtworkValue(entry);
        if (candidate != null) return candidate;
      }
    }
    if (value is Map) {
      if (value.containsKey('bitmap')) {
        final bitmap = value['bitmap'];
        if (bitmap is String) {
          final decoded = _decodeBase64(bitmap);
          if (decoded != null) return decoded;
        }
      }
      for (final entry in value.values) {
        final nested = _extractArtworkValue(entry);
        if (nested != null) return nested;
      }
    }
    if (value is String) {
      return _decodeBase64(value);
    }
    return null;
  }

  Uint8List? _decodeBase64(String raw) {
    var candidate = raw.trim();
    final bitmapIndex = candidate.toLowerCase().indexOf('bitmap');
    if (bitmapIndex != -1) {
      final colon = candidate.indexOf(':', bitmapIndex);
      if (colon != -1 && colon + 1 < candidate.length) {
        candidate = candidate.substring(colon + 1).trim();
      }
    }
    candidate = candidate
        .replaceAll(RegExp('[{} ]'), '')
        .replaceAll('\n', '')
        .trim();
    if (candidate.isEmpty) return null;
    try {
      return base64Decode(candidate);
    } catch (_) {
      return null;
    }
  }
}
