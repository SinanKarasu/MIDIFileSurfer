//
//  SequencerEngine.swift
//  SequencerEngine
//
//  Created by Sinan Karasu on 8/12/21.
//

import SwiftUI
import AVFoundation
import os.log


class SequencerModule {

    //let panel = NSOpenPanel()
    var sequencer: AVAudioSequencer!
    var playInstantaneous = false
    private(set) var  sequencerTrackLengthSeconds: Float = 0.0
    private var audioEngine: AudioEngine!

    var playerIsPlaying: Bool = false

    init(audioEngine: AudioEngine?){
        self.audioEngine = audioEngine
        initAndCreateNode()
    }

    func initAndCreateNode() {
        /* A collection of MIDI events organized into AVMusicTracks, plus a player to play back the events.
         NOTE: The sequencer must be created after the engine is initialized and an instrument node is attached and connected
         */
        sequencer = AVAudioSequencer(audioEngine: audioEngine.engine)

        // load sequencer loop
        guard let midiFileURL = Bundle(for: type(of: self)).url(forResource: "bluesyRiff", withExtension: "mid") else {
            fatalError("couldn't find midi file")
        }

        loadFile(midiFileURL: midiFileURL)

        sequencer.prepareToPlay()

    }

	func processURL(url: URL?) {
        if let url = url {
            if playInstantaneous {
                if self.playerIsPlaying {
                    self.toggleSequencer()
                }
            }

            loadFile(midiFileURL: url)
            if playInstantaneous {
                self.toggleSequencer()
            }
        }

    }

    private func loadFile(midiFileURL: URL) {
        Logger.viewLogger.info("URL: \(midiFileURL)")
        if sequencer.isPlaying  {
            sequencer.stop()
        }
        do {
            try sequencer.load(from: midiFileURL, options: AVMusicSequenceLoadOptions())
        } catch {
            fatalError("couldn't load midi file, \(error.localizedDescription)")
        }

        // enable looping on all the sequencer tracks
        sequencerTrackLengthSeconds = 0
        sequencer.tracks.forEach{ track in
            track.isLoopingEnabled = false
            track.numberOfLoops = AVMusicTrackLoopCount.forever.rawValue
            let trackLengthInSeconds  = Float(track.lengthInSeconds)
            if sequencerTrackLengthSeconds < trackLengthInSeconds {
                sequencerTrackLengthSeconds = trackLengthInSeconds
            }
        }

        sequencer.prepareToPlay()


    }

    var sequencerPlaybackRate: Float {
        get {
            return sequencer?.rate ?? 0.0
        }

        set {
            sequencer?.rate = newValue
        }
    }

    func toggleSequencer() {
        if !self.sequencerIsPlaying {
            do {

                self.audioEngine.startEngine()
                sequencer!.currentPositionInSeconds = 0

                try sequencer!.start()
            } catch {
                fatalError("couldn't start sequencer")
            }
        } else {
            sequencer!.stop()
            NotificationCenter.default.post(name: .ShouldEnginePause, object: nil)
        }
        self.playerIsPlaying = sequencerIsPlaying
    }

    var sequencerIsPlaying: Bool {
        return sequencer?.isPlaying ?? false
    }

    var sequencerCurrentPosition: Float {
        get {
            let x = Float(sequencer.currentPositionInSeconds)
            return x
        }
        set {
            sequencer?.currentPositionInSeconds = TimeInterval(newValue)
        }
    }
}
