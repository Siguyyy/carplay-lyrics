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

Spotify support is optional. To enable it, copy `DriveVerse/Resources/Secrets.example.plist` to `Secrets.plist`, add your Spotify client ID, and register `carplaylyrics://callback` as the redirect URI in your Spotify app. Keep the secret file out of git.

## Downloadable IPA releases

The `Build and publish IPA` GitHub Actions workflow can create a signed IPA and attach it to a GitHub Release when you push a version tag such as `v0.1.0`. Configure these repository Actions secrets first:

- `IOS_CERTIFICATE_BASE64`: base64 encoded Apple Development or Distribution `.p12` certificate
- `IOS_CERTIFICATE_PASSWORD`: password for that `.p12`
- `IOS_TEAM_ID`: your Apple Developer Team ID
- `IOS_APP_PROFILE_BASE64`: base64 encoded ad hoc provisioning profile for `com.siguyyy.carplaylyrics`
- `IOS_WIDGET_PROFILE_BASE64`: base64 encoded ad hoc provisioning profile for `com.siguyyy.carplaylyrics.widgets`

The IPA is signed for the devices included in that profile. An IPA built without a matching signing identity and provisioning profile is not directly installable on an iPhone. For personal sideloading, use a development/ad hoc profile or sign it with your preferred sideload tool.

## Reliability notes

- Drive Mode uses background location updates to keep local lyric tracking alive. The app discards received coordinates, but this still costs battery and requires location permission. iOS may suspend or throttle the process; no local polling design can promise uninterrupted updates for every drive.
- If the Live Activity ends or is dismissed, start Drive Mode again from the app/Shortcut. Verify actual long-drive behavior on the target iOS version and vehicle.
- Spotify updates are polled and can lag after seeking or during poor connectivity.
- No App Store release is claimed: background-location use as a keep-alive and unlicensed lyrics are material distribution blockers.

## Tests

The core unit suite is available from Xcode (`Cmd-U`) or `./scripts/test.sh` on macOS with Xcode command line tools.

## License

MIT for the project's code. Lyrics remain the rights holders' property.
