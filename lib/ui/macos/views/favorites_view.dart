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
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.favoritesTitle,
                style: const TextStyle(
                  color: Colors.white,
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
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.metadataFieldArtist,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.metadataFieldAlbum,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    l10n.metadataFieldDuration,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MacosColors.innerDivider),
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
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: favorites.length,
                  separatorBuilder: (context, _) =>
                      const Divider(height: 1, color: MacosColors.innerDivider),
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
                              ),
                            )
                            .toList();
                        unawaited(_playFavorite(index, queue));
                      },
                      hoverColor: MacosColors.accentHover,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                artist,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                album,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  color: Colors.white70,
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
