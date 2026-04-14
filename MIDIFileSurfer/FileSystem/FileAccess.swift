//
//  FileAccess.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 10/20/21.
//

import SwiftUI
import UniformTypeIdentifiers

final class FileAccess: NSObject {

    var completion: (URL?) -> () = { url in
        print("No completion provided for URL: \(String(describing: url))")
    }
    private var selectionFilter: ((URL) -> Bool)?

    // MARK: - Modal (blocking) file picker

    /// Opens a blocking Open panel. Returns the selected URL, or nil if cancelled.
    /// Use this for "click Play to play" mode.
    public func filterByFileTypes(
        allowedContentTypes: [UTType],
        initialDirectory: URL? = nil,
        completion: @escaping (URL?) -> ()
    ) -> URL? {
        self.completion = completion
        let dialog = makePanel(
            allowedContentTypes: allowedContentTypes,
            multiple: false,
            initialDirectory: initialDirectory
        )
        if dialog.runModal() == .OK {
            return dialog.url
        }
        return nil
    }

    // MARK: - Non-modal (sheet) file picker

    /// Opens a non-blocking panel. For "immediate play" mode the delegate's
    /// `panelSelectionDidChange` fires as soon as the user clicks a file,
    /// calls `completion`, and closes the panel — no OK button needed.
    public func filterByFileTypesSheet(
        allowedContentTypes: [UTType],
        initialDirectory: URL? = nil,
        selectionFilter: ((URL) -> Bool)? = nil,
        completion: @escaping (URL?) -> ()
    ) {
        self.completion = completion
        self.selectionFilter = selectionFilter
        let dialog = makePanel(
            allowedContentTypes: allowedContentTypes,
            multiple: false,
            initialDirectory: initialDirectory
        )

        dialog.begin { [weak self, weak dialog] response in
            guard let self, let dialog else { return }
            // Fallback: if the user navigated to a file and hit Open without
            // the selection-change path having already fired, deliver it now.
            if response == .OK, let url = dialog.url {
                self.completion(url)
            }
        }
    }

    // MARK: - Shared panel factory

    private func makePanel(
        allowedContentTypes: [UTType],
        multiple: Bool,
        initialDirectory: URL?
    ) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.delegate = self
        panel.title = "Select a MIDI File"
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = multiple
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = allowedContentTypes
        panel.directoryURL = initialDirectory
        return panel
    }
}

// MARK: - NSOpenSavePanelDelegate

extension FileAccess: NSOpenSavePanelDelegate {

    /// Fires whenever the user clicks (highlights) a file in the panel.
    /// Calls completion immediately so playback starts — the panel stays open
    /// so the user can keep surfing files with single clicks.
    public func panelSelectionDidChange(_ sender: Any?) {
        guard let panel = sender as? NSOpenPanel,
              let first = panel.urls.first else { return }

        if let selectionFilter, !selectionFilter(first) {
            return
        }
        completion(first)
    }
}
