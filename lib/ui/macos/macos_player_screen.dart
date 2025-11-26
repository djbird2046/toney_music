import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/audio_controller.dart';
import '../../core/library/library_source.dart';
import '../../core/media/audio_formats.dart';
import '../../core/media/song_metadata.dart';
import '../../core/media/song_metadata_util.dart';
import '../../core/playback/playback_track.dart';
import '../../core/playback/playback_helper.dart';
import '../../core/storage/playlist_storage.dart';
import '../../core/storage/library_storage.dart';
import 'macos_colors.dart';
import 'models/media_models.dart';
import 'models/nav_section.dart';
import 'sidebar/macos_sidebar.dart';
import 'views/ai_daily_view.dart';
import 'views/library_view.dart';
import 'views/source_selector_dialog.dart';
import 'views/playlist_view.dart';
import 'views/settings_view.dart';
import 'widgets/macos_mini_player.dart';

class MacosPlayerScreen extends StatefulWidget {
  const MacosPlayerScreen({super.key, required this.controller});

  final AudioController controller;

  @override
  State<MacosPlayerScreen> createState() => _MacosPlayerScreenState();
}

class _MacosPlayerScreenState extends State<MacosPlayerScreen> {
  NavSection selectedSection = NavSection.aiDaily;
  final List<String> playlists = ['Default'];
  int selectedPlaylist = 0;
  bool isRenamingPlaylist = false;
  final TextEditingController _playlistNameController = TextEditingController(
    text: 'Default',
  );
  final SongMetadataUtil _metadataUtil = SongMetadataUtil();
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
  int? _nowPlayingIndex;
  int? _selectedLibraryIndex;
  int? _downloadingIndex;
  double? _downloadProgress;

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
    _keyboardFocusNode = FocusNode();
    unawaited(_initializeLibrary());
    _initializePlaylists();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
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
    final entries = _libraryStorage.load();
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
    setState(() {
      _cancelLibraryImport = false;
      _libraryImportState = LibraryImportState(
        isActive: true,
        message: 'Scanning ${request.paths.length} location(s)…',
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
        _libraryImportState = const LibraryImportState(
          isActive: false,
          message: 'No playable audio files found',
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
        _libraryImportState = const LibraryImportState(
          isActive: false,
          message: 'All selected files are already in the library',
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
            artist: 'Unknown Artist',
            album: 'Unknown Album',
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
          bookmark: null,
          importedAt: DateTime.now(),
          remoteInfo: remoteInfo,
        );
        processed++;
        added++;
        newEntries.add(entry);
        setState(() {
          _metadataCache[path] = enriched;
          _libraryTracks.add(trackRow);
          _libraryTrackPaths.add(path);
          _libraryEntries.add(entry);
          _libraryPathIndex[path] = _libraryTracks.length - 1;
          _libraryImportState = LibraryImportState(
            isActive: true,
            message: 'Importing $processed / $total',
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
            message: 'Importing $processed / $total (some skipped)',
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
    setState(() {
      _libraryImportState = LibraryImportState(
        isActive: false,
        message: cancelled
            ? 'Import cancelled after adding $added tracks'
            : 'Imported $added / $total tracks',
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
    setState(() {
      _cancelLibraryImport = true;
      _libraryImportState = LibraryImportState(
        isActive: true,
        message: 'Stopping import…',
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: Text(
          'Remove "${track.title}"?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove the song from the library list. Files on disk are untouched.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
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
      bookmark: null,
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
      if (reference.metadata != null) {
        metadata = reference.metadata!;
      } else {
        metadata = await _metadataUtil.loadFromPath(path);
      }
      final enriched = metadata.copyWith(
        extras: {...metadata.extras, 'Path': path},
      );
      _metadataCache[path] = enriched;
      entries.add(
        PlaylistEntry(
          path: path,
          metadata: enriched,
          bookmark: reference.bookmark,
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
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: MacosColors.menuBackground,
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Text('Remove', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    );
    if (!mounted) return;
    if (result == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: MacosColors.menuBackground,
          title: const Text(
            'Remove playlist?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will delete the playlist "${playlists[index]}".',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
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
    _submitPlaylistRename();
    setState(() {
      playlists.insert(0, 'New Playlist');
      _playlistEntries['New Playlist'] = <PlaylistEntry>[];
      selectedSection = NavSection.playlists;
      selectedPlaylist = 0;
      isRenamingPlaylist = true;
      _selectedPlaylistRows = <int>{};
      _playlistNameController
        ..text = playlists[0]
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: playlists[0].length,
        );
    });
    _schedulePersist();
  }

  void _seedDefaultPlaylist() {
    final defaultName = playlists.first;
    final entries = tracks
        .map(
          (track) => PlaylistEntry(
            path: track.path,
            metadata: SongMetadata(
              title: track.title,
              artist: track.artist,
              album: 'Unknown Album',
              extras: {'Path': track.path, 'Duration': track.duration},
            ),
            bookmark: null,
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
    final files = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Audio',
          extensions: [
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
      Uint8List? bookmark;
      try {
        bookmark = await widget.controller.createBookmark(path);
      } catch (_) {
        bookmark = null;
      }
      final metadata = await _metadataUtil.loadFromPath(path);
      final enriched = metadata.copyWith(
        extras: {...metadata.extras, 'Path': path},
      );
      _metadataCache[path] = enriched;
      metadataList.add(
        PlaylistEntry(path: path, metadata: enriched, bookmark: bookmark),
      );
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
                  bookmark: entry.bookmark,
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
            bookmark: entry.bookmark,
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
          bookmark: entry.bookmark,
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
        
        // Load and play using cache path
        await widget.controller.load(playableFile.path, bookmark: playableFile.bookmark);
        await widget.controller.play();
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
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text(
          'Unable to play track',
          style: TextStyle(color: Colors.white),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SelectableText(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
            },
            child: const Text('Copy error'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
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
      case NavSection.aiDaily:
        return MacosAiDailyView(categories: aiCategories);
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
        return const MacosSettingsView();
    }
  }

  void _showMetadataDialog(SongMetadata metadata) {
    final entries = <MapEntry<String, String>>[
      MapEntry('Title', metadata.title),
      MapEntry('Artist', metadata.artist),
      MapEntry('Album', metadata.album),
      MapEntry('Path', metadata.extras['Path'] ?? 'Unknown'),
      ...metadata.extras.entries.where(
        (entry) =>
            entry.key != 'Id' && entry.key != 'Picture' && entry.key != 'Path',
      ),
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text(
          'Track Information',
          style: TextStyle(color: Colors.white),
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
                          entry.key,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        final metaPressed = HardwareKeyboard.instance.isMetaPressed;
        if (metaPressed != _isMetaPressed) {
          setState(() => _isMetaPressed = metaPressed);
        }
      },
      child: Scaffold(
        backgroundColor: MacosColors.background,
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
                  const VerticalDivider(width: 1, color: MacosColors.divider),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
            const Divider(height: 1, color: MacosColors.divider),
            MacosMiniPlayer(controller: widget.controller),
          ],
        ),
      ),
    );
  }
}
