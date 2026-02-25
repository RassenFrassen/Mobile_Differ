import SwiftUI

struct KeyDetailView: View {
    let key: MDMKeyRecord
    @State private var showXML = false
    @State private var showSimplified = false
    
    private var displayName: String {
        if key.key == "ANY" {
            return "Custom Keys (any key-value pairs)"
        }
        return key.key
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.title2.weight(.bold))
                                .textSelection(.enabled)
                            Text(key.keyPath)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if key.isDeprecated {
                                Label("Deprecated", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                            if key.required == true {
                                Label("Required", systemImage: "asterisk")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if !key.platforms.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(key.platforms, id: \.self) { platform in
                                PlatformBadge(platform: platform)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Description
            if let description = key.keyDescription, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .font(.body)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Key Details
            Section("Key Details") {
                DetailRow(label: "Key Name", value: key.key)
                DetailRow(label: "Key Path", value: key.keyPath, monospaced: true)
                DetailRow(label: "Payload Type", value: key.payloadType, monospaced: true)
                if let payloadName = key.payloadName {
                    DetailRow(label: "Payload Name", value: payloadName)
                }
                if let keyType = key.keyType {
                    DetailRow(label: "Type", value: keyType)
                }
                if let required = key.required {
                    DetailRow(label: "Required", value: required ? "Yes" : "No")
                }
                if let defaultValue = key.defaultValue {
                    DetailRow(label: "Default Value", value: defaultValue, monospaced: true)
                }
                if let introduced = key.introduced {
                    DetailRow(label: "Introduced", value: introduced)
                }
                if let deprecated = key.deprecated {
                    DetailRow(label: "Deprecated", value: deprecated)
                        .foregroundStyle(.orange)
                }
                if let pubDate = key.publicationDate {
                    DetailRow(label: "Published", value: pubDate)
                }
            }

            // Possible Values
            if let values = key.possibleValues, !values.isEmpty {
                Section("Possible Values") {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            // Sources
            if !key.sources.isEmpty {
                Section {
                    if key.sources.count > 1 {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Available in multiple sources", systemImage: "doc.on.doc.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.vertical, 4)
                            if hasAppleSource {
                                Text("Apple sources are used as the primary source of truth")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    ForEach(key.sources) { source in
                        HStack {
                            Link(destination: URL(string: source.repoURL)!) {
                                Label(source.rawValue, systemImage: source.icon)
                            }
                            if isAppleSource(source) && key.sources.count > 1 {
                                Spacer()
                                Text("Primary")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                } header: {
                    Text(key.sources.count > 1 ? "Sources (\(key.sources.count))" : "Source")
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
                    Text(MDMProfileSampleBuilder.simplifiedProfile(for: key, payloadName: key.payloadName))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
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
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(MDMProfileSampleBuilder.profileXML(for: key, payloadName: key.payloadName))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Profile Examples")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText)
            }
        }
    }

    private var shareText: String {
        var parts = ["MDM Key: \(key.key)", "Path: \(key.keyPath)", "Payload: \(key.payloadType)"]
        if let desc = key.keyDescription { parts.append("Description: \(desc)") }
        if let type = key.keyType { parts.append("Type: \(type)") }
        if !key.platforms.isEmpty { parts.append("Platforms: \(key.platforms.joined(separator: ", "))") }
        return parts.joined(separator: "\n")
    }

    private var hasAppleSource: Bool {
        key.sources.contains { isAppleSource($0) }
    }

    private func isAppleSource(_ source: MDMSource) -> Bool {
        source == .appleDeviceManagement || source == .appleDeveloperDocumentation
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
    }
}
