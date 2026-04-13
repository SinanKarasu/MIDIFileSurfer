//
//  TrackNavigatorView.swift
//  SiKMIDIKitNew
//
//  Created by Sinan Karasu on 3/9/23.
//

import SwiftUI
import MIDIKit

struct TrackNavigatorView: View {
	var tracks: [MIDIFile.Chunk.Track]
	var ppq: Int
	//@Bindable var audioEngine: AudioEngine
	@Bindable var midiFileEnv: MIDIFileEnv
	
	@State private var selectedUnits: Set<Int> = Set<Int>()
	@State var visibility: NavigationSplitViewVisibility = .all
	
	var body: some View {
		VStack {
			Text("Count: \(tracks.count)")
			NavigationSplitView(columnVisibility: $visibility) {
				List(selection: $selectedUnits) {
					ForEach(0..<tracks.count, id: \.self) { index in
						Label("Track \(index+1):", systemImage: "waveform.circle")
					}
				}
			} detail: {
				HStack {
					if midiFileEnv.midiFile != nil {
						ForEach(selectedUnits.sorted().filter { $0 < tracks.count }, id: \.self) { index in
							MIDITrackStructView(track: tracks[index], ppq: ppq)
						}
					} else {
						Text("No MIDI file loaded.")
					}
				}
			}
		}
	}
}

#Preview {
	TrackNavigatorView(tracks: [], ppq: 480, midiFileEnv: MIDIFileEnv())
}

