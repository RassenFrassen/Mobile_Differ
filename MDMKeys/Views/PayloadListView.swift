import SwiftUI

struct PayloadListView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedPayload: MDMPayloadRecord? = nil

    private var allCategories: [String] {
        Array(Set(appState.mdmPayloads.compactMap(\.category))).sorted()
    }

    private var filteredPayloads: [MDMPayloadRecord] {
        appState.mdmPayloads.filter { payload in
            if let category = selectedCategory, payload.category != category { return false }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return payload.name.lowercased().contains(query)
                || payload.payloadType.lowercased().contains(query)
                || (payload.summary?.lowercased().contains(query) ?? false)
        }
    }

    private var groupedPayloads: [(String, [MDMPayloadRecord])] {
        let grouped = Dictionary(grouping: filteredPayloads) { $0.category ?? "Other" }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Group {
                if appState.mdmPayloads.isEmpty {
                    CatalogEmptyStateView {
                        Task { await appState.refreshMDMCatalog() }
                    }
                } else if filteredPayloads.isEmpty && !searchText.isEmpty {
                    SearchEmptyStateView(searchText: searchText)
                } else {
                    List(selection: $selectedPayload) {
                        if allCategories.count > 1 {
                            categoryPicker
                        }
                        ForEach(groupedPayloads, id: \.0) { category, payloads in
                            Section(category) {
                                ForEach(payloads) { payload in
                                    NavigationLink(value: payload) {
                                        PayloadRowView(payload: payload)
                                            .accessibilityLabel("\(payload.name.isEmpty ? payload.payloadType : payload.name). Platforms: \(payload.platforms.joined(separator: ", "))")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await appState.refreshMDMCatalog()
                    }
                }
            }
            .navigationTitle("Payloads")
            .navigationSubtitle("\(filteredPayloads.count) of \(appState.mdmPayloads.count) payloads")
            .searchable(text: $searchText, prompt: "Search payloads…")
            .navigationSplitViewColumnWidth(min: 320, ideal: 450, max: 600)
        } detail: {
            if let payload = selectedPayload {
                PayloadDetailView(payload: payload)
            } else {
                ContentUnavailableView(
                    "Select a Payload",
                    systemImage: "doc.text",
                    description: Text("Choose a payload to view its keys and documentation.")
                )
            }
        }
    }

    private var categoryPicker: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(label: "All", value: nil)
                    ForEach(allCategories, id: \.self) { category in
                        categoryChip(label: category, value: category)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        .listRowBackground(Color.clear)
    }

    private func categoryChip(label: String, value: String?) -> some View {
        Button {
            selectedCategory = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedCategory == value
                        ? Color.accentColor
                        : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(selectedCategory == value ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Payload Row

struct PayloadRowView: View {
    let payload: MDMPayloadRecord

    var body: some View {
        HStack(spacing: 12) {
            PayloadIcon(payloadType: payload.payloadType, sources: payload.sources)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payload.name.isEmpty ? payload.payloadType : payload.name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    if payload.isDeprecated {
                        Text("Deprecated")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                    }
                }
                Text(payload.payloadType)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if !payload.platforms.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(payload.platforms.prefix(4), id: \.self) { PlatformBadge(platform: $0) }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Payload Detail

struct PayloadDetailView: View {
    let payload: MDMPayloadRecord
    @EnvironmentObject var appState: AppState
    
    @State private var showXML = false
    @State private var showSimplified = false

    private var payloadKeys: [MDMKeyRecord] {
        appState.mdmKeys
            .filter { $0.payloadType == payload.payloadType }
            .sorted { $0.keyPath < $1.keyPath }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(payload.name.isEmpty ? payload.payloadType : payload.name)
                        .font(.title2.weight(.bold))
                    Text(payload.payloadType)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    if !payload.platforms.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(payload.platforms, id: \.self) { PlatformBadge(platform: $0) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let summary = payload.summary, !summary.isEmpty {
                Section("Summary") {
                    Text(summary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let discussion = payload.discussion, !discussion.isEmpty {
                Section("Discussion") {
                    Text(discussion)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !payload.sources.isEmpty {
                Section("Sources") {
                    ForEach(payload.sources) { source in
                        Link(destination: URL(string: source.repoURL)!) {
                            Label(source.rawValue, systemImage: source.icon)
                        }
                    }
                }
            }

            if !payloadKeys.isEmpty {
                Section("Keys (\(payloadKeys.count))") {
                    ForEach(payloadKeys) { key in
                        NavigationLink {
                            KeyDetailView(key: key)
                        } label: {
                            KeyRowView(key: key)
                        }
                    }
                }
                
                // Profile Examples
                Section {
                    Button {
                        showSimplified.toggle()
                    } label: {
                        Label(
                            showSimplified ? "Hide Domain & Reference" : "Show Domain & Reference",
                            systemImage: "doc.plaintext"
                        )
                    }

                    if showSimplified {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(MDMProfileSampleBuilder.simplifiedProfile(for: payload, keys: payloadKeys))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Button {
                        showXML.toggle()
                    } label: {
                        Label(
                            showXML ? "Hide Full XML Profile" : "Show Full XML Profile",
                            systemImage: "doc.text.magnifyingglass"
                        )
                    }

                    if showXML {
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            Text(MDMProfileSampleBuilder.profileXML(for: payload, keys: payloadKeys))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 400)
                    }
                } header: {
                    Text("Profile Examples")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(payload.name.isEmpty ? payload.payloadType : payload.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
