import Foundation

/// Lightweight description of the currently loaded track's PCM settings.
public struct TrackFormatInfo: Sendable {
    public let formatLabel: String
    public let bitrateKbps: Double
    public let sampleRateHz: Double
    public let channels: UInt32
    public let bitDepth: UInt32

    public init(formatLabel: String,
                bitrateKbps: Double,
                sampleRateHz: Double,
                channels: UInt32,
                bitDepth: UInt32) {
        self.formatLabel = formatLabel
        self.bitrateKbps = bitrateKbps
        self.sampleRateHz = sampleRateHz
        self.channels = channels
        self.bitDepth = bitDepth
    }

    public var channelDescription: String {
        switch channels {
        case 1: return "mono"
        case 2: return "stereo"
        default: return "\(channels)-ch"
        }
    }

    public var summary: String {
        let kbpsValue = Int(bitrateKbps.rounded())
        let hzValue = Int(sampleRateHz.rounded())
        return "\(formatLabel) \(kbpsValue)kbps \(hzValue)Hz \(channelDescription)"
    }
}

extension PCMFormat {
    var bitrateKbps: Double {
        guard bitDepth > 0 else { return 0 }
        return (sampleRate * Double(bitDepth) * Double(channels)) / 1000.0
    }

    func toTrackFormatInfo(formatLabel: String) -> TrackFormatInfo {
        TrackFormatInfo(formatLabel: formatLabel,
                        bitrateKbps: bitrateKbps,
                        sampleRateHz: sampleRate,
                        channels: channels,
                        bitDepth: bitDepth)
    }
}

public struct TrackTags: Sendable {
    public let title: String?
    public let artist: String?
    public let album: String?
    public let albumArtist: String?
    public let genre: String?
    public let comment: String?
    public let date: String?
    public let trackNumber: String?
    public let discNumber: String?

    public init(title: String?,
                artist: String?,
                album: String?,
                albumArtist: String?,
                genre: String?,
                comment: String?,
                date: String?,
                trackNumber: String?,
                discNumber: String?) {
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.genre = genre
        self.comment = comment
        self.date = date
        self.trackNumber = trackNumber
        self.discNumber = discNumber
    }

    public static let empty = TrackTags(title: nil,
                                        artist: nil,
                                        album: nil,
                                        albumArtist: nil,
                                        genre: nil,
                                        comment: nil,
                                        date: nil,
                                        trackNumber: nil,
                                        discNumber: nil)

    public func displayTitle(fallback: String) -> String {
        title ?? fallback
    }
}

public struct TrackReplayGain: Sendable {
    public let trackGainDb: Double?
    public let albumGainDb: Double?
    public let trackPeak: Double?
    public let albumPeak: Double?
    public let r128TrackGain: Double?
    public let r128AlbumGain: Double?

    public init(trackGainDb: Double?,
                albumGainDb: Double?,
                trackPeak: Double?,
                albumPeak: Double?,
                r128TrackGain: Double?,
                r128AlbumGain: Double?) {
        self.trackGainDb = trackGainDb
        self.albumGainDb = albumGainDb
        self.trackPeak = trackPeak
        self.albumPeak = albumPeak
        self.r128TrackGain = r128TrackGain
        self.r128AlbumGain = r128AlbumGain
    }

    public var hasAnyValue: Bool {
        return trackGainDb != nil || albumGainDb != nil || r128TrackGain != nil || r128AlbumGain != nil
    }
}

/// Aggregated metadata describing the active track, combining container
/// information, codec details, PCM format insights, and tagged attributes.
public struct TrackMetadata: Sendable {
    public let url: URL
    public let containerName: String
    public let codecName: String
    public let sourceBitrateKbps: Double
    public let channelLayout: UInt64
    public let durationMs: Int
    public let pcm: TrackFormatInfo
    public let sampleFormatName: String
    public let fileSizeBytes: Int64
    public let startTimeSeconds: Double
    public let tags: TrackTags
    public let replayGain: TrackReplayGain

    public init(url: URL,
                containerName: String,
                codecName: String,
                sourceBitrateKbps: Double,
                channelLayout: UInt64,
                durationMs: Int,
                pcm: TrackFormatInfo,
                sampleFormatName: String,
                fileSizeBytes: Int64,
                startTimeSeconds: Double,
                tags: TrackTags,
                replayGain: TrackReplayGain) {
        self.url = url
        self.containerName = containerName
        self.codecName = codecName
        self.sourceBitrateKbps = sourceBitrateKbps
        self.channelLayout = channelLayout
        self.durationMs = durationMs
        self.pcm = pcm
        self.sampleFormatName = sampleFormatName
        self.fileSizeBytes = fileSizeBytes
        self.startTimeSeconds = startTimeSeconds
        self.tags = tags
        self.replayGain = replayGain
    }

    public var formattedSourceBitrate: String {
        let value = Int(sourceBitrateKbps.rounded())
        return value > 0 ? "\(value)kbps" : "unknown kbps"
    }

    public var durationDescription: String {
        guard durationMs > 0 else { return "live" }
        let totalSeconds = durationMs / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    public var displayTitle: String {
        tags.displayTitle(fallback: url.lastPathComponent)
    }

    public var fileSizeDescription: String? {
        guard fileSizeBytes > 0 else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSizeBytes)
    }

    public var overallSummary: String {
        var components = [String]()
        components.append(displayTitle)
        components.append(codecName)
        components.append(pcm.summary)
        if sourceBitrateKbps > 0 {
            components.append("src \(formattedSourceBitrate)")
        }
        if let fileSizeDescription {
            components.append(fileSizeDescription)
        }
        return components.joined(separator: " | ")
    }
}
