import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var tokenInput = ""
    @State private var showTokenSaved = false
    @FocusState private var tokenFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                // Catalog Status
                Section {
                    HStack {
                        Label("Keys", systemImage: "key.horizontal")
                        Spacer()
                        Text("\(appState.mdmKeys.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Payloads", systemImage: "doc.text")
                        Spacer()
                        Text("\(appState.mdmPayloads.count)")
                            .foregroundStyle(.secondary)
                    }
                    if let lastUpdated = appState.mdmLastUpdated {
                        HStack {
                            Label("Last Refreshed", systemImage: "clock")
                            Spacer()
                            Text(lastUpdated, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let snapshot = appState.mdmSnapshot {
                        HStack {
                            Label("Catalog Date", systemImage: "calendar")
                            Spacer()
                            Text(snapshot.generatedAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Task { await appState.refreshMDMCatalog() }
                    } label: {
                        if appState.isUpdatingMDMCatalog {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Refreshing…")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Refresh Catalog Now", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(appState.isUpdatingMDMCatalog)

                    if let error = appState.mdmUpdateError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Catalog")
                }

                // Auto Refresh
                Section {
                    Toggle("Auto-refresh in background", isOn: $appState.autoRefreshEnabled)
                        .onChange(of: appState.autoRefreshEnabled) { _, enabled in
                            UserDefaults.standard.set(enabled, forKey: "autoRefreshEnabled")
                            if enabled {
                                MDMUpdateService.shared.scheduleBackgroundRefresh()
                            }
                        }
                } header: {
                    Text("Background Updates")
                } footer: {
                    Text("When enabled, MDM Keys refreshes the catalog in the background once per day and notifies you of changes.")
                }

                // Sources
                Section {
                    ForEach(MDMSource.allCases) { source in
                        Toggle(isOn: Binding(
                            get: { appState.enabledMDMSources.contains(source) },
                            set: { _ in appState.toggleSource(source) }
                        )) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.rawValue)
                                        .font(.body)
                                    Text(source.shortDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: source.icon)
                            }
                        }
                    }
                } header: {
                    Text("Data Sources")
                } footer: {
                    Text("Select which sources to include when refreshing the MDM catalog. Apple sources are recommended. Community sources provide additional payload samples.")
                }

                // GitHub Token
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $tokenInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .focused($tokenFocused)
                            .onAppear { tokenInput = appState.githubToken }

                        HStack {
                            Button("Save Token") {
                                appState.saveGithubToken(tokenInput)
                                tokenFocused = false
                                showTokenSaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showTokenSaved = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(tokenInput == appState.githubToken)

                            if showTokenSaved {
                                Label("Saved", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .transition(.opacity)
                            }

                            Spacer()

                            if !appState.githubToken.isEmpty {
                                Button("Clear", role: .destructive) {
                                    tokenInput = ""
                                    appState.saveGithubToken("")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.red)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: showTokenSaved)
                    }
                } header: {
                    Text("GitHub Token (Optional)")
                } footer: {
                    Text("A GitHub Personal Access Token increases API rate limits from 60 to 5,000 requests per hour. Required for refreshing community sources frequently. Create one at github.com/settings/tokens with read-only scope.")
                }

                // Notification Status
                Section {
                    HStack {
                        Label("Unread Updates", systemImage: "bell.badge")
                        Spacer()
                        Text("\(appState.mdmNotificationUnreadCount)")
                            .foregroundStyle(.secondary)
                    }
                    Button("Mark All as Read") {
                        Task { await appState.markNotificationsRead() }
                    }
                    .disabled(appState.mdmNotificationUnreadCount == 0)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("MDM Keys sends a notification when new or changed MDM keys are found during catalog refresh. Enable notifications in Settings > MDM Keys.")
                }

                // About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/apple/device-management")!) {
                        Label("Apple device-management on GitHub", systemImage: "arrow.up.right.square")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
