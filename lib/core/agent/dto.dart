import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlaybackInfoDto {
  final bool isPlaying;
  final bool isBusy;
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration position;
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
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

  factory PlaybackInfoDto.fromJson(Map<String, dynamic> json) =>
      _$PlaybackInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaybackInfoDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class QueueItemDto {
  final String title;
  final String? artist;
  final String url;

  const QueueItemDto({required this.title, required this.url, this.artist});

  factory QueueItemDto.fromJson(Map<String, dynamic> json) =>
      _$QueueItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QueueItemDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TrackMetadataDto {
  final String url;
  final String? title;
  final String? artist;
  final String? album;
  final List<String>? tags;

  final String container; // flac/wav/aac/dsf …
  final String codec; // pcm_s16le, alac, mp3
  final int? bitrateKbps; // quality
  final String? sampleFormat; // 16bit / 24bit / 32bit
  final String? channelLayout; // stereo, mono …

  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
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

  factory TrackMetadataDto.fromJson(Map<String, dynamic> json) =>
      _$TrackMetadataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TrackMetadataDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SongSummaryDto {
  final String id; // usually the absolute path
  final String title;
  final String? artist;
  final String? album;
  final int? durationSec;
  final String? format;
  final String? source;

  const SongSummaryDto({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.durationSec,
    this.format,
    this.source,
  });

  factory SongSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SongSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SongSummaryDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlaylistSummaryDto {
  final String name;
  final int trackCount;

  const PlaylistSummaryDto({required this.name, required this.trackCount});

  factory PlaylistSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistSummaryDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlaylistDetailDto {
  final String name;
  final List<SongSummaryDto> tracks;

  const PlaylistDetailDto({required this.name, required this.tracks});

  factory PlaylistDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistDetailDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LibrarySummaryDto {
  final int total;
  final List<SongSummaryDto> tracks;

  const LibrarySummaryDto({required this.total, required this.tracks});

  factory LibrarySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$LibrarySummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LibrarySummaryDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FavoritesSummaryDto {
  final int total;
  final List<SongSummaryDto> favorites;

  const FavoritesSummaryDto({required this.total, required this.favorites});

  factory FavoritesSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$FavoritesSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FavoritesSummaryDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ResultStringDto {
  final String result;

  const ResultStringDto({required this.result});

  factory ResultStringDto.fromJson(Map<String, dynamic> json) =>
      _$ResultStringDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResultStringDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ForYouPlaylistDto {
  final List<SongSummaryDto> tracks;
  final String? note;

  const ForYouPlaylistDto({required this.tracks, this.note});

  factory ForYouPlaylistDto.fromJson(Map<String, dynamic> json) =>
      _$ForYouPlaylistDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ForYouPlaylistDtoToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SongMetadataInfoDto {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int? durationSec;
  final Map<String, String>? extras;

  const SongMetadataInfoDto({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.durationSec,
    this.extras,
  });

  factory SongMetadataInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SongMetadataInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SongMetadataInfoDtoToJson(this);
}

int _durationToJson(Duration value) => value.inMilliseconds;

Duration _durationFromJson(int? value) => Duration(milliseconds: value ?? 0);
