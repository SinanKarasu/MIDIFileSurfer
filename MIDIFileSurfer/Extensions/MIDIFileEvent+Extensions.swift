//
//  MIDIFileEvent+Extensions.swift
//  MIDIFileSurfer
//

import SwiftMIDIFile

extension MIDIFileEvent {
	public func midi1RawBytes() -> [UInt8] {
		switch self {
		case .noteOn(let e):
			return e.midi1RawBytes()
		case .noteOff(let e):
			return e.midi1RawBytes()
		case .cc(let e):
			return e.midi1RawBytes()
		case .programChange(let e):
			return e.midi1RawBytes()
		case .pressure(let e):
			return e.midi1RawBytes()
		case .pitchBend(let e):
			return e.midi1RawBytes()
		case .notePressure(let e):
			return e.midi1RawBytes()
		case .sysEx7(let e):
			return e.midi1RawBytes()
		case .universalSysEx7(let e):
			return e.midi1RawBytes()
		default:
			return []
		}
	}
}

extension MIDIFileEvent {
	var isNoteOnZeroVelocity: Bool {
		if case .noteOn(let e) = self {
			return e.velocity.midi1Value == 0
		}
		return false
	}
}
