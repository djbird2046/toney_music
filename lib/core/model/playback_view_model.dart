import 'engine_track_models.dart';
import 'playback_track.dart';

class PlaybackViewModel {
  const PlaybackViewModel({
    required this.isBusy,
    required this.isPlaying,
    required this.hasFile,
    required this.statusMessage,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    this.engineMetadata,
  });

  final bool isBusy;
  final bool isPlaying;
  final bool hasFile;
  final String statusMessage;
  final List<PlaybackTrack> queue;
  final int? currentIndex;
  final Duration position;
  final Duration duration;
  final EngineTrackMetadata? engineMetadata;

  PlaybackTrack? get currentTrack =>
      currentIndex != null && currentIndex! >= 0 && currentIndex! < queue.length
      ? queue[currentIndex!]
      : null;

  factory PlaybackViewModel.initial() => PlaybackViewModel(
    isBusy: false,
    isPlaying: false,
    hasFile: false,
    statusMessage: 'Idle',
    queue: const [],
    currentIndex: null,
    position: Duration.zero,
    duration: Duration.zero,
    engineMetadata: null,
  );

  PlaybackViewModel copyWith({
    bool? isBusy,
    bool? isPlaying,
    bool? hasFile,
    String? statusMessage,
    List<PlaybackTrack>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    EngineTrackMetadata? engineMetadata,
    bool updateEngineMetadata = false,
  }) {
    return PlaybackViewModel(
      isBusy: isBusy ?? this.isBusy,
      isPlaying: isPlaying ?? this.isPlaying,
      hasFile: hasFile ?? this.hasFile,
      statusMessage: statusMessage ?? this.statusMessage,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      engineMetadata: updateEngineMetadata
          ? engineMetadata
          : this.engineMetadata,
    );
  }
}
