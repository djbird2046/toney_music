import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:toney_music/toney_core.dart';

import '../macos_colors.dart';

class MacosMiniPlayer extends StatefulWidget {
  const MacosMiniPlayer({
    super.key,
    required this.controller,
    required this.bitPerfectEnabled,
  });

  final AudioController controller;
  final bool bitPerfectEnabled;

  @override
  State<MacosMiniPlayer> createState() => _MacosMiniPlayerState();
}

class _MacosMiniPlayerState extends State<MacosMiniPlayer> {
  static const _defaultFormat = '--';
  static const _defaultBitrate = '--';
  static const _defaultSampleRate = '--';
  static const _defaultChannel = '--';

  bool _isMuted = false;
  double _volume = 0.7;
  double _preMuteVolume = 0.7;
  bool _isQueueVisible = false;
  final ValueNotifier<int> _queueSelection = ValueNotifier<int>(0);
  OverlayEntry? _queueOverlayEntry;

  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  @override
  void didUpdateWidget(covariant MacosMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
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
            _statValue(metadata, ['Channels', 'Channel Mode'], _defaultChannel);
        final effectiveDuration =
            playback.engineMetadata?.duration ?? playback.duration;
        final positionSeconds = playback.position.inMilliseconds / 1000.0;
        final durationSeconds = effectiveDuration.inMilliseconds / 1000.0;
        final double sliderMax = durationSeconds > 0 ? durationSeconds : 1.0;

        return Container(
          constraints: const BoxConstraints(minHeight: 120),
          color: MacosColors.miniPlayerBackground,
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
                    style: const TextStyle(
                      color: MacosColors.secondaryGrey,
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
                        inactiveTrackColor: MacosColors.innerDivider,
                        activeTrackColor: MacosColors.accentBlue,
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
                    style: const TextStyle(
                      color: MacosColors.secondaryGrey,
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
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text('Volume adjustment failed'),
        content: Text(
          description,
          style: const TextStyle(color: Colors.white70),
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
  void dispose() {
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

class _MiniPlayerButton extends StatelessWidget {
  const _MiniPlayerButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? MacosColors.accentBlue
          : MacosColors.navSelectedBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: isPrimary ? 44 : 36,
          height: isPrimary ? 44 : 36,
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : MacosColors.iconGrey,
          ),
        ),
      ),
    );
  }
}

class _PlaybackControlsGroup extends StatelessWidget {
  const _PlaybackControlsGroup({
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.formatLabel,
    required this.bitrateLabel,
    required this.sampleRateLabel,
    required this.channelLabel,
  });

  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final String formatLabel;
  final String bitrateLabel;
  final String sampleRateLabel;
  final String channelLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniPlayerButton(icon: Icons.skip_previous, onPressed: onPrevious),
            const SizedBox(width: 12),
            _MiniPlayerButton(
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: onTogglePlay,
            ),
            const SizedBox(width: 12),
            _MiniPlayerButton(icon: Icons.skip_next, onPressed: onNext),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: _TrackStats(
            format: formatLabel,
            bitrate: bitrateLabel,
            sampleRate: sampleRateLabel,
            channels: channelLabel,
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
    final labelStyle = TextStyle(
      color: MacosColors.secondaryGrey,
      fontSize: 11,
      fontWeight: FontWeight.w400,
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
    return Material(
      color: isActive
          ? MacosColors.navSelectedBackground
          : MacosColors.navSelectedBackground.withValues(alpha: 0.2),
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
            color: isActive ? MacosColors.accentBlue : Colors.white70,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosColors.sidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MacosColors.innerDivider),
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
              const Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: MacosColors.mutedGrey,
                padding: EdgeInsets.zero,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tracks.isEmpty
                ? const Center(
                    child: Text(
                      'Queue is empty',
                      style: TextStyle(color: Colors.white60),
                    ),
                  )
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (context, _) => const Divider(
                      height: 1,
                      color: MacosColors.innerDivider,
                    ),
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
    final backgroundColor = widget.isCurrent
        ? MacosColors.navSelectedBackground
        : widget.isSelected
        ? MacosColors.navSelectedBackground.withValues(alpha: 0.4)
        : _isHovered
        ? MacosColors.accentHover
        : Colors.transparent;
    final border = widget.isSelected && !widget.isCurrent
        ? Border.all(color: MacosColors.accentBlue.withValues(alpha: 0.35))
        : null;
    final metadata = widget.track.metadata;
    final durationLabel =
        metadata.extras['Duration'] ?? metadata.extras['duration'] ?? '--:--';
    final titleStyle = TextStyle(
      color: widget.isCurrent ? MacosColors.accentBlue : Colors.white,
      fontSize: 14,
      fontWeight: widget.isCurrent ? FontWeight.w600 : FontWeight.w400,
    );
    const subtitleStyle = TextStyle(
      color: MacosColors.secondaryGrey,
      fontSize: 12,
    );
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
    final artwork = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? MacosColors.accentBlue.withValues(alpha: 0.8)
              : MacosColors.innerDivider,
        ),
        color: const Color(0xFF1B1B1B),
        image: bytes != null
            ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
            : null,
      ),
      child: bytes == null
          ? const Icon(Icons.music_note, color: Colors.white30, size: 18)
          : null,
    );
    if (!isCurrent) {
      return artwork;
    }
    return Stack(
      children: [
        artwork,
        const Positioned(
          right: 4,
          bottom: 4,
          child: Icon(Icons.graphic_eq, size: 14, color: Colors.white),
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
            color: isDisabled ? Colors.white24 : Colors.white70,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              inactiveTrackColor: MacosColors.divider,
              activeTrackColor: MacosColors.accentBlue,
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
            border: Border.all(color: MacosColors.innerDivider),
            color: const Color(0xFF1B1B1B),
            image: artwork != null
                ? DecorationImage(
                    image: MemoryImage(artwork),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: artwork == null
              ? const Icon(Icons.music_note, color: Colors.white38)
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MacosColors.secondaryGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
