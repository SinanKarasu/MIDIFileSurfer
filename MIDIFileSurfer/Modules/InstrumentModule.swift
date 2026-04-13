//
//  InstrumentModule.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 8/12/21.
//

import Foundation
import AVFoundation

class InstrumentModule {

    var sampler: AVAudioUnitSampler!
    private var audioEngine: AudioEngine!

    private var engine: AVAudioEngine { audioEngine.engine }

    init(audioEngine: AudioEngine?) {
        self.audioEngine = audioEngine
        initAndCreateNode()
    }

    func initAndCreateNode() {
        sampler = AVAudioUnitSampler()
        engine.attach(sampler)

        guard let bankURL = GMBankLocator.bestAvailableURL() else {
            fatalError("No GM sound bank found — add MuseScore_General.sf2 to the bundle or ensure gs_instruments.dls is present.")
        }
        do {
            try sampler.loadSoundBankInstrument(at: bankURL, program: 0, bankMSB: 0x79, bankLSB: 0)
        } catch {
            fatalError("Couldn't load sound bank into sampler: \(error.localizedDescription)")
        }
    }

    public var tuningValue: AUValue {
        get { AUValue(sampler.globalTuning / 100.0) }
        set { sampler.globalTuning = Float(newValue * 100.0) }
    }
}
