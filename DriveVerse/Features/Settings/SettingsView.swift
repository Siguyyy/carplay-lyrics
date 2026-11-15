import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage(AppModel.pollIntervalKey) private var pollInterval: Double = 5
    @State private var cacheCleared = false

    var body: some View {
        Form {
            Section {
                Picker("Preferred source", selection: pinBinding) {
                    ForEach(SourcePin.allCases) { pin in
                        Text(pin.displayName).tag(pin)
                    }
                }
            } header: {
                Text("Source")
            } footer: {
                Text("Automatic prefers Apple Music whenever it's playing (local, exact position), otherwise Spotify. Pin a source to ignore the other.")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Poll interval")
                        Spacer()
                        Text("\(Int(pollInterval)) s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $pollInterval, in: 3...10, step: 1)
                }
                if model.spotifyConnected {
                    Button("Disconnect Spotify", role: .destructive) {
                        model.disconnectSpotify()
                    }
                }
            } header: {
                Text("Spotify")
            } footer: {
                Text("How often DriveVerse asks Spotify what's playing. Lower is snappier; higher saves battery and API quota. Between reports, lyric timing is extrapolated locally. Spotify Development Mode also requires Premium on the Developer app owner’s account, and the connected account must be allowlisted in the app’s Users and Access settings.")
            }

            Section {
                Button("Clear lyrics cache") {
                    model.clearLyricsCache()
                    cacheCleared = true
                }
                if cacheCleared {
                    Label("Cache cleared", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Lyrics")
            } footer: {
                Text("Lyrics come from LRCLIB and are cached on this device for at most 30 days.")
            }

            Section {
                Toggle("Lyrics focus", isOn: lyricsFocusBinding)
            } header: {
                Text("CarPlay layout")
            } footer: {
                Text("When on, the Live Activity gives the current lyric more room and shows additional upcoming lines. The text keeps its normal size and wraps; changing this also updates an active Live Activity.")
            }

            Section {
                LabeledContent("Drive Mode", value: model.driveMode ? "On" : "Off")
                LabeledContent("Lyric sync tick") {
                    Text(model.syncTickAt?.formatted(date: .omitted, time: .standard) ?? "Not started")
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.driveModeDiagnostic)
                    if let date = model.driveModeDiagnosticAt {
                        Text("Updated \(date.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.activityDiagnostic)
                    if let date = model.activityDiagnosticAt {
                        Text("Updated \(date.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)
            } header: {
                Text("Drive Mode diagnostics")
            } footer: {
                Text("Drive Mode uses a Core Location background activity session while enabled; coordinates are discarded. The timestamps above help identify whether iOS is still delivering location callbacks and whether ActivityKit updates are completing. If lyrics freeze, reopening the app rebuilds the session and refreshes playback. Background execution is controlled by iOS, so this cannot guarantee uninterrupted updates. Location use increases battery consumption; this is intended for personal sideloading.")
            }

            Section {
                EmptyView()
            } header: {
                Text("About")
            } footer: {
                Text("DriveVerse is a personal-use app. Lyrics are fetched from the community-run LRCLIB API for private, non-commercial display. Do not distribute this app without a licensed lyrics provider.")
            }
        }
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var pinBinding: Binding<SourcePin> {
        Binding(get: { model.sourcePin }, set: { model.sourcePin = $0 })
    }

    private var lyricsFocusBinding: Binding<Bool> {
        Binding(get: { model.lyricsFocusLayout }, set: { model.lyricsFocusLayout = $0 })
    }
}
