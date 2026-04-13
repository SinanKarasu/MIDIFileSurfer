//
//  ContentView.swift
//  MIDIFileSurfer
//
//  Created by Sinan Karasu on 11/25/25.
//

import SwiftUI
import MIDIKit

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
                .border(.orange)
        }
        .sheet(isPresented: $showOnboarding) {
            DiskAccessOnboardingView(isPresented: $showOnboarding)
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
