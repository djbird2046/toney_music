import Foundation

/// Public facade to expose limited AudioEngine controls outside the package without
/// surfacing the entire implementation.
public final class AudioEngineFacade {
    nonisolated(unsafe) public static let shared = AudioEngineFacade()

    private let engine = AudioEngine.shared

    private init() {}

    @discardableResult
    public func loadFile(url: URL) throws -> Bool {
        try engine.loadFile(url: url)
        return true
    }

    public func play() throws {
        try engine.play()
    }

    public func pause() throws {
        try engine.pause()
    }

    public func stop() throws {
        try engine.stop()
    }

    public func seek(toMs position: Int) throws {
        try engine.seek(toMs: position)
    }

    public func currentTrackInfo() -> TrackFormatInfo? {
        engine.currentTrackInfo()
    }

    public func currentTrackMetadata() -> TrackMetadata? {
        engine.currentTrackMetadata()
    }

    public func currentTrackURL() -> URL? {
        engine.currentTrackURL()
    }

    public func setVolume(_ value: Double) throws {
        try engine.setVolume(value)
    }

    public func currentVolume() -> Double {
        engine.currentVolume()
    }

    public func setBitPerfectMode(enabled: Bool) throws {
        try engine.setBitPerfectMode(enabled: enabled)
    }

    public var onPlaybackEnded: (() -> Void)? {
        get { engine.onPlaybackEnded }
        set { engine.onPlaybackEnded = newValue }
    }

    public var isPlaying: Bool {
        engine.isPlaying
    }

    public var durationMs: Int {
        engine.durationMs
    }

    public var currentPositionMs: Int {
        engine.currentPositionMs
    }

    public func pcmStatus() -> PCMStatus {
        engine.getPCMStatus()
    }
}
