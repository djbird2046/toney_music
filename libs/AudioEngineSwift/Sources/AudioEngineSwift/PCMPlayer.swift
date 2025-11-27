import Foundation
import Atomics

final class PCMPlayer {
    let ring: LockFreeRingBuffer

    private var formatStorage = PCMFormat(sampleRate: 48_000,
                                          channels: 2,
                                          bitDepth: 32,
                                          isFloat: true)
    private let renderedFramesCounter = ManagedAtomic<Int>(0)
    private let underflowCounter = ManagedAtomic<Int>(0)

    init(bufferSize: Int) {
        ring = LockFreeRingBuffer(capacity: bufferSize)
    }

    func reset() {
        ring.reset()
        renderedFramesCounter.store(0, ordering: .relaxed)
        underflowCounter.store(0, ordering: .relaxed)
    }

    func pushBytes(_ bytes: UnsafePointer<UInt8>, count: Int) {
        guard count > 0 else { return }
        var written = 0
        while written < count {
            let result = ring.write(from: bytes.advanced(by: written), count: count - written)
            if result == 0 {
                Thread.sleep(forTimeInterval: 0.001)
                continue
            }
            written += result
        }
    }

    @discardableResult
    func pullBytes(into dst: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let pulled = ring.read(into: dst, count: count)
        if pulled < count {
            underflowCounter.wrappingIncrement(ordering: .relaxed)
            dst.advanced(by: pulled).initialize(repeating: 0, count: count - pulled)
        }
        let bytesPerFrame = max(1, Int(formatStorage.bytesPerFrame))
        let frames = pulled / bytesPerFrame
        if frames > 0 {
            renderedFramesCounter.wrappingIncrement(by: frames, ordering: .relaxed)
        }
        return pulled
    }

    func setFormat(_ fmt: PCMFormat) {
        formatStorage = fmt
    }

    var format: PCMFormat {
        formatStorage
    }

    var renderedFrames: Int {
        renderedFramesCounter.load(ordering: .relaxed)
    }

    var underflows: Int {
        underflowCounter.load(ordering: .relaxed)
    }

    func consumeUnderflows() -> Int {
        return underflowCounter.exchange(0, ordering: .acquiringAndReleasing)
    }

    /// Returns the number of bytes currently buffered and available for playback.
    var bufferedBytes: Int {
        ring.availableBytes
    }
}
