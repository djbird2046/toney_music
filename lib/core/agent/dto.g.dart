// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackInfoDto _$PlaybackInfoDtoFromJson(Map<String, dynamic> json) =>
    PlaybackInfoDto(
      isPlaying: json['isPlaying'] as bool,
      isBusy: json['isBusy'] as bool,
      position: _durationFromJson((json['position'] as num?)?.toInt()),
      duration: _durationFromJson((json['duration'] as num?)?.toInt()),
      currentIndex: (json['currentIndex'] as num).toInt(),
      queue: (json['queue'] as List<dynamic>)
          .map((e) => QueueItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentTrack: json['currentTrack'] == null
          ? null
          : TrackMetadataDto.fromJson(
              json['currentTrack'] as Map<String, dynamic>),
      statusMessage: json['statusMessage'] as String?,
    );

Map<String, dynamic> _$PlaybackInfoDtoToJson(PlaybackInfoDto instance) {
  final val = <String, dynamic>{
    'isPlaying': instance.isPlaying,
    'isBusy': instance.isBusy,
    'position': _durationToJson(instance.position),
    'duration': _durationToJson(instance.duration),
    'currentIndex': instance.currentIndex,
    'queue': instance.queue.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('currentTrack', instance.currentTrack?.toJson());
  writeNotNull('statusMessage', instance.statusMessage);
  return val;
}

QueueItemDto _$QueueItemDtoFromJson(Map<String, dynamic> json) => QueueItemDto(
      title: json['title'] as String,
      url: json['url'] as String,
      artist: json['artist'] as String?,
    );

Map<String, dynamic> _$QueueItemDtoToJson(QueueItemDto instance) {
  final val = <String, dynamic>{
    'title': instance.title,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artist', instance.artist);
  val['url'] = instance.url;
  return val;
}

TrackMetadataDto _$TrackMetadataDtoFromJson(Map<String, dynamic> json) =>
    TrackMetadataDto(
      url: json['url'] as String,
      container: json['container'] as String,
      codec: json['codec'] as String,
      duration: _durationFromJson((json['duration'] as num?)?.toInt()),
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      bitrateKbps: (json['bitrateKbps'] as num?)?.toInt(),
      sampleFormat: json['sampleFormat'] as String?,
      channelLayout: json['channelLayout'] as String?,
    );

Map<String, dynamic> _$TrackMetadataDtoToJson(TrackMetadataDto instance) {
  final val = <String, dynamic>{
    'url': instance.url,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('title', instance.title);
  writeNotNull('artist', instance.artist);
  writeNotNull('album', instance.album);
  writeNotNull('tags', instance.tags);
  val['container'] = instance.container;
  val['codec'] = instance.codec;
  writeNotNull('bitrateKbps', instance.bitrateKbps);
  writeNotNull('sampleFormat', instance.sampleFormat);
  writeNotNull('channelLayout', instance.channelLayout);
  val['duration'] = _durationToJson(instance.duration);
  return val;
}

SongSummaryDto _$SongSummaryDtoFromJson(Map<String, dynamic> json) =>
    SongSummaryDto(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      durationSec: (json['durationSec'] as num?)?.toInt(),
      format: json['format'] as String?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$SongSummaryDtoToJson(SongSummaryDto instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'title': instance.title,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artist', instance.artist);
  writeNotNull('album', instance.album);
  writeNotNull('durationSec', instance.durationSec);
  writeNotNull('format', instance.format);
  writeNotNull('source', instance.source);
  return val;
}

PlaylistSummaryDto _$PlaylistSummaryDtoFromJson(Map<String, dynamic> json) =>
    PlaylistSummaryDto(
      name: json['name'] as String,
      trackCount: (json['trackCount'] as num).toInt(),
    );

Map<String, dynamic> _$PlaylistSummaryDtoToJson(PlaylistSummaryDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'trackCount': instance.trackCount,
    };

PlaylistDetailDto _$PlaylistDetailDtoFromJson(Map<String, dynamic> json) =>
    PlaylistDetailDto(
      name: json['name'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaylistDetailDtoToJson(PlaylistDetailDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

LibrarySummaryDto _$LibrarySummaryDtoFromJson(Map<String, dynamic> json) =>
    LibrarySummaryDto(
      total: (json['total'] as num).toInt(),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LibrarySummaryDtoToJson(LibrarySummaryDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

FavoritesSummaryDto _$FavoritesSummaryDtoFromJson(Map<String, dynamic> json) =>
    FavoritesSummaryDto(
      total: (json['total'] as num).toInt(),
      favorites: (json['favorites'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FavoritesSummaryDtoToJson(
        FavoritesSummaryDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'favorites': instance.favorites.map((e) => e.toJson()).toList(),
    };

ResultStringDto _$ResultStringDtoFromJson(Map<String, dynamic> json) =>
    ResultStringDto(
      result: json['result'] as String,
    );

Map<String, dynamic> _$ResultStringDtoToJson(ResultStringDto instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

ForYouPlaylistDto _$ForYouPlaylistDtoFromJson(Map<String, dynamic> json) =>
    ForYouPlaylistDto(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$ForYouPlaylistDtoToJson(ForYouPlaylistDto instance) {
  final val = <String, dynamic>{
    'tracks': instance.tracks.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('note', instance.note);
  return val;
}

SongMetadataInfoDto _$SongMetadataInfoDtoFromJson(Map<String, dynamic> json) =>
    SongMetadataInfoDto(
      path: json['path'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      durationSec: (json['durationSec'] as num?)?.toInt(),
      extras: (json['extras'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$SongMetadataInfoDtoToJson(SongMetadataInfoDto instance) {
  final val = <String, dynamic>{
    'path': instance.path,
    'title': instance.title,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artist', instance.artist);
  writeNotNull('album', instance.album);
  writeNotNull('durationSec', instance.durationSec);
  writeNotNull('extras', instance.extras);
  return val;
}
