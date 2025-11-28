import 'package:flutter/material.dart';

import '../macos_colors.dart';
import '../models/nav_section.dart';

class MacosSidebar extends StatelessWidget {
  const MacosSidebar({
    super.key,
    required this.selectedSection,
    required this.onSelectSection,
    required this.playlists,
    required this.selectedPlaylist,
    required this.onPlaylistTap,
    required this.isRenamingPlaylist,
    required this.renameController,
    required this.onPlaylistRenameSubmit,
    required this.onAddPlaylist,
    required this.onPlaylistContextMenu,
  });

  final NavSection selectedSection;
  final ValueChanged<NavSection> onSelectSection;
  final List<String> playlists;
  final int selectedPlaylist;
  final PlaylistTapCallback onPlaylistTap;
  final bool isRenamingPlaylist;
  final TextEditingController renameController;
  final VoidCallback onPlaylistRenameSubmit;
  final VoidCallback onAddPlaylist;
  final void Function(int index, Offset position) onPlaylistContextMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
            width: 200,
      color: MacosColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 16, 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Toney',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavButton(
                    label: 'Music AI',
                    icon: Icons.auto_awesome,
                    isSelected: selectedSection == NavSection.aiDaily,
                    onTap: () => onSelectSection(NavSection.aiDaily),
                  ),
                  const SizedBox(height: 8),
                  _CollapsiblePlaylists(
                    playlists: playlists,
                    selectedSection: selectedSection,
                    selectedPlaylist: selectedPlaylist,
                    onPlaylistTap: onPlaylistTap,
                    isRenaming: isRenamingPlaylist,
                    renameController: renameController,
                    onRenameSubmit: onPlaylistRenameSubmit,
                    onSelectSection: onSelectSection,
                    onAddPlaylist: onAddPlaylist,
                    onPlaylistContextMenu: onPlaylistContextMenu,
                  ),
                  const SizedBox(height: 8),
                  _NavButton(
                    label: 'Favorites',
                    icon: Icons.favorite_border,
                    isSelected: selectedSection == NavSection.favorites,
                    onTap: () => onSelectSection(NavSection.favorites),
                  ),
                  _NavButton(
                    label: 'Library',
                    icon: Icons.library_music_outlined,
                    isSelected: selectedSection == NavSection.library,
                    onTap: () => onSelectSection(NavSection.library),
                  ),
                  _NavButton(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    isSelected: selectedSection == NavSection.settings,
                    onTap: () => onSelectSection(NavSection.settings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: MacosColors.accentHover,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? MacosColors.navSelectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: MacosColors.navSelectedShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? MacosColors.accentBlue
                        : MacosColors.secondaryGrey,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? MacosColors.accentBlue
                        : MacosColors.secondaryGrey,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsiblePlaylists extends StatefulWidget {
  const _CollapsiblePlaylists({
    required this.playlists,
    required this.selectedSection,
    required this.selectedPlaylist,
    required this.onPlaylistTap,
    required this.isRenaming,
    required this.renameController,
    required this.onRenameSubmit,
    required this.onSelectSection,
    required this.onAddPlaylist,
    required this.onPlaylistContextMenu,
  });

  final List<String> playlists;
  final NavSection selectedSection;
  final int selectedPlaylist;
  final PlaylistTapCallback onPlaylistTap;
  final bool isRenaming;
  final TextEditingController renameController;
  final VoidCallback onRenameSubmit;
  final ValueChanged<NavSection> onSelectSection;
  final VoidCallback onAddPlaylist;
  final void Function(int index, Offset position) onPlaylistContextMenu;

  @override
  State<_CollapsiblePlaylists> createState() => _CollapsiblePlaylistsState();
}

class _CollapsiblePlaylistsState extends State<_CollapsiblePlaylists> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => expanded = !expanded),
                child: Row(
                  children: [
                    Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: MacosColors.mutedGrey,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Playlists',
                      style: TextStyle(
                        color: MacosColors.sectionLabel,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: MacosColors.mutedGrey,
                ),
                onPressed: widget.onAddPlaylist,
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ],
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(widget.playlists.length, (index) {
                final isSelected =
                    widget.selectedSection == NavSection.playlists &&
                    widget.selectedPlaylist == index;
                final showRename = isSelected && widget.isRenaming;
                if (showRename) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: MacosColors.renameBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MacosColors.renameBorder),
                    ),
                    child: TextField(
                      controller: widget.renameController,
                      autofocus: true,
                      onSubmitted: (_) => widget.onRenameSubmit(),
                      onEditingComplete: () {
                        widget.onRenameSubmit();
                        expanded = true;
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Rename playlist',
                        hintStyle: TextStyle(color: MacosColors.mutedGrey),
                      ),
                    ),
                  );
                }
                final alreadySelected =
                    widget.selectedSection == NavSection.playlists &&
                    widget.selectedPlaylist == index;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onSecondaryTapDown: (details) {
                      widget.onPlaylistContextMenu(
                        index,
                        details.globalPosition,
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          widget.onSelectSection(NavSection.playlists);
                          widget.onPlaylistTap(
                            index,
                            allowRename: alreadySelected,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: MacosColors.accentHover,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? MacosColors.navSelectedBackground
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              widget.playlists[index],
                              style: TextStyle(
                                color: isSelected
                                    ? MacosColors.accentBlue
                                    : MacosColors.tertiaryGrey,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w400
                                    : FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
