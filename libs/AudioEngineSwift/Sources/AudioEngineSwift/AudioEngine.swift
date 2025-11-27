import Foundation
import AudioToolbox
import CoreAudio
import os
import Darwin
import Atomics

public enum AudioEngineError: Error {
    case audioUnit(OSStatus, String)
    case missingDevice
    case decoderUnavailable(String)
}

extension AudioEngineError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioUnit(let status, let operation):
            return "AudioUnit error (\(operation)): \(status)"
        case .missingDevice:
            return "Audio output device unavailable"
        case .decoderUnavailable(let message):
            return message.isEmpty ? "Decoder unavailable" : message
        }
    }
}

final class LockFreeRingBuffer {
    private let capacity: Int
    private let mask: Int
    private var storage: ContiguousArray<UInt8>

    private let writeHead = ManagedAtomic<Int>(0)
    private let readHead = ManagedAtomic<Int>(0)

    init(capacity: Int) {
        let rounded = LockFreeRingBuffer.nextPowerOfTwo(max(1024, capacity))
        self.capacity = rounded
        self.mask = rounded - 1
        self.storage = ContiguousArray<UInt8>(repeating: 0, count: rounded)
    }

    @inline(__always)
    private static func nextPowerOfTwo(_ value: Int) -> Int {
        var v = 1
        while v < value { v <<= 1 }
        return v
    }

    @discardableResult
    func write(from samples: UnsafePointer<UInt8>, count: Int) -> Int {
        guard count > 0 else { return 0 }

        let localWrite = writeHead.load(ordering: .acquiring)
        let localRead = readHead.load(ordering: .acquiring)

        let used = localWrite &- localRead
        let available = capacity &- used
        if available <= 0 { return 0 }

        let samplesToWrite = min(count, available)

        storage.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            var headIndex = localWrite & mask
            var remaining = samplesToWrite
            var source = samples

            while remaining > 0 {
                let chunk = min(remaining, capacity &- headIndex)
                baseAddress.advanced(by: headIndex).update(from: source, count: chunk)
                source = source.advanced(by: chunk)
                headIndex = (headIndex &+ chunk) & mask
                remaining &-= chunk
            }
        }

        writeHead.wrappingIncrement(by: samplesToWrite, ordering: .releasing)
        return samplesToWrite
    }

    @discardableResult
    func read(into destination: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        guard count > 0 else { return 0 }

        let localWrite = writeHead.load(ordering: .acquiring)
        let localRead = readHead.load(ordering: .acquiring)

        let available = localWrite &- localRead
        if available <= 0 { return 0 }

        let samplesToRead = min(count, available)

        storage.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            var tailIndex = localRead & mask
            var remaining = samplesToRead
            var target = destination

            while remaining > 0 {
                let chunk = min(remaining, capacity &- tailIndex)
                target.update(from: baseAddress.advanced(by: tailIndex), count: chunk)
                target = target.advanced(by: chunk)
                tailIndex = (tailIndex &+ chunk) & mask
                remaining &-= chunk
            }
        }

        readHead.wrappingIncrement(by: samplesToRead, ordering: .releasing)
        return samplesToRead
    }

    func reset() {
        writeHead.store(0, ordering: .relaxed)
        readHead.store(0, ordering: .relaxed)
    }

    /// Returns the number of bytes currently available in the buffer for reading.
    var availableBytes: Int {
        let localWrite = writeHead.load(ordering: .acquiring)
        let localRead = readHead.load(ordering: .acquiring)
        return max(0, localWrite &- localRead)
    }
}

struct PCMFormat {
    var sampleRate: Double
    var channels: UInt32
    var bitDepth: UInt32
    var isFloat: Bool

    var bytesPerFrame: UInt32 {
        max(1, bitDepth / 8) * channels
    }
}

public struct PCMStatus: Sendable {
    public let sampleRate: Double
    public let channels: UInt32
    public let bitDepth: UInt32
    public let bytesPerFrame: UInt32
    public let renderedFrames: Int
    public let underflows: Int
}

final class AudioEngine {
    nonisolated(unsafe) static let shared = AudioEngine()

    private enum PlaybackState { case stopped, playing, paused }

    /// Minimum bytes to buffer before starting playback to prevent initial underruns.
    /// 512KB provides approximately 1s buffer at 48kHz/32bit/2ch or 0.35s at 192kHz/32bit/2ch.
    private static let prebufferThreshold: Int = 512 * 1024
    
    /// Maximum time to wait for prebuffering before starting playback anyway.
    private static let prebufferTimeoutSeconds: Double = 3.0

    private let controlQueue = DispatchQueue(label: "com.audioengine.control")
    // Use high priority for decoder to ensure it can keep up with playback
    private let decoderQueue = DispatchQueue(label: "com.audioengine.decoder", qos: .userInteractive)
    private let logger = Logger(subsystem: "com.audioengine.hires", category: "engine")
    private let pcmPlayer = PCMPlayer(bufferSize: 1 << 22)  // 4MB buffer for high-res audio
    private let dac = DacManager.shared

    private var audioUnit: AudioUnit?
    private var deviceID: AudioDeviceID = kAudioObjectUnknown
    private var hoggedDevice: AudioDeviceID = kAudioObjectUnknown
    private var playbackState: PlaybackState = .stopped

    private var decoder: FFmpegDecoder?
    private var decoderWorkItem: DispatchWorkItem?
    private var decoderShouldStop = false

    private var currentFormat = PCMFormat(sampleRate: 48_000,
                                          channels: 2,
                                          bitDepth: 32,
                                          isFloat: true)
    private var currentSampleFormat: FFmpegDecoder.SampleFormat = .unknown
    private var currentCodecName: String = "Unknown Codec"
    private var currentContainerName: String = "Unknown Container"
    private var currentSourceBitRateKbps: Double = 0
    private var currentChannelLayout: UInt64 = 0
    private var currentSampleFormatName: String = ""
    private var currentFileSizeBytes: Int64 = 0
    private var currentStartTimeSeconds: Double = 0
    private var currentTags: TrackTags = .empty
    private var currentReplayGain = TrackReplayGain(trackGainDb: nil,
                                                    albumGainDb: nil,
                                                    trackPeak: nil,
                                                    albumPeak: nil,
                                                    r128TrackGain: nil,
                                                    r128AlbumGain: nil)
    private var currentMetadata: TrackMetadata?
    private var fileDurationEstimateMs: Int = 0
    private var currentFileURL: URL?

    private init() {}

    deinit {
        controlQueue.sync {
            internalStop()
            stopDecoderLocked()
            tearDownAudioUnitLocked()
        }
    }

    func initialize() {}

    func loadFile(url: URL) throws {
        try controlQueue.sync {
            logger.info("Loading file: \(url.lastPathComponent, privacy: .public)")

            internalStop()
            // Tear down AudioUnit to prevent render callbacks from using stale format during update
            tearDownAudioUnitLocked()
            // Reset buffer first to unblock decoder if it's stuck in pushBytes due to full buffer
            pcmPlayer.reset()
            stopDecoderLocked()
            currentMetadata = nil

            guard let decoder = FFmpegDecoder(url: url) else {
                let message = FFmpegDecoder.lastErrorMessage
                logger.error("Failed to create decoder for \(url.lastPathComponent, privacy: .public)")
                throw AudioEngineError.decoderUnavailable(message)
            }

            currentFileURL = url
            self.decoder = decoder

            currentFormat = PCMFormat(sampleRate: Double(decoder.sampleRate),
                                      channels: UInt32(decoder.channels),
                                      bitDepth: UInt32(decoder.bitDepth),
                                      isFloat: decoder.sampleFormat.isFloat)
            currentSampleFormat = decoder.sampleFormat
            currentCodecName = decoder.codecName
            currentContainerName = decoder.containerName
            currentSourceBitRateKbps = decoder.sourceBitrateKbps
            currentChannelLayout = decoder.channelLayout
            currentSampleFormatName = decoder.sampleFormatName
            currentFileSizeBytes = decoder.fileSizeBytes
            currentStartTimeSeconds = decoder.startTimeSeconds
            currentTags = TrackTags(title: decoder.title,
                                    artist: decoder.artist,
                                    album: decoder.album,
                                    albumArtist: decoder.albumArtist,
                                    genre: decoder.genre,
                                    comment: decoder.comment,
                                    date: decoder.date,
                                    trackNumber: decoder.trackNumber,
                                    discNumber: decoder.discNumber)
            currentReplayGain = TrackReplayGain(trackGainDb: decoder.replayGainTrackDb,
                                                albumGainDb: decoder.replayGainAlbumDb,
                                                trackPeak: decoder.replayPeakTrack,
                                                albumPeak: decoder.replayPeakAlbum,
                                                r128TrackGain: decoder.r128TrackGain,
                                                r128AlbumGain: decoder.r128AlbumGain)
            pcmPlayer.setFormat(currentFormat)

            fileDurationEstimateMs = decoder.durationMs

            let pcmInfo = currentFormat.toTrackFormatInfo(formatLabel: decoder.sampleFormat.displayLabel)
            currentMetadata = TrackMetadata(url: url,
                                            containerName: decoder.containerName,
                                            codecName: decoder.codecName,
                                            sourceBitrateKbps: decoder.sourceBitrateKbps,
                                            channelLayout: decoder.channelLayout,
                                            durationMs: fileDurationEstimateMs,
                                            pcm: pcmInfo,
                                            sampleFormatName: decoder.sampleFormatName,
                                            fileSizeBytes: decoder.fileSizeBytes,
                                            startTimeSeconds: decoder.startTimeSeconds,
                                            tags: currentTags,
                                            replayGain: currentReplayGain)

            do {
                try syncDeviceConfigurationLocked()
            } catch {
                logger.error("Failed to sync device with decoder: \(error.localizedDescription, privacy: .public)")
                throw error
            }

            startDecoderLoopLocked()
        }
    }

    func play() throws {
        // First, wait for prebuffer outside of controlQueue to avoid blocking
        // This allows decoder to continue filling buffer without contention
        let needsPrebuffer = controlQueue.sync { () -> Bool in
            guard decoder != nil else { return false }
            // Only need prebuffer if buffer is low (not resuming from pause with data)
            return pcmPlayer.bufferedBytes < Self.prebufferThreshold
        }
        
        if needsPrebuffer {
            waitForPrebuffer()
        }
        
        // Now start playback with controlQueue locked
        try controlQueue.sync {
            guard decoder != nil else {
                logger.error("Decoder not ready. Call loadFile(url:) before play().")
                throw AudioEngineError.decoderUnavailable("Call loadFile(url:) before play().")
            }
            guard playbackState != .playing else { return }

            try prepareAudioUnitLocked()
            try startAudioOutputLocked()
            playbackState = .playing
            logger.info("Playback started with \(self.pcmPlayer.bufferedBytes) bytes in buffer")
        }
    }
    
    /// Waits until the buffer has enough data or timeout is reached.
    /// This prevents audio underruns at playback start.
    /// Called outside of controlQueue to allow decoder to continue working.
    private func waitForPrebuffer() {
        let startTime = Date()
        let threshold = Self.prebufferThreshold
        let timeout = Self.prebufferTimeoutSeconds
        
        logger.info("Waiting for prebuffer (target: \(threshold) bytes)...")
        
        while pcmPlayer.bufferedBytes < threshold {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= timeout {
                logger.warning("Prebuffer timeout after \(String(format: "%.2f", elapsed))s with \(self.pcmPlayer.bufferedBytes) bytes buffered")
                break
            }
            // Short sleep to avoid busy-waiting
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        let buffered = pcmPlayer.bufferedBytes
        let bufferSeconds = Double(buffered) / Double(max(1, currentFormat.bytesPerFrame)) / currentFormat.sampleRate
        logger.info("Prebuffer complete: \(buffered) bytes (\(String(format: "%.2f", bufferSeconds))s)")
    }

    func pause() throws {
        try controlQueue.sync {
            guard playbackState == .playing else { return }
            if let unit = audioUnit {
                try checkStatus(AudioOutputUnitStop(unit), operation: "AudioOutputUnitStop")
            }
            playbackState = .paused
            releaseHogModeIfNeededLocked()
        }
    }

    func stop() throws {
        try controlQueue.sync {
            try stopPlaybackLocked()
            pcmPlayer.reset()
            stopDecoderLocked()
        }
    }

    func seek(toMs position: Int) throws {
        let wasPlaying = controlQueue.sync { playbackState == .playing }
        
        // Temporarily pause audio output during seek to prevent glitches
        if wasPlaying {
            try controlQueue.sync {
                if let unit = audioUnit {
                    try checkStatus(AudioOutputUnitStop(unit), operation: "AudioOutputUnitStop (seek)")
                }
            }
        }
        
        // Perform seek and reset buffer
        try controlQueue.sync {
            guard let decoder else {
                throw AudioEngineError.decoderUnavailable("Cannot seek without an active decoder")
            }
            decoder.seek(toMs: position)
            pcmPlayer.reset()
        }
        
        // Wait for some data to be buffered before resuming
        if wasPlaying {
            // Use smaller threshold for seek to reduce perceived latency
            let seekBufferThreshold = min(Self.prebufferThreshold / 2, 256 * 1024)
            let startTime = Date()
            let timeout: TimeInterval = 1.0
            
            while pcmPlayer.bufferedBytes < seekBufferThreshold {
                if Date().timeIntervalSince(startTime) >= timeout {
                    logger.warning("Seek prebuffer timeout")
                    break
                }
                Thread.sleep(forTimeInterval: 0.005)
            }
            
            // Resume playback
            try controlQueue.sync {
                guard let unit = audioUnit else { return }
                try checkStatus(AudioOutputUnitStart(unit), operation: "AudioOutputUnitStart (seek resume)")
            }
            
            logger.info("Seek complete, resumed with \(self.pcmPlayer.bufferedBytes) bytes buffered")
        }
    }

    func setOutputDevice(id: AudioDeviceID) throws {
        try controlQueue.sync {
            guard deviceID != id else { return }
            releaseHogModeIfNeededLocked()
            try dac.setDevice(id)
            deviceID = id
            try syncDeviceConfigurationLocked()
        }
    }

    var currentPositionMs: Int {
        controlQueue.sync {
            guard currentFormat.bytesPerFrame > 0 else { return 0 }
            let frames = pcmPlayer.renderedFrames
            return Int((Double(frames) / currentFormat.sampleRate) * 1000.0)
        }
    }

    var durationMs: Int {
        controlQueue.sync { fileDurationEstimateMs }
    }

    var isPlaying: Bool {
        controlQueue.sync { playbackState == .playing }
    }

    func getPCMStatus() -> PCMStatus {
        controlQueue.sync {
            PCMStatus(sampleRate: currentFormat.sampleRate,
                      channels: currentFormat.channels,
                      bitDepth: currentFormat.bitDepth,
                      bytesPerFrame: currentFormat.bytesPerFrame,
                      renderedFrames: pcmPlayer.renderedFrames,
                      underflows: pcmPlayer.underflows)
        }
    }

    func currentTrackInfo() -> TrackFormatInfo? {
        controlQueue.sync { currentMetadata?.pcm }
    }

    func currentTrackURL() -> URL? {
        controlQueue.sync { currentMetadata?.url }
    }

    func currentTrackMetadata() -> TrackMetadata? {
        controlQueue.sync { currentMetadata }
    }

    private func startDecoderLoopLocked() {
        decoderShouldStop = false

        let workItem = DispatchWorkItem { [weak self] in
            self?.decoderLoop()
        }

        decoderWorkItem = workItem

        if let decoder = decoder {
            logger.info("Decoder primed at \(decoder.sampleRate) Hz / \(decoder.channels) ch")
        }

        decoderQueue.async(execute: workItem)
    }

    private func decoderLoop() {
        guard let decoder else { return }

        // Use larger chunk size for better decoding efficiency
        // 16384 frames provides good balance between latency and throughput for high-res audio
        let chunkSize = max(Int(currentFormat.bytesPerFrame) * 16384, 65536)
        var scratch = [UInt8](repeating: 0, count: chunkSize)
        var consecutiveEmptyReads = 0
        let maxConsecutiveEmptyReads = 100  // ~100ms of empty reads before logging
        var totalBytesDecoded: Int64 = 0
        let startTime = Date()
        var lastLogTime = startTime

        logger.info("Decoder loop started. ChunkSize=\(chunkSize), Format=\(self.currentFormat.sampleRate)Hz/\(self.currentFormat.bitDepth)bit/\(self.currentFormat.channels)ch")

        while !decoderShouldStop {
            let decodeStart = Date()
            let bytesRead: Int = scratch.withUnsafeMutableBufferPointer { buffer in
                guard let base = buffer.baseAddress else { return 0 }
                return decoder.read(into: base, maxBytes: buffer.count)
            }
            let decodeTime = Date().timeIntervalSince(decodeStart)

            if bytesRead <= 0 {
                consecutiveEmptyReads += 1
                if consecutiveEmptyReads >= maxConsecutiveEmptyReads {
                    if consecutiveEmptyReads == maxConsecutiveEmptyReads {
                        logger.debug("Decoder waiting for data (possible EOF)")
                    }
                }
                Thread.sleep(forTimeInterval: 0.001)
                continue
            }
            
            consecutiveEmptyReads = 0
            totalBytesDecoded += Int64(bytesRead)

            scratch.withUnsafeBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return }
                pcmPlayer.pushBytes(base, count: bytesRead)
            }

            let underflows = pcmPlayer.consumeUnderflows()
            if underflows > 0 {
                let buffered = pcmPlayer.bufferedBytes
                let elapsed = Date().timeIntervalSince(startTime)
                let avgRate = Double(totalBytesDecoded) / elapsed / 1024.0
                logger.warning("UNDERFLOW! count=\(underflows), buffer=\(buffered)B, avgDecodeRate=\(String(format: "%.1f", avgRate))KB/s, lastDecodeTime=\(String(format: "%.1f", decodeTime * 1000))ms")
            }
            
            // Periodic status log every 5 seconds
            let now = Date()
            if now.timeIntervalSince(lastLogTime) >= 5.0 {
                lastLogTime = now
                let elapsed = now.timeIntervalSince(startTime)
                let avgRate = Double(totalBytesDecoded) / elapsed / 1024.0
                let buffered = pcmPlayer.bufferedBytes
                logger.info("Decoder status: \(String(format: "%.1f", avgRate))KB/s avg, buffer=\(buffered)B")
            }
        }
        
        logger.info("Decoder loop ended. Total decoded: \(totalBytesDecoded) bytes")
    }

    private func stopDecoderLocked() {
        decoderShouldStop = true
        decoderWorkItem?.wait()
        decoderWorkItem = nil
        decoder?.close()
        decoder = nil
    }

    private func prepareAudioUnitLocked() throws {
        if audioUnit != nil { return }

        let targetDevice = try ensureDeviceIDLocked()

        var description = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_HALOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let component = AudioComponentFindNext(nil, &description) else {
            throw AudioEngineError.missingDevice
        }

        var unit: AudioUnit?
        try checkStatus(AudioComponentInstanceNew(component, &unit),
                        operation: "AudioComponentInstanceNew")

        guard let createdUnit = unit else {
            throw AudioEngineError.missingDevice
        }

        var enableIO: UInt32 = 1
        try checkStatus(AudioUnitSetProperty(createdUnit,
                                             kAudioOutputUnitProperty_EnableIO,
                                             kAudioUnitScope_Output,
                                             0,
                                             &enableIO,
                                             UInt32(MemoryLayout.size(ofValue: enableIO))),
                        operation: "Enable output")

        var disableIO: UInt32 = 0
        try checkStatus(AudioUnitSetProperty(createdUnit,
                                             kAudioOutputUnitProperty_EnableIO,
                                             kAudioUnitScope_Input,
                                             1,
                                             &disableIO,
                                             UInt32(MemoryLayout.size(ofValue: disableIO))),
                        operation: "Disable input")

        var currentDevice = targetDevice
        try checkStatus(AudioUnitSetProperty(createdUnit,
                                             kAudioOutputUnitProperty_CurrentDevice,
                                             kAudioUnitScope_Global,
                                             0,
                                             &currentDevice,
                                             UInt32(MemoryLayout.size(ofValue: currentDevice))),
                        operation: "Bind AudioDevice")

        var streamFormat = makeStreamFormat()
        try checkStatus(AudioUnitSetProperty(createdUnit,
                                             kAudioUnitProperty_StreamFormat,
                                             kAudioUnitScope_Input,
                                             0,
                                             &streamFormat,
                                             UInt32(MemoryLayout.size(ofValue: streamFormat))),
                        operation: "Apply stream format")

        var callbackStruct = AURenderCallbackStruct(
            inputProc: AudioEngine.renderProc,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        try checkStatus(AudioUnitSetProperty(createdUnit,
                                             kAudioUnitProperty_SetRenderCallback,
                                             kAudioUnitScope_Input,
                                             0,
                                             &callbackStruct,
                                             UInt32(MemoryLayout.size(ofValue: callbackStruct))),
                        operation: "Install render callback")

        try checkStatus(AudioUnitInitialize(createdUnit),
                        operation: "AudioUnitInitialize")

        audioUnit = createdUnit
    }

    private func startAudioOutputLocked() throws {
        let targetDevice = try ensureDeviceIDLocked()
        
        // Set device sample rate to match file
        do {
            try dac.setSampleRate(currentFormat.sampleRate, for: targetDevice)
            logger.info("Set device sample rate to \(self.currentFormat.sampleRate) Hz")
        } catch {
            logger.error("Failed to set sample rate: \(error.localizedDescription, privacy: .public)")
            // Continue anyway - AudioUnit may handle conversion
        }
        
        // Verify the actual device sample rate
        if let deviceInfo = try? dac.getDeviceInfo(id: targetDevice) {
            if abs(deviceInfo.currentRate - currentFormat.sampleRate) > 1.0 {
                logger.warning("Sample rate mismatch! File: \(self.currentFormat.sampleRate) Hz, Device: \(deviceInfo.currentRate) Hz")
            }
        }
        
        do {
            try dac.acquireHogMode(targetDevice)
            hoggedDevice = targetDevice
        } catch {
            logger.warning("Hog mode unavailable: \(error.localizedDescription, privacy: .public). Fallback to shared mode.")
        }

        guard let unit = audioUnit else {
            throw AudioEngineError.missingDevice
        }

        try checkStatus(AudioOutputUnitStart(unit),
                        operation: "AudioOutputUnitStart")
    }

    private func internalStop() {
        do {
            try stopPlaybackLocked()
        } catch {
            logger.error("Failed to stop audio output cleanly: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func tearDownAudioUnitLocked() {
        if let unit = audioUnit {
            AudioOutputUnitStop(unit)
            AudioUnitUninitialize(unit)
            AudioComponentInstanceDispose(unit)
            audioUnit = nil
        }
    }

    private func makeStreamFormat() -> AudioStreamBasicDescription {
        let bytesPerFrame = currentFormat.bytesPerFrame

        var flags: UInt32 = kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian

        if currentFormat.isFloat {
            flags |= kAudioFormatFlagIsFloat
        } else {
            flags |= kAudioFormatFlagIsSignedInteger
        }

        return AudioStreamBasicDescription(
            mSampleRate: currentFormat.sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: flags,
            mBytesPerPacket: bytesPerFrame,
            mFramesPerPacket: 1,
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: currentFormat.channels,
            mBitsPerChannel: currentFormat.bitDepth,
            mReserved: 0
        )
    }

    private func ensureDeviceIDLocked() throws -> AudioDeviceID {
        if deviceID == kAudioObjectUnknown {
            deviceID = try dac.getDefaultDevice().id
        }
        return deviceID
    }

    private func syncDeviceConfigurationLocked() throws {
        let id = try ensureDeviceIDLocked()
        try dac.setSampleRate(currentFormat.sampleRate, for: id)
        tearDownAudioUnitLocked()
        try prepareAudioUnitLocked()
    }

    private func stopPlaybackLocked() throws {
        if let unit = audioUnit {
            try checkStatus(AudioOutputUnitStop(unit), operation: "AudioOutputUnitStop")
        }
        playbackState = .stopped
        releaseHogModeIfNeededLocked()
    }

    private func releaseHogModeIfNeededLocked() {
        guard hoggedDevice != kAudioObjectUnknown else { return }
        do {
            try dac.releaseHogMode(hoggedDevice)
        } catch {
            logger.error("Failed to release hog mode: \(error.localizedDescription, privacy: .public)")
        }
        hoggedDevice = kAudioObjectUnknown
    }

    private static let renderProc: AURenderCallback = {
        inRefCon, _, _, _, inNumberFrames, ioData in
        let engine = Unmanaged<AudioEngine>.fromOpaque(inRefCon).takeUnretainedValue()
        return engine.render(ioData: ioData, frameCount: inNumberFrames)
    }

    private func render(ioData: UnsafeMutablePointer<AudioBufferList>?,
                        frameCount: UInt32) -> OSStatus {
        guard let ioData = ioData else { return kAudio_ParamError }

        let bytesPerFrame = Int(currentFormat.bytesPerFrame)
        guard bytesPerFrame > 0 else { return kAudio_ParamError }

        let bytesNeeded = Int(frameCount) * bytesPerFrame
        let bufferedBefore = pcmPlayer.bufferedBytes

        if let buffer = UnsafeMutableAudioBufferListPointer(ioData).first,
           let mData = buffer.mData {
            let destination = mData.assumingMemoryBound(to: UInt8.self)
            let pulled = pcmPlayer.pullBytes(into: destination, count: bytesNeeded)
            
            // Log if we're running low on buffer (less than 50% of needed)
            if pulled < bytesNeeded && bufferedBefore < bytesNeeded * 2 {
                // This is called from real-time audio thread, use os_log_info level
                // to avoid blocking. Only log occasionally.
                renderUnderrunCounter += 1
            }
            
            return noErr
        } else {
            return kAudio_ParamError
        }
    }
    
    // Counter for render underruns (accessed from audio thread)
    private var renderUnderrunCounter: Int = 0

    private func checkStatus(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw AudioEngineError.audioUnit(status, operation)
        }
    }
}
