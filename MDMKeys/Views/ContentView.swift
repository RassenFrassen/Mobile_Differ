import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deepLinkService: DeepLinkService
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var selectedTab = 1 // Default to Keys tab

    var body: some View {
        ZStack {
            if appState.isInitializing {
                LoadingView()
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    Tab("Payloads", systemImage: "doc.text", value: 0) {
                        PayloadListView()
                    }

                    Tab("Keys", systemImage: "key.horizontal", value: 1) {
                        KeyBrowserView()
                    }
                    
                    Tab("Compatibility", systemImage: "checkmark.shield", value: 2) {
                        CompatibilityView()
                    }

                    Tab("Updates", systemImage: "bell", value: 3) {
                        NotificationLogView()
                    }
                    .badge(appState.mdmNotificationUnreadCount > 0 ? appState.mdmNotificationUnreadCount : 0)

                    Tab("Docs", systemImage: "book", value: 4) {
                        DocumentationView()
                    }

                    Tab("Settings", systemImage: "gear", value: 5) {
                        SettingsView()
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
                .transition(.opacity)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView()
                }
                .onChange(of: deepLinkService.pendingDeepLink) { oldValue, newValue in
                    handleDeepLink(newValue)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isInitializing)
    }
    
    private func handleDeepLink(_ deepLink: DeepLinkService.DeepLink?) {
        guard let deepLink = deepLink else { return }
        
        switch deepLink {
        case .key, .search, .favorites:
            selectedTab = 1 // Keys tab
        case .payload:
            selectedTab = 0 // Payloads tab
        case .history:
            selectedTab = 3 // Updates/History tab
        case .settings:
            selectedTab = 5 // Settings tab
        }
        
        // Clear the deep link after a short delay to allow navigation
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            deepLinkService.clearPendingDeepLink()
        }
    }
}
