import Foundation

public protocol MoodEngine: Sendable {
    func collectSignals() async -> MoodSignals
}
