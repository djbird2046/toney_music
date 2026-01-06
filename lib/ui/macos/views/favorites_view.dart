import 'dart:async';
import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import '../../../core/audio_controller.dart';
import '../../../core/favorites_controller.dart';
import '../../../core/model/playback_track.dart';
import '../../../core/model/song_metadata.dart';
import '../macos_colors.dart';

class MacosFavoritesView extends StatefulWidget {
  const MacosFavoritesView({
    super.key,
    required this.controller,
    required this.audioController,
  });

  final FavoritesController controller;
  final AudioController audioController;

  @override
  State<MacosFavoritesView> createState() => _MacosFavoritesViewState();
}

class _MacosFavoritesViewState extends State<MacosFavoritesView> {
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

  Future<void> _playFavorite(int index, List<PlaybackTrack> tracks) async {
    widget.audioController.setQueue(tracks, startIndex: index);
    await widget.audioController.playAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Container(
      color: colors.contentBackground,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.favoritesTitle,
                style: TextStyle(
                  color: colors.heading,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
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
            ],
          ),
          const SizedBox(height: 24),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.metadataFieldTitle,
                    style: TextStyle(color: colors.secondaryGrey, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.metadataFieldArtist,
                    style: TextStyle(color: colors.secondaryGrey, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.metadataFieldAlbum,
                    style: TextStyle(color: colors.secondaryGrey, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    l10n.metadataFieldDuration,
                    style: TextStyle(color: colors.secondaryGrey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.innerDivider),
          // List
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final query = _searchController.text.toLowerCase();
                final rawFavorites = widget.controller.favorites;
                final favorites = rawFavorites.where((entry) {
                  if (query.isEmpty) return true;
                  final metadata = entry.metadata;
                  if (metadata == null) return false;
                  return metadata.title.toLowerCase().contains(query) ||
                      metadata.artist.toLowerCase().contains(query) ||
                      metadata.album.toLowerCase().contains(query);
                }).toList();

                if (favorites.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.favoritesEmptyState,
                      style: TextStyle(color: colors.secondaryGrey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: favorites.length,
                  separatorBuilder: (context, _) =>
                      Divider(height: 1, color: colors.innerDivider),
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    final metadata = item.metadata;
                    final title = metadata?.title ?? l10n.favoritesUnknownTitle;
                    final artist =
                        metadata?.artist ?? l10n.favoritesUnknownArtist;
                    final album = metadata?.album ?? l10n.favoritesUnknownAlbum;
                    final duration = metadata?.extras['Duration'] ?? '--:--';

                    return InkWell(
                      onTap: () {
                        // Create a queue from the current filtered list
                        final queue = favorites
                            .map(
                              (e) => PlaybackTrack(
                                path: e.path,
                                metadata:
                                    e.metadata ?? SongMetadata.unknown(e.path),
                                bookmark: e.bookmark,
                              ),
                            )
                            .toList();
                        unawaited(_playFavorite(index, queue));
                      },
                      hoverColor: colors.accentHover,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: colors.heading,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                artist,
                                style: TextStyle(
                                  color: colors.secondaryGrey,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                album,
                                style: TextStyle(
                                  color: colors.secondaryGrey,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                duration,
                                style: TextStyle(
                                  color: colors.secondaryGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
