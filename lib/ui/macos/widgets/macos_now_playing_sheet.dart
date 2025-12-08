import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:toney_music/core/audio_controller.dart';
import 'package:toney_music/core/model/playback_view_model.dart';
import 'package:toney_music/core/model/song_metadata.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../macos_colors.dart';

class MacosNowPlayingSheet extends StatelessWidget {
  const MacosNowPlayingSheet({
    super.key,
    required this.controller,
    required this.isVisible,
    required this.onClose,
    required this.storyText,
    required this.storyDraft,
    required this.isStoryLoading,
    required this.storyError,
    required this.onGenerateStory,
    this.bottomPadding = 140,
  });

  final AudioController controller;
  final bool isVisible;
  final VoidCallback onClose;
  final String? storyText;
  final String storyDraft;
  final bool isStoryLoading;
  final String? storyError;
  final VoidCallback? onGenerateStory;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    final targetHeight = math.max(
      360.0,
      MediaQuery.of(context).size.height - bottomPadding,
    );
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: isVisible ? 1 : 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                height: targetHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.contentBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: ValueListenableBuilder<PlaybackViewModel>(
                      valueListenable: controller.state,
                      builder: (context, playback, _) {
                        final metadata = playback.currentTrack?.metadata;
                        final rawTitle = (metadata?.title ?? '').trim();
                        final title = rawTitle.isNotEmpty
                            ? rawTitle
                            : l10n.nowPlayingNotPlaying;
                        final artistRaw = (metadata?.artist ?? '').trim();
                        final albumRaw = (metadata?.album ?? '').trim();
                        final artist = artistRaw.isNotEmpty
                            ? artistRaw
                            : l10n.libraryUnknownArtist;
                        final album = albumRaw.isNotEmpty
                            ? albumRaw
                            : l10n.libraryUnknownAlbum;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: onClose,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: colors.iconGrey,
                                    size: 26,
                                  ),
                                  tooltip: l10n.nowPlayingCollapse,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _HaloArtwork(
                                      metadata: metadata,
                                      isPlaying:
                                          playback.isPlaying && isVisible,
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: colors.heading,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$artist / $album',
                                          style: TextStyle(
                                            color: colors.secondaryGrey,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 18),
                                        _StoryButton(
                                          onPressed:
                                              metadata == null || isStoryLoading
                                                  ? null
                                                  : onGenerateStory,
                                          label: l10n.nowPlayingStoryButton,
                                          isLoading: isStoryLoading,
                                        ),
                                        const SizedBox(height: 16),
                                        _StoryArea(
                                          storyText: storyText,
                                          draftText: storyDraft,
                                          isLoading: isStoryLoading,
                                          error: storyError,
                                          placeholderText: l10n
                                              .nowPlayingStoryPlaceholder,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HaloArtwork extends StatefulWidget {
  const _HaloArtwork({
    required this.metadata,
    required this.isPlaying,
  });

  final SongMetadata? metadata;
  final bool isPlaying;

  @override
  State<_HaloArtwork> createState() => _HaloArtworkState();
}

class _HaloArtworkState extends State<_HaloArtwork>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant _HaloArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (widget.isPlaying) {
      _spinController.repeat();
      _breathController.repeat(reverse: true);
    } else {
      _spinController.stop();
      _breathController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final artwork = widget.metadata?.artwork;
    final placeholderGradient = LinearGradient(
      colors: [
        colors.accentBlue.withValues(alpha: 0.35),
        colors.accentBlue.withValues(alpha: 0.15),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 320.0);
        return Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _breathController]),
            builder: (context, _) {
              final breathT = _breathController.value;
              final wave = 0.5 + 0.5 * math.sin(breathT * math.pi * 2);
              final glowScale = 1.02 + wave * 0.05;
              final glowOpacity = 0.18 + wave * 0.2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: glowScale,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentBlue
                                .withValues(alpha: glowOpacity),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _spinController.value * 2 * math.pi,
                    child: Container(
                      width: size * 0.82,
                      height: size * 0.82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                colors.innerDivider.withValues(alpha: 0.55),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: artwork != null
                            ? DecorationImage(
                                image: MemoryImage(artwork),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: artwork == null ? placeholderGradient : null,
                      ),
                      child: artwork == null
                          ? Icon(
                              Icons.music_note,
                              color: colors.secondaryGrey,
                              size: 84,
                            )
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StoryButton extends StatelessWidget {
  const _StoryButton({
    this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.accentBlue.withValues(alpha: 0.6)),
        foregroundColor: colors.accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentBlue),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class _StoryArea extends StatelessWidget {
  const _StoryArea({
    required this.storyText,
    required this.draftText,
    required this.isLoading,
    required this.error,
    required this.placeholderText,
  });

  final String? storyText;
  final String draftText;
  final bool isLoading;
  final String? error;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final content = _buildContent(colors);
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.all(14),
      child: content,
    );
  }

  Widget _buildContent(MacosColors colors) {
    if (error != null) {
      return _buildScrollable(
        colors,
        Text(
          error!,
          style: TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }
    if (storyText != null && storyText!.trim().isNotEmpty) {
      return _buildScrollable(
        colors,
        _MarkdownText(text: storyText!),
      );
    }
    if (draftText.isNotEmpty) {
      return _buildScrollable(
        colors,
        _MarkdownText(text: draftText),
      );
    }
    if (isLoading) {
      return _buildScrollable(
        colors,
        _buildLoadingRow(colors, placeholderText),
      );
    }
    return Center(
      child: Text(
        placeholderText,
        style: TextStyle(
          color: colors.secondaryGrey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildScrollable(MacosColors colors, Widget child) {
    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        child: child,
      ),
    );
  }

  Widget _buildLoadingRow(MacosColors colors, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accentBlue),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.heading, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final trimmed = text.trim();
    return MarkdownBody(
      data: trimmed.isEmpty ? text : trimmed,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: colors.heading, fontSize: 14, height: 1.4),
        blockSpacing: 8,
        listBullet: TextStyle(color: colors.heading, fontSize: 14),
      ),
    );
  }
}
