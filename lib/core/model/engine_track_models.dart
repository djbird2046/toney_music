class EngineTrackFormatInfo {
  EngineTrackFormatInfo({
    required this.formatLabel,
    required this.bitrateKbps,
    required this.sampleRateHz,
    required this.channels,
    required this.bitDepth,
    this.channelDescription,
  });

  final String formatLabel;
  final double bitrateKbps;
  final double sampleRateHz;
  final int channels;
  final int bitDepth;
  final String? channelDescription;

  factory EngineTrackFormatInfo.fromJson(Map<String, dynamic> json) {
    return EngineTrackFormatInfo(
      formatLabel: (json['formatLabel'] as String?)?.trim().isNotEmpty == true
          ? json['formatLabel'] as String
          : 'Unknown',
      bitrateKbps: (json['bitrateKbps'] as num?)?.toDouble() ?? 0,
      sampleRateHz: (json['sampleRateHz'] as num?)?.toDouble() ?? 0,
      channels: (json['channels'] as num?)?.toInt() ?? 0,
      bitDepth: (json['bitDepth'] as num?)?.toInt() ?? 0,
      channelDescription: json['channelDescription'] as String?,
    );
  }

  String get bitrateLabel {
    if (bitrateKbps <= 0) return '--';
    return '${bitrateKbps.toStringAsFixed(0)} kbps';
  }

  String get sampleRateLabel {
    if (sampleRateHz <= 0) return '--';
    final kiloHz = sampleRateHz / 1000.0;
    final decimals = (kiloHz - kiloHz.truncateToDouble()).abs() < 0.001 ? 0 : 1;
    final formatted = kiloHz.toStringAsFixed(decimals);
    return '$formatted kHz';
  }

  String get channelsLabel {
    if (channelDescription != null && channelDescription!.isNotEmpty) {
      return channelDescription!;
    }
    if (channels <= 0) return '--';
    if (channels == 1) return 'mono';
    if (channels == 2) return 'stereo';
    return '$channels-ch';
  }
}

class EngineTrackTags {
  EngineTrackTags({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.comment,
    this.date,
    this.trackNumber,
    this.discNumber,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final String? comment;
  final String? date;
  final String? trackNumber;
  final String? discNumber;

  factory EngineTrackTags.fromJson(Map<String, dynamic> json) =>
      EngineTrackTags(
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        album: json['album'] as String?,
        albumArtist: json['albumArtist'] as String?,
        genre: json['genre'] as String?,
        comment: json['comment'] as String?,
        date: json['date'] as String?,
        trackNumber: json['trackNumber'] as String?,
        discNumber: json['discNumber'] as String?,
      );
}

class EngineTrackReplayGain {
  const EngineTrackReplayGain({
    this.trackGainDb,
    this.albumGainDb,
    this.trackPeak,
    this.albumPeak,
    this.r128TrackGain,
    this.r128AlbumGain,
  });

  final double? trackGainDb;
  final double? albumGainDb;
  final double? trackPeak;
  final double? albumPeak;
  final double? r128TrackGain;
  final double? r128AlbumGain;

  factory EngineTrackReplayGain.fromJson(Map<String, dynamic> json) {
    return EngineTrackReplayGain(
      trackGainDb: (json['trackGainDb'] as num?)?.toDouble(),
      albumGainDb: (json['albumGainDb'] as num?)?.toDouble(),
      trackPeak: (json['trackPeak'] as num?)?.toDouble(),
      albumPeak: (json['albumPeak'] as num?)?.toDouble(),
      r128TrackGain: (json['r128TrackGain'] as num?)?.toDouble(),
      r128AlbumGain: (json['r128AlbumGain'] as num?)?.toDouble(),
    );
  }

  bool get hasGain =>
      trackGainDb != null || albumGainDb != null || r128TrackGain != null;
}

class EngineTrackMetadata {
  EngineTrackMetadata({
    required this.url,
    required this.containerName,
    required this.codecName,
    required this.sourceBitrateKbps,
    required this.channelLayout,
    required this.durationMs,
    required this.pcm,
    required this.sampleFormatName,
    required this.fileSizeBytes,
    required this.startTimeSeconds,
    required this.tags,
    this.replayGain,
  });

  final String url;
  final String containerName;
  final String codecName;
  final double sourceBitrateKbps;
  final int channelLayout;
  final int durationMs;
  final EngineTrackFormatInfo pcm;
  final String sampleFormatName;
  final int fileSizeBytes;
  final double startTimeSeconds;
  final EngineTrackTags tags;
  final EngineTrackReplayGain? replayGain;

  factory EngineTrackMetadata.fromJson(Map<String, dynamic> json) {
    final pcmRaw = (json['pcm'] as Map?)?.cast<String, dynamic>();
    final tagsRaw = (json['tags'] as Map?)?.cast<String, dynamic>();
    final replayRaw = (json['replayGain'] as Map?)?.cast<String, dynamic>();
    return EngineTrackMetadata(
      url: json['url'] as String? ?? '',
      containerName: json['containerName'] as String? ?? 'Unknown',
      codecName: json['codecName'] as String? ?? 'Unknown',
      sourceBitrateKbps: (json['sourceBitrateKbps'] as num?)?.toDouble() ?? 0,
      channelLayout: (json['channelLayout'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      pcm: EngineTrackFormatInfo.fromJson(pcmRaw ?? const <String, dynamic>{}),
      sampleFormatName: json['sampleFormatName'] as String? ?? 'Unknown',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      startTimeSeconds: (json['startTimeSeconds'] as num?)?.toDouble() ?? 0,
      tags: EngineTrackTags.fromJson(tagsRaw ?? const <String, dynamic>{}),
      replayGain: replayRaw == null
          ? null
          : EngineTrackReplayGain.fromJson(replayRaw),
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}
