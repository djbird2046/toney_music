import 'package:hive/hive.dart';

import 'playlist_storage.dart';

class ForYouPlaylistSnapshot {
  const ForYouPlaylistSnapshot({required this.entries, this.note});

  final List<PlaylistReference> entries;
  final String? note;

  static const empty = ForYouPlaylistSnapshot(
    entries: <PlaylistReference>[],
    note: null,
  );

  bool get isEmpty => entries.isEmpty;
}

class ForYouPlaylistStorage {
  static const _boxName = 'toney_for_you_playlist';
  static const _keySnapshot = 'snapshot';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  ForYouPlaylistSnapshot load() {
    final box = _box;
    if (box == null) return ForYouPlaylistSnapshot.empty;
    final raw = box.get(_keySnapshot);
    if (raw is! Map) {
      return ForYouPlaylistSnapshot.empty;
    }
    final entriesRaw = raw['entries'];
    final note = raw['note'] as String?;
    final entries = <PlaylistReference>[];
    if (entriesRaw is List) {
      for (final item in entriesRaw) {
        try {
          entries.add(PlaylistReference.fromJson(item));
        } catch (_) {
          continue;
        }
      }
    }
    return ForYouPlaylistSnapshot(entries: entries, note: note);
  }

  Future<void> save(ForYouPlaylistSnapshot snapshot) async {
    final box = _box;
    if (box == null) return;
    await box.put(_keySnapshot, {
      'note': snapshot.note,
      'entries': snapshot.entries.map((e) => e.toJson()).toList(),
    });
  }
}
