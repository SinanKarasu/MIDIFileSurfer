//
//  MIDIEvent rawBytes.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2025 Steffan Andrews • Licensed under MIT License
//

// MARK: - MIDI 1.0
import MIDIKit

/// Returns the complete raw MIDI 1.0 message bytes that comprise the event.
///
/// - Note: This is mainly for internal use and is not necessary to access during typical usage
///   of MIDIKit, but is provided publicly for introspection and debugging purposes.
import MIDIKitSMF

extension MIDIFileEvent {
	public func midi1RawBytes() -> [UInt8] {
		switch self {
		case .noteOn(_, let e):
			return e.midi1RawBytes()
		case .noteOff(_, let e):
			return e.midi1RawBytes()
		case .cc(_, let e):
			return e.midi1RawBytes()
		case .programChange(_, let e):
			return e.midi1RawBytes()
		case .pressure(_, let e):
			return e.midi1RawBytes()
		case .pitchBend(_, let e):
			return e.midi1RawBytes()
		case .notePressure(_, let e):
			return e.midi1RawBytes()
		case .sysEx7(_, let e):
			return e.midi1RawBytes()
		case .universalSysEx7(_, let e):
			return e.midi1RawBytes()
		default:
			return []
		}
	}
}

extension MIDIFileEvent {
	var isNoteOnZeroVelocity: Bool {
		if case .noteOn(_, let e) = self {
			return e.velocity.midi1Value == 0
		}
		return false
	}
}

