//
//  SequencerView.swift
//  SequencerView
//
//  Created by Sinan Karasu on 8/11/21.
//

import SwiftUI
import os.log
internal import Combine
import UniformTypeIdentifiers
internal import AVFAudio
import AppKit

struct SequencerView: View {
	@Bindable var env: MIDIFileEnv
	@Bindable var audioEngine:  AudioEngine
	@State var playerPosition: Double = 0
	@State var playInstantaneous = true
	//@State var counter = 0
	var toggleButtonText: String {
		if self.sequencerModule.playerIsPlaying {
			return "Stop"
		}
		return  "Play"
	}
	
	var openButtonText: String {
		if env.midiFile != nil {
			return "Change MIDI File"
		}
		return "Open MIDI File"
	}
	
	var playInstantaneousText: String {
		
		if self.playInstantaneous  {
			return "Playing Immediate"
		}
		return "Press Play to Play"
	}
	
	var sequencerModule: SequencerModule {
		audioEngine.sequencerModule
	}
		
	var fileAccess : FileAccess!
	init(env: MIDIFileEnv, audioEngine: AudioEngine?){
		//self.sequencerModule = sequencerModule
		self.env = env
		self.audioEngine = audioEngine!
		self.fileAccess = FileAccess()
		//self.audioEngine = sequencerModule.audioEngine
	}
	
	let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
	
	var body: some View {
		GeometryReader { reader in
			ZStack {
				VStack {
					fileNameView //.frame(height:20)
					HStack {
						togglePlaySequencer
						openButton
						modeButton
					}//.frame(height:30)
					Divider()
					HStack {
						VStack {
							progressView
						}
						Divider()
						VStack (alignment: .labelColumn){
							setSequencerPlaybackRate
							setPitchRatePitch
							setVolume
						}
						
					}//.frame(height:50)
				}
			}
		}
	}
	
	func toggleSequencer() {
		if self.sequencerModule.playerIsPlaying {
			self.sequencerModule.toggleSequencer()
			self.audioEngine.stopTimer()
		} else {
			self.sequencerModule.toggleSequencer()
			self.audioEngine.startTimer()
		}
	}
	
	var togglePlaySequencer: some View {
		
		return Button(action: {
			toggleSequencer()
		})
		{
			Text(toggleButtonText)
		}
		
	}
	
	func loadFile(url: URL?) {
		if let url = url {
			if self.sequencerModule.playerIsPlaying {
				self.sequencerModule.toggleSequencer()
				self.audioEngine.stopTimer()
			}
			
			do {
				sequencerModule.processURL(url: url)
				try env.load(url: url)
			} catch {
				let alert = NSAlert()
				alert.messageText = "Error opening the MIDI File:\(url)"
				alert.informativeText = (error as NSError).localizedDescription
				alert.alertStyle = .warning
				alert.runModal()
			}
			
			if playInstantaneous {
				if !self.sequencerModule.playerIsPlaying {
					self.sequencerModule.toggleSequencer()
					self.audioEngine.startTimer()
				}
			}
		}
	}
	
	func printFileName(url: URL?) {
		Logger.viewLogger.info("Got URL Just Printing: \(String(describing: url))")
	}
	
	var fileNameView: some View {
		Text("File: \(env.fileURL?.path ?? "None")")
	}
	
	var openButton: some View {
		Button(action: {
			if playInstantaneous {
				fileAccess!.filterByFileTypesSheet(allowedContentTypes: [.midi], completion: loadFile)
			} else {
				let url = fileAccess!.filterByFileTypes(allowedContentTypes: [.midi], completion: printFileName)
				loadFile(url: url)
			}
		}){
			Text(openButtonText)
		}
	}
	
	var modeButton: some View {
		Button(action: {
			self.playInstantaneous.toggle()
			
		})
		{
			Text(playInstantaneousText)
		}
	}
	
	var setVolume: some View {
		ResettableAlignedSliderView(label: "Volume", value: $audioEngine.outputVolume, defaultValue: 1.0, range: 0.0...1.0)
	}
	
	
	var setPitchRatePitch: some View {
		ResettableAlignedSliderView(label: "Pitch ", value: $audioEngine.pitchRateControlModule.pitchControl.pitch, defaultValue: 0.0, range: -2400...2400)
	}
	
	var setSequencerPlaybackRate: some View {
		ResettableAlignedSliderView(label: "Speed", value: $audioEngine.sequencerModule.sequencerPlaybackRate, defaultValue: 1.0, range: 0.0...2.0)
	}
	
	var progressView: some View {
		return VStack {
			HStack {
				Text(String(format: "current:%3.1f", playerPosition))
					.font(Font.system(.body, design: .monospaced))
					.frame(width:130)
				Divider()
				Text(String(format: "total:%.2f", sequencerModule.sequencerTrackLengthSeconds/audioEngine.sequencerModule.sequencerPlaybackRate))
					.font(Font.system(.body, design: .monospaced))
			}
			ProgressView("Playing Time",
						 value: playerPosition,
						 total: TimeInterval(sequencerModule.sequencerTrackLengthSeconds))
			.shadow(color: Color(red: 0, green: 0, blue: 0.6),
					radius: 4.0, x: 1.0, y: 2.0)
		}
		.onReceive(timer) { _ in
			playerPosition = min(Double(sequencerModule.sequencer.currentPositionInSeconds), TimeInterval(sequencerModule.sequencerTrackLengthSeconds))
		}
		.frame(height: 20)
	}
	
}

#Preview {
	SequencerView(env: MIDIFileEnv(), audioEngine: AudioEngine())
}

