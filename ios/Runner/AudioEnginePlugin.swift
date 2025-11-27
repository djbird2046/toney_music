import Flutter
import UIKit
import AudioEngineSwift

public class AudioEnginePlugin: NSObject, FlutterPlugin {

    private let workQueue = DispatchQueue(label: "audio_engine_plugin")

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
            performAsync {
                let url = URL(fileURLWithPath: path)
                try AudioEngineFacade.shared.loadFile(url: url)
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
            }

        case "seek":
            guard let args = call.arguments as? [String: Any],
            let pos = args["positionMs"] as? Int else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            performAsync {
                AudioEngineFacade.shared.seek(toMs: pos)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
