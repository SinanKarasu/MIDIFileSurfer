//
//  DiskAccessOnboardingView.swift
//  MIDIFileSurfer
//
//  Shown on first launch to explain file-access permissions and let the user
//  either bookmark a folder (App Sandbox friendly) or open Full Disk Access
//  settings (for power users who run outside the App Store sandbox).
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
                        Text("Folder access required")
                            .font(.headline)
                        Text("macOS protects your files. To browse and instantly play MIDI files from any folder, you need to grant access first.")
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
                        Text("Option 1 — Choose a folder (recommended)")
                            .font(.headline)
                        Text("Grant access to your MIDI folder. The app remembers your choice between launches.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Option 2 — Full Disk Access")
                            .font(.headline)
                        Text("Gives the app access to all folders. Set this in System Settings → Privacy & Security → Full Disk Access.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.open.fill")
                        .foregroundStyle(.green)
                        .frame(width: 28)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // ── Action buttons ────────────────────────────────────────────
            HStack(spacing: 12) {

                Button {
                    openFullDiskAccessSettings()
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Skip for now") {
                    markSeen()
                    isPresented = false
                }
                .buttonStyle(.bordered)

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
        let panel = NSOpenPanel()
        panel.title = "Choose your MIDI folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.prompt = "Grant Access"

        if panel.runModal() == .OK, let url = panel.url {
            saveBookmark(for: url)
        }
        markSeen()
        isPresented = false
    }

    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
        markSeen()
        isPresented = false
    }

    // MARK: - Persistence

    private func markSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenDiskAccessOnboarding")
    }

    /// Saves a security-scoped bookmark so the app can access the folder
    /// across launches without presenting another picker.
    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: "midiBookmark")
        } catch {
            // Non-fatal: user can still open files manually.
            print("DiskAccessOnboarding: failed to save bookmark — \(error)")
        }
    }
}

// MARK: - Bookmark resolver (call at app launch)

enum MIDIBookmark {
    /// Resolves a previously saved security-scoped bookmark and starts
    /// accessing the resource. Returns the URL if successful.
    @discardableResult
    static func resumeAccess() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: "midiBookmark") else { return nil }
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
                if let fresh = try? url.bookmarkData(options: .withSecurityScope,
                                                      includingResourceValuesForKeys: nil,
                                                      relativeTo: nil) {
                    UserDefaults.standard.set(fresh, forKey: "midiBookmark")
                }
            }
            url.startAccessingSecurityScopedResource()
            return url
        } catch {
            print("MIDIBookmark: failed to resolve bookmark — \(error)")
            return nil
        }
    }
}

#Preview {
    DiskAccessOnboardingView(isPresented: .constant(true))
}
