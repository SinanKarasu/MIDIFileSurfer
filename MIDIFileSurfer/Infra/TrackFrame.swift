//
//  TrackFrame.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 12/12/25.
//

import SwiftUI
import MIDIKitSMF
import SwiftRadix

/// Musical position state (for PPQ time base).
struct TrackFrame {
	// time signature (real denominator, not exponent)
	var numerator: Int = 4
	var denominator: Int = 4
	
	// position (0-based internally; add +1 for display)
	var bar: Int = 0
	var beat: Int = 0
	/// ticks within the current beat
	var tickWithinBeat: Int = 0
	/// absolute cumulative ticks from beginning of track
	var cumulativeTicks: Int = 0
	
	// extras from MIDI time-sig meta
	var metronomeClocks: UInt8 = 0x18   // 24
	var thirtySecondsPerQuarter: UInt8 = 0x08 // 8
	
	// advance by delta ticks and recompute bar/beat/tick
	mutating func advance(deltaTicks: Int, ppq: Int) {
		cumulativeTicks += deltaTicks
		let ticksPerBeat = (ppq * 4) / denominator
		let ticksPerBar  = numerator * ticksPerBeat
		let inBar        = cumulativeTicks % ticksPerBar
		bar              = cumulativeTicks / ticksPerBar
		beat             = inBar / ticksPerBeat
		tickWithinBeat   = inBar % ticksPerBeat
	}
	
	// apply a new time signature (MIDI stores denom as exponent)
	mutating func applyTimeSignature(numer: UInt8, denomExp: UInt8,
									 metClocks: UInt8, n32perQN: UInt8,
									 ppq: Int)
	{
		numerator = Int(numer)
		denominator = 1 << Int(denomExp)
		metronomeClocks = metClocks
		thirtySecondsPerQuarter = n32perQN
		// Re-evaluate position under new meter using same cumulativeTicks
		advance(deltaTicks: 0, ppq: ppq)
	}
}

extension TrackFrame {
	/// 1-based BBT for UI
	var bbtString: String { "\(bar + 1):\(beat + 1):\(tickWithinBeat)" }
	
	// For display, we’ll show bar/beat and a simple subdivision:remaining using denominator as subdivisions per beat.
	// This needs PPQ to be exact; since DispForm2 does not carry ppq, we’ll show tickWithinBeat directly as ticks.
	var frameInfo: String {
		"(\(numerator)/\(denominator))\(bar + 1):\(beat + 1):\(tickWithinBeat)"
	}

}
