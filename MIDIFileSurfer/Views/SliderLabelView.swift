//
//  SliderLabelView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 12/5/25.
//

import SwiftUI

struct SliderLabelView: View {
	var label: String
	let resetToDefault: () -> Void
	@State private var hovering = false
	
	var body: some View {
		Button(action: resetToDefault) {
			Text(label)
				.foregroundStyle(hovering ? Color.accentColor : Color.primary)
				.underline(hovering)                // optional, but very clear
		}
		.buttonStyle(.plain)                        // no bezel, just text
		.onHover { hovering = $0 }                  // highlight on hover (macOS only)
		//.cursor(.pointingHand)                      // standard “clickable” cursor (macOS only)
		.help("Click to reset speed to 1.0×")       // tooltip
	}
}

