import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../library/library_source.dart';
import '../media/song_metadata.dart';

class LibraryEntry {
  const LibraryEntry({
    required this.path,
    required this.sourceType,
    required this.metadata,
    this.bookmark,
    required this.importedAt,
  });

  final String path;
  final LibrarySourceType sourceType;
  final SongMetadata metadata;
  final Uint8List? bookmark;
  final DateTime importedAt;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'sourceType': sourceType.name,
      'metadata': metadata.toJson(includeArtwork: false),
      'importedAt': importedAt.millisecondsSinceEpoch,
      if (bookmark != null) 'bookmark': base64Encode(bookmark!),
    };
  }

  factory LibraryEntry.fromJson(dynamic json) {
    if (json is! Map) {
      throw ArgumentError('Invalid library entry: $json');
    }
    final path = json['path'] as String?;
    final sourceRaw = json['sourceType'] as String?;
    final metadataRaw = json['metadata'];
    if (path == null || sourceRaw == null || metadataRaw is! Map) {
      throw ArgumentError('Incomplete library entry: $json');
    }
    final sourceType = LibrarySourceType.values.firstWhere(
      (type) => type.name == sourceRaw,
      orElse: () => LibrarySourceType.local,
    );
    final metadata = SongMetadata.fromJson(
      Map<String, dynamic>.from(metadataRaw),
    );
    final importedAtMs = json['importedAt'] as int?;
    final bookmarkRaw = json['bookmark'] as String?;
    return LibraryEntry(
      path: path,
      sourceType: sourceType,
      metadata: metadata,
      bookmark: bookmarkRaw == null
          ? null
          : Uint8List.fromList(base64Decode(bookmarkRaw)),
      importedAt: importedAtMs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(importedAtMs),
    );
  }
}

class LibraryStorage {
  static const _boxName = 'toney_library';
  static const _entriesKey = 'entries';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  List<LibraryEntry> load() {
    final box = _box;
    if (box == null) return const <LibraryEntry>[];
    final raw = box.get(_entriesKey);
    if (raw is! List) return const <LibraryEntry>[];
    final entries = <LibraryEntry>[];
    for (final item in raw) {
      try {
        entries.add(LibraryEntry.fromJson(item));
      } catch (_) {
        continue;
      }
    }
    return entries;
  }

  Future<void> save(List<LibraryEntry> entries) async {
    final box = _box;
    if (box == null) return;
    await box.put(_entriesKey, entries.map((entry) => entry.toJson()).toList());
  }
}
