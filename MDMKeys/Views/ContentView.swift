import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            Tab("Keys", systemImage: "key.horizontal") {
                KeyBrowserView()
            }

            Tab("Payloads", systemImage: "doc.text") {
                PayloadListView()
            }

            Tab("Updates", systemImage: "bell") {
                NotificationLogView()
            }
            .badge(appState.mdmNotificationUnreadCount > 0 ? appState.mdmNotificationUnreadCount : 0)

            Tab("Docs", systemImage: "book") {
                DocumentationView()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}
