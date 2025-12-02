// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_tool_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmptyArguments _$EmptyArgumentsFromJson(Map<String, dynamic> json) =>
    const EmptyArguments();

Map<String, dynamic> _$EmptyArgumentsToJson(EmptyArguments instance) =>
    <String, dynamic>{};

LimitArguments _$LimitArgumentsFromJson(Map<String, dynamic> json) =>
    LimitArguments(
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LimitArgumentsToJson(LimitArguments instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('limit', instance.limit);
  return val;
}

PlaylistDetailArguments _$PlaylistDetailArgumentsFromJson(
        Map<String, dynamic> json) =>
    PlaylistDetailArguments(
      name: json['name'] as String,
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlaylistDetailArgumentsToJson(
    PlaylistDetailArguments instance) {
  final val = <String, dynamic>{
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('limit', instance.limit);
  return val;
}

LibraryTracksArguments _$LibraryTracksArgumentsFromJson(
        Map<String, dynamic> json) =>
    LibraryTracksArguments(
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      filter: json['filter'] as String?,
    );

Map<String, dynamic> _$LibraryTracksArgumentsToJson(
    LibraryTracksArguments instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('limit', instance.limit);
  writeNotNull('offset', instance.offset);
  writeNotNull('filter', instance.filter);
  return val;
}

SongMetadataArguments _$SongMetadataArgumentsFromJson(
        Map<String, dynamic> json) =>
    SongMetadataArguments(
      path: json['path'] as String,
    );

Map<String, dynamic> _$SongMetadataArgumentsToJson(
        SongMetadataArguments instance) =>
    <String, dynamic>{
      'path': instance.path,
    };

SetCurrentPlaylistArguments _$SetCurrentPlaylistArgumentsFromJson(
        Map<String, dynamic> json) =>
    SetCurrentPlaylistArguments(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SetCurrentPlaylistArgumentsToJson(
        SetCurrentPlaylistArguments instance) =>
    <String, dynamic>{
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

CreatePlaylistArguments _$CreatePlaylistArgumentsFromJson(
        Map<String, dynamic> json) =>
    CreatePlaylistArguments(
      name: json['name'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SongSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreatePlaylistArgumentsToJson(
        CreatePlaylistArguments instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

AddSongArguments _$AddSongArgumentsFromJson(Map<String, dynamic> json) =>
    AddSongArguments(
      song: SongSummaryDto.fromJson(json['song'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AddSongArgumentsToJson(AddSongArguments instance) =>
    <String, dynamic>{
      'song': instance.song.toJson(),
    };
