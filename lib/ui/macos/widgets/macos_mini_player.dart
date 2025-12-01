import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:toney_music/toney_core.dart';
import '../../../core/favorites_controller.dart';

import '../macos_colors.dart';

class MacosMiniPlayer extends StatefulWidget {
  const MacosMiniPlayer({
    super.key,
    required this.controller,
    required this.favoritesController,
    required this.bitPerfectEnabled,
  });

  final AudioController controller;
  final FavoritesController favoritesController;
  final bool bitPerfectEnabled;

  @override
  State<MacosMiniPlayer> createState() => _MacosMiniPlayerState();
}

class _MacosMiniPlayerState extends State<MacosMiniPlayer> {
  static const _defaultFormat = '--';
  static const _defaultBitrate = '--';
  static const _defaultSampleRate = '--';
  static const _defaultChannel = '--';

  MacosColors get _colors => context.macosColors;

  bool _isMuted = false;
  double _volume = 0.7;
  double _preMuteVolume = 0.7;
  bool _isQueueVisible = false;
  final ValueNotifier<int> _queueSelection = ValueNotifier<int>(0);
  OverlayEntry? _queueOverlayEntry;
  StreamSubscription<double>? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _volumeSubscription = widget.controller.volumeStream.listen((newVolume) {
      if (!mounted) return;
      setState(() {
        _volume = newVolume;
        _isMuted = newVolume <= 0.001;
        if (!_isMuted) {
          _preMuteVolume = newVolume;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant MacosMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _volumeSubscription?.cancel();
      _volumeSubscription = widget.controller.volumeStream.listen((newVolume) {
        if (!mounted) return;
        setState(() {
          _volume = newVolume;
          _isMuted = newVolume <= 0.001;
          if (!_isMuted) {
            _preMuteVolume = newVolume;
          }
        });
      });
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.bitPerfectEnabled != widget.bitPerfectEnabled) {
      _loadVolume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackViewModel>(
      valueListenable: widget.controller.state,
      builder: (context, playback, _) {
        return AnimatedBuilder(
          animation: widget.favoritesController,
          builder: (context, _) {
            final metadata = playback.currentTrack?.metadata;
            final engineMetadata = playback.engineMetadata;
            final engineFormat = engineMetadata?.pcm;
            final formatLabel =
                engineFormat?.formatLabel ??
                _statValue(metadata, [
                  'Format',
                  'format',
                  'File Type',
                ], _defaultFormat);
            final bitrateLabel =
                engineFormat?.bitrateLabel ??
                _statValue(metadata, ['Bitrate', 'bitrate'], _defaultBitrate);
            final sampleRateLabel =
                engineFormat?.sampleRateLabel ??
                _statValue(metadata, [
                  'Sample Rate',
                  'sample_rate',
                ], _defaultSampleRate);
            final channelLabel =
                engineFormat?.channelsLabel ??
                _statValue(metadata, [
                  'Channels',
                  'Channel Mode',
                ], _defaultChannel);
            final effectiveDuration =
                playback.engineMetadata?.duration ?? playback.duration;
            final positionSeconds = playback.position.inMilliseconds / 1000.0;
            final durationSeconds = effectiveDuration.inMilliseconds / 1000.0;
            final double sliderMax = durationSeconds > 0
                ? durationSeconds
                : 1.0;

            final isFavorite =
                playback.currentTrack != null &&
                widget.favoritesController.isFavorite(
                  playback.currentTrack!.path,
                );

            final colors = _colors;
            return Container(
              constraints: const BoxConstraints(minHeight: 120),
              color: colors.miniPlayerBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: _NowPlayingInfo(metadata: metadata),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: _PlaybackControlsGroup(
                          isPlaying: playback.isPlaying,
                          onTogglePlay: () =>
                              unawaited(widget.controller.togglePlayPause()),
                          onNext: () => unawaited(widget.controller.playNext()),
                          onPrevious: () =>
                              unawaited(widget.controller.playPrevious()),
                          onToggleFavorite: () {
                            if (playback.currentTrack != null) {
                              widget.favoritesController.toggleFavorite(
                                playback.currentTrack!,
                              );
                            }
                          },
                          isFavorite: isFavorite,
                          playbackMode: playback.playbackMode,
                          onPlaybackModeChanged:
                              widget.controller.setPlaybackMode,
                          formatLabel: formatLabel,
                          bitrateLabel: bitrateLabel,
                          sampleRateLabel: sampleRateLabel,
                          channelLabel: channelLabel,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 200,
                        child: _VolumeControl(
                          volume: _isMuted ? 0 : _volume,
                          onChanged: widget.bitPerfectEnabled
                              ? null
                              : _handleVolumeChange,
                          onToggleMute: widget.bitPerfectEnabled
                              ? null
                              : _toggleMute,
                          isMuted: _isMuted || _volume == 0,
                          onToggleQueue: _handleQueueToggle,
                          isQueueVisible: _isQueueVisible,
                          isDisabled: widget.bitPerfectEnabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatTimestamp(positionSeconds),
                        style: TextStyle(
                          color: colors.secondaryGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            inactiveTrackColor: colors.innerDivider,
                            activeTrackColor: colors.accentBlue,
                          ),
                          child: Slider(
                            value: durationSeconds > 0
                                ? positionSeconds
                                      .clamp(0.0, durationSeconds)
                                      .toDouble()
                                : 0.0,
                            max: sliderMax,
                            onChanged: durationSeconds > 0
                                ? (value) {
                                    unawaited(
                                      widget.controller.seek(
                                        (value * 1000).round(),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatTimestamp(durationSeconds),
                        style: TextStyle(
                          color: colors.secondaryGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleMute() {
    if (widget.bitPerfectEnabled) return;
    if (_isMuted) {
      final target = _preMuteVolume.clamp(0.0, 1.0);
      _handleVolumeChange(target == 0 ? 1.0 : target);
    } else {
      _preMuteVolume = _volume <= 0.001 ? 0.7 : _volume;
      _handleVolumeChange(0.0);
    }
  }

  void _handleQueueToggle() {
    if (_isQueueVisible) {
      _hideQueueOverlay();
    } else {
      _showQueueOverlay();
    }
  }

  void _showQueueOverlay() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final playback = widget.controller.state.value;
    _queueSelection.value = playback.currentIndex ?? 0;
    _queueOverlayEntry = OverlayEntry(
      builder: (context) => _QueueDrawerOverlay(
        playbackListenable: widget.controller.state,
        selectionListenable: _queueSelection,
        onSelect: _handleQueueSelect,
        onDismiss: _hideQueueOverlay,
      ),
    );
    overlay.insert(_queueOverlayEntry!);
    setState(() => _isQueueVisible = true);
  }

  void _hideQueueOverlay() {
    _queueOverlayEntry?.remove();
    _queueOverlayEntry = null;
    if (mounted) {
      setState(() => _isQueueVisible = false);
    }
  }

  void _handleQueueSelect(int index) {
    if (_queueSelection.value == index) {
      return;
    }
    _queueSelection.value = index;
    unawaited(widget.controller.playAt(index));
  }

  Future<void> _loadVolume() async {
    try {
      final value = await widget.controller.getVolume();
      if (!mounted) return;
      setState(() {
        _volume = value;
        _isMuted = value <= 0.001;
        if (!_isMuted) {
          _preMuteVolume = value;
        }
      });
    } catch (_) {
      // Ignore volume sync failures in UI.
    }
  }

  void _handleVolumeChange(double value) {
    if (widget.bitPerfectEnabled) return;
    final normalized = value.clamp(0.0, 1.0);
    setState(() {
      _volume = normalized;
      if (normalized <= 0.001) {
        _isMuted = true;
      } else {
        _isMuted = false;
        _preMuteVolume = normalized;
      }
    });
    unawaited(
      widget.controller.setVolume(normalized).catchError((error, _) {
        if (!mounted) return;
        _showVolumeError(error);
        _loadVolume();
      }),
    );
  }

  void _showVolumeError(Object error) {
    final description = error is PlatformException
        ? (error.message?.isNotEmpty == true ? error.message! : error.code)
        : error.toString();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            'Volume adjustment failed',
            style: TextStyle(color: colors.heading),
          ),
          content: Text(description, style: TextStyle(color: colors.mutedGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    _queueOverlayEntry?.remove();
    _queueSelection.dispose();
    super.dispose();
  }

  String _formatTimestamp(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  String _statValue(
    SongMetadata? metadata,
    List<String> keys,
    String fallback,
  ) {
    if (metadata == null) return fallback;
    for (final key in keys) {
      final value = metadata.extras[key];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}

class _PlaybackControlsGroup extends StatefulWidget {
  const _PlaybackControlsGroup({
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleFavorite,
    required this.isFavorite,
    required this.playbackMode,
    required this.onPlaybackModeChanged,
    required this.formatLabel,
    required this.bitrateLabel,
    required this.sampleRateLabel,
    required this.channelLabel,
  });

  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final PlayMode playbackMode;
  final ValueChanged<PlayMode> onPlaybackModeChanged;
  final String formatLabel;
  final String bitrateLabel;
  final String sampleRateLabel;
  final String channelLabel;

  @override
  State<_PlaybackControlsGroup> createState() => _PlaybackControlsGroupState();
}

class _PlaybackControlsGroupState extends State<_PlaybackControlsGroup> {
  IconData get _playModeIcon {
    switch (widget.playbackMode) {
      case PlayMode.sequence:
        return Icons.playlist_play;
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.single:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite Button
            _MiniPlayerButton(
              icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: widget.isFavorite ? Colors.redAccent : null,
              onPressed: widget.onToggleFavorite,
              size: 32,
              iconSize: 16,
            ),
            const SizedBox(width: 12),
            _MiniPlayerButton(
              icon: Icons.skip_previous,
              onPressed: widget.onPrevious,
            ),
            const SizedBox(width: 12),
            _MiniPlayerButton(
              icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: widget.onTogglePlay,
            ),
            const SizedBox(width: 12),
            _MiniPlayerButton(icon: Icons.skip_next, onPressed: widget.onNext),
            const SizedBox(width: 12),
            // Play Mode Button
            _MiniPlayerButton(
              icon: _playModeIcon,
              onPressed: () {
                final nextMode =
                    PlayMode.values[(widget.playbackMode.index + 1) %
                        PlayMode.values.length];
                widget.onPlaybackModeChanged(nextMode);
              },
              size: 32,
              iconSize: 16,
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: _TrackStats(
            format: widget.formatLabel,
            bitrate: widget.bitrateLabel,
            sampleRate: widget.sampleRateLabel,
            channels: widget.channelLabel,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _MiniPlayerButton extends StatelessWidget {
  const _MiniPlayerButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.iconColor,
    this.size,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? iconColor;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? (isPrimary ? 44 : 36);
    final iSize = iconSize ?? 20;
    final colors = context.macosColors;

    return Material(
      color: isPrimary ? colors.accentBlue : colors.navSelectedBackground,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Icon(
            icon,
            color: iconColor ?? (isPrimary ? Colors.white : colors.iconGrey),
            size: iSize,
          ),
        ),
      ),
    );
  }
}

class _TrackStats extends StatelessWidget {
  const _TrackStats({
    required this.format,
    required this.bitrate,
    required this.sampleRate,
    required this.channels,
    this.textAlign = TextAlign.start,
  });

  final String format;
  final String bitrate;
  final String sampleRate;
  final String channels;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final labelStyle = TextStyle(
      color: colors.secondaryGrey,
      fontSize: 11,
      fontWeight: FontWeight.w300,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$format • $bitrate • $sampleRate • $channels',
            style: labelStyle,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

class _MiniIconToggleButton extends StatelessWidget {
  const _MiniIconToggleButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Material(
      color: isActive
          ? colors.navSelectedBackground
          : colors.navSelectedBackground.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: isActive ? colors.accentBlue : colors.secondaryGrey,
          ),
        ),
      ),
    );
  }
}

class _NowPlayingQueuePanel extends StatelessWidget {
  const _NowPlayingQueuePanel({
    required this.tracks,
    required this.currentIndex,
    required this.selectedIndex,
    required this.onClose,
    required this.onSelect,
  });

  final List<PlaybackTrack> tracks;
  final int currentIndex;
  final int selectedIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.sidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.innerDivider),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Now Playing',
                style: TextStyle(
                  color: colors.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: colors.mutedGrey,
                padding: EdgeInsets.zero,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tracks.isEmpty
                ? Center(
                    child: Text(
                      'Queue is empty',
                      style: TextStyle(color: colors.secondaryGrey),
                    ),
                  )
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (context, _) =>
                        Divider(height: 1, color: colors.innerDivider),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isCurrent = index == currentIndex;
                      final isSelected = index == selectedIndex;
                      return _QueueRow(
                        track: track,
                        isCurrent: isCurrent,
                        isSelected: isSelected,
                        onTap: () => onSelect(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueDrawerOverlay extends StatelessWidget {
  const _QueueDrawerOverlay({
    required this.playbackListenable,
    required this.selectionListenable,
    required this.onSelect,
    required this.onDismiss,
  });

  final ValueListenable<PlaybackViewModel> playbackListenable;
  final ValueListenable<int> selectionListenable;
  final ValueChanged<int> onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<PlaybackViewModel>(
                    valueListenable: playbackListenable,
                    builder: (context, playback, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: selectionListenable,
                        builder: (context, selectedIndex, _) {
                          final tracks = playback.queue;
                          final currentIndex = playback.currentIndex ?? -1;
                          final safeSelected = tracks.isEmpty
                              ? -1
                              : selectedIndex.clamp(0, tracks.length - 1);
                          return _NowPlayingQueuePanel(
                            tracks: tracks,
                            currentIndex: currentIndex,
                            selectedIndex: safeSelected,
                            onClose: onDismiss,
                            onSelect: onSelect,
                          );
                        },
                      );
                    },
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

class _QueueRow extends StatefulWidget {
  const _QueueRow({
    required this.track,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  final PlaybackTrack track;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<_QueueRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final backgroundColor = widget.isCurrent
        ? colors.navSelectedBackground
        : widget.isSelected
        ? colors.navSelectedBackground.withValues(alpha: 0.4)
        : _isHovered
        ? colors.accentHover
        : Colors.transparent;
    final border = widget.isSelected && !widget.isCurrent
        ? Border.all(color: colors.accentBlue.withValues(alpha: 0.35))
        : null;
    final metadata = widget.track.metadata;
    final durationLabel =
        metadata.extras['Duration'] ?? metadata.extras['duration'] ?? '--:--';
    final titleStyle = TextStyle(
      color: widget.isCurrent ? colors.accentBlue : colors.heading,
      fontSize: 14,
      fontWeight: widget.isCurrent ? FontWeight.w400 : FontWeight.w300,
    );
    final subtitleStyle = TextStyle(color: colors.secondaryGrey, fontSize: 12);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _QueueArtwork(
                bytes: metadata.artwork,
                isCurrent: widget.isCurrent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      metadata.title,
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metadata.artist,
                      style: subtitleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(durationLabel, style: subtitleStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueArtwork extends StatelessWidget {
  const _QueueArtwork({required this.bytes, required this.isCurrent});

  final Uint8List? bytes;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final artwork = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? colors.accentBlue.withValues(alpha: 0.8)
              : colors.innerDivider,
        ),
        color: colors.contentBackground,
        image: bytes != null
            ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
            : null,
      ),
      child: bytes == null
          ? Icon(Icons.music_note, color: colors.secondaryGrey, size: 18)
          : null,
    );
    if (!isCurrent) {
      return artwork;
    }
    return Stack(
      children: [
        artwork,
        Positioned(
          right: 4,
          bottom: 4,
          child: Icon(Icons.graphic_eq, size: 14, color: colors.accentBlue),
        ),
      ],
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.volume,
    this.onChanged,
    this.onToggleMute,
    required this.isMuted,
    required this.onToggleQueue,
    required this.isQueueVisible,
    this.isDisabled = false,
  });

  final double volume;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onToggleMute;
  final bool isMuted;
  final VoidCallback onToggleQueue;
  final bool isQueueVisible;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _MiniIconToggleButton(
          icon: Icons.queue_music,
          isActive: isQueueVisible,
          onPressed: onToggleQueue,
        ),
        const SizedBox(width: 12),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: onToggleMute,
          icon: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: isDisabled ? colors.innerDivider : colors.heading,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              inactiveTrackColor: colors.divider,
              activeTrackColor: colors.accentBlue,
            ),
            child: Slider(
              value: volume,
              onChanged: isDisabled ? null : onChanged,
              min: 0,
              max: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _NowPlayingInfo extends StatelessWidget {
  const _NowPlayingInfo({this.metadata});

  final SongMetadata? metadata;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final title = metadata?.title ?? 'Nothing playing yet';
    final artist = metadata?.artist ?? 'Select a track to start playback';
    final artwork = metadata?.artwork;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.innerDivider),
            color: colors.contentBackground,
            image: artwork != null
                ? DecorationImage(
                    image: MemoryImage(artwork),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: artwork == null
              ? Icon(Icons.music_note, color: colors.secondaryGrey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.heading,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondaryGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
