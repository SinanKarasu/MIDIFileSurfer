import AVFoundation

final class InstrumentModule {
    let sampler: AVAudioUnitMIDIInstrument

    init(audioEngine: AudioEngine) {
        sampler = AppleMIDIInstrument.make()
        audioEngine.engine.attach(sampler)
    }
}
