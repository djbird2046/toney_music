import 'package:path/path.dart' as p;

const Set<String> kPlayableAudioExtensions = {
  'flac',
  'wav',
  'wave',
  'aiff',
  'aif',
  'mp3',
  'aac',
  'm4a',
  'dsf',
  'dff',
  'ape',
  'alac',
  'ogg',
  'oga',
};

bool isPlayableAudioPath(String path) {
  final extension = p.extension(path).replaceAll('.', '').toLowerCase();
  if (extension.isEmpty) return false;
  return kPlayableAudioExtensions.contains(extension);
}
