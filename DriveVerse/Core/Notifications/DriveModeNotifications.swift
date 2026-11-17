#if os(iOS)
import Foundation
import UserNotifications

@MainActor
final class DriveModeNotifications {
    static let shared = DriveModeNotifications()
    static let enabledKey = "driveModeStatusNotificationsEnabled"
    static let expiryRemindersKey = "sideloadExpiryRemindersEnabled"
    private let expiryReminderIDs = (0..<4).map { "sideload-expiry-\($0)" }

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert])
        } catch {
            return false
        }
    }

    func disable() {
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
    }

    func cancelExpiryReminders() {
        UserDefaults.standard.set(false, forKey: Self.expiryRemindersKey)
        center.removePendingNotificationRequests(withIdentifiers: expiryReminderIDs)
    }

    /// Reads the signed profile embedded by the sideload signer. No estimate is
    /// used: if the profile is absent or cannot be decoded, the caller is told.
    func scheduleExpiryReminders() async -> Date? {
        guard UserDefaults.standard.bool(forKey: Self.expiryRemindersKey),
              let expiry = Self.provisioningExpirationDate(), expiry > Date() else {
            center.removePendingNotificationRequests(withIdentifiers: expiryReminderIDs)
            return nil
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return nil
        }

        center.removePendingNotificationRequests(withIdentifiers: expiryReminderIDs)
        let reminders: [(TimeInterval, String)] = [
            (24 * 60 * 60, "1 day"),
            (3 * 60 * 60, "3 hours"),
            (2 * 60 * 60, "2 hours"),
            (60 * 60, "1 hour")
        ]

        for (index, reminder) in reminders.enumerated() {
            let fireDate = expiry.addingTimeInterval(-reminder.0)
            let delay = fireDate.timeIntervalSinceNow
            guard delay > 1 else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Simon's Karaoke signing expires in \(reminder.1)"
            content.body = "Refresh or reinstall the app before it expires to keep using it."
            content.interruptionLevel = .passive
            let request = UNNotificationRequest(
                identifier: expiryReminderIDs[index],
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            try? await center.add(request)
        }
        return expiry
    }

    func postDriveModeStatus(isOn: Bool) async {
        guard UserDefaults.standard.bool(forKey: Self.enabledKey) else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = isOn ? "Drive Mode is on" : "Drive Mode is off"
        content.body = isOn
            ? "Simon's Karaoke is ready to show lyrics while you drive."
            : "Background lyric updates have stopped."
        content.interruptionLevel = .passive

        let request = UNNotificationRequest(
            identifier: "drive-mode-\(isOn ? "started" : "stopped")-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await center.add(request)
    }

    private static func provisioningExpirationDate() -> Date? {
        let profileURL = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
        guard let message = try? Data(contentsOf: profileURL),
              !message.isEmpty else { return nil }

        // CMSDecoder is macOS-only. iOS provisioning profiles wrap their XML
        // plist in a CMS envelope, so locate the plist payload directly.
        let plistOpen = Data("<plist".utf8)
        let plistClose = Data("</plist>".utf8)
        guard let plistStart = message.range(of: plistOpen),
              let plistEnd = message.range(of: plistClose, in: plistStart.lowerBound..<message.endIndex) else {
            return nil
        }
        let plistData = Data(message[plistStart.lowerBound..<plistEnd.upperBound])
        guard let profile = try? PropertyListSerialization.propertyList(
            from: plistData, options: [], format: nil
        ) as? [String: Any] else { return nil }
        return profile["ExpirationDate"] as? Date
    }
}
#endif
