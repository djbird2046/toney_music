import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../../core/audio_controller.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/favorites_controller.dart';
import '../../core/library/library_source.dart';
import '../../core/media/audio_formats.dart';
import '../../core/model/playback_mode.dart';
import '../../core/model/song_metadata.dart';
import '../../core/media/song_metadata_util.dart';
import '../../core/model/playback_track.dart';
import '../../core/playback/playback_helper.dart';
import '../../core/storage/playlist_storage.dart';
import '../../core/storage/library_storage.dart';
import '../../core/storage/liteagent_config_storage.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/theme/theme_controller.dart';
import 'macos_colors.dart';
import 'models/media_models.dart';
import 'models/nav_section.dart';
import 'sidebar/macos_sidebar.dart';
import 'views/music_ai_view.dart';
import 'views/library_view.dart';
import 'views/source_selector_dialog.dart';
import 'views/playlist_view.dart';
import 'views/favorites_view.dart';
import 'views/settings_view.dart';
import 'widgets/macos_mini_player.dart';

class MacosPlayerScreen extends StatefulWidget {
  const MacosPlayerScreen({
    super.key,
    required this.controller,
    required this.localeController,
    required this.themeController,
  });

  final AudioController controller;
  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<MacosPlayerScreen> createState() => _MacosPlayerScreenState();
}

class _MacosPlayerScreenState extends State<MacosPlayerScreen> {
  NavSection selectedSection = NavSection.musicAI;
  final List<String> playlists = ['Default'];
  int selectedPlaylist = 0;
  bool isRenamingPlaylist = false;
  final TextEditingController _playlistNameController = TextEditingController(
    text: 'Default',
  );
  late final SongMetadataUtil _metadataUtil;
  final Map<String, SongMetadata> _metadataCache = {};
  final List<TrackRow> _libraryTracks = [];
  final Set<String> _libraryTrackPaths = <String>{};
  final Map<String, int> _libraryPathIndex = {};
  final List<LibraryEntry> _libraryEntries = [];
  final LibraryStorage _libraryStorage = LibraryStorage();
  LibraryImportState _libraryImportState = const LibraryImportState.idle();
  bool _cancelLibraryImport = false;
  final Map<String, List<PlaylistEntry>> _playlistEntries = {'Default': []};
  Set<int> _selectedPlaylistRows = <int>{};
  late final FocusNode _keyboardFocusNode;
  bool _isMetaPressed = false;
  final PlaylistStorage _playlistStorage = PlaylistStorage();
  final LiteAgentConfigStorage _liteAgentConfigStorage =
      LiteAgentConfigStorage();
  int? _nowPlayingIndex;
  int? _selectedLibraryIndex;
  int? _downloadingIndex;
  double? _downloadProgress;
  bool _bitPerfectEnabled = false;
  bool _bitPerfectBusy = false;
  late final FavoritesController _favoritesController;
  late AppLanguage _languagePreference;
  late AppThemePreference _themePreference;

  final tracks = [
    const TrackRow(
      title: 'Midnight Transfer',
      artist: 'Unknown Artist',
      path: '/Volumes/NAS/HiFi/DSD/MidnightTransfer.dsf',
      format: 'DSD',
      sampleRate: '192k',
      bitDepth: '1-bit',
      duration: '7:41',
      aiConfidence: 0.92,
    ),
    const TrackRow(
      title: 'Focus Drift',
      artist: 'Zeno',
      path: '/Music/Focus/FocusDrift.flac',
      format: 'FLAC',
      sampleRate: '96k',
      bitDepth: '24-bit',
      duration: '5:06',
      aiConfidence: 0.88,
    ),
    const TrackRow(
      title: 'Piano Study in Blue',
      artist: 'Studio Capture',
      path: '/Volumes/Local/Piano/Blue.wav',
      format: 'WAV',
      sampleRate: '44.1k',
      bitDepth: '16-bit',
      duration: '4:20',
    ),
  ];

  final aiCategories = const [
    AiCategory(name: 'Focus', tracks: 34),
    AiCategory(name: 'Piano', tracks: 22),
    AiCategory(name: 'Ambient', tracks: 48),
  ];

  @override
  void initState() {
    super.initState();
    _metadataUtil = SongMetadataUtil(
      metadataFetcher: widget.controller.extractMetadata,
    );
    _favoritesController = FavoritesController(
      metadataFetcher: widget.controller.extractMetadata,
    );
    _keyboardFocusNode = FocusNode();
    unawaited(_initializeLibrary());
    _initializePlaylists();
    unawaited(_favoritesController.init());
    unawaited(_liteAgentConfigStorage.init());
    widget.controller.state.addListener(_onPlaybackStateChanged);
    _languagePreference = widget.localeController.currentPreference;
    widget.localeController.preference.addListener(
      _onLanguagePreferenceChanged,
    );
    _themePreference = widget.themeController.currentPreference;
    widget.themeController.preference.addListener(_onThemePreferenceChanged);
  }

  @override
  void dispose() {
    widget.controller.state.removeListener(_onPlaybackStateChanged);
    widget.localeController.preference.removeListener(
      _onLanguagePreferenceChanged,
    );
    widget.themeController.preference.removeListener(_onThemePreferenceChanged);
    _favoritesController.dispose();
    _playlistNameController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onPlaybackStateChanged() {
    final newState = widget.controller.state.value;
    if (newState.currentIndex != _nowPlayingIndex) {
      setState(() {
        _nowPlayingIndex = newState.currentIndex;
      });
    }
  }

  Future<void> _initializePlaylists() async {
    await _playlistStorage.init();
    final snapshot = _playlistStorage.load();
    if (!mounted) return;
    if (snapshot.isEmpty) {
      _seedDefaultPlaylist();
      await _persistPlaylists();
      return;
    }
    final loadedNames = snapshot.names.isEmpty ? ['Default'] : snapshot.names;
    final hydrated = <String, List<PlaylistEntry>>{};
    for (final name in loadedNames) {
      final references = snapshot.entries[name] ?? const <PlaylistReference>[];
      hydrated[name] = await _hydratePlaylist(references);
    }
    if (!mounted) return;
    setState(() {
      playlists
        ..clear()
        ..addAll(loadedNames);
      _playlistEntries
        ..clear()
        ..addAll(hydrated);
      selectedPlaylist = 0;
    });
  }

  Future<void> _initializeLibrary() async {
    await _libraryStorage.init();
    final entries = _libraryStorage.load()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
    if (!mounted) return;
    setState(() {
      _libraryEntries
        ..clear()
        ..addAll(entries);
      _libraryTracks
        ..clear()
        ..addAll(
          entries.map(
            (entry) => _buildLibraryTrackRow(
              entry.metadata,
              entry.path,
              entry.sourceType,
            ),
          ),
        );
      _libraryTrackPaths
        ..clear()
        ..addAll(entries.map((entry) => entry.path));
      for (final entry in entries) {
        _metadataCache[entry.path] = entry.metadata;
      }
      _rebuildLibraryIndexCache();
    });
  }

  Future<void> _handleAddLibrarySource() async {
    if (_libraryImportState.isActive) return;
    final request = await showSourceSelectorDialog(context);
    if (!mounted || request == null || request.paths.isEmpty) {
      return;
    }
    unawaited(_importLibrarySources(request));
  }

  Future<void> _importLibrarySources(LibrarySourceRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _cancelLibraryImport = false;
      _libraryImportState = LibraryImportState(
        isActive: true,
        message: l10n.libraryScanningLocations(request.paths.length),
        progress: null,
        canCancel: true,
      );
    });

    // For remote files, use paths directly; for local files, need recursive scan
    List<String> files;
    if (request.type == LibrarySourceType.local) {
      files = await _collectAudioFiles(request.paths);
    } else {
      // Remote files: use path list directly, RemoteFileBrowserDialog only returns audio files
      files = request.paths;
    }

    if (!mounted) return;
    if (_cancelLibraryImport) {
      _finishLibraryImport(cancelled: true, added: 0, total: files.length);
      return;
    }
    if (files.isEmpty) {
      setState(() {
        _libraryImportState = LibraryImportState(
          isActive: false,
          message: l10n.libraryNoAudioFound,
          progress: null,
          canCancel: false,
        );
      });
      return;
    }

    final newFiles = files
        .where((path) => !_libraryTrackPaths.contains(path))
        .toList();
    if (newFiles.isEmpty) {
      setState(() {
        _libraryImportState = LibraryImportState(
          isActive: false,
          message: l10n.libraryAlreadyImported,
          progress: null,
          canCancel: false,
        );
      });
      return;
    }

    var processed = 0;
    var added = 0;
    final total = newFiles.length;
    final newEntries = <LibraryEntry>[];

    for (final path in newFiles) {
      if (_cancelLibraryImport || !mounted) {
        break;
      }
      try {
        // Select metadata extraction method based on source type
        SongMetadata metadata;
        if (request.type == LibrarySourceType.local) {
          // Local file: extract metadata directly
          metadata = await _metadataUtil.loadFromPath(path);
        } else {
          // Remote file: generate basic metadata from filename (avoid download during import)
          final fileName = path.split('/').last;
          final titleWithoutExt = fileName.lastIndexOf('.') != -1
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          metadata = SongMetadata(
            title: titleWithoutExt,
            artist: l10n.libraryUnknownArtist,
            album: l10n.libraryUnknownAlbum,
            extras: {'Path': path, 'isRemote': 'true'},
          );
        }

        if (!mounted || _cancelLibraryImport) break;
        final enriched = metadata.copyWith(
          extras: {...metadata.extras, 'Path': path},
        );
        final trackRow = _buildLibraryTrackRow(enriched, path, request.type);

        // Create remote file info (if remote source)
        RemoteFileInfo? remoteInfo;
        if (request.type != LibrarySourceType.local &&
            request.connectionConfigId != null) {
          remoteInfo = RemoteFileInfo(
            configId: request.connectionConfigId!,
            remotePath: path,
          );
        }

        final entry = LibraryEntry(
          path: path,
          sourceType: request.type,
          metadata: enriched,
          importedAt: DateTime.now(),
          remoteInfo: remoteInfo,
        );
        processed++;
        added++;
        newEntries.add(entry);
        setState(() {
          _metadataCache[path] = enriched;
          _libraryTracks.insert(0, trackRow);
          _libraryEntries.insert(0, entry);
          _libraryTrackPaths.add(path);
          _libraryPathIndex
            ..updateAll((key, value) => value + 1)
            ..[path] = 0;
          if (_selectedLibraryIndex != null) {
            _selectedLibraryIndex = _selectedLibraryIndex! + 1;
          }
          _libraryImportState = LibraryImportState(
            isActive: true,
            message: l10n.libraryImportProgress(processed, total),
            progress: total == 0 ? null : processed / total,
            canCancel: true,
          );
        });
      } catch (error, stackTrace) {
        processed++;
        debugPrint('Failed to import $path: $error\n$stackTrace');
        if (!mounted) break;
        setState(() {
          _libraryImportState = LibraryImportState(
            isActive: true,
            message: l10n.libraryImportProgressSkipped(processed, total),
            progress: total == 0 ? null : processed / total,
            canCancel: true,
          );
        });
      }
    }

    if (newEntries.isNotEmpty) {
      await _libraryStorage.save(_libraryEntries);
    }

    final cancelled = _cancelLibraryImport;
    _finishLibraryImport(cancelled: cancelled, added: added, total: total);
  }

  void _finishLibraryImport({
    required bool cancelled,
    required int added,
    required int total,
  }) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _libraryImportState = LibraryImportState(
        isActive: false,
        message: cancelled
            ? l10n.libraryImportCancelled(added)
            : l10n.libraryImportComplete(added, total),
        progress: cancelled ? null : 1.0,
        canCancel: false,
      );
      _cancelLibraryImport = false;
      _rebuildLibraryIndexCache();
    });
  }

  Future<List<String>> _collectAudioFiles(List<String> roots) async {
    final results = <String>{};
    for (final root in roots) {
      if (_cancelLibraryImport) break;
      try {
        final type = await FileSystemEntity.type(root, followLinks: false);
        if (type == FileSystemEntityType.notFound) {
          continue;
        }
        if (type == FileSystemEntityType.file) {
          if (isPlayableAudioPath(root)) {
            results.add(root);
          }
          continue;
        }
        if (type == FileSystemEntityType.directory) {
          final directory = Directory(root);
          await for (final entity in directory.list(
            recursive: true,
            followLinks: false,
          )) {
            if (_cancelLibraryImport) break;
            if (entity is File && isPlayableAudioPath(entity.path)) {
              results.add(entity.path);
            }
          }
        }
      } catch (error, stackTrace) {
        debugPrint('Skipped path $root: $error\n$stackTrace');
      }
    }
    return results.toList();
  }

  void _cancelLibraryImportProcess() {
    if (!_libraryImportState.isActive) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _cancelLibraryImport = true;
      _libraryImportState = LibraryImportState(
        isActive: true,
        message: l10n.libraryStoppingImport,
        progress: _libraryImportState.progress,
        canCancel: false,
      );
    });
  }

  TrackRow _buildLibraryTrackRow(
    SongMetadata metadata,
    String path,
    LibrarySourceType sourceType,
  ) {
    final extras = metadata.extras;
    String fallback(String key, String alt) {
      final value = extras[key] ?? extras[key.toLowerCase()];
      if (value == null || value.trim().isEmpty) return alt;
      return value.trim();
    }

    return TrackRow(
      title: metadata.title,
      artist: metadata.artist,
      path: path,
      format: _formatLabelFromPath(path),
      sampleRate: fallback('Sample Rate', '--'),
      bitDepth: fallback('Bit Depth', '--'),
      duration: fallback('Duration', '--:--'),
      sourceType: sourceType,
    );
  }

  String _formatLabelFromPath(String path) {
    final extension = p.extension(path).replaceAll('.', '').toUpperCase();
    if (extension.isEmpty) return 'AUDIO';
    return extension;
  }

  Future<void> _confirmDeleteLibraryTrack(TrackRow track) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.libraryRemoveTrackTitle(track.title),
            style: TextStyle(color: colors.heading),
          ),
          content: Text(
            l10n.libraryRemoveTrackMessage,
            style: TextStyle(color: colors.mutedGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.commonRemove,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      await _deleteLibraryTrack(track);
    }
  }

  Future<void> _deleteLibraryTrack(TrackRow track) async {
    final index = _libraryPathIndex[track.path];
    if (index == null || index < 0 || index >= _libraryTracks.length) return;
    setState(() {
      _libraryTracks.removeAt(index);
      _libraryEntries.removeAt(index);
      _libraryTrackPaths.remove(track.path);
      _metadataCache.remove(track.path);
      _rebuildLibraryIndexCache();
    });
    await _libraryStorage.save(_libraryEntries);
  }

  Future<void> _addLibraryTrackToPlaylist(
    TrackRow track,
    String playlistName,
  ) async {
    final metadata =
        _metadataCache[track.path] ??
        SongMetadata.unknown(
          track.title,
        ).copyWith(extras: {'Path': track.path});

    // Get sourceType and remoteInfo from LibraryEntry
    final libraryIndex = _libraryPathIndex[track.path];
    LibrarySourceType? sourceType;
    RemoteFileInfo? remoteInfo;

    if (libraryIndex != null && libraryIndex < _libraryEntries.length) {
      final libraryEntry = _libraryEntries[libraryIndex];
      sourceType = libraryEntry.sourceType;
      remoteInfo = libraryEntry.remoteInfo;
    }

    final entry = PlaylistEntry(
      path: track.path,
      metadata: metadata,
      sourceType: sourceType,
      remoteInfo: remoteInfo,
    );
    _playlistEntries.putIfAbsent(playlistName, () => <PlaylistEntry>[]);
    final updated = List<PlaylistEntry>.from(_playlistEntries[playlistName]!)
      ..add(entry);
    setState(() {
      _playlistEntries[playlistName] = updated;
    });
    _schedulePersist();
  }

  Future<List<PlaylistEntry>> _hydratePlaylist(
    List<PlaylistReference> references,
  ) async {
    final entries = <PlaylistEntry>[];
    for (final reference in references) {
      final path = reference.path;
      SongMetadata metadata;

      bool needsRefresh = false;
      if (reference.metadata != null) {
        metadata = reference.metadata!;
        if (_durationFromMetadata(metadata) == null) {
          needsRefresh = true;
        }
      } else {
        needsRefresh = true;
        metadata = SongMetadata.unknown(path);
      }

      if (needsRefresh) {
        try {
          // If metadata is missing or duration is missing, force reload
          // which now uses native fetcher for duration
          metadata = await _metadataUtil.loadFromPath(path);
        } catch (_) {
          // Keep existing if fetch fails (e.g. file moved)
        }
      }

      final enriched = metadata.copyWith(
        extras: {...metadata.extras, 'Path': path},
      );
      _metadataCache[path] = enriched;
      entries.add(
        PlaylistEntry(
          path: path,
          metadata: enriched,
          sourceType: reference.sourceType,
          remoteInfo: reference.remoteInfo,
        ),
      );
    }
    return entries;
  }

  void _selectNav(NavSection section) {
    if (section != NavSection.playlists) {
      _submitPlaylistRename();
    }
    setState(() {
      selectedSection = section;
      if (section != NavSection.playlists) {
        isRenamingPlaylist = false;
        _selectedPlaylistRows = <int>{};
      }
    });
  }

  void _handlePlaylistTap(int index, {bool allowRename = false}) {
    final isCurrent =
        selectedSection == NavSection.playlists && selectedPlaylist == index;

    if (allowRename && isCurrent && !isRenamingPlaylist) {
      setState(() {
        isRenamingPlaylist = true;
        final name = playlists[index];
        _playlistNameController
          ..text = name
          ..selection = TextSelection.collapsed(offset: name.length);
      });
      return;
    }

    _submitPlaylistRename();
    setState(() {
      selectedSection = NavSection.playlists;
      selectedPlaylist = index;
      isRenamingPlaylist = false;
      _selectedPlaylistRows = <int>{};
    });
    _ensurePlaylistData(playlists[index]);
  }

  void _showPlaylistContextMenu(int index, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: context.macosColors.menuBackground,
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Text(
            l10n.commonRemove,
            style: TextStyle(color: Colors.red.shade400),
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (result == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = dialogContext.macosColors;
          return AlertDialog(
            backgroundColor: colors.menuBackground,
            title: Text(
              l10n.playlistRemoveTitle,
              style: TextStyle(color: colors.heading),
            ),
            content: Text(
              l10n.playlistRemoveMessage(playlists[index]),
              style: TextStyle(color: colors.mutedGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  l10n.commonRemove,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      if (confirm == true) {
        _removePlaylist(index);
      }
    }
  }

  void _removePlaylist(int index) {
    if (playlists.length == 1) return;
    setState(() {
      final removed = playlists.removeAt(index);
      _playlistEntries.remove(removed);
      if (selectedPlaylist >= playlists.length) {
        selectedPlaylist = playlists.length - 1;
      }
      isRenamingPlaylist = false;
      _selectedPlaylistRows = <int>{};
    });
    _schedulePersist();
  }

  void _submitPlaylistRename() {
    if (!isRenamingPlaylist) return;
    setState(() {
      final trimmed = _playlistNameController.text.trim();
      if (trimmed.isNotEmpty) {
        final currentName = playlists[selectedPlaylist];
        playlists[selectedPlaylist] = trimmed;
        _playlistEntries.putIfAbsent(currentName, () => <PlaylistEntry>[]);
        final entries = _playlistEntries.remove(currentName) ?? [];
        _playlistEntries[trimmed] = entries;
      }
      isRenamingPlaylist = false;
    });
    _schedulePersist();
  }

  void _addPlaylist() {
    final l10n = AppLocalizations.of(context)!;
    _submitPlaylistRename();
    setState(() {
      final newName = l10n.playlistNewName;
      playlists.insert(0, newName);
      _playlistEntries[newName] = <PlaylistEntry>[];
      selectedSection = NavSection.playlists;
      selectedPlaylist = 0;
      isRenamingPlaylist = true;
      _selectedPlaylistRows = <int>{};
      _playlistNameController
        ..text = newName
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: newName.length,
        );
    });
    _schedulePersist();
  }

  void _seedDefaultPlaylist() {
    final l10n = AppLocalizations.of(context)!;
    final defaultName = playlists.first;
    final entries = tracks
        .map(
          (track) => PlaylistEntry(
            path: track.path,
            metadata: SongMetadata(
              title: track.title,
              artist: track.artist,
              album: l10n.libraryUnknownAlbum,
              extras: {'Path': track.path, 'Duration': track.duration},
            ),
          ),
        )
        .toList();
    setState(() {
      _playlistEntries[defaultName] = entries;
    });
    _schedulePersist();
  }

  void _ensurePlaylistData(String playlistName) {
    _playlistEntries.putIfAbsent(playlistName, () => <PlaylistEntry>[]);
  }

  String get _currentPlaylistName => playlists[selectedPlaylist];

  List<PlaylistEntry> get _currentPlaylistEntries {
    _ensurePlaylistData(_currentPlaylistName);
    return _playlistEntries[_currentPlaylistName]!;
  }

  void _rebuildLibraryIndexCache() {
    _libraryPathIndex
      ..clear()
      ..addEntries(
        _libraryTracks.asMap().entries.map(
          (entry) => MapEntry(entry.value.path, entry.key),
        ),
      );
  }

  Future<void> _addTracksFromPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: l10n.fileTypeAudio,
          extensions: const [
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
          ],
        ),
      ],
    );
    final paths = files.map((file) => file.path).whereType<String>().toList();
    if (paths.isEmpty) return;
    await _addFilesToCurrentPlaylist(paths);
  }

  Future<void> _addFilesToCurrentPlaylist(List<String> paths) async {
    final metadataList = <PlaylistEntry>[];
    for (final path in paths) {
      final metadata = await _metadataUtil.loadFromPath(path);
      final enriched = metadata.copyWith(
        extras: {...metadata.extras, 'Path': path},
      );
      _metadataCache[path] = enriched;
      metadataList.add(PlaylistEntry(path: path, metadata: enriched));
    }
    if (!mounted) return;
    setState(() {
      final entries = List<PlaylistEntry>.from(_currentPlaylistEntries)
        ..addAll(metadataList);
      _playlistEntries[_currentPlaylistName] = entries;
    });
    _schedulePersist();
  }

  void _handlePlaylistRowTap(int index) {
    if (!_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.requestFocus();
    }
    setState(() {
      if (_isMetaPressed) {
        if (_selectedPlaylistRows.contains(index)) {
          _selectedPlaylistRows = {..._selectedPlaylistRows}..remove(index);
        } else {
          _selectedPlaylistRows = {..._selectedPlaylistRows, index};
        }
      } else {
        _selectedPlaylistRows = {index};
      }
    });
  }

  void _movePlaylistSelectionUp() {
    if (_selectedPlaylistRows.isEmpty) return;
    final sorted = _selectedPlaylistRows.toList()..sort();
    if (sorted.first == 0) return;
    final entries = List<PlaylistEntry>.from(_currentPlaylistEntries);
    for (final index in sorted) {
      final item = entries.removeAt(index);
      entries.insert(index - 1, item);
    }
    setState(() {
      _playlistEntries[_currentPlaylistName] = entries;
      _selectedPlaylistRows = sorted.map((i) => i - 1).toSet();
    });
    _schedulePersist();
  }

  void _movePlaylistSelectionDown() {
    if (_selectedPlaylistRows.isEmpty) return;
    final sorted = _selectedPlaylistRows.toList()..sort();
    final entries = List<PlaylistEntry>.from(_currentPlaylistEntries);
    if (sorted.last >= entries.length - 1) return;
    for (final index in sorted.reversed) {
      final item = entries.removeAt(index);
      entries.insert(index + 1, item);
    }
    setState(() {
      _playlistEntries[_currentPlaylistName] = entries;
      _selectedPlaylistRows = sorted.map((i) => i + 1).toSet();
    });
    _schedulePersist();
  }

  void _deleteTrackAt(int index) {
    final entries = List<PlaylistEntry>.from(_currentPlaylistEntries);
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index);
    setState(() {
      _playlistEntries[_currentPlaylistName] = entries;
      _selectedPlaylistRows = _selectedPlaylistRows
          .where((i) => i != index)
          .map((i) => i > index ? i - 1 : i)
          .toSet();
      if (_nowPlayingIndex != null) {
        if (_nowPlayingIndex == index) {
          _nowPlayingIndex = null;
        } else if (_nowPlayingIndex! > index) {
          _nowPlayingIndex = _nowPlayingIndex! - 1;
        }
      }
    });
    _schedulePersist();
  }

  void _schedulePersist() {
    unawaited(_persistPlaylists());
  }

  Future<void> _persistPlaylists() async {
    final snapshot = PlaylistSnapshot(
      names: List<String>.from(playlists),
      entries: {
        for (final name in playlists)
          name: (_playlistEntries[name] ?? const <PlaylistEntry>[])
              .map(
                (entry) => PlaylistReference(
                  path: entry.path,
                  metadata: entry.metadata,
                  sourceType: entry.sourceType,
                  remoteInfo: entry.remoteInfo,
                ),
              )
              .toList(),
      },
    );
    await _playlistStorage.save(snapshot);
  }

  void _handlePlayTrack(int index) {
    final queue = _currentPlaylistEntries
        .map(
          (entry) => PlaybackTrack(
            path: entry.path,
            metadata: entry.metadata,
            duration: _durationFromMetadata(entry.metadata),
          ),
        )
        .toList();
    widget.controller.setQueue(queue, startIndex: index);
    final previousPlaying = _nowPlayingIndex;
    final previousSelection = Set<int>.from(_selectedPlaylistRows);
    setState(() {
      _nowPlayingIndex = index;
      _selectedPlaylistRows = {index};
    });
    unawaited(
      _playTrackAndHandleErrors(
        index,
        previousPlaying: previousPlaying,
        previousSelection: previousSelection,
        isRemote: _currentPlaylistEntries[index].isRemote,
        remoteInfo: _currentPlaylistEntries[index].remoteInfo,
      ),
    );
  }

  Future<void> _playTrackAndHandleErrors(
    int index, {
    required int? previousPlaying,
    required Set<int> previousSelection,
    bool isRemote = false,
    RemoteFileInfo? remoteInfo,
  }) async {
    try {
      // If remote file, need to preprocess (download cache)
      if (isRemote && remoteInfo != null) {
        // Set downloading state
        setState(() {
          _downloadingIndex = index;
          _downloadProgress = 0.0;
        });

        // Create temporary LibraryEntry for preprocessing
        final entry = _currentPlaylistEntries[index];
        final libraryEntry = LibraryEntry(
          path: entry.path,
          sourceType: entry.sourceType ?? LibrarySourceType.local,
          metadata: entry.metadata,
          importedAt: DateTime.now(),
          remoteInfo: remoteInfo,
        );

        // Use PlaybackHelper to prepare playback file (auto downloads cache)
        final playbackHelper = PlaybackHelper();
        final playableFile = await playbackHelper.prepareForPlayback(
          libraryEntry,
          onDownloadProgress: (received, total) {
            if (!mounted) return;
            setState(() {
              _downloadProgress = total > 0 ? received / total : 0.0;
            });
          },
        );

        // Clear downloading state
        if (mounted) {
          setState(() {
            _downloadingIndex = null;
            _downloadProgress = null;
          });
        }

        // Use playAt with cache path to ensure consistent state update
        await widget.controller.playAt(index, overridePath: playableFile.path);
      } else {
        // Local file, play directly
        await widget.controller.playAt(index);
      }

      _updatePlaylistEntryMissingFlag(index, false);
    } catch (error, stackTrace) {
      debugPrint('Failed to play track at $index: $error\n$stackTrace');
      // Clear downloading state on error
      if (mounted) {
        setState(() {
          _downloadingIndex = null;
          _downloadProgress = null;
        });
      }
      _updatePlaylistEntryMissingFlag(index, true);
      if (!mounted) return;
      setState(() {
        _nowPlayingIndex = previousPlaying;
        _selectedPlaylistRows = previousSelection;
      });
      await _showPlaybackErrorDialog(error);
    }
  }

  void _updatePlaylistEntryMissingFlag(int index, bool isMissing) {
    final playlistName = _currentPlaylistName;
    final entries = List<PlaylistEntry>.from(
      _playlistEntries[playlistName] ?? const <PlaylistEntry>[],
    );
    if (index < 0 || index >= entries.length) return;
    final entry = entries[index];
    final metadata = entry.metadata;
    final extras = Map<String, String>.from(metadata.extras);
    if (isMissing) {
      extras['Missing'] = 'true';
    } else {
      extras.remove('Missing');
    }
    final updated = entry.copyWith(metadata: metadata.copyWith(extras: extras));
    entries[index] = updated;
    setState(() {
      _playlistEntries[playlistName] = entries;
      _metadataCache[entry.path] = updated.metadata;
    });
    _schedulePersist();
  }

  Future<void> _showPlaybackErrorDialog(Object error) async {
    final message = error.toString();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.playbackErrorTitle,
            style: TextStyle(color: colors.heading),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SelectableText(
              message,
              style: TextStyle(color: colors.mutedGrey, fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
              },
              child: Text(l10n.playbackCopyError),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  Duration? _durationFromMetadata(SongMetadata metadata) {
    final extras = metadata.extras;
    Duration? parseNumeric(List<String> keys, Duration Function(int) builder) {
      for (final key in keys) {
        final raw = extras[key];
        if (raw == null) continue;
        final value = int.tryParse(raw.toString().trim());
        if (value != null && value > 0) {
          return builder(value);
        }
      }
      return null;
    }

    Duration? parseClock(String? raw) {
      if (raw == null) return null;
      final parts = raw.split(':').map((p) => int.tryParse(p.trim())).toList();
      if (parts.any((element) => element == null)) return null;
      if (parts.isEmpty) return null;
      int seconds = 0;
      if (parts.length == 1) {
        seconds = parts[0]!;
      } else if (parts.length == 2) {
        seconds = parts[0]! * 60 + parts[1]!;
      } else {
        seconds = parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
      }
      return Duration(seconds: seconds);
    }

    final ms = parseNumeric([
      'duration_ms',
      'DurationMs',
      'DurationMS',
      'TLEN',
    ], (value) => Duration(milliseconds: value));
    if (ms != null) return ms;

    final secs = parseNumeric([
      'duration_seconds',
      'DurationSeconds',
    ], (value) => Duration(seconds: value));
    if (secs != null) return secs;

    return parseClock(extras['Duration'] ?? extras['duration']);
  }

  Widget _buildContent() {
    switch (selectedSection) {
      case NavSection.musicAI:
        return MacosMusicAiView(
          categories: aiCategories,
          configStorage: _liteAgentConfigStorage,
          audioController: widget.controller,
        );
      case NavSection.playlists:
        return MacosPlaylistView(
          playlistName: playlists[selectedPlaylist],
          entries: _currentPlaylistEntries,
          selectedIndices: _selectedPlaylistRows,
          onRowTap: _handlePlaylistRowTap,
          onShowMetadata: _showMetadataDialog,
          onAddTracks: _addTracksFromPicker,
          onDropFiles: _addFilesToCurrentPlaylist,
          onMoveSelectionUp: _movePlaylistSelectionUp,
          onMoveSelectionDown: _movePlaylistSelectionDown,
          onDeleteTrack: _deleteTrackAt,
          playingIndex: _nowPlayingIndex,
          onPlayTrack: _handlePlayTrack,
          downloadingIndex: _downloadingIndex,
          downloadProgress: _downloadProgress,
        );
      case NavSection.favorites:
        return MacosFavoritesView(
          controller: _favoritesController,
          audioController: widget.controller,
        );
      case NavSection.library:
        return MacosLibraryView(
          tracks: _libraryTracks,
          metadataByPath: _metadataCache,
          onShowMetadata: _showMetadataDialog,
          onAddLibrarySource: _handleAddLibrarySource,
          importState: _libraryImportState,
          onCancelImport: _cancelLibraryImportProcess,
          onDeleteTrack: _confirmDeleteLibraryTrack,
          playlists: playlists,
          onAddToPlaylist: _addLibraryTrackToPlaylist,
          selectedIndex: _selectedLibraryIndex,
          onSelectTrack: (index) =>
              setState(() => _selectedLibraryIndex = index),
        );
      case NavSection.settings:
        return MacosSettingsView(
          bitPerfectEnabled: _bitPerfectEnabled,
          bitPerfectBusy: _bitPerfectBusy,
          onToggleBitPerfect: _handleBitPerfectToggle,
          selectedLanguage: _languagePreference,
          onLanguageChanged: _handleLanguagePreferenceChanged,
          selectedTheme: _themePreference,
          onThemeChanged: _handleThemePreferenceChanged,
        );
    }
  }

  void _onLanguagePreferenceChanged() {
    final preference = widget.localeController.currentPreference;
    if (!mounted || preference == _languagePreference) return;
    setState(() {
      _languagePreference = preference;
    });
  }

  void _handleLanguagePreferenceChanged(AppLanguage language) {
    setState(() {
      _languagePreference = language;
    });
    unawaited(widget.localeController.setPreference(language));
  }

  void _onThemePreferenceChanged() {
    final preference = widget.themeController.currentPreference;
    if (!mounted || preference == _themePreference) return;
    setState(() {
      _themePreference = preference;
    });
  }

  void _handleThemePreferenceChanged(AppThemePreference preference) {
    setState(() {
      _themePreference = preference;
    });
    unawaited(widget.themeController.setPreference(preference));
  }

  Future<void> _handleBitPerfectToggle(bool value) async {
    if (_bitPerfectBusy) return;
    final previous = _bitPerfectEnabled;
    setState(() {
      _bitPerfectBusy = true;
    });
    try {
      await widget.controller.setBitPerfectMode(value);
      if (!mounted) return;
      setState(() {
        _bitPerfectEnabled = value;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bitPerfectEnabled = previous;
      });
      _showBitPerfectError(error);
    } finally {
      if (mounted) {
        setState(() {
          _bitPerfectBusy = false;
        });
      }
    }
  }

  void _showBitPerfectError(Object error) {
    final description = error is PlatformException
        ? (error.message?.isNotEmpty == true ? error.message! : error.code)
        : error.toString();
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.settingsBitPerfectUnavailableTitle,
            style: TextStyle(color: colors.heading),
          ),
          content: Text(
            description.isNotEmpty
                ? description
                : l10n.settingsBitPerfectUnavailableMessage,
            style: TextStyle(color: colors.mutedGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  void _showMetadataDialog(SongMetadata metadata) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <MapEntry<String, String>>[
      MapEntry(l10n.metadataFieldTitle, metadata.title),
      MapEntry(l10n.metadataFieldArtist, metadata.artist),
      MapEntry(l10n.metadataFieldAlbum, metadata.album),
      MapEntry(
        l10n.metadataFieldPath,
        metadata.extras['Path'] ?? l10n.libraryUnknownValue,
      ),
      ...metadata.extras.entries.where(
        (entry) =>
            entry.key != 'Id' && entry.key != 'Picture' && entry.key != 'Path',
      ),
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.metadataDialogTitle,
            style: TextStyle(color: colors.heading),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _metadataLabel(entry.key, l10n),
                            style: TextStyle(
                              color: colors.mutedGrey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: colors.heading,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  String _metadataLabel(String key, AppLocalizations l10n) {
    switch (key.toLowerCase()) {
      case 'title':
        return l10n.metadataFieldTitle;
      case 'artist':
        return l10n.metadataFieldArtist;
      case 'album':
        return l10n.metadataFieldAlbum;
      case 'path':
        return l10n.metadataFieldPath;
      case 'duration':
      case 'duration_ms':
      case 'durationms':
      case 'duration_seconds':
        return l10n.metadataFieldDuration;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: l10n.sidebarAppName,
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.about,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.about,
              ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.sidebarSettings,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => _selectNav(NavSection.settings),
                ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: l10n.menuControl,
          menus: [
            PlatformMenuItem(
              label: l10n.menuPlayPause,
              shortcut: const SingleActivator(LogicalKeyboardKey.space),
              onSelected: () => widget.controller.togglePlayPause(),
            ),
            PlatformMenuItem(
              label: l10n.menuNext,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.arrowRight,
                meta: true,
              ),
              onSelected: () => widget.controller.playNext(),
            ),
            PlatformMenuItem(
              label: l10n.menuPrevious,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.arrowLeft,
                meta: true,
              ),
              onSelected: () => widget.controller.playPrevious(),
            ),
            PlatformMenuItem(
              label: l10n.menuIncreaseVolume,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.arrowUp,
                meta: true,
              ),
              onSelected: () async {
                final vol = await widget.controller.getVolume();
                widget.controller.setVolume(vol + 0.05);
              },
            ),
            PlatformMenuItem(
              label: l10n.menuDecreaseVolume,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.arrowDown,
                meta: true,
              ),
              onSelected: () async {
                final vol = await widget.controller.getVolume();
                widget.controller.setVolume(vol - 0.05);
              },
            ),
            PlatformMenu(
              label: l10n.menuMode,
              menus: [
                PlatformMenuItem(
                  label: l10n.menuSequence,
                  onSelected: () =>
                      widget.controller.setPlaybackMode(PlayMode.sequence),
                ),
                PlatformMenuItem(
                  label: l10n.menuLoop,
                  onSelected: () =>
                      widget.controller.setPlaybackMode(PlayMode.loop),
                ),
                PlatformMenuItem(
                  label: l10n.menuSingle,
                  onSelected: () =>
                      widget.controller.setPlaybackMode(PlayMode.single),
                ),
                PlatformMenuItem(
                  label: l10n.menuShuffle,
                  onSelected: () =>
                      widget.controller.setPlaybackMode(PlayMode.shuffle),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: l10n.menuWindow,
          menus: [
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.minimizeWindow,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.minimizeWindow,
              ),
            PlatformMenuItem(
              label: l10n.commonClose,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyW,
                meta: true,
              ),
              onSelected: () => const MethodChannel(
                'window_control',
              ).invokeMethod('minimize'),
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.zoomWindow,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.zoomWindow,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.toggleFullScreen,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
          ],
        ),
      ],
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          final metaPressed = HardwareKeyboard.instance.isMetaPressed;
          if (metaPressed != _isMetaPressed) {
            setState(() => _isMetaPressed = metaPressed);
          }
        },
        child: Scaffold(
          backgroundColor: context.macosColors.background,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    MacosSidebar(
                      selectedSection: selectedSection,
                      onSelectSection: _selectNav,
                      playlists: playlists,
                      selectedPlaylist: selectedPlaylist,
                      onPlaylistTap: _handlePlaylistTap,
                      isRenamingPlaylist: isRenamingPlaylist,
                      renameController: _playlistNameController,
                      onPlaylistRenameSubmit: _submitPlaylistRename,
                      onAddPlaylist: _addPlaylist,
                      onPlaylistContextMenu: _showPlaylistContextMenu,
                    ),
                    VerticalDivider(
                      width: 1,
                      color: context.macosColors.divider,
                    ),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
              Divider(height: 1, color: context.macosColors.divider),
              MacosMiniPlayer(
                controller: widget.controller,
                favoritesController: _favoritesController,
                bitPerfectEnabled: _bitPerfectEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
