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

macOS protects access to your files. On first launch, MIDIFileSurfer asks you to choose a folder that contains your MIDI files.

Click *Choose MIDI Folder* and navigate to the folder where you keep your MIDI files. The app saves a read-only security-scoped bookmark so it can access that folder automatically on every subsequent launch, with no further prompts.

You can re-open the permissions guide at any time from the Help menu.

## Soundbank

MIDIFileSurfer uses Apple's built-in DLS synthesizer and system General MIDI
soundbank. No soundfont download or bundled sample library is required.
Audio startup failures are shown as recoverable errors.

## Finder Quick Look

The app embeds a sandboxed Quick Look preview extension for `public.midi-audio`
(`.mid` / `.midi`). Select a MIDI file in Finder and press Space. The preview
shows format, timing, initial tempo, track names and program-change instruments.
Press Play to listen with Apple's General MIDI sounds; Pause resumes from the
same position, and the timeline supports seeking. Playback never starts
automatically and stops when the preview closes or changes files.

Build and run the containing app, then enable MIDIQuickLook in System Settings
under Login Items & Extensions → Quick Look if needed. macOS chooses among
registered providers for each file type, so another MIDI preview provider can
need disabling. A signed build is needed to verify Finder integration.

Preview input is limited to 32 MB. Large or malformed MIDI files report an error
rather than starting playback. Preview metadata is parsed off the main thread.


## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (to build from source)

## Getting Started

1. Clone the repo and open `MIDIFileSurfer.xcodeproj`
2. Build and run (`⌘R`)
3. On first launch, choose a MIDI folder
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
