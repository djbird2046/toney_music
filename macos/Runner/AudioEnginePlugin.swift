import FlutterMacOS
import Cocoa
import AudioEngineSwift

public class AudioEnginePlugin: NSObject, FlutterPlugin {

    private let workQueue = DispatchQueue(label: "audio_engine_plugin")
    private var activeScopedURL: URL?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "audio_engine",
            binaryMessenger: registrar.messenger
        )
        let instance = AudioEnginePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall,
    result: @escaping FlutterResult) {

        func performAsync(_ action: @escaping () throws -> Void) {
            workQueue.async {
                do {
                    try action()
                    DispatchQueue.main.async {
                        result(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(self.flutterError(for: error, method: call.method))
                    }
                }
            }
        }

        switch call.method {

        case "load":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            let bookmarkData = (args["bookmark"] as? FlutterStandardTypedData)?.data
            performAsync {
                self.stopAccessingCurrentURL()
                let resolvedURL: URL
                if let bookmarkData = bookmarkData {
                    var isStale = false
                    resolvedURL = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                    if resolvedURL.startAccessingSecurityScopedResource() {
                        self.activeScopedURL = resolvedURL
                    }
                } else {
                    resolvedURL = URL(fileURLWithPath: path)
                }
                try AudioEngineFacade.shared.loadFile(url: resolvedURL)
            }

        case "play":
            performAsync {
                try AudioEngineFacade.shared.play()
            }

        case "pause":
            performAsync {
                try AudioEngineFacade.shared.pause()
            }

        case "stop":
            performAsync {
                try AudioEngineFacade.shared.stop()
                self.stopAccessingCurrentURL()
            }

        case "seek":
            guard let args = call.arguments as? [String: Any],
            let pos = args["positionMs"] as? Int else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            performAsync {
                try AudioEngineFacade.shared.seek(toMs: pos)
            }

        case "createBookmark":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            workQueue.async {
                do {
                    let url = URL(fileURLWithPath: path)
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    let data = try url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                    DispatchQueue.main.async {
                        result(FlutterStandardTypedData(bytes: data))
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NATIVE_ERROR",
                                            message: error.localizedDescription,
                                            details: call.method))
                    }
                }
            }

        case "trackInfo":
            workQueue.async {
                let info = AudioEngineFacade.shared.currentTrackInfo()?.toDictionary()
                DispatchQueue.main.async { result(info) }
            }

        case "trackMetadata":
            workQueue.async {
                let metadata = AudioEngineFacade.shared.currentTrackMetadata()?.toDictionary()
                DispatchQueue.main.async { result(metadata) }
            }

        case "trackUrl":
            workQueue.async {
                let url = AudioEngineFacade.shared.currentTrackURL()?.path
                DispatchQueue.main.async { result(url) }
            }

        case "pcmStatus":
            workQueue.async {
                let status = AudioEngineFacade.shared.pcmStatus().toDictionary()
                DispatchQueue.main.async { result(status) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func stopAccessingCurrentURL() {
        activeScopedURL?.stopAccessingSecurityScopedResource()
        activeScopedURL = nil
    }

    private func flutterError(for error: Error, method: String) -> FlutterError {
        if let engineError = error as? AudioEngineError {
            switch engineError {
            case .audioUnit(let status, let operation):
                return FlutterError(
                    code: "audio_unit_error",
                    message: "AudioUnit error during \(operation) (status: \(status))",
                    details: method
                )
            case .missingDevice:
                return FlutterError(
                    code: "device_unavailable",
                    message: "Audio output device unavailable",
                    details: method
                )
            case .decoderUnavailable(let message):
                return FlutterError(
                    code: "decoder_unavailable",
                    message: message.isEmpty ? "Decoder unavailable" : message,
                    details: method
                )
            }
        }
        return FlutterError(
            code: "native_error",
            message: error.localizedDescription,
            details: method
        )
    }
}

private extension TrackFormatInfo {
    func toDictionary() -> [String: Any] {
        [
            "formatLabel": formatLabel,
            "bitrateKbps": bitrateKbps,
            "sampleRateHz": sampleRateHz,
            "channels": channels,
            "bitDepth": bitDepth,
            "channelDescription": channelDescription,
        ]
    }
}

private extension TrackTags {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let title { dict["title"] = title }
        if let artist { dict["artist"] = artist }
        if let album { dict["album"] = album }
        if let albumArtist { dict["albumArtist"] = albumArtist }
        if let genre { dict["genre"] = genre }
        if let comment { dict["comment"] = comment }
        if let date { dict["date"] = date }
        if let trackNumber { dict["trackNumber"] = trackNumber }
        if let discNumber { dict["discNumber"] = discNumber }
        return dict
    }
}

private extension TrackReplayGain {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let trackGainDb { dict["trackGainDb"] = trackGainDb }
        if let albumGainDb { dict["albumGainDb"] = albumGainDb }
        if let trackPeak { dict["trackPeak"] = trackPeak }
        if let albumPeak { dict["albumPeak"] = albumPeak }
        if let r128TrackGain { dict["r128TrackGain"] = r128TrackGain }
        if let r128AlbumGain { dict["r128AlbumGain"] = r128AlbumGain }
        return dict
    }
}

private extension TrackMetadata {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "url": url.path,
            "containerName": containerName,
            "codecName": codecName,
            "sourceBitrateKbps": sourceBitrateKbps,
            "channelLayout": channelLayout,
            "durationMs": durationMs,
            "sampleFormatName": sampleFormatName,
            "fileSizeBytes": fileSizeBytes,
            "startTimeSeconds": startTimeSeconds,
        ]
        dict["pcm"] = pcm.toDictionary()
        dict["tags"] = tags.toDictionary()
        let replay = replayGain.toDictionary()
        if !replay.isEmpty {
            dict["replayGain"] = replay
        }
        return dict
    }
}

private extension PCMStatus {
    func toDictionary() -> [String: Any] {
        [
            "sampleRate": sampleRate,
            "channels": channels,
            "bitDepth": bitDepth,
            "bytesPerFrame": bytesPerFrame,
            "renderedFrames": renderedFrames,
            "underflows": underflows,
        ]
    }
}
