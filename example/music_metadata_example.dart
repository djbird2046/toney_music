import 'dart:io';

import 'package:toney_music/toney_core.dart';

/// Simple script to exercise [SongMetadataUtil].
///
/// Replace [samplePaths] with real files before running:
///   dart example/music_metadata_example.dart
Future<void> main() async {
  const samplePaths = [
    '/Volumes/Data/Music/动漫原声/Diego Mitre - To the Infinity Castle - Muzan vs Hashira Theme (from Demon Slayer) (Cover).flac',
    '/Volumes/Data/Music/流行音乐/大海 WAV.wav',
    '/Volumes/Data/Music/流行音乐/BEYOND - 长城.flac',
  ];

  final util = SongMetadataUtil();

  for (final path in samplePaths) {
    final metadata = await util.loadFromPath(path);
    _printMetadata(path, metadata);
  }
}

void _printMetadata(String path, SongMetadata metadata) {
  stdout
    ..writeln('File: $path')
    ..writeln('  Title  : ${metadata.title}')
    ..writeln('  Artist : ${metadata.artist}')
    ..writeln('  Album  : ${metadata.album}')
    ..writeln('  Fallback? ${metadata.isFallback}')
    ..writeln('  Extras :');

  if (metadata.extras.isEmpty) {
    stdout.writeln('    (none)');
  } else {
    metadata.extras.forEach((key, value) {
      stdout.writeln('    $key: $value');
    });
  }
  stdout.writeln('');
}
