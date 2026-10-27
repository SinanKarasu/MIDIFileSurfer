# Quick Look development and verification

Branch: `feature/quicklook-midi-playback`.
The pre-existing uncommitted model/inspector work is preserved separately in
commit `3e9a303` before the Quick Look feature changes.

## Implementation

- The containing macOS app embeds `MIDIQuickLook.appex` and declares itself an
  alternate viewer for `public.midi-audio`. It can receive Finder Open With URLs.
- The preview displays file format, timing resolution, initial tempo and tracks
  with program-change instruments. It offers Play/Pause, elapsed/total time and
  seeking. There is no autoplay.
- Both playback paths use Apple's DLS synth (`kAudioUnitSubType_DLSSynth`).
  The system owns sample loading. No bundled soundfont or system file path is used.
- Preview loading reads and closes the file, parses metadata off the main thread,
  and retains in-memory MIDI data for playback. Files above 32 MB are rejected.
- Preview disappearance or replacement stops playback, silences MIDI channels,
  invalidates the playback timer and releases the audio graph and file data.
- Audio engine/sequencer startup failures in the main app display an error;
  the extension shows playback errors inline. Soundbank fatal errors are removed.

## Verified on October 27, 2026

- Five XCTest cases passed: metadata/default tempo; malformed-file rejection;
  load/seek/reset without autoplay; preview controller preparation/disappearance;
  offline audio rendering from Apple's synth with nonzero sample output.
- Signed Release builds succeeded for arm64 and x86_64 using the configured
  development identity. This is development signing, not an App Store archive.
- Verified the embedded extension's sandbox and read-only file entitlements.
- Registered a signed development copy and observed the custom Finder preview
  with track/instrument information, a Pause button and advancing elapsed time.
- Initial Finder tests showed the generic icon because an existing Quick Look
  host cached its providers. Installing the development copy and refreshing that
  host allowed the new extension to load.

Development app installed at:
`/Users/sinan/Applications/MIDIFileSurfer-QuickLook-Development.app`.
This is a local test copy; rebuild and replace it when testing later revisions.
No App Store upload, GitHub push or default MIDI-file-handler change was made.

## Commands

```sh
xcodebuild -project MIDIFileSurfer.xcodeproj -scheme MIDIFileSurfer \
  -destination 'platform=macOS' -derivedDataPath /tmp/MIDIFileSurfer-review \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project MIDIFileSurfer.xcodeproj -scheme MIDIFileSurfer \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath /tmp/MIDIFileSurfer-signed build
```

## Before App Store submission

Exercise real-world multi-instrument/percussion files, tempo changes and SMPTE
files on a clean Mac. Manually verify Pause/Resume, seek, end/replay, closing a
playing preview and switching files repeatedly in both Finder's preview pane
and its Space-bar window. Check accessibility and narrow preview sizes. Review
all dependency notices, sample MIDI redistribution rights, privacy declarations,
store metadata and distribution signing. These are release checks, not implied
by successful development builds or the automated tests above.
