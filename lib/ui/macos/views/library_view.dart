import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../../core/model/song_metadata.dart';
import '../macos_colors.dart';
import '../models/media_models.dart';
import '../../../core/library/library_source.dart';

class MacosLibraryView extends StatefulWidget {
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

  @override
  State<MacosLibraryView> createState() => _MacosLibraryViewState();
}

class _MacosLibraryViewState extends State<MacosLibraryView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousTrackCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _previousTrackCount = widget.tracks.length;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MacosLibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.importState.isActive &&
        widget.tracks.length > _previousTrackCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousTrackCount = widget.tracks.length;
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Map<LibrarySourceType, int> _sourceCounts() {
    final counts = <LibrarySourceType, int>{};
    for (final track in widget.tracks) {
      counts.update(track.sourceType, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    final sourceCounts = _sourceCounts();
    final query = _searchController.text.toLowerCase();
    final tracks = widget.tracks.where((track) {
      if (query.isEmpty) return true;
      final metadata =
          widget.metadataByPath[track.path] ?? _fallbackMetadata(track, l10n);
      return metadata.title.toLowerCase().contains(query) ||
          metadata.artist.toLowerCase().contains(query) ||
          metadata.album.toLowerCase().contains(query);
    }).toList();
    final isEmpty = tracks.isEmpty;

    return Container(
      color: colors.contentBackground,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.libraryTitle,
                      style: TextStyle(
                        color: colors.heading,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty
                          ? l10n.libraryEmptySubtitle
                          : l10n.libraryTrackCount(tracks.length),
                      style: TextStyle(color: colors.mutedGrey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                // Search Bar
                Container(
                  width: 200,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.sidebar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.innerDivider),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: colors.iconGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: colors.heading, fontSize: 13),
                          cursorColor: colors.accentBlue,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: l10n.libraryFilterHint,
                            hintStyle: TextStyle(color: colors.mutedGrey),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: widget.importState.isActive
                      ? null
                      : widget.onAddLibrarySource,
                  icon: const Icon(Icons.library_add),
                  label: Text(l10n.libraryAddSources),
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
                    controller: _scrollController,
                    itemCount: tracks.length,
                      separatorBuilder: (context, _) =>
                          Divider(color: colors.innerDivider, height: 1),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final metadata =
                            widget.metadataByPath[track.path] ??
                            _fallbackMetadata(track, l10n);
                        return TrackRowView(
                          track: track,
                          metadata: metadata,
                          onShowMetadata: widget.onShowMetadata,
                          onDelete: widget.onDeleteTrack,
                          onAddToPlaylist: widget.onAddToPlaylist,
                          playlists: widget.playlists,
                          isSelected: widget.selectedIndex == index,
                          onTap: () => widget.onSelectTrack(index),
                        );
                      },
                    ),
            ),
            if (widget.importState.isActive)
              _ImportStatusBar(
                state: widget.importState,
                onCancel: widget.onCancelImport,
              )
            else if (widget.importState.hasStatus)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.importState.message,
                  style: TextStyle(color: colors.mutedGrey, fontSize: 13),
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
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    final menuTheme = Theme.of(context).copyWith(
      popupMenuTheme: PopupMenuThemeData(
        color: colors.menuBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(color: colors.heading, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.5),
        thickness: 1,
        space: 6,
      ),
      hoverColor: colors.accentHover.withValues(alpha: 0.35),
      highlightColor: colors.accentBlue.withValues(alpha: 0.25),
      splashColor: Colors.transparent,
    );

    final infoStyle = TextStyle(
      color: colors.mutedGrey,
      fontSize: 12,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.6,
    );

    final backgroundColor = widget.isSelected
        ? colors.navSelectedBackground.withValues(alpha: 0.85)
        : _isHovered
        ? colors.menuBackground.withValues(alpha: 0.8)
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
            color: colors.menuBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            items: [
              PopupMenuItem<String>(
                value: 'playlist',
                enabled: widget.playlists.isNotEmpty,
                height: 30,
                textStyle: TextStyle(color: colors.heading),
                child: Text(
                  l10n.libraryContextAddToPlaylist,
                  style: TextStyle(color: colors.heading),
                ),
              ),
              const PopupMenuDivider(height: 6),
              PopupMenuItem<String>(
                value: 'detail',
                height: 30,
                textStyle: TextStyle(color: colors.heading),
                child: Text(
                  l10n.libraryContextDetails,
                  style: TextStyle(color: colors.heading),
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
                    style: TextStyle(
                      color: colors.heading,
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) {
        final colors = context.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.libraryContextAddToPlaylist,
            style: TextStyle(color: colors.heading),
          ),
          content: SizedBox(
            width: 280,
            height: maxHeight,
            child: ListView.builder(
              itemCount: widget.playlists.length,
              itemBuilder: (context, index) {
                final name = widget.playlists[index];
                return ListTile(
                  title: Text(name, style: TextStyle(color: colors.heading)),
                  onTap: () => Navigator.of(context).pop(name),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        );
      },
    );
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.counts});

  final Map<LibrarySourceType, int> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: counts.entries.map((entry) {
        final color = _sourceColor(colors, entry.key);
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
                _sourceLabel(entry.key, l10n),
                style: TextStyle(
                  color: colors.heading,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.librarySourceSummaryCount(entry.value),
                style: TextStyle(color: colors.mutedGrey, fontSize: 12),
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
    final colors = context.macosColors;
    final color = _sourceColor(colors, type);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _sourceLabel(type, l10n),
        style: TextStyle(color: colors.heading, fontSize: 11),
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
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.miniPlayerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.innerDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.message,
                  style: TextStyle(color: colors.heading, fontSize: 13),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: colors.innerDivider,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accentBlue),
                ),
              ],
            ),
          ),
          if (state.canCancel) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.libraryStopImport),
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
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music, size: 64, color: colors.innerDivider),
          const SizedBox(height: 12),
          Text(
            l10n.libraryEmptyPrimary,
            style: TextStyle(color: colors.mutedGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.libraryEmptySecondary,
            style: TextStyle(color: colors.secondaryGrey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Color _sourceColor(MacosColors colors, LibrarySourceType type) =>
    switch (type) {
      LibrarySourceType.local => colors.accentBlue,
      LibrarySourceType.samba => Colors.orangeAccent.shade200,
      LibrarySourceType.webdav => Colors.tealAccent.shade200,
      LibrarySourceType.ftp => Colors.purpleAccent.shade200,
      LibrarySourceType.sftp => Colors.indigoAccent.shade200,
    };

String _sourceLabel(LibrarySourceType type, AppLocalizations l10n) =>
    switch (type) {
      LibrarySourceType.local => l10n.librarySourceLocal,
      LibrarySourceType.samba => l10n.librarySourceSamba,
      LibrarySourceType.webdav => l10n.librarySourceWebdav,
      LibrarySourceType.ftp => l10n.librarySourceFtp,
      LibrarySourceType.sftp => l10n.librarySourceSftp,
    };

SongMetadata _fallbackMetadata(TrackRow track, AppLocalizations l10n) {
  return SongMetadata(
    title: track.title,
    artist: track.artist,
    album: l10n.libraryUnknownAlbum,
    extras: {'Path': track.path},
    isFallback: true,
  );
}
