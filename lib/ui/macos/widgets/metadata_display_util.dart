bool isUnknownMetadataValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return true;
  final lower = normalized.toLowerCase();
  if (lower == 'unknown' || lower.startsWith('unknown ')) return true;
  const zhUnknowns = {'未知', '未知艺术家', '未知歌手', '未知专辑', '未知專輯', '未知艺人'};
  if (zhUnknowns.contains(normalized)) return true;
  return false;
}

String displayMetadataValue(String? value, String placeholder) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty || isUnknownMetadataValue(normalized)) {
    return placeholder;
  }
  return normalized;
}
