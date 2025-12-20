import Foundation
import FFmpegBridge

/// Swift wrapper around the FFmpeg C bridge.
final class FFmpegDecoder {
    enum SampleFormat {
        case int16
        case int32
        case float32
        case float64
        case unknown

        init(cFormat: FFDecSampleFormat) {
            switch cFormat {
            case FFDEC_SAMPLE_FMT_S16: self = .int16
            case FFDEC_SAMPLE_FMT_S32: self = .int32
            case FFDEC_SAMPLE_FMT_FLOAT: self = .float32
            case FFDEC_SAMPLE_FMT_DOUBLE: self = .float64
            default: self = .unknown
            }
        }

        var isFloat: Bool {
            switch self {
            case .float32, .float64: return true
            default: return false
            }
        }

        var displayLabel: String {
            switch self {
            case .int16: return "PCM"
            case .int32: return "PCM 32-bit"
            case .float32: return "PCM Float32"
            case .float64: return "PCM Float64"
            case .unknown: return "PCM"
            }
        }
    }

    private var handle: UnsafeMutablePointer<FFDecoderHandle>?
    let sampleRate: Int
    let channels: Int
    let bitDepth: Int
    let durationMs: Int
    let bytesPerFrame: Int
    let sampleFormat: SampleFormat
    let codecName: String
    let containerName: String
    let averageBitRate: Int64
    let channelLayout: UInt64
    let sampleFormatName: String
    let fileSizeBytes: Int64
    let startTimeSeconds: Double
    let title: String?
    let artist: String?
    let album: String?
    let albumArtist: String?
    let genre: String?
    let comment: String?
    let date: String?
    let trackNumber: String?
    let discNumber: String?
    let replayGainTrackDb: Double?
    let replayGainAlbumDb: Double?
    let replayPeakTrack: Double?
    let replayPeakAlbum: Double?
    let r128TrackGain: Double?
    let r128AlbumGain: Double?

    init?(url: URL) {
        let cHandle = url.withUnsafeFileSystemRepresentation { fsPath -> UnsafeMutablePointer<FFDecoderHandle>? in
            guard let fsPath else { return nil }
            return ffdecoder_open(fsPath)
        } ?? url.path.withCString { ffdecoder_open($0) }

        guard let cHandle else {
            return nil
        }
        self.handle = cHandle
        self.sampleRate = Int(ffdecoder_get_sample_rate(cHandle))
        self.channels = Int(ffdecoder_get_channels(cHandle))
        self.bitDepth = Int(ffdecoder_get_bit_depth(cHandle))
        self.durationMs = Int(ffdecoder_get_duration_ms(cHandle))
        self.bytesPerFrame = Int(ffdecoder_get_bytes_per_frame(cHandle))
        self.sampleFormat = SampleFormat(cFormat: ffdecoder_get_sample_format(cHandle))
        self.codecName = FFmpegDecoder.makeString(ffdecoder_get_codec_name(cHandle)) ?? "Unknown Codec"
        self.containerName = FFmpegDecoder.makeString(ffdecoder_get_container_name(cHandle)) ?? "Unknown Container"
        self.averageBitRate = ffdecoder_get_bit_rate(cHandle)
        self.channelLayout = ffdecoder_get_channel_layout(cHandle)
        self.sampleFormatName = FFmpegDecoder.makeString(ffdecoder_get_sample_format_name(cHandle)) ?? self.sampleFormat.displayLabel
        self.fileSizeBytes = ffdecoder_get_file_size_bytes(cHandle)
        self.startTimeSeconds = ffdecoder_get_start_time_seconds(cHandle)
        self.title = FFmpegDecoder.makeString(ffdecoder_get_tag_title(cHandle))
        self.artist = FFmpegDecoder.makeString(ffdecoder_get_tag_artist(cHandle))
        self.album = FFmpegDecoder.makeString(ffdecoder_get_tag_album(cHandle))
        self.albumArtist = FFmpegDecoder.makeString(ffdecoder_get_tag_album_artist(cHandle))
        self.genre = FFmpegDecoder.makeString(ffdecoder_get_tag_genre(cHandle))
        self.comment = FFmpegDecoder.makeString(ffdecoder_get_tag_comment(cHandle))
        self.date = FFmpegDecoder.makeString(ffdecoder_get_tag_date(cHandle))
        self.trackNumber = FFmpegDecoder.makeString(ffdecoder_get_tag_track(cHandle))
        self.discNumber = FFmpegDecoder.makeString(ffdecoder_get_tag_disc(cHandle))
        self.replayGainTrackDb = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_replaygain_track_gain(cHandle))
        self.replayGainAlbumDb = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_replaygain_album_gain(cHandle))
        self.replayPeakTrack = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_replaygain_track_peak(cHandle))
        self.replayPeakAlbum = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_replaygain_album_peak(cHandle))
        self.r128TrackGain = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_r128_track_gain(cHandle))
        self.r128AlbumGain = FFmpegDecoder.makeOptionalDouble(ffdecoder_get_r128_album_gain(cHandle))
    }

    func read(into buffer: UnsafeMutablePointer<UInt8>, maxBytes: Int) -> Int {
        guard let handle else { return 0 }
        let result = ffdecoder_read(handle, buffer, numericCast(maxBytes))
        if result < 0 {
            return 0
        }
        return result
    }

    func seek(toMs position: Int) {
        guard let handle else { return }
        _ = ffdecoder_seek_ms(handle, Int64(position))
    }

    func close() {
        if let handle {
            ffdecoder_close(handle)
            self.handle = nil
        }
    }

    deinit {
        close()
    }

    static var lastErrorMessage: String {
        guard let cString = ffdecoder_last_error() else { return "" }
        return String(cString: cString)
    }
}

extension FFmpegDecoder {
    var sourceBitrateKbps: Double {
        guard averageBitRate > 0 else { return 0 }
        return Double(averageBitRate) / 1000.0
    }

    private static func makeString(_ pointer: UnsafePointer<CChar>?) -> String? {
        guard let pointer, pointer.pointee != 0 else { return nil }
        return String(cString: pointer)
    }

    private static func makeOptionalDouble(_ value: Double) -> Double? {
        guard value.isFinite else { return nil }
        return value
    }
}
