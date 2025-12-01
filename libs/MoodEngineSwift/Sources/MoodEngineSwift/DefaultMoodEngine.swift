import Foundation
import Network

#if os(iOS)
import UIKit
import AVFAudio
#elseif os(macOS)
import AppKit
#endif

@available(iOS 13.0, macOS 10.15, *)
public final class DefaultMoodEngine: MoodEngine {
    private let networkQueue = DispatchQueue(label: "com.toney.moodengine.network")

    public init() {}

    public func collectSignals() async -> MoodSignals {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isHoliday = Self.estimateHoliday(for: now, calendar: calendar)
        let appearance = Self.currentAppearance()
        let battery = Self.currentBatteryState()
        let network = await Self.currentNetworkState(queue: networkQueue)
        let headphones = Self.areHeadphonesConnected()

        return MoodSignals(
            hour: hour,
            weekday: weekday,
            isHoliday: isHoliday,
            appearance: appearance,
            batteryLevel: battery.level,
            isCharging: battery.isCharging,
            isNetworkConnected: network.connected,
            networkType: network.type,
            networkQuality: network.quality,
            headphonesConnected: headphones
        )
    }
}

@available(iOS 13.0, macOS 10.15, *)
private extension DefaultMoodEngine {
    struct BatteryState {
        let level: Float
        let isCharging: Bool
    }

    struct NetworkState {
        let connected: Bool
        let type: MoodSignals.NetworkType
        let quality: MoodSignals.NetworkQuality
    }

    static func estimateHoliday(for date: Date, calendar: Calendar) -> Bool {
        calendar.isDateInWeekend(date)
    }

    static func currentAppearance() -> MoodSignals.AppearanceMode {
#if os(iOS)
        let reader = {
            () -> MoodSignals.AppearanceMode in
            let style = UIScreen.main.traitCollection.userInterfaceStyle
            return style == .dark ? .dark : .light
        }
        return performOnMain(reader)
#elseif os(macOS)
        let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased()
        return style == "dark" ? .dark : .light
#endif
    }

    static func currentBatteryState() -> BatteryState {
#if os(iOS)
        let device = UIDevice.current
        let wasMonitoring = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        defer { device.isBatteryMonitoringEnabled = wasMonitoring }

        let rawLevel = device.batteryLevel
        let normalizedLevel: Float = rawLevel >= 0 ? rawLevel : 1.0
        let isCharging: Bool
        switch device.batteryState {
        case .charging, .full:
            isCharging = true
        default:
            isCharging = false
        }
        return BatteryState(level: normalizedLevel, isCharging: isCharging)
#elseif os(macOS)
        return BatteryState(level: 1.0, isCharging: true)
#endif
    }

    static func currentNetworkState(queue: DispatchQueue) async -> NetworkState {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                let connected = path.status == .satisfied
                let type: MoodSignals.NetworkType
                if !connected {
                    type = .offline
                } else if path.usesInterfaceType(.wifi) {
                    type = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    type = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    type = .ethernet
                } else {
                    type = .unknown
                }

                let quality: MoodSignals.NetworkQuality
                switch path.status {
                case .satisfied:
                    quality = path.isConstrained ? .average : .good
                case .requiresConnection:
                    quality = .average
                case .unsatisfied:
                    quality = .poor
                @unknown default:
                    quality = .unknown
                }

                monitor.cancel()
                continuation.resume(returning: NetworkState(
                    connected: connected,
                    type: type,
                    quality: quality
                ))
            }
            monitor.start(queue: queue)
        }
    }

    static func areHeadphonesConnected() -> Bool {
#if os(iOS)
        let checker = {
            () -> Bool in
            let session = AVAudioSession.sharedInstance()
            return session.currentRoute.outputs.contains { output in
                switch output.portType {
                case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                    return true
                default:
                    return false
                }
            }
        }
        return performOnMain(checker)
#elseif os(macOS)
        return false
#endif
    }

    static func performOnMain<T>(_ block: () -> T) -> T {
        if Thread.isMainThread {
            return block()
        }
        return DispatchQueue.main.sync(execute: block)
    }
}
