import Foundation
import AudioEngineSwift

@objc final class AudioEngineBridge: NSObject {
    @objc static let shared = AudioEngineBridge()

    private override init() {}

    /// Placeholder hook so the Swift package is linked and ready when platform channels need it.
    @objc func prepareIfNeeded() {
        // Future platform-channel handlers can initialize AudioEngineSwift objects here.
    }
}
