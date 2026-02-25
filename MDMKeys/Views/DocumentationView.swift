import SwiftUI

struct DocumentationView: View {
    @State private var expandedSections: Set<String> = ["overview"]

    var body: some View {
        NavigationStack {
            List {
                headerSection

                ForEach(docSections) { section in
                    docSection(section)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Documentation")
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Differ")
                        .font(.title2.weight(.bold))
                    Text("Apple MDM Configuration Reference")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func docSection(_ section: DocSection) -> some View {
        Section {
            if expandedSections.contains(section.id) {
                ForEach(section.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        if let title = item.title {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(item.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            } label: {
                HStack {
                    Label(section.title, systemImage: section.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                    Spacer()
                    Image(systemName: expandedSections.contains(section.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Data Model

private struct DocSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let items: [DocItem]
}

private struct DocItem: Identifiable {
    let id = UUID()
    let title: String?
    let body: String
    init(_ body: String, title: String? = nil) {
        self.title = title
        self.body = body
    }
}

private let docSections: [DocSection] = [
    DocSection(id: "overview", title: "Overview", icon: "info.circle.fill", items: [
        DocItem("Differ is a reference browser for Apple Mobile Device Management (MDM) configuration profile keys. It aggregates data from Apple's official documentation and community sources, keeping you informed when new or changed keys appear."),
        DocItem("The app ships with a full bundled snapshot of the MDM catalog so it works immediately without an internet connection. A background refresh checks for changes daily and sends a notification when anything is added, updated, or removed.")
    ]),

    DocSection(id: "keys", title: "Keys Tab", icon: "key.horizontal.fill", items: [
        DocItem("The Keys tab shows all known MDM configuration keys across all payload types. Each row displays the key name, payload type, and supported platforms.", title: "Browsing Keys"),
        DocItem("Use the search bar to find keys by name, key path, payload type, or description. Search is real-time and case-insensitive.", title: "Searching"),
        DocItem("Tap the filter icon (top-right) to narrow results by platform (iOS, macOS, tvOS, etc.), source, or specific payload type. You can also hide deprecated keys.", title: "Filtering"),
        DocItem("Tap any key row to open its detail view, showing the full key path, description, type information, possible values, and a generated profile XML example.", title: "Key Detail"),
        DocItem("In the detail view, tap 'Show Profile XML Example' to see a valid mobileconfig XML snippet using that key. Use the share button to copy or share the key details.", title: "Profile Examples")
    ]),

    DocSection(id: "payloads", title: "Payloads Tab", icon: "doc.text.fill", items: [
        DocItem("The Payloads tab groups MDM keys by payload type. Payloads represent discrete configuration areas — for example, Wi-Fi, VPN, Restrictions, or Passcode.", title: "Browsing Payloads"),
        DocItem("Tap a payload to see its documentation, supported platforms, source links, and a list of all keys that belong to it.", title: "Payload Detail"),
        DocItem("Use the category chips at the top to filter payloads by their functional area. Search works across payload names, types, and summaries.", title: "Filtering Payloads")
    ]),

    DocSection(id: "updates", title: "Updates Tab", icon: "bell.fill", items: [
        DocItem("Every time Differ refreshes the catalog and finds changes, an entry is added to the Updates tab. Each entry shows what was added, updated, or removed.", title: "Update History"),
        DocItem("Tap an entry to see the full list of individual key changes, including which field changed and what the new value is for updated keys.", title: "Change Details"),
        DocItem("The badge on the Updates tab shows how many unread update notifications you have. Opening the tab marks all as read.", title: "Unread Count")
    ]),

    DocSection(id: "notifications", title: "Notifications", icon: "bell.badge.fill", items: [
        DocItem("Differ can send system notifications when the catalog changes. Enable notifications in iOS Settings > Differ > Notifications.", title: "Enabling Notifications"),
        DocItem("Notifications fire after a background catalog refresh finds new, updated, or removed keys. The notification title and body summarise the counts and which sources and platforms were affected.", title: "Notification Content"),
        DocItem("The app icon badge shows the total count of changes from the most recent update. Opening the app clears the badge.", title: "App Badge"),
        DocItem("Background refresh is rate-limited by iOS to approximately once per day. You can also trigger a manual refresh from the Settings tab or the refresh button in the Keys tab.", title: "Refresh Frequency")
    ]),

    DocSection(id: "sources", title: "Data Sources", icon: "server.rack", items: [
        DocItem("Official Apple MDM payload definitions in YAML format, maintained in the apple/device-management GitHub repository. This is the most authoritative source.", title: "Apple device-management"),
        DocItem("Apple's documentation website at developer.apple.com, crawled to extract payload and property documentation with rich descriptions.", title: "Apple Developer Documentation"),
        DocItem("The ProfileManifests/ProfileManifests repository provides plist-format manifests used by iMazing Profile Editor and Profile Creator. Includes detailed type information and allowed values.", title: "ProfileManifests"),
        DocItem("Community-maintained collections of example .mobileconfig profiles from rtrouton/profiles and Mac-Nerd/Mac-profiles. These reveal real-world key usage.", title: "Community Sources"),
        DocItem("Disable sources you don't need in Settings to reduce API calls and refresh time. Apple device-management is recommended for all users.", title: "Source Selection")
    ]),

    DocSection(id: "github", title: "GitHub Token", icon: "lock.shield.fill", items: [
        DocItem("Without a token, the GitHub API allows 60 requests per hour (unauthenticated). With a token, this rises to 5,000 requests per hour.", title: "Why Use a Token?"),
        DocItem("Go to github.com/settings/tokens and create a Personal Access Token (classic or fine-grained) with no special permissions — read-only public repository access is sufficient.", title: "Creating a Token"),
        DocItem("Enter your token in Settings > GitHub Token and tap Save. It is stored in UserDefaults on your device and never transmitted anywhere other than api.github.com request headers.", title: "Storing the Token"),
        DocItem("A token is only required if you use all six data sources and refresh frequently. For occasional refreshes with Apple sources only, no token is needed.", title: "Do I Need a Token?")
    ]),

    DocSection(id: "offline", title: "Offline & Seed Data", icon: "wifi.slash", items: [
        DocItem("Differ ships with a full pre-built catalog snapshot (mdm_catalog_seed.json) embedded in the app. All \u{200B}browsing features work immediately with no internet connection.", title: "Bundled Catalog"),
        DocItem("The embedded bundles for Apple device-management and ProfileManifests are also included in the app, enabling a full re-index from local files without hitting the internet.", title: "Embedded Repository Bundles"),
        DocItem("After a successful live refresh, the updated catalog is saved locally. On next launch, the saved catalog loads instantly, keeping browsing fast.", title: "Cached Catalog")
    ])
]
