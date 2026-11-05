# MIDIFileSurfer — Mac App Store 1.0

Release scope: free macOS app, with public source on GitHub. iPadOS and visionOS are deferred, with no promise of a port. No accounts, ads, subscriptions, or in-app purchases are planned.

## Already checked

- [x] App and Quick Look extension build on the new Mac.
- [x] Seven automated tests pass, including Apple synth audio rendering and shared track descriptions.
- [x] Zero-speed handling and misleading track labels are fixed locally.
- [x] Project enables App Sandbox and read-only user-selected file access for the app and extension.
- [x] App source has an MIT license; Git remote points to https://github.com/SinanKarasu/MIDIFileSurfer.

These checks are not App Store approval. Source changes through build 2 are committed and pushed on feature/quicklook-midi-playback.

## November 5 release preparation

- Build 1.0 (2) was archived with signing and uploaded successfully through Xcode Organizer.
- App and Quick Look extension are arm64 only, minimum macOS 26.0, version 1.0, build 2.
- Release build and all seven automated tests passed.
- Build 2 bundles third-party MIT notices, a local privacy policy, and the UserDefaults privacy manifest (CA92.1). Help menu links expose notices, privacy, support, and source.
- Public privacy policy: https://github.com/SinanKarasu/MIDIFileSurfer/blob/feature/quicklook-midi-playback/PRIVACY.md
- App Store Connect: Music category, subtitle, calculated 4+ age rating, reviewer notes, no sign-in requirement, and manual release saved.
- Privacy disclosure is saved as Data Not Collected but NOT published; the account holder must confirm Apple's accuracy declaration.
- Pricing and availability remain to be saved. Intended price: free ($0.00).
- Build 2 still needs selecting after processing, reviewer contact information completing, and final submission. No public App Store review submission has been made.
- Bundled DemoLoop.mid redistribution permission is awaiting confirmation from Sinan. TestFlight-installed candidate smoke testing is still outstanding.


## Before making the release build

- [ ] Finish the icon and check small Dock/Finder sizes and the archived app's icon.
- [ ] Review the local changes, commit them, and publish the release source. Confirm the GitHub repository is public and the README matches the shipping features.
- [ ] Add About/Help links for source, support, privacy policy, and third-party notices. Suggested source text: “MIDIFileSurfer is free and open source. App source is available on GitHub under the MIT license. Third-party components retain their respective licenses.”
- [ ] Review all dependency licenses and include required notices. Verify redistribution rights for DemoLoop.mid and any MIDI files used in screenshots or review materials.
- [ ] Audit required-reason API use and add the appropriate PrivacyInfo.xcprivacy declarations. The app uses UserDefaults and currently has no checked-in privacy manifest. Inspect dependency manifests and the final archive as well.
- [ ] Publish a privacy policy and complete App Store privacy answers after checking the app and dependencies. “Data Not Collected” is appropriate only if the audit supports it; local file access alone is not off-device data collection.
- [ ] Make folder access easy to find again after onboarding. Verify adding another folder, cancelling the picker, relaunching, stale bookmarks, unavailable volumes, denied access, and iCloud files that are not downloaded.

## File-access wording

Use folder selection as the normal route. Proposed onboarding text:

> Choose a folder containing your MIDI files. MIDIFileSurfer remembers your permission and only reads those files. You can grant access to another folder when needed. Full Disk Access is not required for normal use.

Full Disk Access and App Sandbox are separate protections. Full Disk Access does not grant a sandboxed app access to arbitrary files without the appropriate sandbox permission. Do not advertise it as a replacement for choosing folders. The existing error text mentions it for non-App-Store builds; review that wording before shipping. Any optional troubleshooting guidance should describe a demonstrated protected-folder problem and remain secondary to folder selection. Another app's onboarding does not establish this app's review outcome.

## Manual release testing

- [ ] Test the signed distribution candidate as a fresh user with no development permissions or saved bookmarks, on the oldest supported macOS and the current shipping macOS. Check Apple silicon and Intel if both are shipped.
- [ ] Exercise immediate surfing and click-to-play; change files rapidly; cancel dialogs; open from Finder; reject malformed files without getting stuck.
- [ ] Check Play/Stop, end-of-file/replay, volume, pitch, minimum/maximum speed, silence after stopping, closing windows, quitting, and changing audio output devices.
- [ ] Use multi-instrument, percussion, lyrics, tempo-change, time-signature-change, SMPTE, long, and malformed MIDI files. Check inspector timing and track descriptions.
- [ ] Verify the installed Quick Look extension in Finder preview panes and Space-bar previews: Play/Pause, seek, end/replay, closing while playing, switching files, and oversized/malformed-file errors. Explain enabling the extension and competing providers in Help.
- [ ] Check keyboard navigation, VoiceOver labels, contrast, light/dark appearance, and small windows.

## App Store Connect and submission

- [ ] Confirm active Developer Program membership, current agreements, and access to the developer team. Free apps do not require the Paid Apps Agreement unless paid content is added.
- [ ] Create the macOS app record with the intended bundle ID, version, build number, category, age rating, and free price. Set availability and answer any applicable regional/trader questions.
- [ ] Prepare final screenshots, description, subtitle, keywords, support URL, privacy-policy URL, and copyright. Describe only shipping features; include the GitHub source link without promising future platforms.
- [ ] Archive in Xcode using the current submission toolchain requirements. Use the App Store Connect distribution workflow; validate signing, provisioning, sandbox entitlements, embedded extension, architectures, and privacy declarations.
- [ ] Upload the archive, resolve validation issues, and complete export-compliance questions based on the actual app and dependencies. No separate Developer ID download is part of this plan.
- [ ] Test the uploaded build through TestFlight where practical. Give App Review contact information and short instructions for folder selection and Quick Look testing. Supply a redistributable sample MIDI file if useful.
- [ ] Select manual release, submit, address review feedback, and release after approval. Confirm the store-installed build works before announcing it to the Logic Pro Facebook group. Follow the group's promotion rules.

## Apple references

Checked October 28, 2026. Recheck requirements at submission time.

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Submitting an app](https://developer.apple.com/app-store/submitting/)
- [Accessing files from App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [Apple DTS explanation of Full Disk Access versus App Sandbox](https://developer.apple.com/forums/thread/124895)
- [Privacy manifests and required-reason APIs](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
- [App privacy information](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Agreements for free and paid apps](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements)
