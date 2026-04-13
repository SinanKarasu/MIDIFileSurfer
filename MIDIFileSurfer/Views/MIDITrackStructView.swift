//
//  MIDITrackIView.swift
//  SiKMIDIKitNew
//
//  Created by Sinan Karasu on 4/1/23.
//

import SwiftUI
import MIDIKit

struct MIDITrackStructView: View {
	
	var track: MIDIFile.Chunk.Track
	var ppq: Int
	@State private var selection = Set<DispFormStruct.ID>()
	
	var body: some View {
		let events = track.events
		var iMesss = [DispFormStruct]()
		for event in events {
			iMesss.append(DispFormStruct.makeDispFormStruct(what: event))
		}
		
		for i in 0..<max(0, iMesss.count - 1) {
			iMesss[i + 1].fixTimeForEvent(from: iMesss[i], ppq: ppq)
		}
		
		return VStack {
			Text("MIDITrackIView, Entries: \(iMesss.count)")
			Table(iMesss, selection: $selection) {
				Group {
					TableColumn("Frame") { (row: DispFormStruct) in
						Text(row.frameInfo).foregroundColor(row.color)
					}
					TableColumn("Cumulative"){ (row: DispFormStruct) in
						Text(row.cumulative).foregroundColor(row.color)
					}
					TableColumn("Delta(ticks)") { (row: DispFormStruct) in
						Text(String(describing: row.delta)).foregroundColor(row.color)
					}
					TableColumn("Status"){ (row: DispFormStruct) in
						Text(row.status).foregroundColor(row.color)
					}
					TableColumn("Channel"){ (row: DispFormStruct) in
						Text(row.channelText).foregroundColor(row.color)
					}
				}
				Group {
					TableColumn("Primary"){ (row: DispFormStruct) in
						Text(row.primaryText).foregroundColor(row.color)
					}
					TableColumn("Secondary"){ (row: DispFormStruct) in
						Text(row.secondaryText).foregroundColor(row.color)
					}
					TableColumn("Data"){ (row: DispFormStruct) in
						Text(row.data).foregroundColor(row.color)
					}
					TableColumn("Detail"){ (row: DispFormStruct) in
						Text(row.detailText).foregroundColor(row.color)
					}
					TableColumn("DataHEX"){ (row: DispFormStruct) in
						Text(row.dataHEX).foregroundColor(row.color)
					}
					
				}
			}
		}
		.border(.purple)
	}
	
}
