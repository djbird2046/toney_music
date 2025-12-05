import 'package:hive/hive.dart';

class PlaybackSettingsSnapshot {
  const PlaybackSettingsSnapshot({required this.autoSampleRateEnabled});

  final bool autoSampleRateEnabled;
}

class PlaybackSettingsStorage {
  static const _boxName = 'toney_playback_settings';
  static const _keyAutoSampleRate = 'auto_sample_rate_enabled';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  PlaybackSettingsSnapshot load() {
    final box = _box;
    if (box == null) {
      return const PlaybackSettingsSnapshot(autoSampleRateEnabled: true);
    }
    final enabled = box.get(_keyAutoSampleRate) as bool?;
    return PlaybackSettingsSnapshot(autoSampleRateEnabled: enabled ?? true);
  }

  Future<void> save({required bool autoSampleRateEnabled}) async {
    final box = _box;
    if (box == null) return;
    await box.put(_keyAutoSampleRate, autoSampleRateEnabled);
  }
}
