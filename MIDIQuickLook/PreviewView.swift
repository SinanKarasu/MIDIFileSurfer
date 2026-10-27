import SwiftUI

struct PreviewView: View {
    let filename: String
    let summary: MIDIPreviewSummary
    @Bindable var player: PreviewPlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(filename, systemImage: "music.note.list")
                .font(.title2.bold()).lineLimit(2)
            HStack {
                Text(summary.format)
                Text("\(summary.tracks.count) tracks")
                Text(summary.tempo)
            }
            .font(.callout).foregroundStyle(.secondary)
            Text(summary.timebase).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button(action: player.toggle) {
                    Label(player.isPlaying ? "Pause" : "Play",
                          systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(minWidth: 65)
                }
                .disabled(player.duration <= 0)
                Text(time(player.position)).monospacedDigit()
                Slider(value: Binding(get: { player.position }, set: { player.seek(to: $0) }),
                       in: 0...max(player.duration, 0.01))
                    .accessibilityLabel("Playback position")
                    .disabled(player.duration <= 0)
                Text(time(player.duration)).monospacedDigit()
            }
            if let error = player.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red).font(.callout).textSelection(.enabled)
            }
            Divider()
            List(summary.tracks) { track in
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name).font(.headline)
                    Text(track.instrument).foregroundStyle(.secondary)
                    Text("\(track.eventCount) events").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 4)
            }
            .listStyle(.inset)
            Text("Apple General MIDI • MIDIFileSurfer")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
    }

    private func time(_ seconds: Double) -> String {
        let seconds = seconds.isFinite ? Int(max(0, seconds)) : 0
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
