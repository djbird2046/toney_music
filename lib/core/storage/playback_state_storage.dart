import 'package:hive/hive.dart';
import '../model/playback_track.dart';
import '../model/playback_mode.dart';

class PlaybackStateStorage {
  static const _boxName = 'toney_playback_state';
  static const _keyQueue = 'queue';
  static const _keyIndex = 'index';
  static const _keyPosition = 'position_ms';
  static const _keyMode = 'playback_mode';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> save({
    required List<PlaybackTrack> queue,
    required int? index,
    required int positionMs,
    required PlayMode mode,
  }) async {
    final box = _box;
    if (box == null) return;

    await box.putAll({
      _keyQueue: queue.map((e) => e.toJson()).toList(),
      _keyIndex: index,
      _keyPosition: positionMs,
      _keyMode: mode.index,
    });
  }

  PlaybackStateSnapshot load() {
    final box = _box;
    if (box == null) return PlaybackStateSnapshot.empty();

    final rawQueue = box.get(_keyQueue);
    final queue = (rawQueue is List)
        ? rawQueue.map((e) {
            try {
              return PlaybackTrack.fromJson(e);
            } catch (_) {
              return null;
            }
          }).whereType<PlaybackTrack>().toList()
        : <PlaybackTrack>[];

    final index = box.get(_keyIndex) as int?;
    final positionMs = box.get(_keyPosition) as int? ?? 0;
    final modeIndex = box.get(_keyMode) as int? ?? 0;
    final mode = PlayMode.values.length > modeIndex
        ? PlayMode.values[modeIndex]
        : PlayMode.sequence;

    return PlaybackStateSnapshot(
      queue: queue,
      currentIndex: index,
      positionMs: positionMs,
      mode: mode,
    );
  }
}

class PlaybackStateSnapshot {
  const PlaybackStateSnapshot({
    required this.queue,
    required this.currentIndex,
    required this.positionMs,
    required this.mode,
  });

  factory PlaybackStateSnapshot.empty() => const PlaybackStateSnapshot(
        queue: [],
        currentIndex: null,
        positionMs: 0,
        mode: PlayMode.sequence,
      );

  final List<PlaybackTrack> queue;
  final int? currentIndex;
  final int positionMs;
  final PlayMode mode;
}
