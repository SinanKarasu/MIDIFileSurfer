//
//  MIDIFileTrack.swift
//  MIDIFileSurfer
//

import Foundation
import SwiftMIDIFile

struct MIDIFileTrack: Identifiable {
	let id = UUID()
	let events: [MIDIFileTrackEvent]
	let timebase: AnyMIDIFileTimebase
}

struct MIDIFileTrackEvent: Identifiable {
	let id = UUID()
	let delta: AnyMIDIFileDeltaTime
	let event: MIDIFileEvent
}

extension AnyMIDI1File {
	var surferTracks: [MIDIFileTrack] {
		switch self {
		case .musical(let file):
			let timebase = AnyMIDIFileTimebase.musical(file.timebase)
			return file.tracks.map { track in
				MIDIFileTrack(
					events: track.events.map {
						MIDIFileTrackEvent(delta: .musical($0.delta), event: $0.event)
					},
					timebase: timebase
				)
			}

		case .smpte(let file):
			let timebase = AnyMIDIFileTimebase.smpte(file.timebase)
			return file.tracks.map { track in
				MIDIFileTrack(
					events: track.events.map {
						MIDIFileTrackEvent(delta: .smpte($0.delta), event: $0.event)
					},
					timebase: timebase
				)
			}
		}
	}
}
