import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlaybackInfoDto {
  final bool isPlaying;
  final bool isBusy;
  final Duration position;
  final Duration duration;
  final int currentIndex;
  final List<QueueItemDto> queue;
  final TrackMetadataDto? currentTrack;
  final String? statusMessage;

  const PlaybackInfoDto({
    required this.isPlaying,
    required this.isBusy,
    required this.position,
    required this.duration,
    required this.currentIndex,
    required this.queue,
    this.currentTrack,
    this.statusMessage,
  });

  factory PlaybackInfoDto.fromJson(Map<String, dynamic> json) => _$PlaybackInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackInfoDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class QueueItemDto {
  final String title;
  final String? artist;
  final String url;

  const QueueItemDto({
    required this.title,
    required this.url,
    this.artist,
  });

  factory QueueItemDto.fromJson(Map<String, dynamic> json) => _$QueueItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QueueItemDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TrackMetadataDto {
  final String url;
  final String? title;
  final String? artist;
  final String? album;
  final List<String>? tags;

  final String container;        // flac/wav/aac/dsf …
  final String codec;            // pcm_s16le, alac, mp3
  final int? bitrateKbps;        // quality
  final String? sampleFormat;    // 16bit / 24bit / 32bit
  final String? channelLayout;   // stereo, mono …

  final Duration duration;

  const TrackMetadataDto({
    required this.url,
    required this.container,
    required this.codec,
    required this.duration,
    this.title,
    this.artist,
    this.album,
    this.tags,
    this.bitrateKbps,
    this.sampleFormat,
    this.channelLayout,
  });

  factory TrackMetadataDto.fromJson(Map<String, dynamic> json) => _$TrackMetadataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TrackMetadataDtoToJson(this);
}