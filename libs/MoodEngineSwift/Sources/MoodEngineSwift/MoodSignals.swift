import Foundation

public struct MoodSignals: Sendable {
    public enum AppearanceMode: String, Codable, Sendable {
        case light
        case dark
    }

    public enum NetworkType: String, Codable, Sendable {
        case wifi
        case cellular
        case ethernet
        case offline
        case unknown
    }

    public enum NetworkQuality: String, Codable, Sendable {
        case good
        case average
        case poor
        case unknown
    }

    public let hour: Int
    public let weekday: Int
    public let isHoliday: Bool
    public let appearance: AppearanceMode
    public let batteryLevel: Float
    public let isCharging: Bool
    public let isNetworkConnected: Bool
    public let networkType: NetworkType
    public let networkQuality: NetworkQuality
    public let headphonesConnected: Bool

    public init(
        hour: Int,
        weekday: Int,
        isHoliday: Bool,
        appearance: AppearanceMode,
        batteryLevel: Float,
        isCharging: Bool,
        isNetworkConnected: Bool,
        networkType: NetworkType,
        networkQuality: NetworkQuality,
        headphonesConnected: Bool
    ) {
        self.hour = hour
        self.weekday = weekday
        self.isHoliday = isHoliday
        self.appearance = appearance
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.isNetworkConnected = isNetworkConnected
        self.networkType = networkType
        self.networkQuality = networkQuality
        self.headphonesConnected = headphonesConnected
    }
}
