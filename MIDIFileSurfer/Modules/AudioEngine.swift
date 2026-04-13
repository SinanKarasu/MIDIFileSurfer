//
//  AudioEngine.swift
//  Adapted from AVAEMixerSample
//

import Foundation
import AVFoundation
import os.log

@Observable
class AudioEngine: NSObject {
    
    var engine: AVAudioEngine!
    
	var sequencerModule: SequencerModule!
    private(set) var instrumentModule: InstrumentModule!
	
    var pitchRateControlModule: PitchRateControlModule!
    
    private(set) var _mixerOutputFileURL: URL? = nil

    private var _isSessionInterrupted: Bool = false
    private var _isConfigChangePending: Bool = false
    
    //MARK: AudioEngine implementation
    
    override init() {
        super.init()
        setupModules()
        setupNotifications()
    }

    func setupModules() {
        engine = AVAudioEngine()

        instrumentModule = InstrumentModule(audioEngine: self)
        pitchRateControlModule = PitchRateControlModule(audioEngine: self)

        self.makeEngineConnections()

        Logger.viewLogger.info("\(self.engine.description)")
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .ShouldEnginePause, object: nil, queue: OperationQueue.main) {note in
            
            /* pausing stops the audio engine and the audio hardware, but does not deallocate the resources allocated by prepare().
             When your app does not need to play audio, you should pause or stop the engine (as applicable), to minimize power consumption.
             */
            if !self._isSessionInterrupted && !self._isConfigChangePending {
                if  self.sequencerModule.sequencerIsPlaying {
                    return
                }
                
                Logger.viewLogger.info("GOT a NOTIFICATION: Pausing Engine")
                self.sequencerModule.playerIsPlaying = false
                self.engine.pause()
                self.engine.reset()
            }
        }

        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: OperationQueue.main) {note in
            // sign up for notifications from the engine if there's a hardware config change
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and reset any state that may have been lost due to nodes being
            // uninitialized when the engine was stopped
            self._isConfigChangePending = true
            
            if !self._isSessionInterrupted {
                Logger.viewLogger.info("Received a \(String(describing:Notification.Name.AVAudioEngineConfigurationChange)) notification!")
                Logger.viewLogger.info("Re-wiring connections");
                self.makeEngineConnections()
            } else {
                Logger.viewLogger.info("Session is interrupted, deferring changes")
            }
        }
        sequencerModule = SequencerModule(audioEngine: self)
    }


    
    func makeEngineConnections() {
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        engine.connect(instrumentModule.sampler, to: pitchRateControlModule.pitchControl, format: stereoFormat)
        engine.connect(pitchRateControlModule.pitchControl, to: engine.mainMixerNode, format: nil)
    }

    func startEngine() {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch let error {
                fatalError("couldn't start engine, \(error.localizedDescription)")
            }
            Logger.viewLogger.info("Started Engine")
        }
    }

    //MARK: Mixer Methods
    // 0.0 - 1.0
    var outputVolume: Float {
        set {
            engine.mainMixerNode.outputVolume = newValue
        }
        
        get {
            return engine.mainMixerNode.outputVolume
        }
    }

    func handleMediaServicesReset(_ notification: Notification) {
        // if we've received this notification, the media server has been reset
        // re-wire all the connections and start the engine
        Logger.viewLogger.info("Media services have been reset!")
        Logger.viewLogger.info("Re-wiring connections")

        self.makeEngineConnections()
    }

    var sequencerPositionSliderUpdateTimer : DispatchSourceTimer? = nil
    var sequencerPositionSlider: Float = 0.0

    func startTimer()  {
        self.sequencerPositionSliderUpdateTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.main)
        if let sequencerPositionSliderUpdateTimer = self.sequencerPositionSliderUpdateTimer {
            sequencerPositionSliderUpdateTimer.schedule(deadline: .now(), repeating: 0.1 * Double(NSEC_PER_SEC), leeway: .nanoseconds(0))
            sequencerPositionSliderUpdateTimer.setEventHandler {
                self.sequencerPositionSlider = Float(self.sequencerModule.sequencerCurrentPosition )
            }
            sequencerPositionSliderUpdateTimer.resume()
        }
    }

    func stopTimer() {
        if let sequencerPositionSliderUpdateTimer = sequencerPositionSliderUpdateTimer {
            sequencerPositionSliderUpdateTimer.cancel()
            self.sequencerPositionSliderUpdateTimer = nil
        }
    }
}
