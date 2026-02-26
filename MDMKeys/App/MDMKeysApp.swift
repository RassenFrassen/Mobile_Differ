import SwiftUI
import BackgroundTasks

@main
struct MDMKeysApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var deepLinkService = DeepLinkService.shared

    init() {
        // Migrate notification log from UserDefaults to file storage if needed
        // This must happen synchronously before any UserDefaults writes to prevent overflow
        MDMNotificationService.migrateFromUserDefaultsIfNeeded()
        
        Task {
            await MDMUpdateService.shared.registerBackgroundTask()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(deepLinkService)
                .onOpenURL { url in
                    _ = deepLinkService.handle(url)
                }
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
