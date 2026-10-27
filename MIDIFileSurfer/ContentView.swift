//
//  ContentView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 11/25/25.
//

import SwiftUI

struct ContentView: View {
    @State var audioEngine = AudioEngine()
    @State var midiFileEnv = MIDIFileEnv()

    @State private var showOnboarding =
        !UserDefaults.standard.bool(forKey: "hasSeenDiskAccessOnboarding")

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "music.note")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Image(systemName: "pianokeys.inverse")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Image(systemName: "music.quarternote.3")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Image(systemName: "music.note.list")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }
            MIDISMFView(audioEngine: audioEngine, midiFileEnv: midiFileEnv)
        }
        .alert("Playback Unavailable", isPresented: Binding(
            get: { audioEngine.playbackError != nil },
            set: { if !$0 { audioEngine.playbackError = nil } }
        )) {
            Button("OK") { audioEngine.playbackError = nil }
        } message: {
            Text(audioEngine.playbackError ?? "")
        }
        .sheet(isPresented: $showOnboarding) {
            DiskAccessOnboardingView(isPresented: $showOnboarding)
        }
        .onOpenURL { url in
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                try midiFileEnv.load(url: url)
                try audioEngine.sequencerModule.processURL(url: url)
            } catch {
                audioEngine.playbackError = "Couldn’t open \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
        .onAppear {
            // Resume any previously granted security-scoped folder access.
            MIDIBookmark.resumeAccess()
        }
    }
}

#Preview {
    ContentView()
}
