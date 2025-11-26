import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../../core/media/song_metadata.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.playlistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
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
                  '${widget.entries.length} tracks',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Move selection up',
                child: IconButton(
                  onPressed: widget.onMoveSelectionUp,
                  icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                ),
              ),
              Tooltip(
                message: 'Move selection down',
                child: IconButton(
                  onPressed: widget.onMoveSelectionDown,
                  icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: widget.onAddTracks,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _PlaylistHeader(),
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
                  itemCount: widget.entries.length,
                  separatorBuilder: (context, _) =>
                      const Divider(color: MacosColors.innerDivider, height: 1),
                  itemBuilder: (context, index) {
                    final entry = widget.entries[index];
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
          items: const [
            PopupMenuItem<String>(
              value: 'play',
              height: 30,
              child: Text('Play', style: TextStyle(color: Colors.white)),
            ),
            PopupMenuDivider(height: 6),
            PopupMenuItem<String>(
              value: 'detail',
              height: 30,
              child: Text('Details', style: TextStyle(color: Colors.white)),
            ),
            PopupMenuDivider(height: 6),
            PopupMenuItem<String>(
              value: 'delete',
              height: 30,
              textStyle: TextStyle(color: Colors.redAccent),
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
              title: const Text(
                'Remove track?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'This song will be removed from the playlist.',
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
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
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
                      color: isMissing ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                      fontWeight: FontWeight.w600,
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
                  ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: const [
          SizedBox(
            width: 36,
            child: Text('No.', style: TextStyle(color: Colors.white54)),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text('Title', style: TextStyle(color: Colors.white54)),
          ),
          Expanded(
            flex: 3,
            child: Text('Album', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
