import 'dart:convert';
import 'dart:typed_data';

class SongMetadata {
  const SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.extras = const <String, String>{},
    this.isFallback = false,
    this.artwork,
  });

  final String title;
  final String artist;
  final String album;
  final Map<String, String> extras;
  final bool isFallback;
  final Uint8List? artwork;

  factory SongMetadata.unknown(String fallbackTitle) => SongMetadata(
    title: fallbackTitle.isEmpty ? 'Unknown Title' : fallbackTitle,
    artist: 'Unknown Artist',
    album: 'Unknown Album',
    extras: const {},
    isFallback: true,
  );

  SongMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    Map<String, String>? extras,
    bool? isFallback,
    Uint8List? artwork,
  }) {
    return SongMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      extras: extras ?? this.extras,
      isFallback: isFallback ?? this.isFallback,
      artwork: artwork ?? this.artwork,
    );
  }

  List<MapEntry<String, String>> toDisplayEntries() {
    final entries = <MapEntry<String, String>>[
      MapEntry('Title', title),
      MapEntry('Artist', artist),
      MapEntry('Album', album),
    ];
    if (artwork != null) {
      entries.add(MapEntry('Artwork bytes', artwork!.lengthInBytes.toString()));
    }
    for (final entry in extras.entries) {
      if (entry.value.trim().isEmpty) continue;
      entries.add(entry);
    }
    return entries;
  }

  Map<String, dynamic> toJson({bool includeArtwork = true}) {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'extras': Map<String, String>.from(extras),
      'isFallback': isFallback,
      if (includeArtwork && artwork != null) 'artwork': base64Encode(artwork!),
    };
  }

  factory SongMetadata.fromJson(Map<String, dynamic> json) {
    final extrasRaw = json['extras'];
    final extras = <String, String>{};
    if (extrasRaw is Map) {
      for (final entry in extrasRaw.entries) {
        extras[entry.key.toString()] = entry.value.toString();
      }
    }
    Uint8List? artwork;
    final artworkRaw = json['artwork'];
    if (artworkRaw is String && artworkRaw.isNotEmpty) {
      try {
        artwork = Uint8List.fromList(base64Decode(artworkRaw));
      } catch (_) {
        artwork = null;
      }
    }
    final titleRaw = json['title'] as String?;
    final artistRaw = json['artist'] as String?;
    final albumRaw = json['album'] as String?;
    return SongMetadata(
      title: titleRaw != null && titleRaw.trim().isNotEmpty
          ? titleRaw
          : 'Unknown Title',
      artist: artistRaw != null && artistRaw.trim().isNotEmpty
          ? artistRaw
          : 'Unknown Artist',
      album: albumRaw != null && albumRaw.trim().isNotEmpty
          ? albumRaw
          : 'Unknown Album',
      extras: extras,
      isFallback: json['isFallback'] as bool? ?? false,
      artwork: artwork,
    );
  }
}
