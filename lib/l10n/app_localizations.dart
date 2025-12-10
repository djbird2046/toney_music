import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @macosAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Toney for macOS'**
  String get macosAppTitle;

  /// No description provided for @iosAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Toney iOS'**
  String get iosAppTitle;

  /// No description provided for @unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unsupported platform: {platform}'**
  String unsupportedPlatform(Object platform);

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageSimplifiedChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsAppearanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceHeader;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose light or dark appearance'**
  String get settingsThemeDescription;

  /// No description provided for @settingsThemeSystemOption.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsThemeSystemOption;

  /// No description provided for @settingsThemeLightOption.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLightOption;

  /// No description provided for @settingsThemeDarkOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDarkOption;

  /// No description provided for @settingsAiHeader.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsAiHeader;

  /// No description provided for @settingsPlaybackHeader.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsPlaybackHeader;

  /// No description provided for @settingsLibraryHeader.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibraryHeader;

  /// No description provided for @settingsBitPerfectTitle.
  ///
  /// In en, this message translates to:
  /// **'Bit-perfect mode'**
  String get settingsBitPerfectTitle;

  /// No description provided for @settingsBitPerfectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bypass system DSP for CoreAudio output'**
  String get settingsBitPerfectSubtitle;

  /// No description provided for @settingsAutoSampleRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto sample-rate switching'**
  String get settingsAutoSampleRateTitle;

  /// No description provided for @settingsAutoSampleRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow source file sample rate on device output'**
  String get settingsAutoSampleRateSubtitle;

  /// No description provided for @settingsWatchMusicFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch Music folder'**
  String get settingsWatchMusicFolderTitle;

  /// No description provided for @settingsWatchMusicFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically import new files inside ~/Music'**
  String get settingsWatchMusicFolderSubtitle;

  /// No description provided for @settingsEnableAiTaggingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable AI tagging'**
  String get settingsEnableAiTaggingTitle;

  /// No description provided for @settingsEnableAiTaggingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send fingerprints to on-device model'**
  String get settingsEnableAiTaggingSubtitle;

  /// No description provided for @settingsLanguageSystemOption.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLanguageSystemOption;

  /// No description provided for @settingsLanguageChineseOption.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get settingsLanguageChineseOption;

  /// No description provided for @settingsLanguageEnglishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglishOption;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose display language'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsLiteAgentChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking availability…'**
  String get settingsLiteAgentChecking;

  /// No description provided for @settingsLiteAgentConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected: {baseUrl}'**
  String settingsLiteAgentConnected(Object baseUrl);

  /// No description provided for @settingsLiteAgentConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {message}'**
  String settingsLiteAgentConnectionFailed(Object message);

  /// No description provided for @settingsLiteAgentNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'LiteAgent not configured'**
  String get settingsLiteAgentNotConfigured;

  /// No description provided for @settingsLiteAgentLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLiteAgentLogout;

  /// No description provided for @settingsLiteAgentConfigure.
  ///
  /// In en, this message translates to:
  /// **'LiteAgent'**
  String get settingsLiteAgentConfigure;

  /// No description provided for @liteAgentConnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to connect.'**
  String get liteAgentConnectPrompt;

  /// No description provided for @liteAgentBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'BaseUrl'**
  String get liteAgentBaseUrl;

  /// No description provided for @liteAgentApiKey.
  ///
  /// In en, this message translates to:
  /// **'ApiKey'**
  String get liteAgentApiKey;

  /// No description provided for @commonTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get commonTest;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @settingsBitPerfectUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Bit-perfect mode unavailable'**
  String get settingsBitPerfectUnavailableTitle;

  /// No description provided for @settingsBitPerfectUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to update bit-perfect mode right now. Please try again later.'**
  String get settingsBitPerfectUnavailableMessage;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @sidebarAppName.
  ///
  /// In en, this message translates to:
  /// **'Toney'**
  String get sidebarAppName;

  /// No description provided for @sidebarMusicAi.
  ///
  /// In en, this message translates to:
  /// **'Music AI'**
  String get sidebarMusicAi;

  /// No description provided for @sidebarFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get sidebarFavorites;

  /// No description provided for @sidebarLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get sidebarLibrary;

  /// No description provided for @sidebarSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sidebarSettings;

  /// No description provided for @sidebarPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get sidebarPlaylists;

  /// No description provided for @sidebarRenamePlaylistHint.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get sidebarRenamePlaylistHint;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No tracks have been imported'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryTrackCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} tracks'**
  String libraryTrackCount(Object count);

  /// No description provided for @libraryFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get libraryFilterHint;

  /// No description provided for @libraryAddSources.
  ///
  /// In en, this message translates to:
  /// **'Add Sources'**
  String get libraryAddSources;

  /// No description provided for @librarySourceSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Music Source'**
  String get librarySourceSelectorTitle;

  /// No description provided for @librarySourceSelectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Click a card to select source, or add a new remote mount'**
  String get librarySourceSelectorSubtitle;

  /// No description provided for @libraryRemoteMounts.
  ///
  /// In en, this message translates to:
  /// **'Remote Mounts'**
  String get libraryRemoteMounts;

  /// No description provided for @libraryContextAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get libraryContextAddToPlaylist;

  /// No description provided for @libraryContextDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get libraryContextDetails;

  /// No description provided for @librarySourceSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String librarySourceSummaryCount(Object count);

  /// No description provided for @libraryStopImport.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get libraryStopImport;

  /// No description provided for @libraryEmptyPrimary.
  ///
  /// In en, this message translates to:
  /// **'Import audio from local disks, cloud drives, Samba, WebDAV, or NFS.'**
  String get libraryEmptyPrimary;

  /// No description provided for @libraryEmptySecondary.
  ///
  /// In en, this message translates to:
  /// **'Drag folders in and Toney will recurse to pick playable files only.'**
  String get libraryEmptySecondary;

  /// No description provided for @librarySourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get librarySourceLocal;

  /// No description provided for @libraryLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Local disks or external drives'**
  String get libraryLocalDescription;

  /// No description provided for @librarySourceSamba.
  ///
  /// In en, this message translates to:
  /// **'Samba'**
  String get librarySourceSamba;

  /// No description provided for @librarySourceWebdav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get librarySourceWebdav;

  /// No description provided for @librarySourceFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get librarySourceFtp;

  /// No description provided for @librarySourceSftp.
  ///
  /// In en, this message translates to:
  /// **'SFTP'**
  String get librarySourceSftp;

  /// No description provided for @libraryAddRemoteMount.
  ///
  /// In en, this message translates to:
  /// **'Add Remote Mount'**
  String get libraryAddRemoteMount;

  /// No description provided for @libraryRemoteConfigAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Remote Mount'**
  String get libraryRemoteConfigAddTitle;

  /// No description provided for @libraryRemoteConfigEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Remote Mount'**
  String get libraryRemoteConfigEditTitle;

  /// No description provided for @libraryRemoteConfigProtocolLabel.
  ///
  /// In en, this message translates to:
  /// **'Protocol Type'**
  String get libraryRemoteConfigProtocolLabel;

  /// No description provided for @libraryRemoteConfigMountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mount Name'**
  String get libraryRemoteConfigMountNameLabel;

  /// No description provided for @libraryRemoteConfigMountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Samba Server'**
  String get libraryRemoteConfigMountNameHint;

  /// No description provided for @libraryRemoteConfigMountNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter mount name'**
  String get libraryRemoteConfigMountNameEmpty;

  /// No description provided for @libraryRemoteConfigHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host Address'**
  String get libraryRemoteConfigHostLabel;

  /// No description provided for @libraryRemoteConfigHostHint.
  ///
  /// In en, this message translates to:
  /// **'IP address or domain'**
  String get libraryRemoteConfigHostHint;

  /// No description provided for @libraryRemoteConfigHostEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter host address'**
  String get libraryRemoteConfigHostEmpty;

  /// No description provided for @libraryRemoteConfigPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get libraryRemoteConfigPortLabel;

  /// No description provided for @libraryRemoteConfigPortEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter port'**
  String get libraryRemoteConfigPortEmpty;

  /// No description provided for @libraryRemoteConfigPortInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid port'**
  String get libraryRemoteConfigPortInvalid;

  /// No description provided for @libraryRemoteConfigUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get libraryRemoteConfigUsernameLabel;

  /// No description provided for @libraryRemoteConfigUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for default user'**
  String get libraryRemoteConfigUsernameHint;

  /// No description provided for @libraryRemoteConfigPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get libraryRemoteConfigPasswordLabel;

  /// No description provided for @libraryRemoteConfigRemotePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote Path (optional)'**
  String get libraryRemoteConfigRemotePathLabel;

  /// No description provided for @libraryRemoteConfigRemotePathHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., /share/music'**
  String get libraryRemoteConfigRemotePathHint;

  /// No description provided for @libraryRemoteConfigTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get libraryRemoteConfigTestButton;

  /// No description provided for @libraryRemoteConfigTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get libraryRemoteConfigTesting;

  /// No description provided for @libraryRemoteConfigSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get libraryRemoteConfigSaveButton;

  /// No description provided for @libraryRemoteConfigSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get libraryRemoteConfigSaving;

  /// No description provided for @libraryRemoteConfigTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection test successful!'**
  String get libraryRemoteConfigTestSuccess;

  /// No description provided for @libraryRemoteConfigTestFailure.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed, please check configuration'**
  String get libraryRemoteConfigTestFailure;

  /// No description provided for @libraryRemoteConfigTestError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {message}'**
  String libraryRemoteConfigTestError(Object message);

  /// No description provided for @libraryRemoteConfigSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get libraryRemoteConfigSaveFailedTitle;

  /// No description provided for @libraryRemoteConfigSaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to save configuration: {message}'**
  String libraryRemoteConfigSaveFailedMessage(Object message);

  /// No description provided for @libraryProtocolSambaDescription.
  ///
  /// In en, this message translates to:
  /// **'Windows network file sharing'**
  String get libraryProtocolSambaDescription;

  /// No description provided for @libraryProtocolWebdavDescription.
  ///
  /// In en, this message translates to:
  /// **'HTTP-based file sharing'**
  String get libraryProtocolWebdavDescription;

  /// No description provided for @libraryProtocolFtpDescription.
  ///
  /// In en, this message translates to:
  /// **'Traditional file transfer'**
  String get libraryProtocolFtpDescription;

  /// No description provided for @libraryProtocolSftpDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure file transfer'**
  String get libraryProtocolSftpDescription;

  /// No description provided for @libraryUnknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get libraryUnknownArtist;

  /// No description provided for @libraryUnknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get libraryUnknownAlbum;

  /// No description provided for @libraryUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get libraryUnknownValue;

  /// No description provided for @nowPlayingNotPlaying.
  ///
  /// In en, this message translates to:
  /// **'Not playing'**
  String get nowPlayingNotPlaying;

  /// No description provided for @nowPlayingCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get nowPlayingCollapse;

  /// No description provided for @nowPlayingStoryButton.
  ///
  /// In en, this message translates to:
  /// **'Music Story'**
  String get nowPlayingStoryButton;

  /// No description provided for @nowPlayingStoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No story yet'**
  String get nowPlayingStoryPlaceholder;

  /// No description provided for @libraryScanningLocations.
  ///
  /// In en, this message translates to:
  /// **'Scanning {count} location(s)…'**
  String libraryScanningLocations(Object count);

  /// No description provided for @libraryNoAudioFound.
  ///
  /// In en, this message translates to:
  /// **'No playable audio files found'**
  String get libraryNoAudioFound;

  /// No description provided for @libraryAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'All selected files are already in the library'**
  String get libraryAlreadyImported;

  /// No description provided for @libraryImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {processed} / {total}'**
  String libraryImportProgress(Object processed, Object total);

  /// No description provided for @libraryImportProgressSkipped.
  ///
  /// In en, this message translates to:
  /// **'Importing {processed} / {total} (some skipped)'**
  String libraryImportProgressSkipped(Object processed, Object total);

  /// No description provided for @libraryImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled after adding {count} tracks'**
  String libraryImportCancelled(Object count);

  /// No description provided for @libraryImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} / {total} tracks'**
  String libraryImportComplete(Object count, Object total);

  /// No description provided for @libraryStoppingImport.
  ///
  /// In en, this message translates to:
  /// **'Stopping import…'**
  String get libraryStoppingImport;

  /// No description provided for @libraryRemoveTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\"?'**
  String libraryRemoveTrackTitle(Object title);

  /// No description provided for @libraryRemoveTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the song from the library list. Files on disk are untouched.'**
  String get libraryRemoveTrackMessage;

  /// No description provided for @libraryConfirmDeleteRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get libraryConfirmDeleteRemoteTitle;

  /// No description provided for @libraryConfirmDeleteRemoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete remote mount \"{name}\"?'**
  String libraryConfirmDeleteRemoteMessage(Object name);

  /// No description provided for @libraryLoadRemoteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load configurations: {message}'**
  String libraryLoadRemoteError(Object message);

  /// No description provided for @libraryDeleteRemoteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {message}'**
  String libraryDeleteRemoteError(Object message);

  /// No description provided for @libraryPickLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Local Files or Folders'**
  String get libraryPickLocalTitle;

  /// No description provided for @libraryPickAudioFilesButton.
  ///
  /// In en, this message translates to:
  /// **'Select Audio Files'**
  String get libraryPickAudioFilesButton;

  /// No description provided for @libraryPickFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get libraryPickFolderButton;

  /// No description provided for @playlistRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove playlist?'**
  String get playlistRemoveTitle;

  /// No description provided for @playlistRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete the playlist \"{name}\".'**
  String playlistRemoveMessage(Object name);

  /// No description provided for @playlistNewName.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get playlistNewName;

  /// No description provided for @fileTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get fileTypeAudio;

  /// No description provided for @playbackErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to play track'**
  String get playbackErrorTitle;

  /// No description provided for @playbackCopyError.
  ///
  /// In en, this message translates to:
  /// **'Copy error'**
  String get playbackCopyError;

  /// No description provided for @metadataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Information'**
  String get metadataDialogTitle;

  /// No description provided for @metadataFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get metadataFieldTitle;

  /// No description provided for @metadataFieldArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get metadataFieldArtist;

  /// No description provided for @metadataFieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get metadataFieldAlbum;

  /// No description provided for @metadataFieldPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get metadataFieldPath;

  /// No description provided for @metadataFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get metadataFieldDuration;

  /// No description provided for @menuControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get menuControl;

  /// No description provided for @menuPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get menuPlayPause;

  /// No description provided for @menuNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get menuNext;

  /// No description provided for @menuPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get menuPrevious;

  /// No description provided for @menuIncreaseVolume.
  ///
  /// In en, this message translates to:
  /// **'Increase Volume'**
  String get menuIncreaseVolume;

  /// No description provided for @menuDecreaseVolume.
  ///
  /// In en, this message translates to:
  /// **'Decrease Volume'**
  String get menuDecreaseVolume;

  /// No description provided for @menuMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get menuMode;

  /// No description provided for @menuSequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get menuSequence;

  /// No description provided for @menuLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get menuLoop;

  /// No description provided for @menuSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get menuSingle;

  /// No description provided for @menuShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get menuShuffle;

  /// No description provided for @menuWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// No description provided for @playlistTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String playlistTrackCount(Object count);

  /// No description provided for @playlistMoveSelectionUp.
  ///
  /// In en, this message translates to:
  /// **'Move selection up'**
  String get playlistMoveSelectionUp;

  /// No description provided for @playlistMoveSelectionDown.
  ///
  /// In en, this message translates to:
  /// **'Move selection down'**
  String get playlistMoveSelectionDown;

  /// No description provided for @playlistAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get playlistAddButton;

  /// No description provided for @playlistPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playlistPlayAll;

  /// No description provided for @playlistContextPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playlistContextPlay;

  /// No description provided for @playlistRemoveTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove track?'**
  String get playlistRemoveTrackTitle;

  /// No description provided for @playlistRemoveTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'This song will be removed from the playlist.'**
  String get playlistRemoveTrackMessage;

  /// No description provided for @playlistColumnNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get playlistColumnNumber;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No favorites found'**
  String get favoritesEmptyState;

  /// No description provided for @favoritesUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get favoritesUnknownTitle;

  /// No description provided for @favoritesUnknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get favoritesUnknownArtist;

  /// No description provided for @favoritesUnknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get favoritesUnknownAlbum;

  /// No description provided for @musicAiChatButton.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get musicAiChatButton;

  /// No description provided for @musicAiForYouRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing recommendations...'**
  String get musicAiForYouRefreshing;

  /// No description provided for @musicAiForYouUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String musicAiForYouUpdatedAt(Object time);

  /// No description provided for @musicAiForYouError.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed, tap to retry'**
  String get musicAiForYouError;

  /// No description provided for @musicAiForYouEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your For You playlist will appear here after generation.'**
  String get musicAiForYouEmpty;

  /// No description provided for @musicAiForYouNote.
  ///
  /// In en, this message translates to:
  /// **'Why these picks: {note}'**
  String musicAiForYouNote(Object note);

  /// No description provided for @musicAiForYouDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get musicAiForYouDetails;

  /// No description provided for @musicAiForYouNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No agent details yet.'**
  String get musicAiForYouNoDetails;

  /// No description provided for @musicAiRefreshPicks.
  ///
  /// In en, this message translates to:
  /// **'Refresh picks'**
  String get musicAiRefreshPicks;

  /// No description provided for @musicAiTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get musicAiTabForYou;

  /// No description provided for @musicAiTabChat.
  ///
  /// In en, this message translates to:
  /// **'Tell Me'**
  String get musicAiTabChat;

  /// No description provided for @musicAiTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Configure AI'**
  String get musicAiTabConfig;

  /// No description provided for @musicAiLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get musicAiLoading;

  /// No description provided for @musicAiNewSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get musicAiNewSession;

  /// No description provided for @musicAiError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {message}'**
  String musicAiError(Object message);

  /// No description provided for @musicAiMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get musicAiMessagePlaceholder;

  /// No description provided for @musicAiSessionInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing session...'**
  String get musicAiSessionInitializing;

  /// No description provided for @musicAiExtendedInfo.
  ///
  /// In en, this message translates to:
  /// **'Extended Information'**
  String get musicAiExtendedInfo;

  /// No description provided for @musicAiMessageDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get musicAiMessageDetail;

  /// No description provided for @musicAiMessageDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Details'**
  String get musicAiMessageDetailTitle;

  /// No description provided for @musicAiMessageDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic events for this message'**
  String get musicAiMessageDetailEmpty;

  /// No description provided for @iosPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS Player'**
  String get iosPlayerTitle;

  /// No description provided for @iosAudioPathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Audio file path'**
  String get iosAudioPathPlaceholder;

  /// No description provided for @iosLoadButton.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get iosLoadButton;

  /// No description provided for @iosSeekPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Seek position (ms)'**
  String get iosSeekPlaceholder;

  /// No description provided for @iosSeekButton.
  ///
  /// In en, this message translates to:
  /// **'Seek'**
  String get iosSeekButton;

  /// No description provided for @iosStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {message}'**
  String iosStatusLabel(Object message);

  /// No description provided for @iosEnterFilePath.
  ///
  /// In en, this message translates to:
  /// **'Enter a file path first'**
  String get iosEnterFilePath;

  /// No description provided for @iosEnterValidPosition.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid integer position'**
  String get iosEnterValidPosition;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
