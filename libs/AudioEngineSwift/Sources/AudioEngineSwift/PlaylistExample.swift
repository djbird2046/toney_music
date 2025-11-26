import Foundation

public enum PlaylistExampleError: Error, LocalizedError {
    case emptyPlaylist
    case invalidIndex(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyPlaylist:
            return "Playlist is empty. Provide at least one local file path."
        case .invalidIndex(let index):
            return "No track at index \(index)."
        }
    }
}

/// Simple helper that demonstrates how to control the engine with a mutable
/// list of file-system paths. Update `playlistPaths` to point to the tracks you
/// want to audition, call `loadCurrentTrack()`, then drive playback.
public final class PlaylistExampleController {
    private let engine: AudioEngineFacade
    public var playlistPaths: [String] {
        didSet {
            guard !playlistPaths.isEmpty else {
                currentIndex = 0
                return
            }
            currentIndex = max(0, min(currentIndex, playlistPaths.count - 1))
        }
    }
    private var currentIndex: Int

    public init(playlistPaths: [String] = PlaylistExampleController.demoPaths,
                engine: AudioEngineFacade = .shared) {
        self.playlistPaths = playlistPaths
        self.engine = engine
        self.currentIndex = 0
    }

    /// Loads the file for the currently selected index.
    @discardableResult
    public func loadCurrentTrack() throws -> URL {
        guard !playlistPaths.isEmpty else { throw PlaylistExampleError.emptyPlaylist }
        let path = playlistPaths[currentIndex]
        let url = urlForPath(path)
        try engine.loadFile(url: url)
        return url
    }

    public func play() throws {
        try engine.play()
    }

    public func pause() throws {
        try engine.pause()
    }

    public func resume() throws {
        try engine.play()
    }

    public func stop() throws {
        try engine.stop()
    }

    /// Loads and selects the next track in the playlist (wrapping at the end).
    @discardableResult
    public func skipToNextTrack() throws -> URL {
        return try advanceTrackIndex(by: 1)
    }

    /// Loads and selects the previous track in the playlist (wrapping to the end).
    @discardableResult
    public func skipToPreviousTrack() throws -> URL {
        return try advanceTrackIndex(by: -1)
    }

    /// Loads and selects an arbitrary index in the playlist.
    @discardableResult
    public func selectTrack(at index: Int) throws -> URL {
        guard playlistPaths.indices.contains(index) else {
            throw PlaylistExampleError.invalidIndex(index)
        }
        currentIndex = index
        return try loadCurrentTrack()
    }

    /// Friendly title for the currently selected entry.
    public var currentTrackDisplayName: String? {
        guard !playlistPaths.isEmpty else { return nil }
        let url = URL(fileURLWithPath: playlistPaths[currentIndex])
        return url.lastPathComponent
    }

    /// Convenience string like "PCM 1411kbps 44100Hz stereo" for the active track.
    public var currentTrackSummary: String? {
        if let metadata = engine.currentTrackMetadata() {
            return metadata.overallSummary
        }
        return engine.currentTrackInfo()?.summary
    }

    public var currentTrackMetadata: TrackMetadata? {
        engine.currentTrackMetadata()
    }

    private func advanceTrackIndex(by offset: Int) throws -> URL {
        guard !playlistPaths.isEmpty else { throw PlaylistExampleError.emptyPlaylist }
        let count = playlistPaths.count
        currentIndex = (currentIndex + offset) % count
        if currentIndex < 0 { currentIndex += count }
        return try loadCurrentTrack()
    }

    private func urlForPath(_ path: String) -> URL {
        let expanded: String
        if path.hasPrefix("~") {
            expanded = (path as NSString).expandingTildeInPath
        } else {
            expanded = path
        }
        return URL(fileURLWithPath: expanded)
    }
}

public extension PlaylistExampleController {
    /// Placeholder paths you can copy or override when initializing
    /// `PlaylistExampleController`.
    static let demoPaths: [String] = [
        "/Users/you/Music/track-one.flac",
        "/Users/you/Music/track-two.wav",
        "/Users/you/Music/track-three.mp3",
    ]

    /// Minimal walkthrough for developers experimenting in a Playground or CLI tool.
    ///
    /// ```swift
    /// var controller = PlaylistExampleController()
    /// try controller.loadCurrentTrack()
    /// try controller.play()
    /// try controller.pause()
    /// try controller.resume()
    /// try controller.skipToNextTrack()
    /// ```
    static func runDemoSequence() {
        let controller = PlaylistExampleController()
        do {
            try controller.loadCurrentTrack()
            try controller.play()
            try controller.pause()
            try controller.resume()
            _ = try controller.skipToNextTrack()
            _ = try controller.skipToPreviousTrack()
            try controller.stop()
        } catch {
            print("Playlist demo failed: \(error)")
        }
    }
}
