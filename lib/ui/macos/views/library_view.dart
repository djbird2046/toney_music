import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/model/song_metadata.dart';
import '../macos_colors.dart';
import '../models/media_models.dart';
import '../../../core/library/library_source.dart';

class MacosLibraryView extends StatelessWidget {
  const MacosLibraryView({
    super.key,
    required this.tracks,
    required this.metadataByPath,
    required this.onShowMetadata,
    required this.onAddLibrarySource,
    required this.importState,
    required this.onCancelImport,
    required this.onDeleteTrack,
    required this.playlists,
    required this.onAddToPlaylist,
    required this.selectedIndex,
    required this.onSelectTrack,
  });

  final List<TrackRow> tracks;
  final Map<String, SongMetadata> metadataByPath;
  final void Function(SongMetadata metadata) onShowMetadata;
  final VoidCallback onAddLibrarySource;
  final LibraryImportState importState;
  final VoidCallback onCancelImport;
  final void Function(TrackRow track) onDeleteTrack;
  final List<String> playlists;
  final void Function(TrackRow track, String playlist) onAddToPlaylist;
  final int? selectedIndex;
  final void Function(int index) onSelectTrack;

  Map<LibrarySourceType, int> _sourceCounts() {
    final counts = <LibrarySourceType, int>{};
    for (final track in tracks) {
      counts.update(track.sourceType, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final sourceCounts = _sourceCounts();
    final isEmpty = tracks.isEmpty;

    return Container(
      color: MacosColors.contentBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(
                        color: MacosColors.heading,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty
                          ? 'No tracks have been imported'
                          : 'Total ${tracks.length} tracks',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: importState.isActive ? null : onAddLibrarySource,
                  icon: const Icon(Icons.library_add),
                  label: const Text('Add Sources'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sourceCounts.isNotEmpty) _SourceSummary(counts: sourceCounts),
            if (sourceCounts.isNotEmpty) const SizedBox(height: 12),
            Expanded(
              child: isEmpty
                  ? const _EmptyLibraryState()
                  : ListView.separated(
                      itemCount: tracks.length,
                      separatorBuilder: (context, _) => const Divider(
                        color: MacosColors.innerDivider,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final metadata =
                            metadataByPath[track.path] ??
                            _fallbackMetadata(track);
                        return TrackRowView(
                          track: track,
                          metadata: metadata,
                          onShowMetadata: onShowMetadata,
                          onDelete: onDeleteTrack,
                          onAddToPlaylist: onAddToPlaylist,
                          playlists: playlists,
                          isSelected: selectedIndex == index,
                          onTap: () => onSelectTrack(index),
                        );
                      },
                    ),
            ),
            if (importState.isActive)
              _ImportStatusBar(state: importState, onCancel: onCancelImport)
            else if (importState.hasStatus)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  importState.message,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TrackRowView extends StatefulWidget {
  const TrackRowView({
    super.key,
    required this.track,
    required this.metadata,
    required this.onShowMetadata,
    required this.onDelete,
    required this.onAddToPlaylist,
    required this.playlists,
    required this.isSelected,
    required this.onTap,
  });

  final TrackRow track;
  final SongMetadata metadata;
  final void Function(SongMetadata metadata) onShowMetadata;
  final void Function(TrackRow track) onDelete;
  final void Function(TrackRow track, String playlist) onAddToPlaylist;
  final List<String> playlists;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TrackRowView> createState() => _TrackRowViewState();
}

class _TrackRowViewState extends State<TrackRowView> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final menuTheme = Theme.of(context).copyWith(
      popupMenuTheme: PopupMenuThemeData(
        color: MacosColors.menuBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.5),
        thickness: 1,
        space: 6,
      ),
      hoverColor: MacosColors.accentHover.withValues(alpha: 0.35),
      highlightColor: MacosColors.accentBlue.withValues(alpha: 0.25),
      splashColor: Colors.transparent,
    );

    final infoStyle = TextStyle(
      color: Colors.grey.shade500,
      fontSize: 12,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.6,
    );

    final backgroundColor = widget.isSelected
        ? MacosColors.navSelectedBackground.withValues(alpha: 0.85)
        : _isHovered
        ? MacosColors.menuBackground.withValues(alpha: 0.8)
        : Colors.transparent;

    return Theme(
      data: menuTheme,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onSecondaryTapDown: (details) async {
          final position = RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          );
          final action = await showMenu<String>(
            context: context,
            position: position,
            color: MacosColors.menuBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            items: [
              PopupMenuItem<String>(
                value: 'playlist',
                enabled: widget.playlists.isNotEmpty,
                height: 30,
                textStyle: const TextStyle(color: Colors.white),
                child: const Text(
                  'Add to Playlist',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuDivider(height: 6),
              PopupMenuItem<String>(
                value: 'detail',
                height: 30,
                textStyle: const TextStyle(color: Colors.white),
                child: const Text(
                  'Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuDivider(height: 6),
              PopupMenuItem<String>(
                value: 'delete',
                height: 30,
                textStyle: const TextStyle(color: Colors.redAccent),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
          if (!context.mounted || action == null) return;
          if (action == 'detail') {
            widget.onShowMetadata(widget.metadata);
          } else if (action == 'delete') {
            widget.onDelete(widget.track);
          } else if (action == 'playlist') {
            final playlist = await _pickPlaylist(context);
            if (playlist != null) {
              widget.onAddToPlaylist(widget.track, playlist);
            }
          }
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.metadata.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    widget.track.path,
                    style: infoStyle.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _SourceBadge(type: widget.track.sourceType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _pickPlaylist(BuildContext context) async {
    if (widget.playlists.isEmpty) return null;
    final maxHeight = math.min(320.0, widget.playlists.length * 48.0 + 8);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text(
          'Add to playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 280,
          height: maxHeight,
          child: ListView.builder(
            itemCount: widget.playlists.length,
            itemBuilder: (context, index) {
              final name = widget.playlists[index];
              return ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(name),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.counts});

  final Map<LibrarySourceType, int> counts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: counts.entries.map((entry) {
        final color = _sourceColor(entry.key);
        return Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.value} tracks',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.type});

  final LibrarySourceType type;

  @override
  Widget build(BuildContext context) {
    final color = _sourceColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        type.label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _ImportStatusBar extends StatelessWidget {
  const _ImportStatusBar({required this.state, required this.onCancel});

  final LibraryImportState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosColors.miniPlayerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosColors.innerDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    MacosColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
          if (state.canCancel) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.library_music, size: 64, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'Import audio from local disks, cloud drives, Samba, WebDAV, or NFS.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Drag folders in and Toney will recurse to pick playable files only.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Color _sourceColor(LibrarySourceType type) => switch (type) {
  LibrarySourceType.local => MacosColors.accentBlue,
  LibrarySourceType.samba => Colors.orangeAccent.shade200,
  LibrarySourceType.webdav => Colors.tealAccent.shade200,
  LibrarySourceType.ftp => Colors.purpleAccent.shade200,
  LibrarySourceType.sftp => Colors.indigoAccent.shade200,
};

SongMetadata _fallbackMetadata(TrackRow track) {
  return SongMetadata(
    title: track.title,
    artist: track.artist,
    album: 'Unknown Album',
    extras: {'Path': track.path},
    isFallback: true,
  );
}
