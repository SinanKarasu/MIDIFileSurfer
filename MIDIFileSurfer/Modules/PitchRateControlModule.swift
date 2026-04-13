//
//  PitchRateControlModule.swift
//  SiKMIDIPlayer
//
//  Created by Sinan Karasu on 10/27/21.
//

import AVFoundation

@Observable
class PitchRateControlModule{
    var playerIsPlaying: Bool = false

    var pitchControl = AVAudioUnitTimePitch()

    private var audioEngine: AudioEngine!

    private var engine : AVAudioEngine {
        audioEngine.engine
    }

    init(audioEngine: AudioEngine?){
        self.audioEngine = audioEngine
        initAndCreateNode()
    }

    func initAndCreateNode() {
        pitchControl.pitch = 0
        engine.attach(pitchControl)
    }

}
