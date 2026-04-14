//
//  DiskAccessOnboardingView.swift
//  MIDIFileSurfer
//
//  Shown on first launch to explain the sandbox-friendly file access flow
//  and let the user bookmark a folder for future launches.
//

import SwiftUI
import AppKit

struct DiskAccessOnboardingView: View {

    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {

            // ── Header ───────────────────────────────────────────────────
            VStack(spacing: 8) {
                Image(systemName: "pianokeys.inverse")
                    .font(.system(size: 52))
                    .foregroundColor(.accentColor)
                Text("Welcome to MIDIFileSurfer")
                    .font(.title.bold())
                Text("Click any MIDI file in the browser and it plays — no OK button needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // ── Explanation ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Folder access")
                            .font(.headline)
                        Text("macOS protects your files. Choose a folder that contains your MIDI files and MIDIFileSurfer will remember it for later.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "folder.badge.questionmark")
                        .foregroundStyle(.orange)
                        .frame(width: 28)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose a folder (recommended)")
                            .font(.headline)
                        Text("Grant read-only access to your MIDI folder. The app remembers your choice between launches.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // ── Action buttons ────────────────────────────────────────────
            HStack(spacing: 12) {
                Button("Skip for now") {
                    markSeen()
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    chooseFolder()
                } label: {
                    Label("Choose MIDI Folder", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(minWidth: 520, maxWidth: 600)
    }

    // MARK: - Actions

    private func chooseFolder() {
        _ = MIDIBookmark.promptForFolderAccess()
        markSeen()
        isPresented = false
    }

    // MARK: - Persistence

    private func markSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenDiskAccessOnboarding")
    }

}

// MARK: - Bookmark resolver (call at app launch)

enum MIDIBookmark {
    private static let legacyBookmarkKey = "midiBookmark"
    private static let legacyBookmarkPathKey = "midiBookmarkPath"
    private static let bookmarkStoreKey = "midiFolderBookmarks"
    private static let recentDirectoryKey = "midiRecentDirectoryPath"
    private static var activeFolderURLs: [String: URL] = [:]

    /// Presents a folder picker and saves a read-only security-scoped
    /// bookmark for the selected folder.
    @discardableResult
    static func promptForFolderAccess(
        title: String = "Choose your MIDI folder",
        prompt: String = "Grant Access",
        initialDirectory: URL? = nil
    ) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = "Select the folder itself, then click \(prompt). Double-click opens the folder instead of selecting it."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.prompt = prompt
        panel.directoryURL = initialDirectory

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return saveBookmark(for: url)
    }

    /// Saves a read-only security-scoped bookmark so the app can access the
    /// selected folder across launches without presenting another picker.
    @discardableResult
    static func saveBookmark(for url: URL) -> URL? {
        migrateLegacyBookmarkIfNeeded()
        let normalizedURL = url.standardizedFileURL
        let normalizedPath = normalizedURL.path

        do {
            let data = try normalizedURL.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var bookmarks = storedBookmarks()
            bookmarks[normalizedPath] = data
            UserDefaults.standard.set(bookmarks, forKey: bookmarkStoreKey)
            UserDefaults.standard.set(normalizedPath, forKey: recentDirectoryKey)
            return resolveBookmarkData(data, originalPath: normalizedPath)
        } catch {
            // Non-fatal: user can still open files manually.
            print("MIDIBookmark: failed to save bookmark — \(error)")
            return nil
        }
    }

    /// Resolves a previously saved security-scoped bookmark and starts
    /// accessing the resource. Returns the URL if successful.
    @discardableResult
    static func resumeAccess() -> [URL] {
        migrateLegacyBookmarkIfNeeded()
        var resolvedURLs: [URL] = []

        for (path, data) in storedBookmarks() {
            if let url = resolveBookmarkData(data, originalPath: path) {
                resolvedURLs.append(url)
            }
        }

        return resolvedURLs.sorted { $0.path < $1.path }
    }

    static func grantedFolderURLs() -> [URL] {
        migrateLegacyBookmarkIfNeeded()
        if !activeFolderURLs.isEmpty {
            return activeFolderURLs.values.sorted { $0.path < $1.path }
        }
        return storedBookmarks().keys.sorted().map { URL(fileURLWithPath: $0) }
    }

    static func grantedFolder(containing url: URL) -> URL? {
        let standardizedURL = url.standardizedFileURL
        return grantedFolderURLs()
            .sorted { $0.path.count > $1.path.count }
            .first { standardizedURL.isInside($0) }
    }

    static func recentDirectoryURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: recentDirectoryKey) else { return nil }
        return URL(fileURLWithPath: path)
    }

    static func rememberRecentFile(_ url: URL) {
        UserDefaults.standard.set(url.deletingLastPathComponent().path, forKey: recentDirectoryKey)
    }

    private static func resolveBookmarkData(_ data: Data, originalPath: String) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Refresh the bookmark so it stays valid.
                if let fresh = try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                                                      includingResourceValuesForKeys: nil,
                                                      relativeTo: nil) {
                    var bookmarks = storedBookmarks()
                    bookmarks[url.standardizedFileURL.path] = fresh
                    if originalPath != url.standardizedFileURL.path {
                        bookmarks.removeValue(forKey: originalPath)
                    }
                    UserDefaults.standard.set(bookmarks, forKey: bookmarkStoreKey)
                    UserDefaults.standard.set(url.standardizedFileURL.path, forKey: recentDirectoryKey)
                }
            }
            guard url.startAccessingSecurityScopedResource() else {
                print("MIDIBookmark: failed to start accessing security-scoped resource")
                return nil
            }
            activeFolderURLs[url.standardizedFileURL.path] = url
            return url
        } catch {
            print("MIDIBookmark: failed to resolve bookmark — \(error)")
            return nil
        }
    }

    private static func storedBookmarks() -> [String: Data] {
        UserDefaults.standard.dictionary(forKey: bookmarkStoreKey) as? [String: Data] ?? [:]
    }

    private static func migrateLegacyBookmarkIfNeeded() {
        guard storedBookmarks().isEmpty,
              let legacyData = UserDefaults.standard.data(forKey: legacyBookmarkKey),
              let legacyPath = UserDefaults.standard.string(forKey: legacyBookmarkPathKey)
        else { return }

        UserDefaults.standard.set([legacyPath: legacyData], forKey: bookmarkStoreKey)
        UserDefaults.standard.removeObject(forKey: legacyBookmarkKey)
        UserDefaults.standard.removeObject(forKey: legacyBookmarkPathKey)
    }
}

#Preview {
    DiskAccessOnboardingView(isPresented: .constant(true))
}
