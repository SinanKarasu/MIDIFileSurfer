//
//  ResettableSlider.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 12/5/25.
//

import SwiftUI


private enum LabelColumn: AlignmentID {
	static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.trailing] }
}
extension HorizontalAlignment {
	static let labelColumn = HorizontalAlignment(LabelColumn.self)
}

struct ResettableAlignedSliderView: View {
	var label: String
	@Binding var value: Float
	let defaultValue: Float
	let range: ClosedRange<Float>
	
	var body: some View {
		HStack {
			SliderLabelView(label: label)
			{
				value = defaultValue      // double-click to reset
			}
			.alignmentGuide(.labelColumn) { d in d[.trailing] }
			Slider(value: $value, in: range)
				.alignmentGuide(.labelColumn) { d in d[.leading] }
		}
	}
}

