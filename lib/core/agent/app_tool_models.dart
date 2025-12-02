import 'package:json_annotation/json_annotation.dart';

import 'dto.dart';

part 'app_tool_models.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EmptyArguments {
  const EmptyArguments();

  factory EmptyArguments.fromJson(Map<String, dynamic> json) =>
      _$EmptyArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$EmptyArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LimitArguments {
  final int? limit;

  const LimitArguments({this.limit});

  factory LimitArguments.fromJson(Map<String, dynamic> json) =>
      _$LimitArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$LimitArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlaylistDetailArguments {
  final String name;
  final int? limit;

  const PlaylistDetailArguments({required this.name, this.limit});

  factory PlaylistDetailArguments.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDetailArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistDetailArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LibraryTracksArguments {
  final int? limit;
  final int? offset;
  final String? filter;

  const LibraryTracksArguments({
    this.limit,
    this.offset,
    this.filter,
  });

  factory LibraryTracksArguments.fromJson(Map<String, dynamic> json) =>
      _$LibraryTracksArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryTracksArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SongMetadataArguments {
  final String path;

  const SongMetadataArguments({required this.path});

  factory SongMetadataArguments.fromJson(Map<String, dynamic> json) =>
      _$SongMetadataArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$SongMetadataArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SetCurrentPlaylistArguments {
  final List<SongSummaryDto> tracks;

  const SetCurrentPlaylistArguments({required this.tracks});

  factory SetCurrentPlaylistArguments.fromJson(Map<String, dynamic> json) =>
      _$SetCurrentPlaylistArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$SetCurrentPlaylistArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CreatePlaylistArguments {
  final String name;
  final List<SongSummaryDto> tracks;

  const CreatePlaylistArguments({required this.name, required this.tracks});

  factory CreatePlaylistArguments.fromJson(Map<String, dynamic> json) =>
      _$CreatePlaylistArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePlaylistArgumentsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AddSongArguments {
  final SongSummaryDto song;

  const AddSongArguments({required this.song});

  factory AddSongArguments.fromJson(Map<String, dynamic> json) =>
      _$AddSongArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$AddSongArgumentsToJson(this);
}
