//
//  InstrumentOverviewView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 12/6/25.
//

import SwiftUI


struct TrackInstrumentSummary: Identifiable {
	let id = UUID()
	let trackIndex: Int
	let trackName: String
	let instrumentName: String
	let midiChannel: Int?
}

struct InstrumentOverviewView: View {
	let tracks: [TrackInstrumentSummary]
	
	// Unique instrument list for quick glance
	private var uniqueInstrumentNames: [String] {
		Array(Set(tracks.map { $0.instrumentName })).sorted()
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			
			// Overall instruments used
			if !uniqueInstrumentNames.isEmpty {
				Text("Instruments used (\(uniqueInstrumentNames.count))")
					.font(.headline)
				
				Text(uniqueInstrumentNames.joined(separator: ", "))
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(2)
					.truncationMode(.tail)
			}
			
			// Track-by-track overview
			List(tracks) { info in
				HStack {
					Text("#\(info.trackIndex)")
						.font(.system(.body, design: .monospaced))
						.frame(width: 40, alignment: .trailing)
					
					VStack(alignment: .leading, spacing: 2) {
						Text(info.instrumentName)
						if !info.trackName.isEmpty {
							Text(info.trackName)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					
					Spacer()
					
					if let ch = info.midiChannel {
						Text("Ch \(ch)")
							.font(.caption)
							.foregroundStyle(.secondary)
							.foregroundStyle(Color(hue: Double(ch)/16.0, saturation: 0.5, brightness: 0.9))

					}
				}
			}
		}
		.padding()
	}
}

#Preview {
	InstrumentOverviewView(tracks: [
		TrackInstrumentSummary(trackIndex: 1,
							   trackName: "Piano Intro",
							   instrumentName: "Acoustic Grand Piano",
							   midiChannel: 1),
		TrackInstrumentSummary(trackIndex: 2,
							   trackName: "Strings",
							   instrumentName: "Violin",
							   midiChannel: 2),
		TrackInstrumentSummary(trackIndex: 3,
							   trackName: "Bass",
							   instrumentName: "Acoustic Bass",
							   midiChannel: 3),
		TrackInstrumentSummary(trackIndex: 4,
							   trackName: "Drums",
							   instrumentName: "Standard Kit",
							   midiChannel: 10)
	])
}
