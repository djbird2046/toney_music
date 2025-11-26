import Flutter
import UIKit
import AudioEngineSwift

public class AudioEnginePlugin: NSObject, FlutterPlugin {

    private let workQueue = DispatchQueue(label: "audio_engine_plugin")
    private var activeScopedURL: URL?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "audio_engine",
            binaryMessenger: registrar.messenger()
        )
        let instance = AudioEnginePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession error: \(error)")
        }
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
                        result(FlutterError(code: "NATIVE_ERROR",
                                            message: error.localizedDescription,
                                            details: call.method))
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
                AudioEngineFacade.shared.play()
            }

        case "pause":
            performAsync {
                AudioEngineFacade.shared.pause()
            }

        case "stop":
            performAsync {
                AudioEngineFacade.shared.stop()
                self.stopAccessingCurrentURL()
            }

        case "seek":
            guard let args = call.arguments as? [String: Any],
            let pos = args["positionMs"] as? Int else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            performAsync {
                AudioEngineFacade.shared.seek(toMs: pos)
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

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func stopAccessingCurrentURL() {
        activeScopedURL?.stopAccessingSecurityScopedResource()
        activeScopedURL = nil
    }
}
