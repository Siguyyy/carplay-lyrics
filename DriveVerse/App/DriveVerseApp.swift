#if os(iOS)
import SwiftUI

@main
struct DriveVerseApp: App {
    private let model = AppModel.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .task {
                    _ = await DriveModeNotifications.shared.scheduleExpiryReminders()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        model.foregroundResync()
                        Task { _ = await DriveModeNotifications.shared.scheduleExpiryReminders() }
                    }
                }
        }
    }
}
#endif
