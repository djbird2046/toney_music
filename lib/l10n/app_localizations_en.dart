// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get macosAppTitle => 'Toney for macOS';

  @override
  String get iosAppTitle => 'Toney iOS';

  @override
  String unsupportedPlatform(Object platform) {
    return 'Unsupported platform: $platform';
  }

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageSimplifiedChinese => 'Simplified Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsAppearanceHeader => 'Appearance';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeDescription => 'Choose light or dark appearance';

  @override
  String get settingsThemeSystemOption => 'Follow system';

  @override
  String get settingsThemeLightOption => 'Light';

  @override
  String get settingsThemeDarkOption => 'Dark';

  @override
  String get settingsAiHeader => 'AI';

  @override
  String get settingsPlaybackHeader => 'Playback';

  @override
  String get settingsLibraryHeader => 'Library';

  @override
  String get settingsBitPerfectTitle => 'Bit-perfect mode';

  @override
  String get settingsBitPerfectSubtitle =>
      'Bypass system DSP for CoreAudio output';

  @override
  String get settingsAutoSampleRateTitle => 'Auto sample-rate switching';

  @override
  String get settingsAutoSampleRateSubtitle =>
      'Follow source file sample rate on device output';

  @override
  String get settingsWatchMusicFolderTitle => 'Watch Music folder';

  @override
  String get settingsWatchMusicFolderSubtitle =>
      'Automatically import new files inside ~/Music';

  @override
  String get settingsEnableAiTaggingTitle => 'Enable AI tagging';

  @override
  String get settingsEnableAiTaggingSubtitle =>
      'Send fingerprints to on-device model';

  @override
  String get settingsLanguageSystemOption => 'Follow system';

  @override
  String get settingsLanguageChineseOption => '简体中文';

  @override
  String get settingsLanguageEnglishOption => 'English';

  @override
  String get settingsLanguageDescription => 'Choose display language';

  @override
  String get settingsLiteAgentChecking => 'Checking availability…';

  @override
  String settingsLiteAgentConnected(Object baseUrl) {
    return 'Connected: $baseUrl';
  }

  @override
  String settingsLiteAgentConnectionFailed(Object message) {
    return 'Connection failed: $message';
  }

  @override
  String get settingsLiteAgentNotConfigured => 'LiteAgent not configured';

  @override
  String get settingsLiteAgentLogout => 'Sign out';

  @override
  String get settingsLiteAgentTitle => 'LiteAgent';

  @override
  String get settingsLiteAgentConfigure => 'Configure';

  @override
  String get liteAgentConnectPrompt => 'Enter your credentials to connect.';

  @override
  String get liteAgentBaseUrl => 'BaseUrl';

  @override
  String get liteAgentApiKey => 'ApiKey';

  @override
  String get commonTest => 'Test';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get settingsBitPerfectUnavailableTitle =>
      'Bit-perfect mode unavailable';

  @override
  String get settingsBitPerfectUnavailableMessage =>
      'Unable to update bit-perfect mode right now. Please try again later.';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonError => 'Error';

  @override
  String get sidebarAppName => 'Toney';

  @override
  String get sidebarMusicAi => 'Music AI';

  @override
  String get sidebarFavorites => 'Favorites';

  @override
  String get sidebarLibrary => 'Library';

  @override
  String get sidebarSettings => 'Settings';

  @override
  String get sidebarPlaylists => 'Playlists';

  @override
  String get sidebarRenamePlaylistHint => 'Rename playlist';

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmptySubtitle => 'No tracks have been imported';

  @override
  String libraryTrackCount(Object count) {
    return 'Total $count tracks';
  }

  @override
  String get libraryFilterHint => 'Filter';

  @override
  String get libraryAddSources => 'Add Sources';

  @override
  String get librarySourceSelectorTitle => 'Select Music Source';

  @override
  String get librarySourceSelectorSubtitle =>
      'Click a card to select source, or add a new remote mount';

  @override
  String get libraryRemoteMounts => 'Remote Mounts';

  @override
  String get libraryContextAddToPlaylist => 'Add to Playlist';

  @override
  String get libraryContextDetails => 'Details';

  @override
  String librarySourceSummaryCount(Object count) {
    return '$count tracks';
  }

  @override
  String get libraryStopImport => 'Stop';

  @override
  String get libraryEmptyPrimary =>
      'Import audio from local disks, cloud drives, Samba, WebDAV, or NFS.';

  @override
  String get libraryEmptySecondary =>
      'Drag folders in and Toney will recurse to pick playable files only.';

  @override
  String get librarySourceLocal => 'Local';

  @override
  String get libraryLocalDescription => 'Local disks or external drives';

  @override
  String get librarySourceSamba => 'Samba';

  @override
  String get librarySourceWebdav => 'WebDAV';

  @override
  String get librarySourceFtp => 'FTP';

  @override
  String get librarySourceSftp => 'SFTP';

  @override
  String get libraryAddRemoteMount => 'Add Remote Mount';

  @override
  String get libraryRemoteConfigAddTitle => 'Add Remote Mount';

  @override
  String get libraryRemoteConfigEditTitle => 'Edit Remote Mount';

  @override
  String get libraryRemoteConfigProtocolLabel => 'Protocol Type';

  @override
  String get libraryRemoteConfigMountNameLabel => 'Mount Name';

  @override
  String get libraryRemoteConfigMountNameHint => 'e.g., My Samba Server';

  @override
  String get libraryRemoteConfigMountNameEmpty => 'Please enter mount name';

  @override
  String get libraryRemoteConfigHostLabel => 'Host Address';

  @override
  String get libraryRemoteConfigHostHint => 'IP address or domain';

  @override
  String get libraryRemoteConfigHostEmpty => 'Please enter host address';

  @override
  String get libraryRemoteConfigPortLabel => 'Port';

  @override
  String get libraryRemoteConfigPortEmpty => 'Please enter port';

  @override
  String get libraryRemoteConfigPortInvalid => 'Invalid port';

  @override
  String get libraryRemoteConfigUsernameLabel => 'Username (optional)';

  @override
  String get libraryRemoteConfigUsernameHint => 'Leave empty for default user';

  @override
  String get libraryRemoteConfigPasswordLabel => 'Password (optional)';

  @override
  String get libraryRemoteConfigRemotePathLabel => 'Remote Path (optional)';

  @override
  String get libraryRemoteConfigRemotePathHint => 'e.g., /share/music';

  @override
  String get libraryRemoteConfigTestButton => 'Test Connection';

  @override
  String get libraryRemoteConfigTesting => 'Testing...';

  @override
  String get libraryRemoteConfigSaveButton => 'Save';

  @override
  String get libraryRemoteConfigSaving => 'Saving...';

  @override
  String get libraryRemoteConfigTestSuccess => 'Connection test successful!';

  @override
  String get libraryRemoteConfigTestFailure =>
      'Connection test failed, please check configuration';

  @override
  String libraryRemoteConfigTestError(Object message) {
    return 'Connection failed: $message';
  }

  @override
  String get libraryRemoteConfigSaveFailedTitle => 'Save Failed';

  @override
  String libraryRemoteConfigSaveFailedMessage(Object message) {
    return 'Unable to save configuration: $message';
  }

  @override
  String get libraryProtocolSambaDescription => 'Windows network file sharing';

  @override
  String get libraryProtocolWebdavDescription => 'HTTP-based file sharing';

  @override
  String get libraryProtocolFtpDescription => 'Traditional file transfer';

  @override
  String get libraryProtocolSftpDescription => 'Secure file transfer';

  @override
  String get libraryUnknownArtist => '--';

  @override
  String get libraryUnknownAlbum => '--';

  @override
  String get libraryUnknownValue => '--';

  @override
  String get nowPlayingNotPlaying => 'Not playing';

  @override
  String get nowPlayingCollapse => 'Collapse';

  @override
  String get nowPlayingStoryButton => 'Music Story';

  @override
  String get nowPlayingStoryPlaceholder => '--';

  @override
  String get miniPlayerEmptyTitle => '--';

  @override
  String get miniPlayerEmptySubtitle => '--';

  @override
  String libraryScanningLocations(Object count) {
    return 'Scanning $count location(s)…';
  }

  @override
  String get libraryNoAudioFound => 'No playable audio files found';

  @override
  String get libraryAlreadyImported =>
      'All selected files are already in the library';

  @override
  String libraryImportProgress(Object processed, Object total) {
    return 'Importing $processed / $total';
  }

  @override
  String libraryImportProgressSkipped(Object processed, Object total) {
    return 'Importing $processed / $total (some skipped)';
  }

  @override
  String libraryImportCancelled(Object count) {
    return 'Import cancelled after adding $count tracks';
  }

  @override
  String libraryImportComplete(Object count, Object total) {
    return 'Imported $count / $total tracks';
  }

  @override
  String get libraryStoppingImport => 'Stopping import…';

  @override
  String libraryRemoveTrackTitle(Object title) {
    return 'Remove \"$title\"?';
  }

  @override
  String get libraryRemoveTrackMessage =>
      'This will remove the song from the library list. Files on disk are untouched.';

  @override
  String get libraryConfirmDeleteRemoteTitle => 'Confirm Delete';

  @override
  String libraryConfirmDeleteRemoteMessage(Object name) {
    return 'Are you sure you want to delete remote mount \"$name\"?';
  }

  @override
  String libraryLoadRemoteError(Object message) {
    return 'Failed to load configurations: $message';
  }

  @override
  String libraryDeleteRemoteError(Object message) {
    return 'Failed to delete: $message';
  }

  @override
  String get libraryPickLocalTitle => 'Select Local Files or Folders';

  @override
  String get libraryPickAudioFilesButton => 'Select Audio Files';

  @override
  String get libraryPickFolderButton => 'Select Folder';

  @override
  String get playlistRemoveTitle => 'Remove playlist?';

  @override
  String playlistRemoveMessage(Object name) {
    return 'This will delete the playlist \"$name\".';
  }

  @override
  String get playlistNewName => 'New Playlist';

  @override
  String get fileTypeAudio => 'Audio';

  @override
  String get playbackErrorTitle => 'Unable to play track';

  @override
  String get playbackCopyError => 'Copy error';

  @override
  String get metadataDialogTitle => 'Track Information';

  @override
  String get metadataFieldTitle => 'Title';

  @override
  String get metadataFieldArtist => 'Artist';

  @override
  String get metadataFieldAlbum => 'Album';

  @override
  String get metadataFieldPath => 'Path';

  @override
  String get metadataFieldDuration => 'Duration';

  @override
  String get menuControl => 'Control';

  @override
  String get menuPlayPause => 'Play/Pause';

  @override
  String get menuNext => 'Next';

  @override
  String get menuPrevious => 'Previous';

  @override
  String get menuIncreaseVolume => 'Increase Volume';

  @override
  String get menuDecreaseVolume => 'Decrease Volume';

  @override
  String get menuMode => 'Mode';

  @override
  String get menuSequence => 'Sequence';

  @override
  String get menuLoop => 'Loop';

  @override
  String get menuSingle => 'Single';

  @override
  String get menuShuffle => 'Shuffle';

  @override
  String get menuWindow => 'Window';

  @override
  String playlistTrackCount(Object count) {
    return '$count tracks';
  }

  @override
  String get playlistMoveSelectionUp => 'Move selection up';

  @override
  String get playlistMoveSelectionDown => 'Move selection down';

  @override
  String get playlistAddButton => 'Add';

  @override
  String get playlistPlayAll => 'Play All';

  @override
  String get playlistContextPlay => 'Play';

  @override
  String get playlistRemoveTrackTitle => 'Remove track?';

  @override
  String get playlistRemoveTrackMessage =>
      'This song will be removed from the playlist.';

  @override
  String get playlistColumnNumber => 'No.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyState => 'No favorites found';

  @override
  String get favoritesUnknownTitle => 'Unknown Title';

  @override
  String get favoritesUnknownArtist => 'Unknown Artist';

  @override
  String get favoritesUnknownAlbum => 'Unknown Album';

  @override
  String get musicAiChatButton => 'AI Chat';

  @override
  String get musicAiForYouRefreshing => 'Refreshing recommendations...';

  @override
  String musicAiForYouUpdatedAt(Object time) {
    return 'Updated at $time';
  }

  @override
  String get musicAiForYouError => 'Refresh failed, tap to retry';

  @override
  String get musicAiForYouEmpty =>
      'Your For You playlist will appear here after generation.';

  @override
  String musicAiForYouNote(Object note) {
    return 'Why these picks: $note';
  }

  @override
  String get musicAiForYouDetails => 'View details';

  @override
  String get musicAiForYouNoDetails => 'No agent details yet.';

  @override
  String get musicAiRefreshPicks => 'Refresh picks';

  @override
  String get musicAiTabForYou => 'For You';

  @override
  String get musicAiTabChat => 'Tell Me';

  @override
  String get musicAiTabConfig => 'Configure AI';

  @override
  String get musicAiLoading => 'Connecting...';

  @override
  String get musicAiNewSession => 'New Session';

  @override
  String musicAiError(Object message) {
    return 'An error occurred: $message';
  }

  @override
  String get musicAiMessagePlaceholder => 'Type your message...';

  @override
  String get musicAiSessionInitializing => 'Initializing session...';

  @override
  String get musicAiExtendedInfo => 'Extended Information';

  @override
  String get musicAiMessageDetail => 'Detail';

  @override
  String get musicAiMessageDetailTitle => 'Message Details';

  @override
  String get musicAiMessageDetailEmpty =>
      'No diagnostic events for this message';

  @override
  String get iosPlayerTitle => 'iOS Player';

  @override
  String get iosAudioPathPlaceholder => 'Audio file path';

  @override
  String get iosLoadButton => 'Load';

  @override
  String get iosSeekPlaceholder => 'Seek position (ms)';

  @override
  String get iosSeekButton => 'Seek';

  @override
  String iosStatusLabel(Object message) {
    return 'Status: $message';
  }

  @override
  String get iosEnterFilePath => 'Enter a file path first';

  @override
  String get iosEnterValidPosition => 'Enter a valid integer position';

  @override
  String get commonOk => 'OK';
}
