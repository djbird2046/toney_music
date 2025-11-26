import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../library/library_source.dart';
import '../media/song_metadata.dart';

/// Remote file info model
/// Used for storing connection configuration and path info for remote audio files
class RemoteFileInfo {
  const RemoteFileInfo({
    required this.configId,
    required this.remotePath,
  });

  /// Connection configuration ID (references configuration in ConfigManager)
  final String configId;
  
  /// Remote file path
  final String remotePath;

  Map<String, dynamic> toJson() {
    return {
      'configId': configId,
      'remotePath': remotePath,
    };
  }

  factory RemoteFileInfo.fromJson(Map<String, dynamic> json) {
    return RemoteFileInfo(
      configId: json['configId'] as String,
      remotePath: json['remotePath'] as String,
    );
  }
}

class LibraryEntry {
  const LibraryEntry({
    required this.path,
    required this.sourceType,
    required this.metadata,
    this.bookmark,
    required this.importedAt,
    this.remoteInfo,
  });

  final String path;
  final LibrarySourceType sourceType;
  final SongMetadata metadata;
  final Uint8List? bookmark;
  final DateTime importedAt;
  
  /// Remote file info (only has value when sourceType is remote type)
  final RemoteFileInfo? remoteInfo;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'sourceType': sourceType.name,
      'metadata': metadata.toJson(includeArtwork: false),
      'importedAt': importedAt.millisecondsSinceEpoch,
      if (bookmark != null) 'bookmark': base64Encode(bookmark!),
      if (remoteInfo != null) 'remoteInfo': remoteInfo!.toJson(),
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
    final remoteInfoRaw = json['remoteInfo'];
    
    RemoteFileInfo? remoteInfo;
    if (remoteInfoRaw is Map) {
      try {
        remoteInfo = RemoteFileInfo.fromJson(
          Map<String, dynamic>.from(remoteInfoRaw),
        );
      } catch (_) {
        // Ignore invalid remote info
      }
    }
    
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
      remoteInfo: remoteInfo,
    );
  }
  
  /// Whether is remote file
  bool get isRemote => sourceType != LibrarySourceType.local;
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
