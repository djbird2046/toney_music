import Cocoa
import FlutterMacOS
import MoodEngineSwift

@available(macOS 10.15, *)
public class MoodEnginePlugin: NSObject, FlutterPlugin {
  private let engine: MoodEngine

  public override init() {
    self.engine = DefaultMoodEngine()
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "mood_engine",
      binaryMessenger: registrar.messenger
    )
    let instance = MoodEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "collectSignals":
      Task {
        let signals = await engine.collectSignals()
        let payload = self.serialize(signals)
        DispatchQueue.main.async {
          result(payload)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func serialize(_ signals: MoodSignals) -> [String: Any] {
    return [
      "hour": signals.hour,
      "weekday": signals.weekday,
      "isHoliday": signals.isHoliday,
      "appearance": signals.appearance.rawValue,
      "batteryLevel": signals.batteryLevel,
      "isCharging": signals.isCharging,
      "isNetworkConnected": signals.isNetworkConnected,
      "networkType": signals.networkType.rawValue,
      "networkQuality": signals.networkQuality.rawValue,
      "headphonesConnected": signals.headphonesConnected,
    ]
  }
}
