import Foundation
import SwiftMIDIFile

struct MIDIPreviewSummary: Sendable {
    struct Track: Identifiable, Sendable {
        let id: Int
        let name: String
        let instrument: String
        let eventCount: Int
    }
    let format: String
    let timebase: String
    let tempo: String
    let tracks: [Track]

    init(data: Data) throws {
        let file = try AnyMIDI1File(data: data)
        format = file.format.description
        timebase = file.timebase.description
        switch file {
        case .musical(let musical):
            let bpm: Double = musical.initialTempo?.bpm ?? 120.0
            tempo = String(format: "%.1f BPM (initial)", bpm)
        case .smpte:
            tempo = "SMPTE timing"
        }
        tracks = file.surferTracks.enumerated().map { index, track in
            Track(track: track, index: index)
        }
    }
}

extension MIDIPreviewSummary.Track {
    init(track: MIDIFileTrack, index: Int) {
        let name = track.events.compactMap { entry -> String? in
            if case .text(let text) = entry.event, text.textType == .trackOrSequenceName {
                return text.text
            }
            return nil
        }.first ?? "Track \(index + 1)"
        var channels = Set<Int>()
        var programs: [Int: Set<Int>] = [:]
        var hasLyrics = false
        var hasText = false
        for entry in track.events {
            switch entry.event {
            case .noteOn(let event): channels.insert(Int(event.channel))
            case .noteOff(let event): channels.insert(Int(event.channel))
            case .cc(let event): channels.insert(Int(event.channel))
            case .pitchBend(let event): channels.insert(Int(event.channel))
            case .pressure(let event): channels.insert(Int(event.channel))
            case .notePressure(let event): channels.insert(Int(event.channel))
            case .programChange(let event):
                let channel = Int(event.channel)
                channels.insert(channel)
                programs[channel, default: []].insert(Int(event.program))
            case .text(let event):
                hasLyrics = hasLyrics || event.textType == .lyric
                hasText = hasText || event.textType == .text
            default: break
            }
        }
        // Older karaoke files often store words as generic text events.
        let lyricName = ["words", "lyrics", "lyric"].contains(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        var descriptions = channels.sorted().map { channel -> String in
            if channel == 9 { return "Ch 10: Percussion" }
            let names = programs[channel]?.sorted().map { GeneralMIDI.name(for: $0) }
            return "Ch \(channel + 1): " + (names?.joined(separator: ", ") ?? "Acoustic Grand Piano (default)")
        }
        if hasLyrics || (hasText && lyricName) { descriptions.append("Lyrics") }
        if descriptions.isEmpty { descriptions = [hasText ? "Text and metadata" : "Metadata"] }
        self.init(id: index, name: name,
                  instrument: descriptions.joined(separator: " • "),
                  eventCount: track.events.count)
    }
}
