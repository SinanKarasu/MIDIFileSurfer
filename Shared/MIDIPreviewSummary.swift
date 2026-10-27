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
            let name = track.events.compactMap { entry -> String? in
                if case .text(let text) = entry.event, text.textType == .trackOrSequenceName {
                    return text.text
                }
                return nil
            }.first ?? "Track \(index + 1)"
            let instruments = Set(track.events.compactMap { entry -> String? in
                if case .programChange(let event) = entry.event {
                    return "Ch \(Int(event.channel) + 1): \(GeneralMIDI.name(for: Int(event.program)))"
                }
                return nil
            }).sorted()
            return Track(id: index, name: name,
                         instrument: instruments.isEmpty ? "Default program / MIDI events" : instruments.joined(separator: ", "),
                         eventCount: track.events.count)
        }
    }
}
