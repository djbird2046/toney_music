import '../audio_controller.dart';
import '../model/engine_track_models.dart';
import 'dto.dart';
import 'song_mapper.dart';

class PlaybackAgent {
  PlaybackAgent({required AudioController controller})
    : _controller = controller;

  final AudioController _controller;

  PlaybackInfoDto getPlaybackInfo({int maxQueueItems = 25}) {
    final state = _controller.state.value;
    return PlaybackInfoDto(
      isPlaying: state.isPlaying,
      isBusy: state.isBusy,
      position: state.position,
      duration: state.duration,
      currentIndex: state.currentIndex ?? -1,
      queue: state.queue
          .take(maxQueueItems)
          .map(
            (track) => QueueItemDto(
              title: track.metadata.title,
              artist: _cleanUnknown(track.metadata.artist),
              url: track.path,
            ),
          )
          .toList(),
      currentTrack: _buildTrackMetadataDto(state.engineMetadata),
      statusMessage: state.statusMessage,
    );
  }

  PlaylistDetailDto getCurrentQueue({int? limit}) {
    final state = _controller.state.value;
    final tracks = state.queue
        .take(limit ?? state.queue.length)
        .map(
          (track) => SongMapper.fromMetadata(
            path: track.path,
            metadata: track.metadata,
          ),
        )
        .toList();
    return PlaylistDetailDto(name: 'Current Queue', tracks: tracks);
  }

  Future<ResultStringDto> setQueue(List<SongSummaryDto> tracks) async {
    final playbackTracks = tracks
        .map(SongMapper.playbackTrackFromSummary)
        .toList(growable: false);
    _controller.setQueue(
      playbackTracks,
      startIndex: playbackTracks.isNotEmpty ? 0 : null,
    );
    return ResultStringDto(result: 'queue_updated:${playbackTracks.length}');
  }

  Future<ResultStringDto> addSongAndPlay(SongSummaryDto song) async {
    final state = _controller.state.value;
    final newQueue = List.of(state.queue)
      ..add(SongMapper.playbackTrackFromSummary(song));
    final newIndex = newQueue.length - 1;
    _controller.setQueue(newQueue, startIndex: state.currentIndex);
    await _controller.playAt(newIndex);
    return ResultStringDto(result: 'playing:${song.title}');
  }

  TrackMetadataDto? _buildTrackMetadataDto(EngineTrackMetadata? metadata) {
    if (metadata == null) return null;
    return TrackMetadataDto(
      url: metadata.url,
      title: metadata.tags.title,
      artist: metadata.tags.artist,
      album: metadata.tags.album,
      tags: _buildTagList(metadata),
      container: metadata.containerName,
      codec: metadata.codecName,
      duration: metadata.duration,
      bitrateKbps: metadata.sourceBitrateKbps.toInt(),
      sampleFormat: metadata.sampleFormatName,
      channelLayout: metadata.pcm.channelsLabel,
    );
  }

  List<String>? _buildTagList(EngineTrackMetadata metadata) {
    final tags = <String>{};
    void add(String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      tags.add(trimmed);
    }

    add(metadata.tags.genre);
    add(metadata.tags.albumArtist);
    add(metadata.tags.date);
    if (tags.isEmpty) return null;
    return tags.toList()..sort();
  }

  String? _cleanUnknown(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().startsWith('unknown')) return null;
    return trimmed;
  }
}
