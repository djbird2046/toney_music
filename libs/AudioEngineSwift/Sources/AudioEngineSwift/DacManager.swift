import Foundation
import CoreAudio
import AudioToolbox
import Darwin
#if canImport(AppKit)
import AppKit
#endif

struct AudioDeviceInfo {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let sampleRates: [Double]
    let currentRate: Double
    let isHogged: Bool
}

enum DacManagerError: Error {
    case deviceNotFound
    case propertyError(OSStatus, String)
    case deviceBusy(pid_t?, String?)
}

extension DacManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Audio device not found"
        case .propertyError(let status, let op):
            return "\(op) failed (status: \(status))"
        case .deviceBusy(let pid, let name):
            if let name = name {
                if let pid = pid, pid > 0 {
                    return "\(name) (PID \(pid))"
                }
                return name
            }
            if let pid = pid, pid > 0 {
                return "PID \(pid)"
            }
            return "another application"
        }
    }
}

final class DacManager {
    nonisolated(unsafe) static let shared = DacManager()

    private let queue = DispatchQueue(label: "com.audioengine.dacmanager")
    private var activeDevice: AudioDeviceID?

    private init() {}

    private func hogOwnerInfo(id: AudioDeviceID) -> (pid_t, String?)? {
        var ownerPID = pid_t(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: ownerPID))
        guard AudioObjectGetPropertyData(id,
                                         &address,
                                         0,
                                         nil,
                                         &size,
                                         &ownerPID) == noErr else { return nil }
        guard ownerPID != 0 else { return nil }
        return (ownerPID, resolveProcessName(for: ownerPID))
    }

    func currentHogOwner(for id: AudioDeviceID?) -> (pid_t?, String?)? {
        queue.sync {
            let target: AudioDeviceID
            if let id, id != kAudioObjectUnknown {
                target = id
            } else if let defaultID = try? defaultOutputDeviceID() {
                target = defaultID
            } else {
                return nil
            }
            guard let info = hogOwnerInfo(id: target) else { return nil }
            return (info.0, info.1)
        }
    }

    func listOutputDevices() -> [AudioDeviceInfo] {
        return (try? queue.sync { try fetchAllDeviceInfos() }) ?? []
    }

    func getDefaultDevice() throws -> AudioDeviceInfo {
        return try queue.sync {
            let id = try defaultOutputDeviceID()
            return try buildDeviceInfo(id: id)
        }
    }

    func getDeviceInfo(id: AudioDeviceID) throws -> AudioDeviceInfo {
        return try queue.sync {
            guard deviceExists(id) else { throw DacManagerError.deviceNotFound }
            return try buildDeviceInfo(id: id)
        }
    }

    func setDevice(_ id: AudioDeviceID) throws {
        try queue.sync {
            guard deviceExists(id) else { throw DacManagerError.deviceNotFound }
            var newID = id
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            try checkStatus(AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                      &address,
                                                      0,
                                                      nil,
                                                      UInt32(MemoryLayout.size(ofValue: newID)),
                                                      &newID),
                            operation: "Set default output device")
            activeDevice = id
        }
    }

    func setSampleRate(_ rate: Double, for id: AudioDeviceID) throws {
        try queue.sync {
            if let hog = hogOwnerInfo(id: id), hog.0 != getpid() {
                throw DacManagerError.deviceBusy(hog.0, hog.1)
            }

            var mutableRate = rate
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyNominalSampleRate,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let status = AudioObjectSetPropertyData(id,
                                                    &address,
                                                    0,
                                                    nil,
                                                    UInt32(MemoryLayout.size(ofValue: mutableRate)),
                                                    &mutableRate)
            if status == kAudioHardwareIllegalOperationError {
                if let hog = hogOwnerInfo(id: id), hog.0 != getpid() {
                    throw DacManagerError.deviceBusy(hog.0, hog.1)
                }
            }
            try checkStatus(status, operation: "Set sample rate")
        }
    }

    func ensureSampleRateMatches(format: PCMFormat) throws {
        try queue.sync {
            let targetDevice = activeDevice ?? (try? defaultOutputDeviceID()) ?? kAudioObjectUnknown
            guard targetDevice != kAudioObjectUnknown else { throw DacManagerError.deviceNotFound }
            let info = try buildDeviceInfo(id: targetDevice)
            if abs(info.currentRate - format.sampleRate) > 0.1 {
                try setSampleRate(format.sampleRate, for: targetDevice)
            }
        }
    }

    func acquireHogMode(_ id: AudioDeviceID) throws {
        try queue.sync {
            if let hog = hogOwnerInfo(id: id) {
                if hog.0 == getpid() {
                    return
                }
                throw DacManagerError.deviceBusy(hog.0, hog.1)
            }

            var newPID = getpid()
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyHogMode,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let status = AudioObjectSetPropertyData(id,
                                                    &address,
                                                    0,
                                                    nil,
                                                    UInt32(MemoryLayout.size(ofValue: newPID)),
                                                    &newPID)
            if status == kAudioHardwareIllegalOperationError {
                if let hog = hogOwnerInfo(id: id) {
                    throw DacManagerError.deviceBusy(hog.0, hog.1)
                }
            }
            try checkStatus(status, operation: "Acquire hog mode")
        }
    }

    func releaseHogMode(_ id: AudioDeviceID) throws {
        try queue.sync {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyHogMode,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var zero: pid_t = 0
            try checkStatus(AudioObjectSetPropertyData(id,
                                                       &address,
                                                       0,
                                                       nil,
                                                       UInt32(MemoryLayout.size(ofValue: zero)),
                                                       &zero),
                            operation: "Release hog mode")
        }
    }

    // MARK: - Helpers

    private func fetchAllDeviceInfos() throws -> [AudioDeviceInfo] {
        let ids = try fetchOutputDeviceIDs()
        return try ids.map { try buildDeviceInfo(id: $0) }
    }

    private func fetchOutputDeviceIDs() throws -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        try checkStatus(AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                                       &address,
                                                       0,
                                                       nil,
                                                       &dataSize),
                        operation: "Get device list size")
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        try checkStatus(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                   &address,
                                                   0,
                                                   nil,
                                                   &dataSize,
                                                   &devices),
                        operation: "Get device list")
        return devices.filter { deviceHasOutput($0) }
    }

    private func deviceHasOutput(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        var size: UInt32 = 0
        if AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) != noErr {
            return false
        }
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { buffer.deallocate() }
        if AudioObjectGetPropertyData(id, &address, 0, nil, &size, buffer) != noErr {
            return false
        }
        let abl = buffer.bindMemory(to: AudioBufferList.self, capacity: 1)
        let list = UnsafeMutableAudioBufferListPointer(abl)
        var channelCount = 0
        for buf in list {
            channelCount += Int(buf.mNumberChannels)
        }
        return channelCount > 0
    }

    private func buildDeviceInfo(id: AudioDeviceID) throws -> AudioDeviceInfo {
        let name = try deviceName(id: id)
        let uid = try deviceUID(id: id)
        let sampleRates = try availableSampleRates(id: id)
        let currentRate = try nominalSampleRate(id: id)
        let hogged = try isDeviceHogged(id: id)
        return AudioDeviceInfo(id: id,
                               uid: uid,
                               name: name,
                               sampleRates: sampleRates,
                               currentRate: currentRate,
                               isHogged: hogged)
    }

    private func deviceName(id: AudioDeviceID) throws -> String {
        var cfName: CFString = "" as CFString
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: cfName))
        try withUnsafeMutablePointer(to: &cfName) { pointer in
            try checkStatus(AudioObjectGetPropertyData(id,
                                                       &address,
                                                       0,
                                                       nil,
                                                       &size,
                                                       UnsafeMutableRawPointer(pointer)),
                            operation: "Get device name")
        }
        return cfName as String
    }

    private func deviceUID(id: AudioDeviceID) throws -> String {
        var cfUID: CFString = "" as CFString
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: cfUID))
        try withUnsafeMutablePointer(to: &cfUID) { pointer in
            try checkStatus(AudioObjectGetPropertyData(id,
                                                       &address,
                                                       0,
                                                       nil,
                                                       &size,
                                                       UnsafeMutableRawPointer(pointer)),
                            operation: "Get device UID")
        }
        return cfUID as String
    }

    private func availableSampleRates(id: AudioDeviceID) throws -> [Double] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        try checkStatus(AudioObjectGetPropertyDataSize(id,
                                                       &address,
                                                       0,
                                                       nil,
                                                       &size),
                        operation: "Get sample rate range size")
        let count = Int(size) / MemoryLayout<AudioValueRange>.size
        var ranges = [AudioValueRange](repeating: AudioValueRange(mMinimum: 0, mMaximum: 0), count: count)
        try checkStatus(AudioObjectGetPropertyData(id,
                                                   &address,
                                                   0,
                                                   nil,
                                                   &size,
                                                   &ranges),
                        operation: "Get sample rate ranges")
        var rates: [Double] = []
        for range in ranges {
            if range.mMinimum == range.mMaximum {
                rates.append(range.mMinimum)
            } else {
                rates.append(range.mMinimum)
                rates.append(range.mMaximum)
            }
        }
        return Array(Set(rates)).sorted()
    }

    private func nominalSampleRate(id: AudioDeviceID) throws -> Double {
        var rate = Double(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: rate))
        try checkStatus(AudioObjectGetPropertyData(id,
                                                   &address,
                                                   0,
                                                   nil,
                                                   &size,
                                                   &rate),
                        operation: "Get sample rate")
        return rate
    }

    private func isDeviceHogged(id: AudioDeviceID) throws -> Bool {
        var pid = pid_t(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: pid))
        try checkStatus(AudioObjectGetPropertyData(id,
                                                   &address,
                                                   0,
                                                   nil,
                                                   &size,
                                                   &pid),
                        operation: "Read hog mode")
        return pid != 0 && pid != getpid()
    }

    private func defaultOutputDeviceID() throws -> AudioDeviceID {
        var device = AudioDeviceID(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout.size(ofValue: device))
        try checkStatus(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                   &address,
                                                   0,
                                                   nil,
                                                   &size,
                                                   &device),
                        operation: "Get default output device")
        guard device != kAudioObjectUnknown else { throw DacManagerError.deviceNotFound }
        return device
    }

    private func deviceExists(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        return AudioObjectHasProperty(id, &address)
    }

    private func checkStatus(_ status: OSStatus, operation: String) throws {
        guard status == noErr else { throw DacManagerError.propertyError(status, operation) }
    }

    private func resolveProcessName(for pid: pid_t) -> String? {
        #if canImport(AppKit)
        if let app = NSRunningApplication(processIdentifier: pid) {
            return app.localizedName
        }
        #endif
        var pathBuffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let result = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        if result > 0 {
            let path = String(cString: pathBuffer)
            if let name = path.split(separator: "/").last {
                return String(name)
            }
            return path
        }
        return nil
    }
}
