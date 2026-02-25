import SwiftUI

struct KeyDetailView: View {
    let key: MDMKeyRecord
    @State private var showXML = false

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.key)
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
                Section("Sources") {
                    ForEach(key.sources) { source in
                        Link(destination: URL(string: source.repoURL)!) {
                            Label(source.rawValue, systemImage: source.icon)
                        }
                    }
                }
            }

            // Profile XML Example
            Section {
                Button {
                    showXML.toggle()
                } label: {
                    Label(
                        showXML ? "Hide Profile XML Example" : "Show Profile XML Example",
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
                Text("Profile Example")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(key.key)
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
