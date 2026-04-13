//
//  GMBankLocator.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 9/7/25.
//

import Foundation

enum GMBankLocator {

    // System DLS candidates (present on every macOS install)
    private static let systemCandidates: [String] = [
        "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls",
        "/System/Library/Components/CoreAudio.component/Contents/Resources/GM.DLS",
    ]

    /// The bundled MuseScore General SF2 (not in repo — must be added manually).
    static func bundledMuseScoreURL() -> URL? {
        Bundle.main.url(forResource: "MuseScore_General", withExtension: "sf2")
    }

    /// System GM bank (always available on macOS).
    static func systemGMBankURL() -> URL? {
        systemCandidates.first {
            FileManager.default.fileExists(atPath: $0)
        }.map { URL(fileURLWithPath: $0) }
    }

    /// Returns the best available soundbank: bundled SF2 first, system DLS as fallback.
    static func bestAvailableURL() -> URL? {
        bundledMuseScoreURL() ?? systemGMBankURL()
    }
}
