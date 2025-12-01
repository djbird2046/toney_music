// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get macosAppTitle => 'Toney（macOS）';

  @override
  String get iosAppTitle => 'Toney iOS';

  @override
  String unsupportedPlatform(Object platform) {
    return '不支持的平台：$platform';
  }

  @override
  String get languageSystemDefault => '跟随系统';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageEnglish => '英文';

  @override
  String get settingsLanguageLabel => '语言';

  @override
  String get settingsAppearanceHeader => '外观';

  @override
  String get settingsThemeLabel => '主题';

  @override
  String get settingsThemeDescription => '选择 Toney 的明暗模式';

  @override
  String get settingsThemeSystemOption => '跟随系统';

  @override
  String get settingsThemeLightOption => '浅色';

  @override
  String get settingsThemeDarkOption => '深色';

  @override
  String get settingsPlaybackHeader => '播放';

  @override
  String get settingsLibraryHeader => '曲库';

  @override
  String get settingsBitPerfectTitle => '比特完美模式';

  @override
  String get settingsBitPerfectSubtitle => '绕过系统 DSP，直接输出到 CoreAudio';

  @override
  String get settingsAutoSampleRateTitle => '自动切换采样率';

  @override
  String get settingsAutoSampleRateSubtitle => '根据音源文件采样率调整输出';

  @override
  String get settingsWatchMusicFolderTitle => '监听音乐文件夹';

  @override
  String get settingsWatchMusicFolderSubtitle => '自动导入 ~/Music 中的新文件';

  @override
  String get settingsEnableAiTaggingTitle => '启用 AI 标签';

  @override
  String get settingsEnableAiTaggingSubtitle => '将指纹发送给本地模型';

  @override
  String get settingsLanguageSystemOption => '跟随系统';

  @override
  String get settingsLanguageChineseOption => '简体中文';

  @override
  String get settingsLanguageEnglishOption => '英文';

  @override
  String get settingsLanguageDescription => '选择界面语言';

  @override
  String get settingsBitPerfectUnavailableTitle => '无法切换比特完美模式';

  @override
  String get settingsBitPerfectUnavailableMessage => '暂时无法更新比特完美模式，请稍后再试。';

  @override
  String get commonClose => '关闭';

  @override
  String get commonCancel => '取消';

  @override
  String get commonRemove => '移除';

  @override
  String get commonDelete => '删除';

  @override
  String get sidebarAppName => 'Toney';

  @override
  String get sidebarMusicAi => '音乐 AI';

  @override
  String get sidebarFavorites => '收藏';

  @override
  String get sidebarLibrary => '曲库';

  @override
  String get sidebarSettings => '设置';

  @override
  String get sidebarPlaylists => '播放列表';

  @override
  String get sidebarRenamePlaylistHint => '重命名播放列表';

  @override
  String get libraryTitle => '曲库';

  @override
  String get libraryEmptySubtitle => '尚未导入任何曲目';

  @override
  String libraryTrackCount(Object count) {
    return '共 $count 首曲目';
  }

  @override
  String get libraryFilterHint => '筛选';

  @override
  String get libraryAddSources => '添加来源';

  @override
  String get libraryContextAddToPlaylist => '添加到播放列表';

  @override
  String get libraryContextDetails => '详情';

  @override
  String librarySourceSummaryCount(Object count) {
    return '$count 首曲目';
  }

  @override
  String get libraryStopImport => '停止';

  @override
  String get libraryEmptyPrimary => '从本地磁盘、云盘、Samba、WebDAV 或 NFS 导入音频。';

  @override
  String get libraryEmptySecondary => '将文件夹拖入窗口，Toney 会递归筛选可播放的文件。';

  @override
  String get librarySourceLocal => '本地';

  @override
  String get librarySourceSamba => 'Samba';

  @override
  String get librarySourceWebdav => 'WebDAV';

  @override
  String get librarySourceFtp => 'FTP';

  @override
  String get librarySourceSftp => 'SFTP';

  @override
  String get libraryUnknownArtist => '未知艺术家';

  @override
  String get libraryUnknownAlbum => '未知专辑';

  @override
  String get libraryUnknownValue => '未知';

  @override
  String libraryScanningLocations(Object count) {
    return '正在扫描 $count 个位置…';
  }

  @override
  String get libraryNoAudioFound => '没有找到可播放的音频文件';

  @override
  String get libraryAlreadyImported => '选中的文件已全部在曲库中';

  @override
  String libraryImportProgress(Object processed, Object total) {
    return '正在导入 $processed / $total';
  }

  @override
  String libraryImportProgressSkipped(Object processed, Object total) {
    return '正在导入 $processed / $total（部分已跳过）';
  }

  @override
  String libraryImportCancelled(Object count) {
    return '已添加 $count 首曲目后取消导入';
  }

  @override
  String libraryImportComplete(Object count, Object total) {
    return '已导入 $count / $total 首曲目';
  }

  @override
  String get libraryStoppingImport => '正在停止导入…';

  @override
  String libraryRemoveTrackTitle(Object title) {
    return '移除“$title”？';
  }

  @override
  String get libraryRemoveTrackMessage => '此操作只会从曲库列表移除，磁盘上的文件不会被删除。';

  @override
  String get playlistRemoveTitle => '删除播放列表？';

  @override
  String playlistRemoveMessage(Object name) {
    return '此操作将删除播放列表“$name”。';
  }

  @override
  String get playlistNewName => '新的播放列表';

  @override
  String get fileTypeAudio => '音频';

  @override
  String get playbackErrorTitle => '无法播放曲目';

  @override
  String get playbackCopyError => '复制错误';

  @override
  String get metadataDialogTitle => '曲目信息';

  @override
  String get metadataFieldTitle => '标题';

  @override
  String get metadataFieldArtist => '艺术家';

  @override
  String get metadataFieldAlbum => '专辑';

  @override
  String get metadataFieldPath => '路径';

  @override
  String get metadataFieldDuration => '时长';

  @override
  String get menuControl => '控制';

  @override
  String get menuPlayPause => '播放/暂停';

  @override
  String get menuNext => '下一首';

  @override
  String get menuPrevious => '上一首';

  @override
  String get menuIncreaseVolume => '提高音量';

  @override
  String get menuDecreaseVolume => '降低音量';

  @override
  String get menuMode => '播放模式';

  @override
  String get menuSequence => '顺序播放';

  @override
  String get menuLoop => '循环播放';

  @override
  String get menuSingle => '单曲循环';

  @override
  String get menuShuffle => '随机播放';

  @override
  String get menuWindow => '窗口';

  @override
  String playlistTrackCount(Object count) {
    return '$count 首曲目';
  }

  @override
  String get playlistMoveSelectionUp => '上移选中项';

  @override
  String get playlistMoveSelectionDown => '下移选中项';

  @override
  String get playlistAddButton => '添加';

  @override
  String get playlistPlayAll => '全部播放';

  @override
  String get playlistContextPlay => '播放';

  @override
  String get playlistRemoveTrackTitle => '删除曲目？';

  @override
  String get playlistRemoveTrackMessage => '该曲目将从播放列表移除。';

  @override
  String get playlistColumnNumber => '序号';

  @override
  String get favoritesTitle => '收藏';

  @override
  String get favoritesEmptyState => '暂无收藏歌曲';

  @override
  String get favoritesUnknownTitle => '未知标题';

  @override
  String get favoritesUnknownArtist => '未知艺术家';

  @override
  String get favoritesUnknownAlbum => '未知专辑';

  @override
  String get musicAiChatButton => 'AI 对话';

  @override
  String get musicAiTabForYou => '为你推荐';

  @override
  String get musicAiTabChat => '跟我说';

  @override
  String get musicAiTabConfig => '配置 AI';

  @override
  String get musicAiLoading => '正在连接...';

  @override
  String get musicAiNewSession => '新的会话';

  @override
  String musicAiError(Object message) {
    return '发生错误：$message';
  }

  @override
  String get musicAiMessagePlaceholder => '输入你的问题...';

  @override
  String get musicAiSessionInitializing => '正在初始化会话...';

  @override
  String get musicAiExtendedInfo => '扩展信息';

  @override
  String get iosPlayerTitle => 'iOS 播放器';

  @override
  String get iosAudioPathPlaceholder => '音频文件路径';

  @override
  String get iosLoadButton => '加载';

  @override
  String get iosSeekPlaceholder => '跳转位置（毫秒）';

  @override
  String get iosSeekButton => '跳转';

  @override
  String iosStatusLabel(Object message) {
    return '状态：$message';
  }

  @override
  String get iosEnterFilePath => '请先输入文件路径';

  @override
  String get iosEnterValidPosition => '请输入有效的整数位置';

  @override
  String get commonOk => '好的';
}
