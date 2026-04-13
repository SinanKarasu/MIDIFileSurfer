//
//  DispFormStruct.swift
//
//  Rewritten for cleaner, safer display logic.
//  Uses MIDIKitSMF + MIDIKit value types, inspired by MIDIHelpers.
//

import SwiftUI
import MIDIKitSMF
import SwiftRadix


// MARK: - Main display struct

struct DispFormStruct: Identifiable {
	
	init(delta: MIDIFileEvent.DeltaTime, event: MIDIFileEvent, status: String = "") { //}, frame: TrackFrame3? = nil) {
		self.delta = delta
		self.event = event
		self.status = status
		//self.frame = frame
	}
	let id = UUID()
	let delta: MIDIFileEvent.DeltaTime
	let event: MIDIFileEvent
	let status: String
	var frame = TrackFrame()           // if you want BBT info
	
	var channelText: String {
		switch event {
		case .cc(_, let e):              return "Ch \(Int(e.channel) + 1)"
		case .noteOn(_, let e):          return "Ch \(Int(e.channel) + 1)"
		case .noteOff(_, let e):         return "Ch \(Int(e.channel) + 1)"
		case .pressure(_, let e):        return "Ch \(Int(e.channel) + 1)"
		case .programChange(_, let e):   return "Ch \(Int(e.channel) + 1)"
		case .pitchBend(_, let e):       return "Ch \(Int(e.channel) + 1)"
		case .notePressure(_, let e):    return "Ch \(Int(e.channel) + 1)"
		default:                         return "--"
		}
	}
	
	var primaryText: String {
		switch event {
		case .noteOn(_, let e):          return "Note \(e.note.number)"
		case .noteOff(_, let e):         return "Note \(e.note.number)"
		case .cc(_, let e):              return "CC \(e.controller.number)"
		case .programChange(_, let e):   return "Program \(e.program)"
		case .pitchBend(_, let e):       return "Bend \(e.value)"
		case .pressure(_, let e):        return "Pressure \(e.amount)"
		case .notePressure(_, let e):    return "Aftertouch \(e.amount)"
		case .tempo(_, let e):           return "Tempo \(e.bpmEncoded)"
		case .keySignature(_, let e):
			// MIDI SMF Key Signature: signed sharps/flats count (-7...+7) plus major/minor flag.
			// MIDIKitSMF v4+ exposes Swift structs (not KVC-compliant), so avoid value(forKey:).
			func intField(_ names: [String]) -> Int? {
				for c in Mirror(reflecting: e).children {
					guard let label = c.label, names.contains(label) else { continue }
					switch c.value {
					case let v as Int: return v
					case let v as Int8: return Int(v)
					case let v as UInt8: return Int(v)
					case let v as Int16: return Int(v)
					case let v as UInt16: return Int(v)
					default: break
					}
				}
				return nil
			}
			func boolField(_ names: [String]) -> Bool? {
				for c in Mirror(reflecting: e).children {
					guard let label = c.label, names.contains(label) else { continue }
					if let v = c.value as? Bool { return v }
					if let v = c.value as? Int { return v != 0 }
					if let v = c.value as? UInt8 { return v != 0 }
				}
				return nil
			}
			
			let sf = intField(["flatsOrSharps", "sharpsFlats", "sf", "key"]) ?? 0
			// MIDIKitSMF's current KeySignature prints like: KeySignature(flatsOrSharps: -1, majorKey: true)
			let majorKey = boolField(["majorKey", "isMajor"]) ?? true
			let isMinor = boolField(["isMinor", "minor"])
			let isMajor = isMinor.map { !$0 } ?? majorKey
			
			guard (-7...7).contains(sf) else { return "Key Signature" }
			
			let majorNames = ["Cb","Gb","Db","Ab","Eb","Bb","F","C","G","D","A","E","B","F#","C#"]
			let minorNames = ["Abm","Ebm","Bbm","Fm","Cm","Gm","Dm","Am","Em","Bm","F#m","C#m","G#m","D#m","A#m"]
			let offset = sf + 7
			let name = (isMajor ? majorNames : minorNames)[offset]
			let mode = isMajor ? "Maj" : "Min"
			return "Key \(name) \(mode)"
			
		case .timeSignature(_, let e):   return "Time \(e.numerator)/\(1 << Int(e.denominator))"
		default:                         return "--"
		}
	}
	
	var secondaryText: String {
		switch event {
		case .noteOn(_, let e):          return "Vel \(e.velocity)"
		case .noteOff(_, let e):         return "Vel \(e.velocity)"
		case .cc(_, let e):              return "Val \(e.value)"
		case .pitchBend(_, let e):       return "LSB/MSB \(e.value)"
		case .tempo(_, let tempo):		 return String(format: "BPM %.2f", tempo.bpmEncoded)
			
		default:                         return "--"
		}
	}
	
	var detailText: String {
		switch event {
		case .noteOn(_, _):          	 return frame.bbtString
		case .cc(_, _):                  return frame.bbtString
		default:                         return "--"
		}
	}
	
	var data: String {
		switch event {
		case .noteOn(_, let e):          return "note=\(e.note.number) vel=\(e.velocity)"
		case .noteOff(_, let e):         return "note=\(e.note.number) vel=\(e.velocity)"
		case .cc(_, let e):              return "cc=\(e.controller.number) val=\(e.value)"
		case .programChange(_, let e):   return "program=\(e.program)"
		case .pitchBend(_, let e):       return "value=\(e.value)"
		case .pressure(_, let e):        return "amount=\(e.amount)"
		case .notePressure(_, let e):    return "amount=\(e.amount)"
		default:                         return "--"
		}
	}
	
	var color: Color {
		switch event {
		case .noteOn:					return( event.isNoteOnZeroVelocity ? .red.opacity(0.8) : .green )
		case .noteOff:                   return .red
		case .cc:                        return .blue
		case .tempo:                     return .orange
		default:                         return .accentColor
		}
	}
	
	// Update this form’s frame based on the previous form’s frame and ppq.
	mutating func fixTimeForEvent(from: DispFormStruct, ppq: Int)  {
		var fr = from.frame
		let deltaTicks = from.delta.ticksValue(using: .musical(ticksPerQuarterNote: UInt16(ppq)))
		fr.advance(deltaTicks: Int(deltaTicks), ppq: ppq)
		self.frame = fr
	}
	
	
}

// MARK: - Event-specific display wrappers

extension DispFormStruct {
	static func makeDispFormStruct(what: MIDIFileEvent) -> DispFormStruct {
		switch what {
		case let .cc(delta, _):
			return DispFormStruct(delta: delta, event: what)
		case let .channelPrefix(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Controller")
		case let .keySignature(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Controller")
		case let .noteOff(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Note Off")
		case let .noteOn(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Note On")
		case let .notePressure(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Note Pressure")
		case let .pitchBend(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Pitch Bend")
		case let .portPrefix(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Port Prefix")
		case let .pressure(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Pressure")
		case let .programChange(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Program Change")
		case let .rpn(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "RPN")
		case let .nrpn(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "NRPN")
		case let .sequenceNumber(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Sequence Number")
		case let .sequencerSpecific(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Sequence Specific")
		case let .smpteOffset(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "SMPTE Offset")
		case let .sysEx7(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Sys EX7")
		case let .tempo(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Tempo")
		case let .text(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Text")
		case let .timeSignature(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Time Signature")
		case let .universalSysEx7(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Universal SysEx7")
		case let .unrecognizedMeta(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "Unrecognized Meta")
		case let .xmfPatchTypePrefix(delta,  _):
			return DispFormStruct(delta: delta, event: what, status: "XMF Patch Type Prefix")
		}
	}
}

extension DispFormStruct {
	var cumulative: String { String(frame.cumulativeTicks) }
	var dataHEX: String { return event.midi1RawBytes().hex.stringValue(padTo: 2) }
	var frameInfo: String { self.frame.frameInfo }
}
