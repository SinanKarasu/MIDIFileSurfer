import AVFoundation
import Observation

@MainActor @Observable
final class PreviewPlayer {
    private var engine: AVAudioEngine?
    private var synth: AVAudioUnitMIDIInstrument?
    private var sequencer: AVAudioSequencer?
    private var timer: Timer?
    private var data: Data?
    var isPlaying = false
    var position: Double = 0
    var duration: Double = 0
    var error: String?

    func load(_ data: Data) throws {
        stop()
        self.data = data
        error = nil
        // Inspect duration without starting audio hardware or loading instruments.
        let sequence = AVAudioSequencer()
        try sequence.load(from: data, options: [])
        duration = sequence.tracks.map(\.lengthInSeconds).filter(\.isFinite).max() ?? 0
    }

    func toggle() {
        if isPlaying { pause(); return }
        do {
            if sequencer == nil {
                guard let data else { return }
                let engine = AVAudioEngine()
                let synth = AppleMIDIInstrument.make()
                engine.attach(synth)
                engine.connect(synth, to: engine.mainMixerNode, format: nil)
                let sequence = AVAudioSequencer(audioEngine: engine)
                try sequence.load(from: data, options: [])
                for track in sequence.tracks {
                    track.destinationAudioUnit = synth
                    track.isLoopingEnabled = false
                }
                self.engine = engine
                self.synth = synth
                sequencer = sequence
            }
            guard let engine, let sequencer else { return }
            error = nil
            if position >= duration { position = 0 }
            sequencer.currentPositionInSeconds = position
            if !engine.isRunning { try engine.start() }
            sequencer.prepareToPlay()
            try sequencer.start()
            isPlaying = true
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.updatePosition() }
            }
        } catch {
            pause()
            self.error = "Playback unavailable: \(error.localizedDescription)"
            engine?.stop()
            sequencer = nil
            synth = nil
            engine = nil
        }
    }

    func seek(to value: Double) {
        guard value.isFinite else { return }
        if let synth { AppleMIDIInstrument.silence(synth) }
        position = min(max(0, value), duration)
        sequencer?.currentPositionInSeconds = position
    }

    func pause() {
        sequencer?.stop()
        if let synth { AppleMIDIInstrument.silence(synth) }
        timer?.invalidate()
        timer = nil
        isPlaying = false
        engine?.pause()
    }

    func stop() {
        pause()
        engine?.stop()
        sequencer = nil
        synth = nil
        engine = nil
        data = nil
        position = 0
        duration = 0
    }

    private func updatePosition() {
        guard let sequencer else { return }
        position = min(sequencer.currentPositionInSeconds, duration)
        if !sequencer.isPlaying || position >= duration {
            pause()
            position = duration
        }
    }
}
