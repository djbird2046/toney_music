import Foundation
import Testing
@testable import AudioEngineSwift

@Test
func ringBufferMaintainsFIFOAcrossWraps() throws {
    let ring = LockFreeRingBuffer(capacity: 256)

    let firstChunk = (0..<256).map { UInt8($0 & 0xFF) }
    firstChunk.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return }
        let written = ring.write(from: base, count: buffer.count)
        #expect(written == buffer.count)
    }

    var initialDrain = [UInt8](repeating: 0, count: 128)
    initialDrain.withUnsafeMutableBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return }
        let read = ring.read(into: base, count: buffer.count)
        #expect(read == buffer.count)
    }
    #expect(initialDrain == Array(firstChunk.prefix(128)))

    let secondChunk = (256..<512).map { UInt8($0 & 0xFF) }
    secondChunk.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return }
        let written = ring.write(from: base, count: buffer.count)
        #expect(written == buffer.count)
    }

    var finalDrain = [UInt8](repeating: 0, count: 384)
    finalDrain.withUnsafeMutableBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return }
        let read = ring.read(into: base, count: buffer.count)
        #expect(read == buffer.count)
    }

    let expected = Array(firstChunk.suffix(128)) + secondChunk
    #expect(finalDrain == expected)
}

@Test
func pcmPlayerTracksFramesAndUnderflows() throws {
    let player = PCMPlayer(bufferSize: 1024)
    let format = PCMFormat(sampleRate: 44_100, channels: 2, bitDepth: 16, isFloat: false)
    player.setFormat(format)

    let source = [UInt8](repeating: 0xAA, count: 8)
    source.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return }
        player.pushBytes(base, count: buffer.count)
    }

    var destination = [UInt8](repeating: 0xFF, count: 12)
    let pulled = destination.withUnsafeMutableBufferPointer { buffer -> Int in
        guard let base = buffer.baseAddress else { return 0 }
        return player.pullBytes(into: base, count: buffer.count)
    }

    #expect(pulled == 8)
    #expect(player.renderedFrames == 2)
    #expect(player.underflows == 1)
    #expect(destination.prefix(8).allSatisfy { $0 == 0xAA })
    #expect(destination.suffix(4).allSatisfy { $0 == 0 })

    let consumedUnderflows = player.consumeUnderflows()
    #expect(consumedUnderflows == 1)
    #expect(player.underflows == 0)

    player.reset()
    #expect(player.renderedFrames == 0)
    #expect(player.underflows == 0)
}

@Test
func trackFormatInfoBuildsSummary() throws {
    let pcm = PCMFormat(sampleRate: 44_100,
                        channels: 2,
                        bitDepth: 16,
                        isFloat: false)
    let info = pcm.toTrackFormatInfo(formatLabel: "PCM")
    #expect(info.summary == "PCM 1411kbps 44100Hz stereo")
    #expect(info.channelDescription == "stereo")
    #expect(info.bitrateKbps == pcm.bitrateKbps)
}

@Test
func trackMetadataProducesReadableSummary() throws {
    let pcm = TrackFormatInfo(formatLabel: "PCM",
                              bitrateKbps: 1411,
                              sampleRateHz: 44_100,
                              channels: 2,
                              bitDepth: 16)
    let tags = TrackTags(title: "My Song",
                         artist: "Artist",
                         album: "Album",
                         albumArtist: nil,
                         genre: "Rock",
                         comment: nil,
                         date: "2024",
                         trackNumber: "1",
                         discNumber: "1")
    let replayGain = TrackReplayGain(trackGainDb: -3.2,
                                     albumGainDb: -4.1,
                                     trackPeak: 0.98,
                                     albumPeak: nil,
                                     r128TrackGain: nil,
                                     r128AlbumGain: nil)
    let meta = TrackMetadata(url: URL(fileURLWithPath: "/tmp/song.flac"),
                             containerName: "FLAC",
                             codecName: "flac",
                             sourceBitrateKbps: 900,
                             channelLayout: 3,
                             durationMs: 185_000,
                             pcm: pcm,
                             sampleFormatName: "s16",
                             fileSizeBytes: 20_000_000,
                             startTimeSeconds: 0,
                             tags: tags,
                             replayGain: replayGain)
    #expect(meta.formattedSourceBitrate == "900kbps")
    #expect(meta.durationDescription == "3:05")
    #expect(meta.overallSummary.contains("flac"))
    #expect(meta.overallSummary.contains("PCM"))
    #expect(meta.fileSizeDescription != nil)
    #expect(meta.displayTitle == "My Song")
    #expect(meta.replayGain.hasAnyValue)
}
