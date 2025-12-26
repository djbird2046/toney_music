import 'dart:async';

import 'package:hive/hive.dart';
import '../library/library_source.dart';
import '../model/song_metadata.dart';
import 'library_storage.dart';

class PlaylistReference {
  const PlaylistReference({
    required this.path,
    this.metadata,
    this.sourceType,
    this.remoteInfo,
    this.bookmark,
  });

  final String path;
  final SongMetadata? metadata;
  final LibrarySourceType? sourceType;
  final RemoteFileInfo? remoteInfo;
  final String? bookmark;

  /// Whether is remote file
  bool get isRemote =>
      sourceType != null && sourceType != LibrarySourceType.local;

  Map<String, dynamic> toJson() => {
    'path': path,
    if (metadata != null) 'metadata': metadata!.toJson(),
    if (sourceType != null) 'sourceType': sourceType!.name,
    if (remoteInfo != null) 'remoteInfo': remoteInfo!.toJson(),
    if (bookmark != null) 'bookmark': bookmark,
  };

  static PlaylistReference fromJson(dynamic json) {
    if (json is String) {
      return PlaylistReference(path: json);
    }
    if (json is! Map) {
      throw ArgumentError('Invalid playlist entry: $json');
    }
    final path = json['path'] as String?;
    if (path == null) {
      throw ArgumentError('Missing path in playlist entry: $json');
    }
    SongMetadata? metadata;
    final metadataRaw = json['metadata'];
    if (metadataRaw is Map) {
      try {
        metadata = SongMetadata.fromJson(
          Map<String, dynamic>.from(metadataRaw),
        );
      } catch (_) {
        metadata = null;
      }
    }

    // Parse sourceType
    LibrarySourceType? sourceType;
    final sourceRaw = json['sourceType'] as String?;
    if (sourceRaw != null) {
      try {
        sourceType = LibrarySourceType.values.firstWhere(
          (type) => type.name == sourceRaw,
        );
      } catch (_) {
        sourceType = null;
      }
    }

    // Parse remoteInfo
    RemoteFileInfo? remoteInfo;
    final remoteInfoRaw = json['remoteInfo'];
    if (remoteInfoRaw is Map) {
      try {
        remoteInfo = RemoteFileInfo.fromJson(
          Map<String, dynamic>.from(remoteInfoRaw),
        );
      } catch (_) {
        remoteInfo = null;
      }
    }
    final bookmark = json['bookmark'] as String?;

    return PlaylistReference(
      path: path,
      metadata: metadata,
      sourceType: sourceType,
      remoteInfo: remoteInfo,
      bookmark: bookmark,
    );
  }
}

class PlaylistSnapshot {
  const PlaylistSnapshot({required this.names, required this.entries});

  final List<String> names;
  final Map<String, List<PlaylistReference>> entries;

  bool get isEmpty => names.isEmpty;

  static const empty = PlaylistSnapshot(
    names: <String>[],
    entries: <String, List<PlaylistReference>>{},
  );
}

class PlaylistStorage {
  static const _boxName = 'toney_playlists';
  static const _snapshotKey = 'snapshot';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  PlaylistSnapshot load() {
    final box = _box;
    if (box == null) {
      return PlaylistSnapshot.empty;
    }
    final raw = box.get(_snapshotKey);
    if (raw is! Map) {
      return PlaylistSnapshot.empty;
    }
    final names = (raw['names'] as List?)?.cast<String>() ?? const <String>[];
    final entriesRaw = (raw['entries'] as Map?) ?? const {};
    final entries = <String, List<PlaylistReference>>{};
    entriesRaw.forEach((key, value) {
      if (key is String && value is List) {
        final refs = <PlaylistReference>[];
        for (final item in value) {
          try {
            refs.add(PlaylistReference.fromJson(item));
          } catch (_) {
            continue;
          }
        }
        entries[key] = refs;
      }
    });
    return PlaylistSnapshot(names: names, entries: entries);
  }

  Future<void> save(PlaylistSnapshot snapshot) async {
    final box = _box;
    if (box == null) return;
    await box.put(_snapshotKey, {
      'names': snapshot.names,
      'entries': snapshot.entries.map(
        (key, value) =>
            MapEntry(key, value.map((entry) => entry.toJson()).toList()),
      ),
    });
  }

  StreamSubscription<BoxEvent>? watch(void Function() onChanged) {
    final box = _box;
    if (box == null) return null;
    return box.watch(key: _snapshotKey).listen((event) {
      onChanged();
    });
  }
}
