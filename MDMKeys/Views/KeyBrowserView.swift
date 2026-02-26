import SwiftUI

struct KeyBrowserView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var selectedPlatform: String? = nil
    @State private var selectedSource: MDMSource? = nil
    @State private var selectedPayloadType: String? = nil
    @State private var showDeprecated = true
    @State private var showFilters = false
    @State private var selectedKey: MDMKeyRecord? = nil
    @State private var showOnlyFavorites = false

    private var allPlatforms: [String] {
        Array(Set(appState.mdmKeys.flatMap(\.platforms))).sorted()
    }

    private var allPayloadTypes: [String] {
        Array(Set(appState.mdmKeys.map(\.payloadType))).sorted()
    }

    private var filteredKeys: [MDMKeyRecord] {
        appState.mdmKeys.filter { key in
            if showOnlyFavorites && !appState.isFavorite(key.id) { return false }
            if !showDeprecated && key.isDeprecated { return false }
            if let platform = selectedPlatform, !key.platforms.contains(platform) { return false }
            if let source = selectedSource, !key.sources.contains(source) { return false }
            if let payloadType = selectedPayloadType, key.payloadType != payloadType { return false }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return key.key.lowercased().contains(query)
                || key.keyPath.lowercased().contains(query)
                || (key.payloadName?.lowercased().contains(query) ?? false)
                || (key.keyDescription?.lowercased().contains(query) ?? false)
        }
    }

    private var activeFilterCount: Int {
        var count = 0
        if selectedPlatform != nil { count += 1 }
        if selectedSource != nil { count += 1 }
        if selectedPayloadType != nil { count += 1 }
        if !showDeprecated { count += 1 }
        if showOnlyFavorites { count += 1 }
        return count
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all), 
                           preferredCompactColumn: .constant(.sidebar)) {
            Group {
                if appState.mdmKeys.isEmpty && !appState.isUpdatingMDMCatalog {
                    emptyState
                } else {
                    keyList
                }
            }
            .navigationTitle("Differ")
            .navigationSubtitle("\(filteredKeys.count) of \(appState.mdmKeys.count) keys")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search keys, payloads, descriptions…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    favoritesToggleButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(
                    platforms: allPlatforms,
                    payloadTypes: allPayloadTypes,
                    selectedPlatform: $selectedPlatform,
                    selectedSource: $selectedSource,
                    selectedPayloadType: $selectedPayloadType,
                    showDeprecated: $showDeprecated,
                    showOnlyFavorites: $showOnlyFavorites
                )
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 450, max: 600)
        } detail: {
            if let key = selectedKey {
                KeyDetailView(key: key)
            } else {
                ContentUnavailableView(
                    "Select a Key",
                    systemImage: "key.horizontal",
                    description: Text("Choose an MDM key from the list to view its details.")
                )
            }
        }
    }

    private var keyList: some View {
        List(filteredKeys, selection: $selectedKey) { key in
            NavigationLink(value: key) {
                KeyRowView(key: key, isFavorite: appState.isFavorite(key.id))
                    .accessibilityLabel("\(key.key). \(key.payloadType). Platforms: \(key.platforms.joined(separator: ", "))")
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Task {
                        await appState.toggleFavorite(key.id)
                        HapticService.lightImpact()
                    }
                } label: {
                    Label(appState.isFavorite(key.id) ? "Unfavorite" : "Favorite",
                          systemImage: appState.isFavorite(key.id) ? "star.slash" : "star.fill")
                }
                .tint(appState.isFavorite(key.id) ? .gray : .yellow)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await appState.refreshMDMCatalog()
        }
        .overlay {
            if appState.isUpdatingMDMCatalog {
                ProgressView("Refreshing catalog…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .overlay {
            if !appState.isUpdatingMDMCatalog && filteredKeys.isEmpty && !searchText.isEmpty {
                SearchEmptyStateView(searchText: searchText)
            }
        }
    }

    private var emptyState: some View {
        Group {
            if let error = appState.mdmUpdateError {
                NetworkErrorStateView(message: error) {
                    Task { await appState.refreshMDMCatalog() }
                }
            } else {
                CatalogEmptyStateView {
                    Task { await appState.refreshMDMCatalog() }
                }
            }
        }
    }

    private var favoritesToggleButton: some View {
        Button {
            HapticService.lightImpact()
            showOnlyFavorites.toggle()
        } label: {
            Image(systemName: showOnlyFavorites ? "star.fill" : "star")
                .foregroundStyle(showOnlyFavorites ? .yellow : .primary)
        }
        .accessibilityLabel(showOnlyFavorites ? "Show all keys" : "Show favorites only")
    }

    private var filterButton: some View {
        Button {
            HapticService.lightImpact()
            showFilters = true
        } label: {
            Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filters (\(activeFilterCount) active)")
    }

    private var refreshButton: some View {
        Button {
            HapticService.mediumImpact()
            Task { await appState.refreshMDMCatalog() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(appState.isUpdatingMDMCatalog)
        .accessibilityLabel("Refresh catalog")
    }
}

// MARK: - Key Row

struct KeyRowView: View {
    let key: MDMKeyRecord
    let isFavorite: Bool

    private var displayName: String {
        if key.key == "ANY" {
            return "Custom Keys (any key-value pairs)"
        }
        return key.key
    }

    var body: some View {
        HStack(spacing: 12) {
            PayloadIcon(payloadType: key.payloadType, sources: key.sources)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text(displayName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)

                    if key.isDeprecated {
                        Text("Deprecated")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                    }
                    if key.required == true {
                        Text("Required")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                    }
                }

                Text(key.payloadType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !key.platforms.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(key.platforms.prefix(4), id: \.self) { platform in
                            PlatformBadge(platform: platform)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Platform Badge

struct PlatformBadge: View {
    let platform: String

    var body: some View {
        Text(shortName)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityLabel(platform)
    }

    private var shortName: String {
        switch platform.lowercased() {
        case let p where p.contains("ios") || p.contains("iphone"): return "iOS"
        case let p where p.contains("ipad"): return "iPadOS"
        case let p where p.contains("macos") || p.contains("mac"): return "macOS"
        case let p where p.contains("tvos") || p.contains("tv"): return "tvOS"
        case let p where p.contains("watchos") || p.contains("watch"): return "watchOS"
        case let p where p.contains("vision"): return "visionOS"
        default: return platform.prefix(6).description
        }
    }

    private var color: Color {
        switch platform.lowercased() {
        case let p where p.contains("ios") || p.contains("iphone"): return .blue
        case let p where p.contains("ipad"): return .indigo
        case let p where p.contains("macos") || p.contains("mac"): return .purple
        case let p where p.contains("tvos") || p.contains("tv"): return .teal
        case let p where p.contains("watchos") || p.contains("watch"): return .green
        case let p where p.contains("vision"): return .orange
        default: return .gray
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    let platforms: [String]
    let payloadTypes: [String]

    @Binding var selectedPlatform: String?
    @Binding var selectedSource: MDMSource?
    @Binding var selectedPayloadType: String?
    @Binding var showDeprecated: Bool
    @Binding var showOnlyFavorites: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var payloadSearch = ""

    private var filteredPayloadTypes: [String] {
        payloadSearch.isEmpty ? payloadTypes : payloadTypes.filter {
            $0.localizedCaseInsensitiveContains(payloadSearch)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Favorites") {
                    Toggle("Show only favorites", isOn: $showOnlyFavorites)
                }

                Section("Deprecated Keys") {
                    Toggle("Show deprecated keys", isOn: $showDeprecated)
                }

                Section("Platform") {
                    Button("All Platforms") { selectedPlatform = nil }
                        .foregroundStyle(selectedPlatform == nil ? .primary : .secondary)
                    ForEach(platforms, id: \.self) { platform in
                        Button {
                            selectedPlatform = platform == selectedPlatform ? nil : platform
                        } label: {
                            HStack {
                                Text(platform)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPlatform == platform {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Source") {
                    Button("All Sources") { selectedSource = nil }
                        .foregroundStyle(selectedSource == nil ? .primary : .secondary)
                    ForEach(MDMSource.allCases) { source in
                        Button {
                            selectedSource = source == selectedSource ? nil : source
                        } label: {
                            HStack {
                                Label(source.rawValue, systemImage: source.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSource == source {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    TextField("Search payload types…", text: $payloadSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("All Payload Types") { selectedPayloadType = nil }
                        .foregroundStyle(selectedPayloadType == nil ? .primary : .secondary)
                    ForEach(filteredPayloadTypes, id: \.self) { type in
                        Button {
                            selectedPayloadType = type == selectedPayloadType ? nil : type
                        } label: {
                            HStack {
                                Text(type)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPayloadType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Payload Type")
                }
            }
            .navigationTitle("Filter Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedPlatform = nil
                        selectedSource = nil
                        selectedPayloadType = nil
                        showDeprecated = true
                        showOnlyFavorites = false
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
