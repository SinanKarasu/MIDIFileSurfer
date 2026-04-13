//
//  MIDIInfoHeaderView.swift
//  SiKMIDIKitNew
//
//  Created by Sinan Karasu on 2/19/23.
//

import SwiftUI
import MIDIKitSMF

struct MIDIInfoHeaderView: View {
	/*@Bindable*/ var midiFileEnv: MIDIFileEnv
	var ppq: Int
	var body: some View {
		GeometryReader { proxy in
			VStack(alignment: .leading){
				if let file = midiFileEnv.midiFile {
					// Make optional and non-String types explicit and avoid LocalizedStringKey interpolation
					let urlString = midiFileEnv.fileURL?.path(percentEncoded: false) ?? "—"
					Text(verbatim: "MIDI File: \(urlString)")
					Text(verbatim: "Format: \(file.format.description)")
					Text(verbatim: "TimeBase: \(file.timeBase.description)")
					Text(verbatim: "PPQ: \(ppq)")
					Text(verbatim: "num tracks: \(file.tracks.count)")
					Text(verbatim: "Tick resolution: \(midiFileEnv.tickResolution(), default: "")")
				} else {
					Text("Waiting for a MIDI file.")
				}
			}
		}
		.border(.yellow)
	}
}

#Preview {
	MIDIInfoHeaderView(midiFileEnv: MIDIFileEnv(), ppq: 480)
}
