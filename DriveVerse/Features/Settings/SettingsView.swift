import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage(AppModel.pollIntervalKey) private var pollInterval: Double = 5
    @AppStorage(DriveModeNotifications.enabledKey) private var statusNotificationsEnabled = false
    @AppStorage(DriveModeNotifications.expiryRemindersKey) private var expiryRemindersEnabled = false
    @State private var cacheCleared = false
    @State private var expiryReminderStatus = ""

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
                Text("How often Simon's Karaoke asks Spotify what's playing. Lower is snappier; higher saves battery and API quota. Between reports, lyric timing is extrapolated locally. Spotify Development Mode also requires Premium on the Spotify Developer app owner’s account, and the connected account must be allowlisted in the app’s Users and Access settings.")
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
                Toggle("Drive Mode status notifications", isOn: $statusNotificationsEnabled)
                    .onChange(of: statusNotificationsEnabled) { _, enabled in
                        Task { @MainActor in
                            if enabled {
                                let allowed = await DriveModeNotifications.shared.requestPermission()
                                if !allowed { statusNotificationsEnabled = false }
                            } else {
                                DriveModeNotifications.shared.disable()
                            }
                        }
                    }
                Toggle("Sideload expiration reminders", isOn: $expiryRemindersEnabled)
                    .onChange(of: expiryRemindersEnabled) { _, enabled in
                        Task { @MainActor in
                            if enabled {
                                let allowed = await DriveModeNotifications.shared.requestPermission()
                                guard allowed else {
                                    expiryRemindersEnabled = false
                                    expiryReminderStatus = "Allow notifications in iOS Settings to enable reminders."
                                    return
                                }
                                let expiry = await DriveModeNotifications.shared.scheduleExpiryReminders()
                                if let expiry {
                                    expiryReminderStatus = "Signing expires (expiry.formatted(date: .abbreviated, time: .shortened)). Reminders are scheduled for 1 day, 3 hours, 2 hours, and 1 hour before expiry."
                                } else {
                                    expiryRemindersEnabled = false
                                    expiryReminderStatus = "This build’s embedded signing profile isn’t readable. Expiration reminders can’t be scheduled reliably."
                                }
                            } else {
                                DriveModeNotifications.shared.cancelExpiryReminders()
                                expiryReminderStatus = ""
                            }
                        }
                    }
                if !expiryReminderStatus.isEmpty {
                    Text(expiryReminderStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Drive Mode alerts are quiet and include no song or lyric information. Expiry reminders read the signing profile embedded in the sideloaded app and schedule local alerts 1 day, 3 hours, 2 hours, and 1 hour before it expires. They aren’t based on a guessed 7-day cycle.")
            }

            Section {
                LabeledContent("Drive Mode", value: model.driveMode ? "On" : "Off")
                LabeledContent("Lyric sync tick") {
                    Text(model.syncTickAt?.formatted(date: .omitted, time: .standard) ?? "Not started")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Largest sync gap") {
                    Text(model.lastObservedSyncGap.map { String(format: "%.1f s", $0) } ?? "Not measured")
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
                Text("Simon's Karaoke is a personal-use app. Lyrics are fetched from the community-run LRCLIB API for private, non-commercial display. Do not distribute this app without a licensed lyrics provider.")
            }
        }
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            guard expiryRemindersEnabled else { return }
            if let expiry = await DriveModeNotifications.shared.scheduleExpiryReminders() {
                expiryReminderStatus = "Signing expires \(expiry.formatted(date: .abbreviated, time: .shortened)). Reminders are scheduled."
            } else {
                expiryRemindersEnabled = false
                expiryReminderStatus = "This build’s embedded signing profile isn’t readable. Expiration reminders can’t be scheduled reliably."
            }
        }
    }

    private var pinBinding: Binding<SourcePin> {
        Binding(get: { model.sourcePin }, set: { model.sourcePin = $0 })
    }

    private var lyricsFocusBinding: Binding<Bool> {
        Binding(get: { model.lyricsFocusLayout }, set: { model.lyricsFocusLayout = $0 })
    }
}
