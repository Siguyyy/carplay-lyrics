# CarPlay Lyrics

Synced lyrics for Apple Music or Spotify, designed for a glance on the lock screen and (on supported iOS versions) CarPlay. This project is a personal-use sideload build based on the DriveVerse codebase.

## Compatibility

- iOS 17+ runs the iPhone app and Live Activity on the Lock Screen.
- Live Activity mirroring onto CarPlay requires iOS 26+. On iOS 17, use the in-app CarPlay Preview to inspect the layout; the preview does not simulate a connected vehicle or validate system mirroring.
- Apple Music detection is local. Spotify uses your own account via Spotify's Web API and PKCE.
- Lyrics use LRCLIB. This is for personal use; public distribution requires a properly licensed lyrics provider.

## Build and preview

On a Mac with Xcode 16 or newer:

1. Generate/open `DriveVerse.xcodeproj` with `brew install xcodegen && ./scripts/generate.sh`.
2. Select an iOS 17+ simulator and run the app. The home screen has **Preview on CarPlay** for a sample dashboard tile.
3. To test device-only playback detection and actual Live Activity display, use a physical iPhone. Actual CarPlay mirroring requires iOS 26+ and a compatible vehicle.

For a local unsigned simulator build, Xcode handles signing automatically. For a phone build, set your own team and bundle identifier in `project.yml`, regenerate, and configure signing in Xcode.

Spotify support is optional. To enable it, add your Spotify client ID in the app, register `carplaylyrics://callback` as the redirect URI in your Spotify Developer app, and authorize Spotify. **Spotify Development Mode requires an active Premium subscription on the Developer app owner’s account.** The Spotify account connected in CarPlay Lyrics must also be added under that app’s **Users and Access** allowlist. Without these requirements, Spotify may authorize successfully but playback requests can fail with HTTP 403. Keep client credentials private; never commit personal secrets.

## Downloadable IPA releases

Every successful build from `main` (or manual Actions run) publishes an unsigned IPA as a GitHub Release and also retains it as a workflow artifact for 30 days. Open the repository's **Releases** page and download `CarPlayLyrics-unsigned.ipa`, or use the stable latest-release URL:

`https://github.com/Siguyyy/carplay-lyrics/releases/latest/download/CarPlayLyrics-unsigned.ipa`

The IPA is unsigned, like AirCard17's convenient sideload packages. Install it using AltStore, SideStore, Sideloadly, or another tool that signs it with your Apple account. Tapping an unsigned IPA on the phone will not install it.

The workflow runs XcodeGen with Bash explicitly, builds the iOS app with code signing disabled, packages `Payload/DriveVerse.app`, uploads an artifact, and attaches the IPA to a uniquely tagged release. No signing secrets are required.

## Reliability notes

- Drive Mode uses background location updates to keep local lyric tracking alive. The app discards received coordinates, but this still costs battery and requires location permission. iOS may suspend or throttle the process; no local polling design can promise uninterrupted updates for every drive.
- If the Live Activity ends or is dismissed, start Drive Mode again from the app/Shortcut. Verify actual long-drive behavior on the target iOS version and vehicle.
- Spotify updates are polled and can lag after seeking or during poor connectivity.
- No App Store release is claimed: background-location use as a keep-alive and unlicensed lyrics are material distribution blockers.

## Tests

The core unit suite is available from Xcode (`Cmd-U`) or `./scripts/test.sh` on macOS with Xcode command line tools.

## License

MIT for the project's code. Lyrics remain the rights holders' property.
