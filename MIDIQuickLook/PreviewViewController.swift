import AppKit
import QuickLookUI
import SwiftUI

@MainActor
final class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {
    private let player = PreviewPlayer()
    private var generation = UUID()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 720, height: 480))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        player.stop()
        let request = UUID()
        generation = request
        Task {
            do {
                let (data, summary) = try await Task.detached(priority: .userInitiated) {
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 32 * 1024 * 1024 else {
                        throw NSError(domain: "MIDIQuickLook", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "This MIDI file is too large to preview (32 MB limit)."])
                    }
                    let file = try FileHandle(forReadingFrom: url)
                    defer { try? file.close() }
                    let data = try file.read(upToCount: 32 * 1024 * 1024 + 1) ?? Data()
                    guard data.count <= 32 * 1024 * 1024 else {
                        throw NSError(domain: "MIDIQuickLook", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "This MIDI file is too large to preview (32 MB limit)."])
                    }
                    return (data, try MIDIPreviewSummary(data: data))
                }.value
                guard generation == request else { handler(CancellationError()); return }
                try player.load(data)
                for child in children { child.view.removeFromSuperview(); child.removeFromParent() }
                let host = NSHostingController(rootView: PreviewView(filename: url.lastPathComponent,
                                                                   summary: summary, player: player))
                addChild(host)
                host.view.frame = view.bounds
                host.view.autoresizingMask = [.width, .height]
                view.addSubview(host.view)
                preferredContentSize = NSSize(width: 720, height: 480)
                handler(nil)
            } catch { handler(error) }
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        generation = UUID()
        player.stop()
    }
}
