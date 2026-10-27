import AVFoundation
import AudioToolbox

/// Apple's multitimbral General MIDI synth loads its own system soundbank.
/// No bundled samples, private resource paths, downloads or file permissions.
enum AppleMIDIInstrument {
    static func make() -> AVAudioUnitMIDIInstrument {
        AVAudioUnitMIDIInstrument(audioComponentDescription: AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_DLSSynth,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        ))
    }

    static func silence(_ instrument: AVAudioUnitMIDIInstrument) {
        for channel in UInt8(0)...15 {
            instrument.sendController(64, withValue: 0, onChannel: channel)
            instrument.sendController(123, withValue: 0, onChannel: channel)
            instrument.sendController(120, withValue: 0, onChannel: channel)
        }
    }
}
