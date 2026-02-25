import Foundation

enum MDMSource: String, CaseIterable, Identifiable, Codable {
    case appleDeviceManagement = "Apple device-management"
    case appleDeveloperDocumentation = "Apple Developer Documentation"
    case profileCreator = "ProfileManifests"
    case rtroutonProfiles = "rtrouton/profiles"
    case rodChristiansenProfiles = "rodchristiansen/mobileconfig-profiles"
    case macNerdProfiles = "Mac-Nerd/Mac-profiles"

    var id: String { rawValue }

    var repoURL: String {
        switch self {
        case .appleDeviceManagement:
            return "https://github.com/apple/device-management"
        case .appleDeveloperDocumentation:
            return "https://developer.apple.com/documentation/devicemanagement"
        case .profileCreator:
            return "https://github.com/ProfileManifests/ProfileManifests"
        case .rtroutonProfiles:
            return "https://github.com/rtrouton/profiles"
        case .rodChristiansenProfiles:
            return "https://github.com/rodchristiansen/mobileconfig-profiles"
        case .macNerdProfiles:
            return "https://github.com/Mac-Nerd/Mac-profiles"
        }
    }

    var creditName: String {
        switch self {
        case .appleDeviceManagement: return "Apple"
        case .appleDeveloperDocumentation: return "Apple"
        case .profileCreator: return "ProfileManifests"
        case .rtroutonProfiles: return "rtrouton"
        case .rodChristiansenProfiles: return "rodchristiansen"
        case .macNerdProfiles: return "Mac-Nerd"
        }
    }

    var shortDescription: String {
        switch self {
        case .appleDeviceManagement:
            return "Official Apple device-management repository."
        case .appleDeveloperDocumentation:
            return "Apple developer documentation for MDM payloads."
        case .profileCreator:
            return "Community ProfileManifests payload manifest source."
        case .rtroutonProfiles:
            return "Community profile payload samples."
        case .rodChristiansenProfiles:
            return "Community mobileconfig profile library."
        case .macNerdProfiles:
            return "Community macOS configuration profile collection."
        }
    }

    var icon: String {
        switch self {
        case .appleDeviceManagement, .appleDeveloperDocumentation:
            return "apple.logo"
        case .profileCreator:
            return "doc.text.magnifyingglass"
        case .rtroutonProfiles:
            return "person.fill"
        case .rodChristiansenProfiles:
            return "doc.text"
        case .macNerdProfiles:
            return "doc.badge.gearshape"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        if let source = MDMSource(rawValue: value) {
            self = source
            return
        }

        switch value {
        case "appleDeviceManagement": self = .appleDeviceManagement
        case "appleDeveloperDocumentation": self = .appleDeveloperDocumentation
        case "profileCreator": self = .profileCreator
        case "ProfileCreator": self = .profileCreator
        case "rtroutonProfiles": self = .rtroutonProfiles
        case "rodChristiansenProfiles": self = .rodChristiansenProfiles
        case "mobileconfigProfiles": self = .rodChristiansenProfiles  // Legacy compatibility
        case "rodchristiansen/Profiles": self = .rodChristiansenProfiles  // Legacy compatibility
        case "mobileconfig-profiles": self = .rodChristiansenProfiles  // Legacy compatibility
        case "macNerdProfiles": self = .macNerdProfiles
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown MDM source: \(value)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct MDMSnapshot: Codable {
    let schemaVersion: Int
    let generatedAt: Date
    let sources: [MDMSourceSnapshot]
    let payloads: [MDMPayloadRecord]
    let keys: [MDMKeyRecord]
}

struct MDMSourceSnapshot: Codable {
    let source: MDMSource
    let repoURL: String
    let revision: String?
    let licenseName: String?
    let licenseURL: String?
    let fetchedAt: Date
    let itemCount: Int
}

struct MDMPayloadRecord: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let payloadType: String
    let category: String?
    let platforms: [String]
    let introduced: String?
    let deprecated: String?
    let sources: [MDMSource]
    let summary: String?
    let discussion: String?
    let profileExample: String?
    let profileExampleSyntax: String?

    init(
        id: String,
        name: String,
        payloadType: String,
        category: String?,
        platforms: [String],
        introduced: String?,
        deprecated: String?,
        sources: [MDMSource],
        summary: String? = nil,
        discussion: String? = nil,
        profileExample: String? = nil,
        profileExampleSyntax: String? = nil
    ) {
        self.id = id
        self.name = name
        self.payloadType = payloadType
        self.category = category
        self.platforms = platforms
        self.introduced = introduced
        self.deprecated = deprecated
        self.sources = sources
        self.summary = summary
        self.discussion = discussion
        self.profileExample = profileExample
        self.profileExampleSyntax = profileExampleSyntax
    }

    var isDeprecated: Bool { deprecated != nil }
}

struct MDMKeyRecord: Identifiable, Codable, Hashable {
    let id: String
    let key: String
    let keyPath: String
    let payloadType: String
    let payloadName: String?
    let platforms: [String]
    let sources: [MDMSource]
    let introduced: String?
    let deprecated: String?
    let publicationDate: String?
    let keyType: String?
    let keyDescription: String?
    let required: Bool?
    let defaultValue: String?
    let possibleValues: [String]?

    var isDeprecated: Bool { deprecated != nil }

    static func signature(payloadType: String, keyPath: String) -> String {
        "\(payloadType)|\(keyPath)"
    }
}

enum MDMKeyChangeType: String, Codable, Hashable {
    case added
    case updated
    case removed
}

struct MDMKeyFieldDelta: Codable, Hashable {
    let fieldName: String
    let oldValue: String?
    let newValue: String?
}

struct MDMKeyUpdatedChange: Codable, Hashable {
    let before: MDMKeyRecord
    let after: MDMKeyRecord
    let deltas: [MDMKeyFieldDelta]
}

struct MDMCatalogKeyChanges: Codable, Hashable {
    let added: [MDMKeyRecord]
    let updated: [MDMKeyUpdatedChange]
    let removed: [MDMKeyRecord]

    var totalCount: Int {
        added.count + updated.count + removed.count
    }
}

enum MDMProfileSampleBuilder {
    static func hierarchyComponents(for keyPath: String) -> [String] {
        let parts = tokens(from: keyPath).map { token in
            switch token {
            case let .key(name):
                return name
            case .arrayItem:
                return "[]"
            }
        }
        return parts.isEmpty ? [keyPath] : parts
    }

    static func hierarchyRoot(for keyPath: String) -> String {
        hierarchyComponents(for: keyPath).first ?? keyPath
    }

    static func hierarchyTrail(for keyPath: String) -> String? {
        let parts = hierarchyComponents(for: keyPath)
        guard parts.count > 1 else { return nil }
        return parts.dropFirst().joined(separator: " > ")
    }

    static func hierarchyDisplay(for keyPath: String) -> String {
        hierarchyComponents(for: keyPath).joined(separator: " > ")
    }

    static func simplifiedProfile(for key: MDMKeyRecord, payloadName: String?) -> String {
        let resolvedPayloadName = nonEmpty(payloadName)
            ?? nonEmpty(key.payloadName)
            ?? key.payloadType
        
        var lines: [String] = []
        lines.append("Payload Type: \(key.payloadType)")
        lines.append("Payload Name: \(resolvedPayloadName)")
        lines.append("")
        lines.append("Key Reference:")
        lines.append("  \(key.keyPath)")
        
        if let keyType = key.keyType {
            lines.append("  Type: \(keyType)")
        }
        if let required = key.required {
            lines.append("  Required: \(required ? "Yes" : "No")")
        }
        if let defaultValue = key.defaultValue {
            lines.append("  Default: \(defaultValue)")
        }
        
        return lines.joined(separator: "\n")
    }
    
    static func profileXML(for key: MDMKeyRecord, payloadName: String?) -> String {
        let resolvedPayloadName = nonEmpty(payloadName)
            ?? nonEmpty(key.payloadName)
            ?? key.payloadType

        let leafValue = sampleValue(for: key)
        let nested = nestedValue(tokens: tokens(from: key.keyPath), leaf: leafValue)

        let keyEntries: [(String, PlistValue)]
        if case let .dict(entries) = nested, !entries.isEmpty {
            keyEntries = entries
        } else {
            keyEntries = [(key.keyPath, leafValue)]
        }

        var payloadEntries: [(String, PlistValue)] = [
            ("PayloadType", .string(key.payloadType)),
            ("PayloadVersion", .integer(1)),
            ("PayloadIdentifier", .string("com.example.\(sanitizedIdentifier(from: key.payloadType)).payload")),
            ("PayloadUUID", .string("00000000-0000-0000-0000-000000000000")),
            ("PayloadDisplayName", .string(resolvedPayloadName))
        ]
        payloadEntries.append(contentsOf: keyEntries)

        let root: PlistValue = .dict([
            ("PayloadType", .string("Configuration")),
            ("PayloadVersion", .integer(1)),
            ("PayloadIdentifier", .string("com.example.generatedprofile")),
            ("PayloadUUID", .string("11111111-1111-1111-1111-111111111111")),
            ("PayloadDisplayName", .string("Generated \(resolvedPayloadName) Example")),
            ("PayloadContent", .array([.dict(payloadEntries)]))
        ])

        return plistDocument(for: root)
    }

    private enum PathToken {
        case key(String)
        case arrayItem
    }

    private enum PlistValue {
        case bool(Bool)
        case integer(Int)
        case real(Double)
        case string(String)
        case array([PlistValue])
        case dict([(String, PlistValue)])
        case date(String)
        case data(String)
    }

    private enum ValueKind {
        case bool
        case integer
        case real
        case string
        case array
        case dict
        case date
        case data
    }

    private static func tokens(from keyPath: String) -> [PathToken] {
        let rawPieces = keyPath
            .split(separator: ".", omittingEmptySubsequences: false)
            .map(String.init)

        var normalizedPieces: [String] = []
        var index = 0

        while index < rawPieces.count {
            let piece = rawPieces[index]
            if piece.isEmpty {
                if index + 1 < rawPieces.count, !rawPieces[index + 1].isEmpty {
                    normalizedPieces.append(".\(rawPieces[index + 1])")
                    index += 2
                } else {
                    index += 1
                }
                continue
            }

            normalizedPieces.append(piece)
            index += 1
        }

        var pathTokens: [PathToken] = []
        for piece in normalizedPieces {
            appendTokens(from: piece, into: &pathTokens)
        }

        return pathTokens
    }

    private static func appendTokens(from piece: String, into tokens: inout [PathToken]) {
        let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed == "[]" || isArrayIndex(trimmed) {
            tokens.append(.arrayItem)
            return
        }

        if trimmed.contains("[]") {
            var remainder = trimmed
            while let range = remainder.range(of: "[]") {
                let prefix = String(remainder[..<range.lowerBound])
                if !prefix.isEmpty {
                    tokens.append(.key(prefix))
                }
                tokens.append(.arrayItem)
                remainder = String(remainder[range.upperBound...])
            }
            if !remainder.isEmpty {
                tokens.append(.key(remainder))
            }
            return
        }

        tokens.append(.key(trimmed))
    }

    private static func isArrayIndex(_ value: String) -> Bool {
        value.range(of: #"^\[\d+\]$"#, options: .regularExpression) != nil
    }

    private static func nestedValue(tokens: [PathToken], leaf: PlistValue) -> PlistValue {
        guard let first = tokens.first else { return leaf }
        let remaining = Array(tokens.dropFirst())

        switch first {
        case .arrayItem:
            return .array([nestedValue(tokens: remaining, leaf: leaf)])
        case let .key(name):
            return .dict([(name, nestedValue(tokens: remaining, leaf: leaf))])
        }
    }

    private static func sampleValue(for key: MDMKeyRecord) -> PlistValue {
        switch valueKind(from: key.keyType) {
        case .bool:
            return .bool(parsedBool(from: key.defaultValue) ?? true)
        case .integer:
            return .integer(parsedInt(from: key.defaultValue) ?? parsedInt(from: key.possibleValues?.first) ?? 1)
        case .real:
            return .real(parsedDouble(from: key.defaultValue) ?? parsedDouble(from: key.possibleValues?.first) ?? 1.0)
        case .array:
            return .array([sampleArrayElement(for: key)])
        case .dict:
            return .dict([("ExampleKey", sampleScalarElement(for: key))])
        case .date:
            return .date("2026-01-01T00:00:00Z")
        case .data:
            return .data("AA==")
        case .string:
            return .string(sampleString(for: key))
        }
    }

    private static func sampleArrayElement(for key: MDMKeyRecord) -> PlistValue {
        let loweredType = key.keyType?.lowercased() ?? ""
        if loweredType.contains("boolean") || loweredType.contains("bool") {
            return .bool(true)
        }
        if loweredType.contains("integer") || loweredType.contains(" int") {
            return .integer(parsedInt(from: key.defaultValue) ?? parsedInt(from: key.possibleValues?.first) ?? 1)
        }
        if loweredType.contains("double") || loweredType.contains("float") || loweredType.contains("number") || loweredType.contains("real") {
            return .real(parsedDouble(from: key.defaultValue) ?? parsedDouble(from: key.possibleValues?.first) ?? 1.0)
        }
        if loweredType.contains("object") || loweredType.contains("dictionary") || loweredType.contains("dict") {
            return .dict([("ExampleKey", sampleScalarElement(for: key))])
        }
        return .string(sampleString(for: key))
    }

    private static func sampleScalarElement(for key: MDMKeyRecord) -> PlistValue {
        if let boolValue = parsedBool(from: key.defaultValue) {
            return .bool(boolValue)
        }
        if let intValue = parsedInt(from: key.defaultValue) {
            return .integer(intValue)
        }
        if let doubleValue = parsedDouble(from: key.defaultValue) {
            return .real(doubleValue)
        }
        return .string(sampleString(for: key))
    }

    private static func sampleString(for key: MDMKeyRecord) -> String {
        if let defaultValue = nonEmpty(key.defaultValue) {
            return defaultValue
        }
        if let firstValue = key.possibleValues?.compactMap(nonEmpty).first {
            return firstValue
        }
        return "ExampleValue"
    }

    private static func valueKind(from keyType: String?) -> ValueKind {
        let lowered = keyType?.lowercased() ?? ""

        if lowered.contains("array") || lowered.hasSuffix("[]") {
            return .array
        }
        if lowered.contains("object") || lowered.contains("dictionary") || lowered.contains("dict") {
            return .dict
        }
        if lowered.contains("boolean") || lowered == "bool" {
            return .bool
        }
        if lowered.contains("double") || lowered.contains("float") || lowered.contains("number") || lowered.contains("real") {
            return .real
        }
        if lowered.contains("integer") || lowered.contains(" int") || lowered.hasPrefix("int") {
            return .integer
        }
        if lowered.contains("date") {
            return .date
        }
        if lowered.contains("data") {
            return .data
        }
        return .string
    }

    private static func parsedBool(from value: String?) -> Bool? {
        guard let normalized = nonEmpty(value)?.lowercased() else { return nil }
        if normalized == "true" || normalized == "yes" || normalized == "1" {
            return true
        }
        if normalized == "false" || normalized == "no" || normalized == "0" {
            return false
        }
        return nil
    }

    private static func parsedInt(from value: String?) -> Int? {
        guard let text = nonEmpty(value) else { return nil }
        if let direct = Int(text) {
            return direct
        }
        guard let range = text.range(of: #"-?\d+"#, options: .regularExpression) else { return nil }
        return Int(text[range])
    }

    private static func parsedDouble(from value: String?) -> Double? {
        guard let text = nonEmpty(value) else { return nil }
        if let direct = Double(text) {
            return direct
        }
        guard let range = text.range(of: #"-?\d+(?:\.\d+)?"#, options: .regularExpression) else { return nil }
        return Double(text[range])
    }

    private static func plistDocument(for root: PlistValue) -> String {
        var lines: [String] = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
            "<plist version=\"1.0\">"
        ]
        lines.append(contentsOf: xmlLines(for: root, indentLevel: 0))
        lines.append("</plist>")
        return lines.joined(separator: "\n")
    }

    private static func xmlLines(for value: PlistValue, indentLevel: Int) -> [String] {
        let indent = String(repeating: "    ", count: indentLevel)
        switch value {
        case let .bool(flag):
            return ["\(indent)<\(flag ? "true" : "false")/>"]
        case let .integer(number):
            return ["\(indent)<integer>\(number)</integer>"]
        case let .real(number):
            return ["\(indent)<real>\(format(number))</real>"]
        case let .string(text):
            return ["\(indent)<string>\(xmlEscaped(text))</string>"]
        case let .date(text):
            return ["\(indent)<date>\(xmlEscaped(text))</date>"]
        case let .data(text):
            return ["\(indent)<data>\(xmlEscaped(text))</data>"]
        case let .array(values):
            var lines: [String] = ["\(indent)<array>"]
            if values.isEmpty {
                lines.append("\(indent)</array>")
                return lines
            }
            for item in values {
                lines.append(contentsOf: xmlLines(for: item, indentLevel: indentLevel + 1))
            }
            lines.append("\(indent)</array>")
            return lines
        case let .dict(entries):
            var lines: [String] = ["\(indent)<dict>"]
            for (key, nestedValue) in entries {
                lines.append("\(indent)    <key>\(xmlEscaped(key))</key>")
                lines.append(contentsOf: xmlLines(for: nestedValue, indentLevel: indentLevel + 1))
            }
            lines.append("\(indent)</dict>")
            return lines
        }
    }

    private static func format(_ number: Double) -> String {
        if number.rounded(.towardZero) == number {
            return "\(Int(number))"
        }
        return "\(number)"
    }

    private static func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func sanitizedIdentifier(from payloadType: String) -> String {
        let lowered = payloadType.lowercased()
        let replaced = lowered.replacingOccurrences(
            of: #"[^a-z0-9.]+"#,
            with: ".",
            options: .regularExpression
        )
        return replaced.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}
