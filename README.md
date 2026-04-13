# MIDIFileSurfer

A macOS MIDI file browser and player. Point it at a folder, click any file, and it plays — no Open button, no confirmation dialog, no friction.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## What it does

MIDIFileSurfer is built around a single idea: **surfing**. Open the file browser, navigate to a folder of MIDI files, and click through them one by one. Each click loads and starts playing the file immediately. No double-click, no Play button — just click and listen.

It also doubles as a MIDI file inspector. For every loaded file you get:

- Full track listing with instrument names (General MIDI Level 1, all 128 programs)
- Event table per track — note on/off, program changes, control changes, tempo, time signature, SysEx — with bar/beat/tick positions
- File header info: format type, PPQ or SMPTE timebase, track count
- Instrument overview across all tracks and channels

Playback controls let you adjust speed (0–2×) and pitch (±2400 cents) in real time without stopping.

## Modes

| Mode | Behaviour |
|------|-----------|
| **Immediate** (default) | Click a file → plays instantly. Panel stays open for surfing. |
| **Click to Play** | Select a file, then press Play. |

Toggle between modes with the mode button in the transport bar.

## File access

macOS protects access to your files. For surfing to work properly — especially if your MIDI files are spread across multiple folders — MIDIFileSurfer needs permission to read them.

On first launch the app walks you through two options:

**Option 1 — Choose a MIDI folder (recommended)**
Click *Choose MIDI Folder* and navigate to the folder where you keep your MIDI files. The app saves a security-scoped bookmark so it can access that folder automatically on every subsequent launch, with no further prompts.

**Option 2 — Full Disk Access**
For power users who work across many different folders. Go to *System Settings → Privacy & Security → Full Disk Access* and add MIDIFileSurfer. The onboarding screen has a button that takes you straight there.

You can re-open the permissions guide at any time from the Help menu.

## Soundbank

MIDIFileSurfer uses a bundled GM soundbank (`MuseScore_General.sf2`) for playback. This file is **not included in the repository** due to its size (≈205 MB).

To build from source, download it from the [MuseScore repository](https://github.com/musescore/MuseScore/tree/master/share/sound) and place it at:

```
MIDIFileSurfer/Supporting Files/MuseScore_General.sf2
```

The app will fall back to the system GM bank (`gs_instruments.dls`) if the bundled file is not found.

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build from source)

## Getting Started

1. Clone the repo and open `MIDIFileSurfer.xcodeproj`
2. Build and run (`⌘R`)
3. On first launch, grant folder access or Full Disk Access
4. Click *Open MIDI File* to open the file browser
5. Click any `.mid` file — it plays immediately

## Roadmap

- [ ] Folder bookmark management (add/remove multiple folders)
- [ ] Recent files list
- [ ] Per-track mute and solo
- [ ] MIDI output routing (send to external synths / DAWs)
- [ ] iPadOS port

## License

MIT — see [LICENSE](LICENSE).
