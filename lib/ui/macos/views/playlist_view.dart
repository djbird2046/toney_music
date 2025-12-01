import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../../core/model/song_metadata.dart';
import '../macos_colors.dart';
import '../models/media_models.dart';

class MacosPlaylistView extends StatefulWidget {
  const MacosPlaylistView({
    super.key,
    required this.playlistName,
    required this.entries,
    required this.selectedIndices,
    required this.onRowTap,
    required this.onShowMetadata,
    required this.onAddTracks,
    required this.onDropFiles,
    required this.onMoveSelectionUp,
    required this.onMoveSelectionDown,
    required this.onDeleteTrack,
    required this.playingIndex,
    required this.onPlayTrack,
    this.downloadingIndex,
    this.downloadProgress,
  });

  final String playlistName;
  final List<PlaylistEntry> entries;
  final Set<int> selectedIndices;
  final void Function(int index) onRowTap;
  final void Function(SongMetadata metadata) onShowMetadata;
  final VoidCallback onAddTracks;
  final Future<void> Function(List<String> paths) onDropFiles;
  final VoidCallback onMoveSelectionUp;
  final VoidCallback onMoveSelectionDown;
  final void Function(int index) onDeleteTrack;
  final int? playingIndex;
  final void Function(int index) onPlayTrack;
  final int? downloadingIndex;
  final double? downloadProgress;

  @override
  State<MacosPlaylistView> createState() => _MacosPlaylistViewState();
}

class _MacosPlaylistViewState extends State<MacosPlaylistView> {
  bool _isDropping = false;
  int? _hoveredIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.toLowerCase();
    final entries = widget.entries.where((entry) {
      if (query.isEmpty) return true;
      final metadata = entry.metadata;
      return metadata.title.toLowerCase().contains(query) ||
          metadata.artist.toLowerCase().contains(query) ||
          metadata.album.toLowerCase().contains(query);
    }).toList();

    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.playlistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MacosColors.navSelectedBackground.withValues(
                    alpha: 0.25,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MacosColors.aiCardBorder),
                ),
                child: Text(
                  l10n.playlistTrackCount(widget.entries.length),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
              // Search Bar
              Container(
                width: 200,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MacosColors.innerDivider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 16,
                      color: MacosColors.iconGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        cursorColor: MacosColors.accentBlue,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.libraryFilterHint,
                          hintStyle: const TextStyle(
                            color: MacosColors.mutedGrey,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Tooltip(
                message: l10n.playlistMoveSelectionUp,
                child: IconButton(
                  onPressed: widget.onMoveSelectionUp,
                  icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                ),
              ),
              Tooltip(
                message: l10n.playlistMoveSelectionDown,
                child: IconButton(
                  onPressed: widget.onMoveSelectionDown,
                  icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: widget.onAddTracks,
                icon: const Icon(Icons.add),
                label: Text(l10n.playlistAddButton),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: MacosColors.navSelectedBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  if (widget.entries.isNotEmpty) {
                    widget.onPlayTrack(0);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.playlistPlayAll),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: MacosColors.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PlaylistHeader(),
          Expanded(
            child: DropTarget(
              onDragEntered: (_) => setState(() => _isDropping = true),
              onDragExited: (_) => setState(() => _isDropping = false),
              onDragDone: (details) async {
                setState(() => _isDropping = false);
                final paths = details.files
                    .map((file) => file.path)
                    .whereType<String>()
                    .toList();
                if (paths.isEmpty) return;
                await widget.onDropFiles(paths);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDropping
                        ? MacosColors.accentBlue
                        : MacosColors.innerDivider,
                  ),
                  color: _isDropping
                      ? MacosColors.accentHover
                      : Colors.transparent,
                ),
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, _) =>
                      const Divider(color: MacosColors.innerDivider, height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected = widget.selectedIndices.contains(index);
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) {
                        if (_hoveredIndex == index) {
                          setState(() => _hoveredIndex = null);
                        }
                      },
                      child: _PlaylistRow(
                        index: index,
                        entry: entry,
                        isSelected: isSelected,
                        isHovered: _hoveredIndex == index,
                        isPlaying: widget.playingIndex == index,
                        isMissing: entry.metadata.extras['Missing'] == 'true',
                        isDownloading: widget.downloadingIndex == index,
                        downloadProgress: widget.downloadingIndex == index
                            ? widget.downloadProgress
                            : null,
                        onSelect: () => widget.onRowTap(index),
                        onShowMetadata: widget.onShowMetadata,
                        onDelete: () => widget.onDeleteTrack(index),
                        onPlay: () => widget.onPlayTrack(index),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.index,
    required this.entry,
    required this.isSelected,
    required this.isHovered,
    required this.isPlaying,
    required this.isMissing,
    required this.isDownloading,
    this.downloadProgress,
    required this.onSelect,
    required this.onShowMetadata,
    required this.onDelete,
    required this.onPlay,
  });

  final int index;
  final PlaylistEntry entry;
  final bool isSelected;
  final bool isHovered;
  final bool isPlaying;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback onSelect;
  final void Function(SongMetadata metadata) onShowMetadata;
  final VoidCallback onDelete;
  final VoidCallback onPlay;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    final metadata = entry.metadata;
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onPlay,
      onSecondaryTapDown: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          color: MacosColors.menuBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          items: [
            PopupMenuItem<String>(
              value: 'play',
              height: 30,
              child: Text(
                l10n.playlistContextPlay,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const PopupMenuDivider(height: 6),
            PopupMenuItem<String>(
              value: 'detail',
              height: 30,
              child: Text(
                l10n.libraryContextDetails,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const PopupMenuDivider(height: 6),
            PopupMenuItem<String>(
              value: 'delete',
              height: 30,
              textStyle: const TextStyle(color: Colors.redAccent),
              child: Text(
                l10n.commonDelete,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
        if (!context.mounted) return;
        if (result == 'play') {
          onPlay();
        } else if (result == 'detail') {
          onShowMetadata(metadata);
        } else if (result == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: MacosColors.menuBackground,
              title: Text(
                l10n.playlistRemoveTrackTitle,
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(
                l10n.playlistRemoveTrackMessage,
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.commonDelete,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            onDelete();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(),
          border: isPlaying
              ? const Border(
                  left: BorderSide(color: MacosColors.accentBlue, width: 3),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _ArtworkTile(
              bytes: metadata.artwork,
              isDownloading: isDownloading,
              downloadProgress: downloadProgress,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMissing
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metadata.artist,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMissing
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                metadata.album,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMissing
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                metadata.extras['Duration'] ?? '--:--',
                style: TextStyle(
                  color: isMissing
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            if (isPlaying)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.equalizer,
                  color: MacosColors.accentBlue,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _backgroundColor() {
    if (isPlaying) {
      return MacosColors.navSelectedBackground.withValues(alpha: 0.4);
    }
    if (isSelected) {
      return MacosColors.navSelectedBackground.withValues(alpha: 0.3);
    }
    if (isHovered) {
      return MacosColors.accentHover;
    }
    if (isMissing) {
      return null;
    }
    return null;
  }
}

class _ArtworkTile extends StatelessWidget {
  const _ArtworkTile({
    required this.bytes,
    this.isDownloading = false,
    this.downloadProgress,
  });

  final Uint8List? bytes;
  final bool isDownloading;
  final double? downloadProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          // 封面图
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MacosColors.innerDivider),
              color: const Color(0xFF1B1B1B),
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: bytes == null
                ? const Icon(Icons.music_note, color: Colors.white30, size: 20)
                : null,
          ),
          // 下载进度遮罩和圆环
          if (isDownloading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        MacosColors.accentBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              l10n.playlistColumnNumber,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              l10n.metadataFieldTitle,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.metadataFieldAlbum,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              l10n.metadataFieldDuration,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
