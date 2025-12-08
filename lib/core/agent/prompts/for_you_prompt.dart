import 'dart:convert';

import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';

import '../dto.dart';

const String _forYouPromptZh = '''
你是 Toney 的智能选曲助手，只能使用我提供的本地曲库 tracks 列表生成 “For You” 推荐，禁止虚构路径或元数据。
目标：根据 moodSignals 和曲库，挑出 limit 条歌曲，贴合当下场景且有多样性，避免同艺人/专辑堆叠。
曲库不够就返回尽可能多的去重曲目，不添加外部歌曲。
只可调用 setForYouPlaylist(tracks:[SongSummaryDto], note:string?) 返回，note 用简短句子解释选择逻辑。
强制要求：tracks 必须是数组，长度至少为 limit（若曲库不足则用全部去重列表），每个元素为 SongSummaryDto；禁止只返回单个字符串或单元素。
如果 tracks 不是数组或长度小于 limit，请纠正后重新调用 setForYouPlaylist；不要提交仅一首歌的结果。
''';

const String _forYouPromptEn = '''
You are Toney’s smart curator. Only use the provided local library “tracks” to build a “For You” playlist—never invent paths or metadata.
Goal: pick exactly “limit” songs that fit the current moodSignals, stay diverse, and avoid stacking the same artist/album.
If the library is too small, return as many unique tracks as possible from it; do not add external songs.
Respond only by calling setForYouPlaylist(tracks:[SongSummaryDto], note:string?) where “note” briefly explains why you chose these tracks.
Requirements: “tracks” must be an array with at least “limit” items (or the full unique library if smaller), each item a SongSummaryDto. Do not return a single string or single-element result.
If “tracks” is not an array or is shorter than “limit”, fix it and call setForYouPlaylist again; never submit just one song.
''';

String systemPromptForLocale(String localeCode) {
  if (localeCode.toLowerCase().startsWith('zh')) return _forYouPromptZh;
  return _forYouPromptEn;
}

UserTask buildForYouTask({
  required MoodSignalsDto moodSignals,
  required LibrarySummaryDto librarySummary,
  List<SongSummaryDto>? favorites,
  List<SongSummaryDto>? recents,
  required int limit,
  required String localeCode,
}) {
  final encoder = const JsonEncoder.withIndent('  ');
  final payload = <String, dynamic>{
    'limit': limit,
    'moodSignals': moodSignals.toJson(),
    'librarySummary': librarySummary.toJson(),
  };
  if (favorites != null && favorites.isNotEmpty) {
    payload['favorites'] = favorites.map((f) => f.toJson()).toList();
  }
  if (recents != null && recents.isNotEmpty) {
    payload['recents'] = recents.map((r) => r.toJson()).toList();
  }

  final message = StringBuffer()
    ..writeln(systemPromptForLocale(localeCode))
    ..writeln('---')
    ..writeln('context:')
    ..writeln(encoder.convert(payload));

  return UserTask(
    content: [Content(type: ContentType.text, message: message.toString())],
    isChunk: true,
  );
}
