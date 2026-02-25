import SwiftUI
import BackgroundTasks

@main
struct MDMKeysApp: App {
    @StateObject private var appState = AppState()

    init() {
        Task {
            await MDMUpdateService.shared.registerBackgroundTask()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task { @MainActor in
                        await appState.markNotificationsRead()
                        await MDMNotificationService.shared.syncBadgeWithUnreadCount()
                    }
                }
                .task {
                    await appState.loadInitialCatalog()
                    await appState.loadNotificationData()
                    await MDMNotificationService.shared.requestAuthorization()
                    await MDMUpdateService.shared.scheduleBackgroundRefresh()
                }
        }
    }
}
