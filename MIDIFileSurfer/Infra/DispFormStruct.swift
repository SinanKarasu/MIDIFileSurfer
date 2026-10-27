//
//  DispFormStruct.swift
//
//  Rewritten for cleaner, safer display logic.
//  Uses SwiftMIDIFile value types, inspired by MIDIHelpers.
//

import SwiftUI
import SwiftMIDIFile
import SwiftRadix


// MARK: - Main display struct

struct DispFormStruct: Identifiable {
	
	init(delta: AnyMIDIFileDeltaTime, event: MIDIFileEvent, status: String = "") { //}, frame: TrackFrame3? = nil) {
		self.delta = delta
		self.event = event
		self.status = status
		//self.frame = frame
	}
	let id = UUID()
	let delta: AnyMIDIFileDeltaTime
	let event: MIDIFileEvent
	let status: String
	var frame = TrackFrame()           // if you want BBT info
	
	var channelText: String {
		switch event {
		case .cc(let e):              return "Ch \(Int(e.channel) + 1)"
		case .noteOn(let e):          return "Ch \(Int(e.channel) + 1)"
		case .noteOff(let e):         return "Ch \(Int(e.channel) + 1)"
		case .pressure(let e):        return "Ch \(Int(e.channel) + 1)"
		case .programChange(let e):   return "Ch \(Int(e.channel) + 1)"
		case .pitchBend(let e):       return "Ch \(Int(e.channel) + 1)"
		case .notePressure(let e):    return "Ch \(Int(e.channel) + 1)"
		default:                         return "--"
		}
	}
	
	var primaryText: String {
		switch event {
		case .noteOn(let e):          return "Note \(e.note.number)"
		case .noteOff(let e):         return "Note \(e.note.number)"
		case .cc(let e):              return "CC \(e.controller.number)"
		case .programChange(let e):   return "Program \(e.program)"
		case .pitchBend(let e):       return "Bend \(e.value)"
		case .pressure(let e):        return "Pressure \(e.amount)"
		case .notePressure(let e):    return "Aftertouch \(e.amount)"
		case .tempo(let e):           return String(format: "Tempo %.2f", e.bpm)
		case .keySignature(let e):
			// MIDI SMF Key Signature: signed sharps/flats count (-7...+7) plus major/minor flag.
			// SwiftMIDIFile exposes Swift structs (not KVC-compliant), so avoid value(forKey:).
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
			// SwiftMIDIFile's current KeySignature prints like: KeySignature(flatsOrSharps: -1, majorKey: true)
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
			
		case .timeSignature(let e):   return "Time \(e.numerator)/\(1 << Int(e.denominator))"
		default:                         return "--"
		}
	}
	
	var secondaryText: String {
		switch event {
		case .noteOn(let e):          return "Vel \(e.velocity)"
		case .noteOff(let e):         return "Vel \(e.velocity)"
		case .cc(let e):              return "Val \(e.value)"
		case .pitchBend(let e):       return "LSB/MSB \(e.value)"
		case .tempo(let tempo):		 return String(format: "BPM %.2f", tempo.bpm)
			
		default:                         return "--"
		}
	}
	
	var detailText: String {
		switch event {
		case .noteOn(_):          	 return frame.bbtString
		case .cc(_):                  return frame.bbtString
		default:                         return "--"
		}
	}
	
	var data: String {
		switch event {
		case .noteOn(let e):          return "note=\(e.note.number) vel=\(e.velocity)"
		case .noteOff(let e):         return "note=\(e.note.number) vel=\(e.velocity)"
		case .cc(let e):              return "cc=\(e.controller.number) val=\(e.value)"
		case .programChange(let e):   return "program=\(e.program)"
		case .pitchBend(let e):       return "value=\(e.value)"
		case .pressure(let e):        return "amount=\(e.amount)"
		case .notePressure(let e):    return "amount=\(e.amount)"
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
	mutating func fixTimeForEvent(from: DispFormStruct, timebase: AnyMIDIFileTimebase)  {
		var fr = from.frame
		let deltaTicks = from.delta.ticks(using: timebase)
		let ppq: Int
		switch timebase {
		case .musical(let musicalTimebase):
			ppq = Int(musicalTimebase.ticksPerQuarterNote)
		case .smpte(let smpteTimebase):
			ppq = max(1, Int(smpteTimebase.ticksPerFrame))
		}
		fr.advance(deltaTicks: Int(deltaTicks), ppq: ppq)
		self.frame = fr
	}
	
	
}

private extension MIDIFileEvent.AnyTempo {
	var bpm: Double {
		guard microsecondsPerQuarter > 0 else { return 0 }
		return 60_000_000.0 / Double(microsecondsPerQuarter)
	}
}

// MARK: - Event-specific display wrappers

extension DispFormStruct {
	static func makeDispFormStruct(what trackEvent: MIDIFileTrackEvent) -> DispFormStruct {
		let event = trackEvent.event
		switch event {
		case .cc:
			return DispFormStruct(delta: trackEvent.delta, event: event)
		case .channelPrefix:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Controller")
		case .keySignature:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Controller")
		case .noteOff:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Note Off")
		case .noteOn:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Note On")
		case .notePressure:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Note Pressure")
		case .pitchBend:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Pitch Bend")
		case .portPrefix:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Port Prefix")
		case .pressure:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Pressure")
		case .programChange:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Program Change")
		case .rpn:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "RPN")
		case .nrpn:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "NRPN")
		case .sequenceNumber:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Sequence Number")
		case .sequencerSpecific:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Sequence Specific")
		case .smpteOffset:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "SMPTE Offset")
		case .sysEx7:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Sys EX7")
		case .tempo:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Tempo")
		case .text:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Text")
		case .timeSignature:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Time Signature")
		case .universalSysEx7:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Universal SysEx7")
		case .undefinedMeta:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "Undefined Meta")
		case .xmfPatchTypePrefix:
			return DispFormStruct(delta: trackEvent.delta, event: event, status: "XMF Patch Type Prefix")
		}
	}
}

extension DispFormStruct {
	var cumulative: String { String(frame.cumulativeTicks) }
	var dataHEX: String { return event.midi1RawBytes().hex.stringValue(padTo: 2) }
	var frameInfo: String { self.frame.frameInfo }
}
