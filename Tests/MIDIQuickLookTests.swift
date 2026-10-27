import XCTest
import AVFoundation
import AppKit

final class MIDIQuickLookTests: XCTestCase {
    // One piano note, 480 PPQ, lasting one quarter note at the default 120 BPM.
    private var midi: Data {
        Data([0x4d,0x54,0x68,0x64,0,0,0,6,0,0,0,1,1,0xe0,
              0x4d,0x54,0x72,0x6b,0,0,0,16,
              0,0xc0,0, 0,0x90,60,100, 0x83,0x60,0x80,60,0, 0,0xff,0x2f,0])
    }

    func testSummaryParsesTrackAndDefaultTempo() throws {
        let summary = try MIDIPreviewSummary(data: midi)
        XCTAssertEqual(summary.tracks.count, 1)
        XCTAssertEqual(summary.tracks[0].name, "Track 1")
        XCTAssertTrue(summary.tracks[0].instrument.contains("Acoustic Grand Piano"))
        XCTAssertEqual(summary.tempo, "120.0 BPM (initial)")
    }

    func testMalformedFileIsRejected() {
        XCTAssertThrowsError(try MIDIPreviewSummary(data: Data("not MIDI".utf8)))
    }

    @MainActor func testLoadingNeverAutoplaysAndStopClearsState() throws {
        let player = PreviewPlayer()
        try player.load(midi)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.position, 0)
        XCTAssertEqual(player.duration, 0.5, accuracy: 0.05)
        player.seek(to: 0.25)
        XCTAssertEqual(player.position, 0.25, accuracy: 0.01)
        player.seek(to: -1)
        XCTAssertEqual(player.position, 0)
        player.seek(to: 100)
        XCTAssertEqual(player.position, player.duration)
        try player.load(midi)
        XCTAssertEqual(player.position, 0)
        XCTAssertFalse(player.isPlaying)
        player.stop()
        XCTAssertEqual(player.duration, 0)
        XCTAssertEqual(player.position, 0)
        XCTAssertFalse(player.isPlaying)
        player.toggle()
        XCTAssertFalse(player.isPlaying)
    }

    @MainActor func testAppleSynthRendersSoundWithoutBundledSamples() throws {
        let engine = AVAudioEngine()
        let synth = AppleMIDIInstrument.make()
        engine.attach(synth)
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2))
        engine.connect(synth, to: engine.mainMixerNode, format: format)
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { AppleMIDIInstrument.silence(synth); engine.stop() }
        synth.startNote(60, withVelocity: 100, onChannel: 0)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096))
        var peak: Float = 0
        for _ in 0..<8 {
            let status = try engine.renderOffline(4096, to: buffer)
            if status == .success, let samples = buffer.floatChannelData?[0] {
                for index in 0..<Int(buffer.frameLength) { peak = max(peak, abs(samples[index])) }
            }
        }
        XCTAssertGreaterThan(peak, 0.0001, "Apple's system synth must produce audio without a bundled bank")
    }
    @MainActor func testPreviewControllerLoadsAndDisappears() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mid")
        try midi.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let controller = PreviewViewController()
        let error: Error? = await withCheckedContinuation { continuation in
            controller.preparePreviewOfFile(at: url) { continuation.resume(returning: $0) }
        }
        XCTAssertNil(error)
        XCTAssertEqual(controller.children.count, 1)
        controller.view.frame = NSRect(x: 0, y: 0, width: 720, height: 480)
        controller.view.layoutSubtreeIfNeeded()
        controller.viewWillDisappear()
    }

}
