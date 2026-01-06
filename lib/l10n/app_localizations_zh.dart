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
  String get settingsThemeDescription => '选择明暗模式';

  @override
  String get settingsThemeSystemOption => '跟随系统';

  @override
  String get settingsThemeLightOption => '浅色';

  @override
  String get settingsThemeDarkOption => '深色';

  @override
  String get settingsAiHeader => 'AI';

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
  String get settingsLiteAgentChecking => '正在检查可用性…';

  @override
  String settingsLiteAgentConnected(Object baseUrl) {
    return '已连接：$baseUrl';
  }

  @override
  String settingsLiteAgentConnectionFailed(Object message) {
    return '连接失败：$message';
  }

  @override
  String get settingsLiteAgentNotConfigured => '未配置 LiteAgent';

  @override
  String get settingsLiteAgentLogout => '退出';

  @override
  String get settingsLiteAgentTitle => 'LiteAgent';

  @override
  String get settingsLiteAgentConfigure => '去配置';

  @override
  String get liteAgentConnectPrompt => '输入凭据以连接。';

  @override
  String get liteAgentBaseUrl => 'BaseUrl';

  @override
  String get liteAgentApiKey => 'ApiKey';

  @override
  String get commonTest => '测试';

  @override
  String get commonConfirm => '确认';

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
  String get commonEdit => '编辑';

  @override
  String get commonError => '错误';

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
  String get librarySourceSelectorTitle => '选择音乐来源';

  @override
  String get librarySourceSelectorSubtitle => '点击卡片选择来源，或添加新的远程挂载';

  @override
  String get libraryRemoteMounts => '远程挂载';

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
  String get libraryLocalDescription => '本地磁盘或外接驱动器';

  @override
  String get librarySourceSamba => 'Samba';

  @override
  String get librarySourceWebdav => 'WebDAV';

  @override
  String get librarySourceFtp => 'FTP';

  @override
  String get librarySourceSftp => 'SFTP';

  @override
  String get libraryAddRemoteMount => '添加远程挂载';

  @override
  String get libraryRemoteConfigAddTitle => '添加远程挂载';

  @override
  String get libraryRemoteConfigEditTitle => '编辑远程挂载';

  @override
  String get libraryRemoteConfigProtocolLabel => '协议类型';

  @override
  String get libraryRemoteConfigMountNameLabel => '挂载名称';

  @override
  String get libraryRemoteConfigMountNameHint => '例如：My Samba Server';

  @override
  String get libraryRemoteConfigMountNameEmpty => '请输入挂载名称';

  @override
  String get libraryRemoteConfigHostLabel => '主机地址';

  @override
  String get libraryRemoteConfigHostHint => 'IP 地址或域名';

  @override
  String get libraryRemoteConfigHostEmpty => '请输入主机地址';

  @override
  String get libraryRemoteConfigPortLabel => '端口';

  @override
  String get libraryRemoteConfigPortEmpty => '请输入端口';

  @override
  String get libraryRemoteConfigPortInvalid => '端口无效';

  @override
  String get libraryRemoteConfigUsernameLabel => '用户名（可选）';

  @override
  String get libraryRemoteConfigUsernameHint => '留空将使用默认用户';

  @override
  String get libraryRemoteConfigPasswordLabel => '密码（可选）';

  @override
  String get libraryRemoteConfigRemotePathLabel => '远程路径（可选）';

  @override
  String get libraryRemoteConfigRemotePathHint => '例如：/share/music';

  @override
  String get libraryRemoteConfigTestButton => '测试连接';

  @override
  String get libraryRemoteConfigTesting => '正在测试…';

  @override
  String get libraryRemoteConfigSaveButton => '保存';

  @override
  String get libraryRemoteConfigSaving => '正在保存…';

  @override
  String get libraryRemoteConfigTestSuccess => '连接测试成功！';

  @override
  String get libraryRemoteConfigTestFailure => '连接测试失败，请检查配置';

  @override
  String libraryRemoteConfigTestError(Object message) {
    return '连接失败：$message';
  }

  @override
  String get libraryRemoteConfigSaveFailedTitle => '保存失败';

  @override
  String libraryRemoteConfigSaveFailedMessage(Object message) {
    return '无法保存配置：$message';
  }

  @override
  String get libraryProtocolSambaDescription => 'Windows 网络文件共享';

  @override
  String get libraryProtocolWebdavDescription => '基于 HTTP 的文件共享';

  @override
  String get libraryProtocolFtpDescription => '传统文件传输';

  @override
  String get libraryProtocolSftpDescription => '安全文件传输';

  @override
  String get libraryUnknownArtist => '--';

  @override
  String get libraryUnknownAlbum => '--';

  @override
  String get libraryUnknownValue => '--';

  @override
  String get nowPlayingNotPlaying => '未在播放';

  @override
  String get nowPlayingCollapse => '收起';

  @override
  String get nowPlayingStoryButton => '音乐故事';

  @override
  String get nowPlayingStoryPlaceholder => '--';

  @override
  String get miniPlayerEmptyTitle => '--';

  @override
  String get miniPlayerEmptySubtitle => '--';

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
  String get libraryConfirmDeleteRemoteTitle => '确认删除';

  @override
  String libraryConfirmDeleteRemoteMessage(Object name) {
    return '确定要删除远程挂载“$name”吗？';
  }

  @override
  String libraryLoadRemoteError(Object message) {
    return '无法加载配置：$message';
  }

  @override
  String libraryDeleteRemoteError(Object message) {
    return '删除失败：$message';
  }

  @override
  String get libraryPickLocalTitle => '选择本地文件或文件夹';

  @override
  String get libraryPickAudioFilesButton => '选择音频文件';

  @override
  String get libraryPickFolderButton => '选择文件夹';

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
  String get musicAiForYouRefreshing => '正在生成推荐...';

  @override
  String musicAiForYouUpdatedAt(Object time) {
    return '更新于 $time';
  }

  @override
  String get musicAiForYouError => '生成失败，点击重试';

  @override
  String get musicAiForYouEmpty => '生成后将在此展示推荐。';

  @override
  String musicAiForYouNote(Object note) {
    return '推荐思路：$note';
  }

  @override
  String get musicAiForYouDetails => '查看详情';

  @override
  String get musicAiForYouNoDetails => '暂无 Agent 详情。';

  @override
  String get musicAiRefreshPicks => '换一批';

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
  String get musicAiMessageDetail => '详情';

  @override
  String get musicAiMessageDetailTitle => '消息详情';

  @override
  String get musicAiMessageDetailEmpty => '该消息没有诊断事件';

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
