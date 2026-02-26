import SwiftUI
import UserNotifications

/// First-launch onboarding screen introducing users to the app
struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Welcome to Differ",
                    description: "Your comprehensive reference for Apple Mobile Device Management configuration profile keys.",
                    features: [
                        "Browse 1,973+ MDM keys from official sources",
                        "Search across 126 documented payloads",
                        "View platform compatibility and requirements"
                    ]
                )
                .tag(0)
                
                // Page 2: Offline First
                OnboardingPage(
                    systemImage: "arrow.down.circle.fill",
                    title: "Works Offline",
                    description: "The complete MDM catalog is bundled with the app. No internet required for browsing.",
                    features: [
                        "Full catalog available offline",
                        "Optional background updates",
                        "Never lose access to MDM documentation"
                    ]
                )
                .tag(1)
                
                // Page 3: Stay Updated
                OnboardingPage(
                    systemImage: "bell.badge.fill",
                    title: "Track Changes",
                    description: "Enable notifications to stay informed about new and updated MDM keys.",
                    features: [
                        "Get notified of catalog updates",
                        "Background refresh once daily",
                        "View detailed change history"
                    ],
                    showNotificationPrompt: true
                )
                .tag(2)
                
                // Page 4: Get Started
                OnboardingFinalPage()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Navigation Buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentPage < 3 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .interactiveDismissDisabled()
    }
}

/// Individual onboarding page content
struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let description: String
    let features: [String]
    var showNotificationPrompt: Bool = false
    
    @State private var notificationStatus: NotificationPermissionStatus = .notRequested
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(.orange.gradient)
                .symbolEffect(.bounce, value: systemImage)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        Text(feature)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            
            if showNotificationPrompt {
                VStack(spacing: 12) {
                    switch notificationStatus {
                    case .notRequested:
                        Button {
                            requestNotificationPermission()
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge.fill")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                    case .requesting:
                        ProgressView()
                            .controlSize(.regular)
                        
                    case .granted:
                        Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.orange)
                        
                    case .denied:
                        VStack(spacing: 8) {
                            Label("Enable in Settings", systemImage: "gear")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.orange)
                            
                            Button {
                                openSettings()
                            } label: {
                                Text("Open Settings")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private func requestNotificationPermission() {
        notificationStatus = .requesting
        
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                
                await MainActor.run {
                    HapticService.success()
                    notificationStatus = granted ? .granted : .denied
                }
            } catch {
                await MainActor.run {
                    HapticService.error()
                    notificationStatus = .denied
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

/// Final onboarding page with app icon and get started
struct OnboardingFinalPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon
            Image(systemName: "doc.text.image.fill")
                .font(.system(size: 100))
                .foregroundStyle(.orange.gradient)
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle.bold())
                
                Text("Start exploring the comprehensive MDM catalog")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                TipRow(icon: "magnifyingglass", text: "Use search to quickly find specific keys")
                TipRow(icon: "line.3.horizontal.decrease.circle", text: "Filter by payload type or platform")
                TipRow(icon: "doc.on.doc", text: "Tap any key to view detailed information")
                TipRow(icon: "gear", text: "Configure sources and refresh in Settings")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

/// Helper view for tips with icon
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .font(.title3)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
/// Notification permission status for onboarding
enum NotificationPermissionStatus {
    case notRequested
    case requesting
    case granted
    case denied
}

