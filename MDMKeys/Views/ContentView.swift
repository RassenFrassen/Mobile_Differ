import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some View {
        ZStack {
            if appState.isInitializing {
                LoadingView()
                    .transition(.opacity)
            } else {
                TabView {
                    Tab("Payloads", systemImage: "doc.text") {
                        PayloadListView()
                    }

                    Tab("Keys", systemImage: "key.horizontal") {
                        KeyBrowserView()
                    }
                    
                    Tab("Compatibility", systemImage: "checkmark.shield") {
                        CompatibilityView()
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
                .tabViewStyle(.sidebarAdaptable)
                .transition(.opacity)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isInitializing)
    }
}
