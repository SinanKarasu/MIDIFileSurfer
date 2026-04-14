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
			MIDIBookmark.rememberRecentFile(url)
			if self.sequencerModule.playerIsPlaying {
				self.sequencerModule.toggleSequencer()
				self.audioEngine.stopTimer()
			}
			
			do {
				try sequencerModule.processURL(url: url)
				try env.load(url: url)
			} catch {
				presentLoadError(for: url, error: error)
				return
			}
			
			if playInstantaneous {
				if !self.sequencerModule.playerIsPlaying {
					self.sequencerModule.toggleSequencer()
					self.audioEngine.startTimer()
				}
			}
		}
	}

		private func presentLoadError(for url: URL, error: Error) {
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = "Can't Open \(url.lastPathComponent)"
		alert.informativeText = loadErrorMessage(for: url, error: error)

		if shouldOfferFolderAccess(for: url, error: error) {
			alert.addButton(withTitle: "Share Folder")
			alert.addButton(withTitle: "Open File")
			alert.addButton(withTitle: "OK")

			switch alert.runModal() {
			case .alertFirstButtonReturn:
				if let folderURL = MIDIBookmark.promptForFolderAccess(
					title: "Choose the folder that contains \(url.lastPathComponent)",
					prompt: "Grant Access",
					initialDirectory: url.deletingLastPathComponent()
				),
				url.isInside(folderURL) {
					loadFile(url: url)
				}
			case .alertSecondButtonReturn:
				if let replacementURL = promptForSpecificFileAccess(for: url) {
					loadFile(url: replacementURL)
				}
			default:
				break
			}
			return
		}

		alert.runModal()
	}

	private func loadErrorMessage(for url: URL, error: Error) -> String {
		if isLikelyICloudPlaceholder(url) {
			return """
			This file appears to live in iCloud and may not be downloaded on this Mac yet. Download it locally in Finder, then try again.

			Share Folder if you want MIDIFileSurfer to surf this folder with single clicks, or Open File if you only want this one file right now.
			"""
		}

		if shouldOfferFolderAccess(for: url, error: error) {
			return """
			This file is outside the folders currently shared with MIDIFileSurfer.

			Share Folder to grant read-only access to the folder that contains it, or Open File to reopen only this one file right now. If it lives in iCloud Drive, make sure it is downloaded locally first.

			If you use a non-App-Store build and keep MIDI files scattered across many locations, Full Disk Access can also help.
			"""
		}

		return (error as NSError).localizedDescription
	}

	private func shouldOfferFolderAccess(for url: URL, error: Error) -> Bool {
		MIDIBookmark.grantedFolder(containing: url) == nil || isLikelyPermissionError(error) || isLikelyICloudPlaceholder(url)
	}

	private func isLikelyPermissionError(_ error: Error) -> Bool {
		let nsError = error as NSError
		if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoPermissionError {
			return true
		}
		if nsError.domain == NSPOSIXErrorDomain && (nsError.code == EACCES || nsError.code == EPERM) {
			return true
		}
		if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
			return isLikelyPermissionError(underlying)
		}
		return false
	}

	private func isLikelyICloudPlaceholder(_ url: URL) -> Bool {
		guard FileManager.default.isUbiquitousItem(at: url) else { return false }
		let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
		return values?.ubiquitousItemDownloadingStatus != URLUbiquitousItemDownloadingStatus.current
	}

	private func promptForSpecificFileAccess(for url: URL) -> URL? {
		let panel = NSOpenPanel()
		panel.title = "Choose \(url.lastPathComponent)"
		panel.message = "Select the MIDI file you want to open right now."
		panel.prompt = "Open"
		panel.canChooseFiles = true
		panel.canChooseDirectories = false
		panel.canCreateDirectories = false
		panel.allowsMultipleSelection = false
		panel.allowedContentTypes = [.midi]
		panel.directoryURL = url.deletingLastPathComponent()

		guard panel.runModal() == .OK else { return nil }
		return panel.url
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
				openImmediateFileBrowser()
			} else {
				let url = fileAccess!.filterByFileTypes(
					allowedContentTypes: [.midi],
					initialDirectory: MIDIBookmark.recentDirectoryURL() ?? MIDIBookmark.grantedFolderURLs().first,
					completion: printFileName
				)
				loadFile(url: url)
			}
		}){
			Text(openButtonText)
		}
	}

	private func openImmediateFileBrowser() {
		let preferredDirectory =
			MIDIBookmark.recentDirectoryURL()
			?? env.fileURL?.deletingLastPathComponent()
			?? MIDIBookmark.grantedFolderURLs().first

		fileAccess!.filterByFileTypesSheet(
			allowedContentTypes: [.midi],
			initialDirectory: preferredDirectory,
			completion: loadFile
		)
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

extension URL {
	func isInside(_ directory: URL) -> Bool {
		let filePath = standardizedFileURL.path
		let directoryPath = directory.standardizedFileURL.path
		return filePath == directoryPath || filePath.hasPrefix(directoryPath + "/")
	}
}

#Preview {
	SequencerView(env: MIDIFileEnv(), audioEngine: AudioEngine())
}
