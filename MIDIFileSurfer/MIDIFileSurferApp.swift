//
//  MIDIFileSurferApp.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 11/25/25.
//

import SwiftUI
import AppKit

@main
struct MIDIFileSurferApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
        .commands {
            CommandGroup(replacing: .help) {
                Button("MIDIFileSurfer Support") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/SinanKarasu/MIDIFileSurfer/issues")!)
                }
                Button("Source Code") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/SinanKarasu/MIDIFileSurfer")!)
                }
                Divider()
                Button("Privacy Policy") { showDocument("PrivacyPolicy", title: "Privacy Policy") }
                Button("Third-Party Notices") { showDocument("ThirdPartyNotices", title: "Third-Party Notices") }
            }
        }
	}

    private func showDocument(_ resource: String, title: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 680, height: 520))
        scrollView.hasVerticalScroller = true
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.font = .systemFont(ofSize: 13)
        textView.string = text
        scrollView.documentView = textView
        let window = NSWindow(contentRect: scrollView.bounds,
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = title
        window.isReleasedWhenClosed = false
        window.contentView = scrollView
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
