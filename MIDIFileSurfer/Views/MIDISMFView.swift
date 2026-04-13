//
//  MIDISMFView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 2/15/23.
//

import SwiftUI
import MIDIKit
import MIDIKitSMF

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
                    TrackNavigatorView(tracks: file.tracks, ppq: ppq, midiFileEnv: midiFileEnv)
                }
            }
        }
    }

    // MARK: - Tick resolution

    /// Returns the effective PPQ for display purposes.
    /// For musical (PPQ) files this is exact. For SMPTE/timecode files it returns
    /// fps × ticksPerFrame, which gives ticks-per-second — a consistent value that
    /// lets downstream BBT formatting show something meaningful.
    func effectivePPQ(for file: MIDIFile) -> Int {
        switch file.timeBase {
        case .musical(let ticksPerQuarterNote):
            return Int(ticksPerQuarterNote)
        case .timecode(let smpteFormat, let ticksPerFrame):
            let fps: Double
            switch smpteFormat {
            case .fps24:        fps = 24.0
            case .fps25:        fps = 25.0
            case .fps29_97d:    fps = 30_000.0 / 1_001.0   // 29.97 drop-frame
            case .fps30:        fps = 30.0
            @unknown default:   fps = 30.0
            }
            return Int((fps * Double(ticksPerFrame)).rounded())
        }
    }

    // MARK: - Instrument summary

    func makeInstrumentSummaries(from file: MIDIFile) -> [TrackInstrumentSummary] {
        file.tracks.enumerated().compactMap { idx, track in
            summaryForTrack(track, index: idx + 1)
        }
    }
}

// MARK: - Track/instrument helpers

extension MIDISMFView {
    func summaryForTrack(_ track: MIDIFile.Chunk.Track, index: Int) -> TrackInstrumentSummary? {
        let trackName = findTrackName(in: track) ?? "Track \(index)"
        if let (channel, program) = findFirstProgramChange(in: track) {
            return TrackInstrumentSummary(
                trackIndex: index,
                trackName: trackName,
                instrumentName: gmInstrumentName(for: program),
                midiChannel: Int(channel) + 1
            )
        }
        return TrackInstrumentSummary(
            trackIndex: index,
            trackName: trackName,
            instrumentName: "Unknown Instrument",
            midiChannel: 1
        )
    }

    func findTrackName(in track: MIDIFile.Chunk.Track) -> String? {
        for ev in track.events {
            if case .text(_, let e) = ev, e.textType == .trackOrSequenceName {
                return e.text
            }
        }
        return nil
    }

    func findFirstProgramChange(in track: MIDIFile.Chunk.Track) -> (channel: Int, program: Int)? {
        for ev in track.events {
            if case .programChange(_, let e) = ev {
                return (channel: Int(e.channel), program: Int(e.program))
            }
        }
        return nil
    }

    // MARK: - Full General MIDI Level 1 program name table (programs 0–127)

    func gmInstrumentName(for program: Int) -> String {
        let names: [String] = [
            // Piano (0–7)
            "Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano",
            "Honky-tonk Piano", "Electric Piano 1", "Electric Piano 2",
            "Harpsichord", "Clavinet",
            // Chromatic Percussion (8–15)
            "Celesta", "Glockenspiel", "Music Box", "Vibraphone",
            "Marimba", "Xylophone", "Tubular Bells", "Dulcimer",
            // Organ (16–23)
            "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
            "Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
            // Guitar (24–31)
            "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)",
            "Electric Guitar (jazz)", "Electric Guitar (clean)",
            "Electric Guitar (muted)", "Overdriven Guitar",
            "Distortion Guitar", "Guitar Harmonics",
            // Bass (32–39)
            "Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)",
            "Fretless Bass", "Slap Bass 1", "Slap Bass 2",
            "Synth Bass 1", "Synth Bass 2",
            // Strings (40–47)
            "Violin", "Viola", "Cello", "Contrabass",
            "Tremolo Strings", "Pizzicato Strings",
            "Orchestral Harp", "Timpani",
            // Ensemble (48–55)
            "String Ensemble 1", "String Ensemble 2",
            "Synth Strings 1", "Synth Strings 2",
            "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
            // Brass (56–63)
            "Trumpet", "Trombone", "Tuba", "Muted Trumpet",
            "French Horn", "Brass Section", "Synth Brass 1", "Synth Brass 2",
            // Reed (64–71)
            "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
            "Oboe", "English Horn", "Bassoon", "Clarinet",
            // Pipe (72–79)
            "Piccolo", "Flute", "Recorder", "Pan Flute",
            "Blown Bottle", "Shakuhachi", "Whistle", "Ocarina",
            // Synth Lead (80–87)
            "Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)",
            "Lead 4 (chiff)", "Lead 5 (charang)", "Lead 6 (voice)",
            "Lead 7 (fifths)", "Lead 8 (bass + lead)",
            // Synth Pad (88–95)
            "Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)",
            "Pad 4 (choir)", "Pad 5 (bowed)", "Pad 6 (metallic)",
            "Pad 7 (halo)", "Pad 8 (sweep)",
            // Synth Effects (96–103)
            "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)",
            "FX 4 (atmosphere)", "FX 5 (brightness)", "FX 6 (goblins)",
            "FX 7 (echoes)", "FX 8 (sci-fi)",
            // Ethnic (104–111)
            "Sitar", "Banjo", "Shamisen", "Koto",
            "Kalimba", "Bagpipe", "Fiddle", "Shanai",
            // Percussive (112–119)
            "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock",
            "Taiko Drum", "Melodic Tom", "Synth Drum", "Reverse Cymbal",
            // Sound Effects (120–127)
            "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet",
            "Telephone Ring", "Helicopter", "Applause", "Gunshot",
        ]
        guard program >= 0, program < names.count else {
            return "Program \(program)"
        }
        return names[program]
    }
}
