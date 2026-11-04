//
//  MIDISMFView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 2/15/23.
//

import SwiftUI
import SwiftMIDIFile

struct MIDISMFView: View {
    @Bindable var audioEngine: AudioEngine
    @Bindable var midiFileEnv: MIDIFileEnv

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                Text("MIDI File Surfer")
                    .font(.headline)
                SequencerView(env: midiFileEnv, audioEngine: audioEngine)
                    .frame(height: 150)
                if let file = midiFileEnv.midiFile {
                    let ppq = effectivePPQ(for: file)
                    let instrumentSummaries = makeInstrumentSummaries(from: file)
                    HStack {
                        MIDIInfoHeaderView(midiFileEnv: midiFileEnv, ppq: ppq)
                        Spacer()
                        InstrumentOverviewView(tracks: instrumentSummaries)
                    }
                    .frame(maxHeight: 200)
                    TrackNavigatorView(tracks: file.surferTracks, ppq: ppq, midiFileEnv: midiFileEnv)
                }
            }
        }
    }

    // MARK: - Tick resolution

    /// Returns the effective PPQ for display purposes.
    /// For musical (PPQ) files this is exact. For SMPTE/timecode files it returns
    /// fps × ticksPerFrame, which gives ticks-per-second — a consistent value that
    /// lets downstream BBT formatting show something meaningful.
    func effectivePPQ(for file: AnyMIDI1File) -> Int {
        switch file.timebase {
        case .musical(let timebase):
            return Int(timebase.ticksPerQuarterNote)
        case .smpte(let timebase):
            let fps: Double
            switch timebase.frameRate {
            case .fps24:        fps = 24.0
            case .fps25:        fps = 25.0
            case .fps29_97d:    fps = 30_000.0 / 1_001.0   // 29.97 drop-frame
            case .fps30:        fps = 30.0
            }
            return Int((fps * Double(timebase.ticksPerFrame)).rounded())
        }
    }

    // MARK: - Instrument summary

    func makeInstrumentSummaries(from file: AnyMIDI1File) -> [TrackInstrumentSummary] {
        file.surferTracks.enumerated().map { index, track in
            let summary = MIDIPreviewSummary.Track(track: track, index: index)
            return TrackInstrumentSummary(
                trackIndex: index + 1,
                trackName: summary.name,
                instrumentName: summary.instrument,
                midiChannel: nil // Channels are included in the shared description.
            )
        }
    }
}
