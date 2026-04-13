//
//  FileAccess.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 10/20/21.
//

import SwiftUI
import UniformTypeIdentifiers
import os.log

open class FileAccess: NSObject {

    enum FileIntent {
        case openRead
        case openReadMultiple
        case saveWrite
        case chooseDirectory
    }

    var intent: FileIntent = .openRead

    var completion: (URL?) -> () = { url in
        print("No completion provided for URL: \(String(describing: url))")
    }

    // Keeps the non-modal panel alive and lets us close it programmatically.
    private weak var activePanel: NSOpenPanel?

    // MARK: - Modal (blocking) file picker

    /// Opens a blocking Open panel. Returns the selected URL, or nil if cancelled.
    /// Use this for "click Play to play" mode.
    public func filterByFileTypes(
        allowedContentTypes: [UTType],
        completion: @escaping (URL?) -> ()
    ) -> URL? {
        self.completion = completion
        let dialog = makePanel(allowedContentTypes: allowedContentTypes, multiple: false)
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
        completion: @escaping (URL?) -> ()
    ) {
        self.completion = completion
        let dialog = makePanel(allowedContentTypes: allowedContentTypes, multiple: false)
        activePanel = dialog

        dialog.begin { [weak self, weak dialog] response in
            guard let self, let dialog else { return }
            // Fallback: if the user navigated to a file and hit Open without
            // the selection-change path having already fired, deliver it now.
            if response == .OK, let url = dialog.url {
                self.completion(url)
            }
            self.activePanel = nil
        }
    }

    // MARK: - Shared panel factory

    private func makePanel(allowedContentTypes: [UTType], multiple: Bool) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.delegate = self
        panel.title = "Select a MIDI File"
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = multiple
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = allowedContentTypes
        return panel
    }

    // MARK: - Directory picker

    public func selectSingleDirectory() -> URL? {
        let dialog = NSOpenPanel()
        dialog.delegate = self
        dialog.title = "Choose a folder"
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        if dialog.runModal() == .OK {
            return dialog.url
        }
        return nil
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

        completion(first)
    }

    public func panel(_ sender: Any, validate url: URL) throws {
        switch intent {
        case .saveWrite:
            if !FileManager.default.isWritableFile(atPath: url.path) {
                throw CocoaError(.fileWriteVolumeReadOnly)
            }
        case .chooseDirectory:
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue else {
                throw CocoaError(.fileReadNoSuchFile)
            }
        default:
            break
        }
    }

    public func panel(_ sender: Any, shouldEnable url: URL) -> Bool { true }

    public func panel(_ sender: Any, userEnteredFilename filename: String, confirmed: Bool) -> String? {
        filename
    }
}
