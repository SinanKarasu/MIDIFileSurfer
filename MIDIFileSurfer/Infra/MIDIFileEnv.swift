//
//  MIDIFileEnv.swift
//  SiKMIDIKitNew
//
//  Created by Sinan Karasu on 2/15/23.
//

import Foundation
import MIDIKitSMF

/// Effective tick resolution of a MIDI file.
enum TickResolution {
	case musical(ppq: Int)
	case timecode(fps: Double, ticksPerFrame: Int, dropFrame: Bool)
}

@MainActor
@Observable
final class MIDIFileEnv {
	
	private(set) var fileURL: URL?
	private(set) var midiFile: MIDIFile?
	private(set) var tempoMap: TempoMap!
	
	//var isLoaded: Bool { midiFile != nil }
	
	init(initialURL: URL? = nil) {
		if let url = initialURL { try? load(url: url) }
	}
	
	func load(url: URL) throws {
		// Let the error propagate out; caller can present it.
		unload()
		let file = try MIDIFile(midiFile: url)
		self.fileURL = url
		self.tempoMap = TempoMap(file: file)
		self.midiFile = file
	}
	
	func unload() {
		self.midiFile = nil
		self.fileURL = nil
	}
	
	func tickResolution() -> TickResolution? {
		guard let file = midiFile else { return nil }
		
		switch file.timeBase {
		case .musical(let ppq):
			return .musical(ppq: Int(ppq))
			
		case .timecode(let format, let ticksPerFrame):
			// No explicit type name here — let the compiler infer it.
			let fps: Double
			let drop: Bool
			switch format {
			case .fps24:        (fps, drop) = (24.0, false)
			case .fps25:        (fps, drop) = (25.0, false)
			case .fps29_97d:    (fps, drop) = (30000.0/1001.0, true)  // 29.97 drop-frame
			case .fps30:        (fps, drop) = (30.0, false)
			@unknown default:   (fps, drop) = (30.0, false)
			}
			
			return .timecode(fps: fps, ticksPerFrame: Int(ticksPerFrame), dropFrame: drop)
		}
	}
}
