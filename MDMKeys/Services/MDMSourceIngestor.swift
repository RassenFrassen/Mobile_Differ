import Foundation
import CryptoKit
#if canImport(Yams)
import Yams
#endif

actor MDMSourceIngestor {
    static let shared = MDMSourceIngestor()

    struct SourceResult {
        let source: MDMSource
        let payloads: [MDMPayloadRecord]
        let keys: [MDMKeyRecord]
        let revision: String?
        let licenseName: String?
        let licenseURL: String?
    }

    func fetchAll(token: String?, enabledSources: Set<MDMSource>) async -> [SourceResult] {
        await withTaskGroup(of: SourceResult?.self) { group in
            if enabledSources.contains(.appleDeviceManagement) {
                group.addTask { await self.fetchAppleDeviceManagement(token: token) }
            }
            if enabledSources.contains(.appleDeveloperDocumentation) {
                group.addTask { await self.fetchAppleDeveloperDocumentation() }
            }
            if enabledSources.contains(.profileCreator) {
                group.addTask { await self.fetchProfileCreatorRepo(token: token) }
            }
            if enabledSources.contains(.rtroutonProfiles) {
                group.addTask { await self.fetchRtroutonProfiles(token: token) }
            }
            if enabledSources.contains(.rodChristiansenProfiles) {
                group.addTask { await self.fetchRodChristiansenProfiles(token: token) }
            }
            if enabledSources.contains(.macNerdProfiles) {
                group.addTask { await self.fetchMacNerdProfiles(token: token) }
            }

            var results: [SourceResult] = []
            for await result in group {
                if let result { results.append(result) }
            }
            return results
        }
    }

    // MARK: - Apple device-management

    private func fetchAppleDeviceManagement(token: String?) async -> SourceResult? {
        let owner = "apple"
        let repo = "device-management"
        let path = "mdm/profiles"

        do {
            if let mirrored = try await fetchAppleDeviceManagementFromMirror(owner: owner, repo: repo, path: path) {
                return mirrored
            }

            let repoInfo = try? await GitHubService.shared.fetchRepo(owner: owner, repo: repo, token: token)
            let files = try await GitHubService.shared.listFiles(owner: owner, repo: repo, path: path, token: token)
            let profileFiles = files.filter { $0.name.hasSuffix(".yaml") || $0.name.hasSuffix(".yml") || $0.name.hasSuffix(".json") }

            var payloads: [MDMPayloadRecord] = []
            var keys: [MDMKeyRecord] = []

            for file in profileFiles {
                guard let downloadURL = file.downloadURL else { continue }
                let content = try await GitHubService.shared.fetchContent(url: downloadURL, token: token)
                let parsed = AppleMDMYamlParser.parse(content: content, source: .appleDeviceManagement)
                payloads.append(contentsOf: parsed.payloads)
                keys.append(contentsOf: parsed.keys)
            }

            return SourceResult(
                source: .appleDeviceManagement,
                payloads: payloads,
                keys: keys,
                revision: repoInfo?.updatedAt,
                licenseName: "MIT",
                licenseURL: "https://github.com/apple/device-management/blob/release/LICENSE"
            )
        } catch {
            return nil
        }
    }

    private func fetchAppleDeviceManagementFromMirror(owner: String, repo: String, path: String) async throws -> SourceResult? {
        let sync = try await GitMirrorService.shared.syncDaily(owner: owner, repo: repo)
        let profilesRoot = sync.localURL.appendingPathComponent(path, isDirectory: true)
        let files = localFilesRecursive(
            root: profilesRoot,
            allowedExtensions: ["yaml", "yml", "json"]
        )

        guard !files.isEmpty else { return nil }

        var payloads: [MDMPayloadRecord] = []
        var keys: [MDMKeyRecord] = []

        for fileURL in files {
            guard let content = readText(from: fileURL) else { continue }
            let parsed = AppleMDMYamlParser.parse(content: content, source: .appleDeviceManagement)
            payloads.append(contentsOf: parsed.payloads)
            keys.append(contentsOf: parsed.keys)
        }

        return SourceResult(
            source: .appleDeviceManagement,
            payloads: payloads,
            keys: keys,
            revision: sync.currentRevision,
            licenseName: "MIT",
            licenseURL: "https://github.com/apple/device-management/blob/release/LICENSE"
        )
    }

    // MARK: - Apple Developer Documentation (developer.apple.com)

    private func fetchAppleDeveloperDocumentation() async -> SourceResult? {
        do {
            return try await fetchAppleDeveloperDocumentationData()
        } catch {
            return nil
        }
    }

    private func fetchAppleDeveloperDocumentationData() async throws -> SourceResult {
        let docsRootPath = "/documentation/devicemanagement"
        let docsProfilePath = "/documentation/devicemanagement/profile-specific-payload-keys"
        let topicPayloadType = "docs.devicemanagement.topics"
        let topicPayloadName = "Device Management Documentation Topics"
        let maxPages = 360

        var payloads: [String: MDMPayloadRecord] = [:]
        var keys: [String: MDMKeyRecord] = [:]
        var revisionInputs: [String] = []

        let profileDoc = try await fetchDeveloperDocumentationJSON(path: docsProfilePath)
        let sectionByURL = developerDocsSectionMap(from: profileDoc.document)
        var deprecatedHintByPath: [String: String] = [:]
        mergeDeveloperDocReferenceDeprecationHints(
            from: profileDoc.document,
            into: &deprecatedHintByPath
        )

        var queue: [String] = [docsRootPath, docsProfilePath]
        queue.append(contentsOf: developerDocReferencePaths(from: profileDoc.document))

        var visited: Set<String> = []

        while let nextPath = queue.first, visited.count < maxPages {
            queue.removeFirst()
            guard let path = normalizeDeveloperDocsPath(nextPath), !visited.contains(path) else { continue }
            visited.insert(path)

            let fetched = try? await fetchDeveloperDocumentationJSON(path: path)
            guard let fetched else { continue }
            mergeDeveloperDocReferenceDeprecationHints(
                from: fetched.document,
                into: &deprecatedHintByPath
            )

            revisionInputs.append(path)
            if let etag = fetched.response.value(forHTTPHeaderField: "Etag") {
                revisionInputs.append("\(path)#\(etag)")
            }

            let title = developerDocTitle(from: fetched.document, path: path)
            let abstract = developerDocAbstract(from: fetched.document)
            let contentDetails = developerDocContentDetails(from: fetched.document)
            let platforms = developerDocPlatforms(from: fetched.document)
            let deprecatedAt = mergedDeprecatedValue(
                developerDocDeprecatedVersion(from: fetched.document),
                deprecatedHintByPath[path]
            )
            let sectionCategory = developerDocsCategory(for: path, sectionByURL: sectionByURL)

            if payloads[topicPayloadType] == nil {
                payloads[topicPayloadType] = MDMPayloadRecord(
                    id: topicPayloadType,
                    name: topicPayloadName,
                    payloadType: topicPayloadType,
                category: "Documentation",
                platforms: [],
                introduced: nil,
                deprecated: nil,
                sources: [.appleDeveloperDocumentation],
                summary: nil,
                discussion: nil,
                profileExample: nil,
                profileExampleSyntax: nil
            )
            }

            let topicKeyPath = developerDocsRelativePath(path)
            let topicKey = MDMKeyRecord(
                id: MDMKeyRecord.signature(payloadType: topicPayloadType, keyPath: topicKeyPath),
                key: title,
                keyPath: topicKeyPath,
                payloadType: topicPayloadType,
                payloadName: topicPayloadName,
                platforms: platforms,
                sources: [.appleDeveloperDocumentation],
                introduced: nil,
                deprecated: deprecatedAt,
                publicationDate: fetched.response.value(forHTTPHeaderField: "Last-Modified"),
                keyType: developerDocRole(from: fetched.document),
                keyDescription: abstract.isEmpty ? nil : abstract,
                required: nil,
                defaultValue: nil,
                possibleValues: nil
            )
            keys[topicKey.id] = topicKey

            let pagePayloadType = developerDocsPayloadType(for: path)
            payloads[pagePayloadType] = MDMPayloadRecord(
                id: pagePayloadType,
                name: title,
                payloadType: pagePayloadType,
                category: sectionCategory,
                platforms: platforms,
                introduced: nil,
                deprecated: deprecatedAt,
                sources: [.appleDeveloperDocumentation],
                summary: abstract.isEmpty ? nil : abstract,
                discussion: contentDetails.discussion,
                profileExample: contentDetails.profileExample,
                profileExampleSyntax: contentDetails.profileExampleSyntax
            )

            let pageProperties = developerDocProperties(
                from: fetched.document,
                fallbackDeprecated: deprecatedAt
            )
            for property in pageProperties {
                let keyPath = property.name
                let keyRecord = MDMKeyRecord(
                    id: MDMKeyRecord.signature(payloadType: pagePayloadType, keyPath: keyPath),
                    key: property.name,
                    keyPath: keyPath,
                    payloadType: pagePayloadType,
                    payloadName: title,
                    platforms: platforms,
                    sources: [.appleDeveloperDocumentation],
                    introduced: property.introduced,
                    deprecated: property.deprecated,
                    publicationDate: fetched.response.value(forHTTPHeaderField: "Last-Modified"),
                    keyType: property.type,
                    keyDescription: property.description,
                    required: property.required,
                    defaultValue: property.defaultValue,
                    possibleValues: property.possibleValues
                )
                keys[keyRecord.id] = keyRecord
            }

            queue.append(contentsOf: developerDocReferencePaths(from: fetched.document))
        }

        let revision = developerDocsRevision(from: revisionInputs)

        return SourceResult(
            source: .appleDeveloperDocumentation,
            payloads: Array(payloads.values),
            keys: Array(keys.values),
            revision: revision,
            licenseName: nil,
            licenseURL: "https://www.apple.com/legal/internet-services/terms/site.html"
        )
    }

    private struct DeveloperDocFetchResult {
        let document: [String: Any]
        let response: HTTPURLResponse
    }

    private struct DeveloperDocProperty {
        let name: String
        let description: String?
        let type: String?
        let required: Bool?
        let defaultValue: String?
        let possibleValues: [String]?
        let introduced: String?
        let deprecated: String?
    }

    private struct DeveloperDocContentDetails {
        let discussion: String?
        let profileExample: String?
        let profileExampleSyntax: String?

        static let empty = DeveloperDocContentDetails(
            discussion: nil,
            profileExample: nil,
            profileExampleSyntax: nil
        )
    }

    private func fetchDeveloperDocumentationJSON(path: String) async throws -> DeveloperDocFetchResult {
        guard let normalizedPath = normalizeDeveloperDocsPath(path),
              let url = developerDocsDataURL(path: normalizedPath) else {
            throw GitHubError.networkError("Invalid Apple docs path: \(path)")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Differ/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GitHubError.networkError("Apple docs request failed: \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.networkError("Apple docs response invalid")
        }
        guard (200...299).contains(http.statusCode) else {
            throw GitHubError.networkError("Apple docs HTTP \(http.statusCode)")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GitHubError.decodingError("Apple docs JSON is not an object")
        }

        return DeveloperDocFetchResult(document: obj, response: http)
    }

    private func developerDocsDataURL(path: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "developer.apple.com"
        components.path = "/tutorials/data\(path).json"
        return components.url
    }

    private func normalizeDeveloperDocsPath(_ rawPath: String) -> String? {
        let raw = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let pathCandidate: String
        if raw.hasPrefix("http://") || raw.hasPrefix("https://"), let absolute = URL(string: raw) {
            pathCandidate = absolute.path
        } else {
            pathCandidate = raw
        }

        guard pathCandidate.hasPrefix("/") else { return nil }
        let noFragment = pathCandidate.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? pathCandidate
        let noQuery = noFragment.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? noFragment
        guard noQuery.hasPrefix("/documentation/devicemanagement") else { return nil }
        return noQuery
    }

    private func developerDocReferencePaths(from document: [String: Any]) -> [String] {
        guard let references = document["references"] as? [String: Any] else { return [] }
        var paths: Set<String> = []
        for value in references.values {
            guard let ref = value as? [String: Any],
                  let url = ref["url"] as? String,
                  let normalized = normalizeDeveloperDocsPath(url) else { continue }
            paths.insert(normalized)
        }
        return Array(paths).sorted()
    }

    private func mergeDeveloperDocReferenceDeprecationHints(
        from document: [String: Any],
        into hints: inout [String: String]
    ) {
        guard let references = document["references"] as? [String: Any] else { return }

        for value in references.values {
            guard let reference = value as? [String: Any],
                  let rawURL = reference["url"] as? String,
                  let normalizedPath = normalizeDeveloperDocsPath(rawURL),
                  let deprecatedHint = developerDocReferenceDeprecatedValue(from: reference) else {
                continue
            }

            hints[normalizedPath] = mergedDeprecatedValue(
                hints[normalizedPath],
                deprecatedHint
            )
        }
    }

    private func developerDocReferenceDeprecatedValue(from reference: [String: Any]) -> String? {
        if let version = developerDocString(reference["deprecatedVersion"]) {
            return version
        }

        if let deprecatedAt = developerDocString(reference["deprecatedAt"]) {
            return deprecatedAt
        }

        if let deprecated = reference["deprecated"] {
            if let flag = deprecated as? Bool {
                return flag ? "Deprecated" : nil
            }
            return developerDocString(deprecated)
        }

        return nil
    }

    private func mergedDeprecatedValue(_ lhs: String?, _ rhs: String?) -> String? {
        let left = lhs?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let right = rhs?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        switch (left, right) {
        case let (.some(leftValue), .some(rightValue)):
            if leftValue == rightValue { return leftValue }
            if leftValue == "Deprecated" { return rightValue }
            if rightValue == "Deprecated" { return leftValue }

            let parts = Set(
                (leftValue.split(separator: ",") + rightValue.split(separator: ","))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
            return parts.sorted().joined(separator: ", ").nilIfEmpty
        case let (.some(leftValue), .none):
            return leftValue
        case let (.none, .some(rightValue)):
            return rightValue
        case (.none, .none):
            return nil
        }
    }

    private func developerDocsSectionMap(from document: [String: Any]) -> [String: String] {
        guard let topicSections = document["topicSections"] as? [[String: Any]],
              let references = document["references"] as? [String: Any] else {
            return [:]
        }

        var map: [String: String] = [:]
        for section in topicSections {
            guard let title = section["title"] as? String else { continue }
            let identifiers = section["identifiers"] as? [String] ?? []
            for identifier in identifiers {
                guard let ref = references[identifier] as? [String: Any],
                      let url = ref["url"] as? String,
                      let normalized = normalizeDeveloperDocsPath(url) else { continue }
                map[normalized] = title
            }
        }

        return map
    }

    private func developerDocsCategory(for path: String, sectionByURL: [String: String]) -> String? {
        if let section = sectionByURL[path] {
            return section
        }

        let components = path.split(separator: "/").map(String.init)
        guard components.count >= 4 else { return nil }
        let parent = "/documentation/devicemanagement/\(components[3])"
        return sectionByURL[parent]
    }

    private func developerDocsPayloadType(for path: String) -> String {
        let relative = developerDocsRelativePath(path)
            .replacingOccurrences(of: "/", with: ".")
            .replacingOccurrences(of: "-", with: "_")
        return "docs.devicemanagement.\(relative)"
    }

    private func developerDocsRelativePath(_ path: String) -> String {
        let prefix = "/documentation/devicemanagement/"
        if path == "/documentation/devicemanagement" {
            return "root"
        }
        if path.hasPrefix(prefix) {
            return String(path.dropFirst(prefix.count))
        }
        return path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func developerDocTitle(from document: [String: Any], path: String) -> String {
        if let metadata = document["metadata"] as? [String: Any],
           let title = metadata["title"] as? String,
           !title.isEmpty {
            return title
        }
        if let title = document["title"] as? String, !title.isEmpty {
            return title
        }
        return developerDocsRelativePath(path)
    }

    private func developerDocRole(from document: [String: Any]) -> String? {
        if let metadata = document["metadata"] as? [String: Any],
           let role = metadata["role"] as? String,
           !role.isEmpty {
            return role
        }
        return nil
    }

    private func developerDocAbstract(from document: [String: Any]) -> String {
        let text = developerDocText(from: document["abstract"])
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func developerDocContentDetails(from document: [String: Any]) -> DeveloperDocContentDetails {
        guard let sections = document["primaryContentSections"] as? [[String: Any]] else {
            return .empty
        }

        var discussionParts: [String] = []
        var profileExample: String?
        var profileExampleSyntax: String?
        var currentHeading: String?

        for section in sections where (section["kind"] as? String) == "content" {
            let contentItems = section["content"] as? [[String: Any]] ?? []
            for item in contentItems {
                let itemType = item["type"] as? String

                if itemType == "heading" {
                    currentHeading = normalizedDeveloperDocHeading(item["text"] as? String)
                    continue
                }

                if currentHeading == "discussion" {
                    if itemType == "table" || itemType == "codeListing" { continue }
                    let text = developerDocText(from: item["inlineContent"]).nilIfEmpty
                        ?? developerDocText(from: item["content"]).nilIfEmpty
                        ?? developerDocText(from: item).nilIfEmpty
                    if let text {
                        discussionParts.append(text)
                    }
                    continue
                }

                if currentHeading == "profile example" {
                    if itemType == "codeListing" && profileExample == nil {
                        if let codeLines = item["code"] as? [String], !codeLines.isEmpty {
                            profileExample = codeLines.joined(separator: "\n")
                        } else if let code = developerDocString(item["code"]) {
                            profileExample = code
                        }
                        profileExampleSyntax = (item["syntax"] as? String)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .nilIfEmpty
                    }
                    continue
                }

                // Fallback: some docs omit the "Profile example" heading.
                if itemType == "codeListing", profileExample == nil {
                    if let codeLines = item["code"] as? [String], !codeLines.isEmpty {
                        profileExample = codeLines.joined(separator: "\n")
                    } else if let code = developerDocString(item["code"]) {
                        profileExample = code
                    }
                    profileExampleSyntax = (item["syntax"] as? String)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .nilIfEmpty
                }
            }
        }

        let discussion = discussionParts
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        return DeveloperDocContentDetails(
            discussion: discussion,
            profileExample: profileExample?.nilIfEmpty,
            profileExampleSyntax: profileExampleSyntax
        )
    }

    private func normalizedDeveloperDocHeading(_ raw: String?) -> String? {
        raw?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .nilIfEmpty
    }

    private func developerDocPlatforms(from document: [String: Any]) -> [String] {
        var platforms: [String] = []
        if let metadata = document["metadata"] as? [String: Any],
           let listed = metadata["platforms"] as? [[String: Any]] {
            platforms.append(contentsOf: listed.compactMap { $0["name"] as? String })
        }

        if platforms.isEmpty,
           let sections = document["primaryContentSections"] as? [[String: Any]] {
            for section in sections where (section["kind"] as? String) == "declarations" {
                let declarations = section["declarations"] as? [[String: Any]] ?? []
                for declaration in declarations {
                    if let listed = declaration["platforms"] as? [String] {
                        platforms.append(contentsOf: listed)
                    }
                }
            }
        }

        return Array(Set(platforms)).sorted()
    }

    private func developerDocDeprecatedVersion(from document: [String: Any]) -> String? {
        guard let metadata = document["metadata"] as? [String: Any] else { return nil }

        var versions: [String] = []
        if let platforms = metadata["platforms"] as? [[String: Any]] {
            versions = platforms.compactMap { platform in
                developerDocString(platform["deprecatedAt"])
            }
        }

        if versions.isEmpty {
            if let deprecated = metadata["deprecated"] as? Bool, deprecated {
                return "Deprecated"
            }
            return nil
        }

        let deduped = Array(Set(versions)).sorted()
        if deduped.count == 1 {
            return deduped[0]
        }
        return deduped.joined(separator: ", ")
    }

    private func developerDocProperties(
        from document: [String: Any],
        fallbackDeprecated: String?
    ) -> [DeveloperDocProperty] {
        guard let sections = document["primaryContentSections"] as? [[String: Any]] else {
            return []
        }

        var properties: [DeveloperDocProperty] = []
        for section in sections where (section["kind"] as? String) == "properties" {
            let items = section["items"] as? [[String: Any]] ?? []
            for item in items {
                guard let name = item["name"] as? String, !name.isEmpty else { continue }

                let type = developerDocType(from: item["type"]).nilIfEmpty
                let description = developerDocText(from: item["content"]).nilIfEmpty
                let required = item["required"] as? Bool
                let introduced = developerDocString(item["introducedVersion"])
                let deprecated = developerDocPropertyDeprecatedValue(
                    item: item,
                    fallbackDeprecated: fallbackDeprecated
                )

                var defaultValue: String? = nil
                var possibleValues: [String]? = nil
                let attributes = item["attributes"] as? [[String: Any]] ?? []
                for attribute in attributes {
                    guard let kind = attribute["kind"] as? String else { continue }
                    if kind == "default" {
                        defaultValue = developerDocString(attribute["value"])
                    } else if kind == "allowedValues",
                              let values = attribute["values"] as? [Any] {
                        let parsed = values.compactMap(developerDocString)
                        if !parsed.isEmpty {
                            possibleValues = parsed
                        }
                    }
                }

                properties.append(
                    DeveloperDocProperty(
                        name: name,
                        description: description,
                        type: type,
                        required: required,
                        defaultValue: defaultValue,
                        possibleValues: possibleValues,
                        introduced: introduced,
                        deprecated: deprecated
                    )
                )
            }
        }

        return properties
    }

    private func developerDocType(from value: Any?) -> String {
        switch value {
        case let string as String:
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case let dict as [String: Any]:
            if let text = dict["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return developerDocText(from: value)
        case let array as [[String: Any]]:
            let pieces = array.compactMap { item -> String? in
                if let text = item["text"] as? String {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                }
                return nil
            }
            if !pieces.isEmpty {
                return pieces.joined(separator: " ")
            }
            return developerDocText(from: value)
        default:
            return developerDocText(from: value)
        }
    }

    private func developerDocPropertyDeprecatedValue(
        item: [String: Any],
        fallbackDeprecated: String?
    ) -> String? {
        if let version = developerDocString(item["deprecatedVersion"]) {
            return version
        }

        if let value = item["deprecated"] {
            if let boolValue = value as? Bool {
                if boolValue {
                    return fallbackDeprecated ?? "Deprecated"
                }
            } else if let textValue = developerDocString(value) {
                return textValue
            }
        }

        return nil
    }

    private func developerDocText(from value: Any?) -> String {
        var pieces: [String] = []
        collectDeveloperDocText(value, into: &pieces)
        let collapsed = pieces
            .joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func collectDeveloperDocText(_ value: Any?, into pieces: inout [String]) {
        switch value {
        case let text as String:
            if !text.isEmpty {
                pieces.append(text)
            }
        case let dict as [String: Any]:
            if let text = dict["text"] as? String, !text.isEmpty {
                pieces.append(text)
            }
            for nested in dict.values {
                collectDeveloperDocText(nested, into: &pieces)
            }
        case let array as [Any]:
            for item in array {
                collectDeveloperDocText(item, into: &pieces)
            }
        default:
            break
        }
    }

    private func developerDocString(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let text = value as? String {
            return text.nilIfEmpty
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        let text = "\(value)"
        return text.nilIfEmpty
    }

    private func developerDocsRevision(from fragments: [String]) -> String? {
        guard !fragments.isEmpty else { return nil }
        let stable = fragments.sorted().joined(separator: "\n")
        let digest = SHA256.hash(data: Data(stable.utf8))
        let hex = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        return "docs-\(hex)"
    }

    // MARK: - ProfileManifests

    private func fetchProfileCreatorRepo(token: String?) async -> SourceResult? {
        let source: MDMSource = .profileCreator
        let owner = "ProfileManifests"
        let repo = "ProfileManifests"
        let licenseName = "MIT"
        let licenseURL = "https://github.com/ProfileManifests/ProfileManifests/blob/main/LICENSE"

        // Try offline bundle first
        if let bundled = try? await fetchProfileManifestsFromBundle(
            source: source,
            licenseName: licenseName,
            licenseURL: licenseURL
        ) {
            return bundled
        }

        if let localResult = fetchProfileManifestsFromLocalCheckout(
            source: source,
            licenseName: licenseName,
            licenseURL: licenseURL
        ) {
            return localResult
        }

        do {
            if let mirrored = try await fetchProfileManifestsFromMirror(
                owner: owner,
                repo: repo,
                source: source,
                licenseName: licenseName,
                licenseURL: licenseURL
            ) {
                return mirrored
            }

            let repoInfo = try? await GitHubService.shared.fetchRepo(owner: owner, repo: repo, token: token)
            let files = try await listProfileFilesRecursive(owner: owner, repo: repo, token: token)

            var payloadsByType: [String: MDMPayloadRecord] = [:]
            var keysByID: [String: MDMKeyRecord] = [:]

            for file in files {
                guard file.name.hasSuffix(".plist"),
                      file.path.hasPrefix("Manifests/") || file.path.hasPrefix("manifests/"),
                      let downloadURL = file.downloadURL else {
                    continue
                }

                let data = try await GitHubService.shared.fetchData(url: downloadURL, token: token)
                let manifestRoot = file.path.hasPrefix("Manifests/") ? "Manifests" : "manifests"
                let category = profileManifestCategory(fromRelativePath: file.path, rootFolderName: manifestRoot)
                let extracted = ProfileManifestCatalogExtractor.extract(
                    from: data,
                    source: source,
                    category: category
                )
                mergeCatalogExtracted(
                    extracted,
                    payloads: &payloadsByType,
                    keys: &keysByID
                )
            }

            guard !payloadsByType.isEmpty || !keysByID.isEmpty else { return nil }

            return SourceResult(
                source: source,
                payloads: Array(payloadsByType.values),
                keys: Array(keysByID.values),
                revision: repoInfo?.updatedAt,
                licenseName: licenseName,
                licenseURL: licenseURL
            )
        } catch {
            return nil
        }
    }

    // MARK: - rtrouton/profiles

    private func fetchRtroutonProfiles(token: String?) async -> SourceResult? {
        await fetchProfilesFromRepo(
            owner: "rtrouton",
            repo: "profiles",
            source: .rtroutonProfiles,
            token: token,
            licenseName: "MIT",
            licenseURL: "https://github.com/rtrouton/profiles/blob/main/LICENSE"
        )
    }

    // MARK: - rodchristiansen/mobileconfig-profiles

    private func fetchRodChristiansenProfiles(token: String?) async -> SourceResult? {
        await fetchProfilesFromRepo(
            owner: "rodchristiansen",
            repo: "mobileconfig-profiles",
            source: .rodChristiansenProfiles,
            token: token,
            licenseName: nil,
            licenseURL: nil
        )
    }

    // MARK: - Mac-Nerd/Mac-profiles

    private func fetchMacNerdProfiles(token: String?) async -> SourceResult? {
        await fetchProfilesFromRepo(
            owner: "Mac-Nerd",
            repo: "Mac-profiles",
            source: .macNerdProfiles,
            token: token,
            licenseName: nil,
            licenseURL: nil
        )
    }

    private func fetchProfileManifestsFromLocalCheckout(
        source: MDMSource,
        licenseName: String?,
        licenseURL: String?
    ) -> SourceResult? {
        guard let root = localProfileManifestsRoot() else { return nil }
        let manifestsRoot = preferredProfileManifestFolder(in: root)
        guard let manifestsRoot else { return nil }

        let files = localFilesRecursive(root: manifestsRoot, allowedExtensions: ["plist"])
        guard !files.isEmpty else { return nil }

        var payloadsByType: [String: MDMPayloadRecord] = [:]
        var keysByID: [String: MDMKeyRecord] = [:]

        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let category = profileManifestCategory(fileURL: fileURL, manifestsRoot: manifestsRoot)
            let extracted = ProfileManifestCatalogExtractor.extract(
                from: data,
                source: source,
                category: category
            )
            mergeCatalogExtracted(
                extracted,
                payloads: &payloadsByType,
                keys: &keysByID
            )
        }

        guard !payloadsByType.isEmpty || !keysByID.isEmpty else { return nil }

        return SourceResult(
            source: source,
            payloads: Array(payloadsByType.values),
            keys: Array(keysByID.values),
            revision: "local-checkout",
            licenseName: licenseName,
            licenseURL: licenseURL
        )
    }

    private func fetchProfileManifestsFromMirror(
        owner: String,
        repo: String,
        source: MDMSource,
        licenseName: String?,
        licenseURL: String?
    ) async throws -> SourceResult? {
        let sync = try await GitMirrorService.shared.syncDaily(owner: owner, repo: repo)
        guard let manifestsRoot = preferredProfileManifestFolder(in: sync.localURL) else { return nil }

        let files = localFilesRecursive(root: manifestsRoot, allowedExtensions: ["plist"])
        guard !files.isEmpty else { return nil }

        var payloadsByType: [String: MDMPayloadRecord] = [:]
        var keysByID: [String: MDMKeyRecord] = [:]

        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let category = profileManifestCategory(fileURL: fileURL, manifestsRoot: manifestsRoot)
            let extracted = ProfileManifestCatalogExtractor.extract(
                from: data,
                source: source,
                category: category
            )
            mergeCatalogExtracted(
                extracted,
                payloads: &payloadsByType,
                keys: &keysByID
            )
        }

        guard !payloadsByType.isEmpty || !keysByID.isEmpty else { return nil }

        return SourceResult(
            source: source,
            payloads: Array(payloadsByType.values),
            keys: Array(keysByID.values),
            revision: sync.currentRevision,
            licenseName: licenseName,
            licenseURL: licenseURL
        )
    }

    private func localProfileManifestsRoot() -> URL? {
        let fm = FileManager.default

        if let envOverride = ProcessInfo.processInfo.environment["DIFFER_PROFILE_MANIFESTS_PATH"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !envOverride.isEmpty {
            let url = URL(fileURLWithPath: envOverride, isDirectory: true)
            if fm.fileExists(atPath: url.path) {
                return url
            }
        }

        let candidates: [URL] = [
            Bundle.main.resourceURL?.appendingPathComponent("ProfileManifests-master", isDirectory: true)
        ].compactMap { $0 }

        for candidate in candidates where fm.fileExists(atPath: candidate.path) {
            return candidate
        }

        return nil
    }

    private func preferredProfileManifestFolder(in root: URL) -> URL? {
        let fm = FileManager.default
        let candidates = [
            root.appendingPathComponent("Manifests", isDirectory: true),
            root.appendingPathComponent("manifests", isDirectory: true)
        ]
        for candidate in candidates where fm.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }

    private func profileManifestCategory(fileURL: URL, manifestsRoot: URL) -> String? {
        let relative = fileURL.path.replacingOccurrences(of: manifestsRoot.path + "/", with: "")
        let components = relative.split(separator: "/").map(String.init)
        guard components.count > 1 else { return nil }
        return components[0]
    }

    private func profileManifestCategory(fromRelativePath relativePath: String, rootFolderName: String) -> String? {
        let prefix = "\(rootFolderName)/"
        guard relativePath.hasPrefix(prefix) else { return nil }
        let relative = String(relativePath.dropFirst(prefix.count))
        let components = relative.split(separator: "/").map(String.init)
        guard components.count > 1 else { return nil }
        return components[0]
    }

    private func mergeCatalogExtracted(
        _ extracted: (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord]),
        payloads: inout [String: MDMPayloadRecord],
        keys: inout [String: MDMKeyRecord]
    ) {
        for payload in extracted.payloads {
            if var existing = payloads[payload.payloadType] {
                let mergedSources = Array(Set(existing.sources + payload.sources)).sorted { $0.rawValue < $1.rawValue }
                let mergedPlatforms = Array(Set(existing.platforms + payload.platforms)).sorted()
                existing = MDMPayloadRecord(
                    id: existing.id,
                    name: existing.name.isEmpty ? payload.name : existing.name,
                    payloadType: existing.payloadType,
                    category: existing.category ?? payload.category,
                    platforms: mergedPlatforms,
                    introduced: existing.introduced ?? payload.introduced,
                    deprecated: existing.deprecated ?? payload.deprecated,
                    sources: mergedSources,
                    summary: existing.summary ?? payload.summary,
                    discussion: existing.discussion ?? payload.discussion,
                    profileExample: existing.profileExample ?? payload.profileExample,
                    profileExampleSyntax: existing.profileExampleSyntax ?? payload.profileExampleSyntax
                )
                payloads[payload.payloadType] = existing
            } else {
                payloads[payload.payloadType] = payload
            }
        }

        for key in extracted.keys {
            if var existing = keys[key.id] {
                let mergedSources = Array(Set(existing.sources + key.sources)).sorted { $0.rawValue < $1.rawValue }
                let mergedPlatforms = Array(Set(existing.platforms + key.platforms)).sorted()
                existing = MDMKeyRecord(
                    id: existing.id,
                    key: existing.key,
                    keyPath: existing.keyPath,
                    payloadType: existing.payloadType,
                    payloadName: existing.payloadName ?? key.payloadName,
                    platforms: mergedPlatforms,
                    sources: mergedSources,
                    introduced: existing.introduced ?? key.introduced,
                    deprecated: existing.deprecated ?? key.deprecated,
                    publicationDate: existing.publicationDate ?? key.publicationDate,
                    keyType: existing.keyType ?? key.keyType,
                    keyDescription: existing.keyDescription ?? key.keyDescription,
                    required: existing.required ?? key.required,
                    defaultValue: existing.defaultValue ?? key.defaultValue,
                    possibleValues: existing.possibleValues ?? key.possibleValues
                )
                keys[key.id] = existing
            } else {
                keys[key.id] = key
            }
        }
    }

    // MARK: - Shared profile repo ingestion

    private func fetchProfilesFromRepo(
        owner: String,
        repo: String,
        source: MDMSource,
        token: String?,
        licenseName: String?,
        licenseURL: String?
    ) async -> SourceResult? {
        do {
            // Try offline bundle first (embedded or downloaded)
            if let bundled = try await fetchProfilesFromBundle(
                source: source,
                licenseName: licenseName,
                licenseURL: licenseURL
            ) {
                return bundled
            }
            
            if let mirrored = try await fetchProfilesFromMirror(
                owner: owner,
                repo: repo,
                source: source,
                licenseName: licenseName,
                licenseURL: licenseURL
            ) {
                return mirrored
            }

            let repoInfo = try? await GitHubService.shared.fetchRepo(owner: owner, repo: repo, token: token)
            let files = try await listProfileFilesRecursive(owner: owner, repo: repo, token: token)

            var payloads: [MDMPayloadRecord] = []
            var keys: [MDMKeyRecord] = []

            for file in files {
                guard let downloadURL = file.downloadURL else { continue }
                let data = try await GitHubService.shared.fetchData(url: downloadURL, token: token)
                let extracted = ProfilePayloadExtractor.extract(from: data, source: source)
                payloads.append(contentsOf: extracted.payloads)
                keys.append(contentsOf: extracted.keys)
            }

            return SourceResult(
                source: source,
                payloads: payloads,
                keys: keys,
                revision: repoInfo?.updatedAt,
                licenseName: licenseName,
                licenseURL: licenseURL
            )
        } catch {
            return nil
        }
    }

    private func fetchProfilesFromMirror(
        owner: String,
        repo: String,
        source: MDMSource,
        licenseName: String?,
        licenseURL: String?
    ) async throws -> SourceResult? {
        let sync = try await GitMirrorService.shared.syncDaily(owner: owner, repo: repo)
        let files = localFilesRecursive(
            root: sync.localURL,
            allowedExtensions: ["mobileconfig", "plist", "xml", "json"]
        )

        guard !files.isEmpty else { return nil }

        var payloads: [MDMPayloadRecord] = []
        var keys: [MDMKeyRecord] = []

        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let extracted = ProfilePayloadExtractor.extract(from: data, source: source)
            payloads.append(contentsOf: extracted.payloads)
            keys.append(contentsOf: extracted.keys)
        }

        return SourceResult(
            source: source,
            payloads: payloads,
            keys: keys,
            revision: sync.currentRevision,
            licenseName: licenseName,
            licenseURL: licenseURL
        )
    }

    private func listProfileFilesRecursive(owner: String, repo: String, token: String?) async throws -> [GitHubFile] {
        var results: [GitHubFile] = []
        var queue: [String] = [""]

        while let path = queue.first {
            queue.removeFirst()
            let files = try await GitHubService.shared.listFiles(owner: owner, repo: repo, path: path, token: token)
            for file in files {
                if file.isDirectory {
                    queue.append(file.path)
                    continue
                }
                if isProfileFile(file.name) {
                    results.append(file)
                }
            }
        }

        return results
    }

    private func isProfileFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mobileconfig", "plist", "xml", "json"].contains(ext)
    }

    private func localFilesRecursive(root: URL, allowedExtensions: Set<String>) -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.path) else { return [] }
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { continue }

            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                files.append(fileURL)
            }
        }

        return files.sorted { $0.path < $1.path }
    }

    private func readText(from fileURL: URL) -> String? {
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else { return nil }
        if let content = String(data: data, encoding: .utf8) { return content }
        if let content = String(data: data, encoding: .ascii) { return content }
        return String(decoding: data, as: UTF8.self)
    }
    
    // MARK: - Offline Bundle Support
    
    /// Fetches profiles from an offline bundle (embedded or downloaded)
    private func fetchProfilesFromBundle(
        source: MDMSource,
        licenseName: String?,
        licenseURL: String?
    ) async throws -> SourceResult? {
        let bundleService = RepositoryBundleService.shared
        
        guard let bundlePath = try await bundleService.getBundlePath(for: source) else {
            return nil
        }
        
        // List all .mobileconfig files in the bundle
        let files = await bundleService.listFiles(
            in: bundlePath,
            withExtensions: ["mobileconfig", "xml", "plist"]
        )
        
        guard !files.isEmpty else { return nil }
        
        var payloads: [MDMPayloadRecord] = []
        var keys: [MDMKeyRecord] = []
        
        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let extracted = ProfilePayloadExtractor.extract(from: data, source: source)
            payloads.append(contentsOf: extracted.payloads)
            keys.append(contentsOf: extracted.keys)
        }
        
        // Get modification date as revision
        let attributes = try? FileManager.default.attributesOfItem(atPath: bundlePath.path)
        let modDate = attributes?[.modificationDate] as? Date ?? Date()
        let revision = ISO8601DateFormatter().string(from: modDate)
        
        return SourceResult(
            source: source,
            payloads: payloads,
            keys: keys,
            revision: revision,
            licenseName: licenseName,
            licenseURL: licenseURL
        )
    }
    
    /// Fetches ProfileManifests from an offline bundle (embedded or downloaded)
    private func fetchProfileManifestsFromBundle(
        source: MDMSource,
        licenseName: String?,
        licenseURL: String?
    ) async throws -> SourceResult? {
        let bundleService = RepositoryBundleService.shared
        
        guard let bundlePath = try await bundleService.getBundlePath(for: source) else {
            return nil
        }
        
        // List all .plist files in the Manifests directory
        let files = await bundleService.listFiles(
            in: bundlePath,
            withExtensions: ["plist"],
            subdirectory: "Manifests"
        )
        
        guard !files.isEmpty else { return nil }
        
        var payloadsByType: [String: MDMPayloadRecord] = [:]
        var keysByID: [String: MDMKeyRecord] = [:]
        
        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            
            // Determine category from file path
            let category = profileManifestCategory(fileURL: fileURL, manifestsRoot: bundlePath)
            
            let extracted = ProfileManifestCatalogExtractor.extract(
                from: data,
                source: source,
                category: category
            )
            mergeCatalogExtracted(
                extracted,
                payloads: &payloadsByType,
                keys: &keysByID
            )
        }
        
        guard !payloadsByType.isEmpty || !keysByID.isEmpty else { return nil }
        
        // Get modification date as revision
        let attributes = try? FileManager.default.attributesOfItem(atPath: bundlePath.path)
        let modDate = attributes?[.modificationDate] as? Date ?? Date()
        let revision = ISO8601DateFormatter().string(from: modDate)
        
        return SourceResult(
            source: source,
            payloads: Array(payloadsByType.values),
            keys: Array(keysByID.values),
            revision: revision,
            licenseName: licenseName,
            licenseURL: licenseURL
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Apple YAML Parser (best-effort)

private enum AppleMDMYamlParser {
    static func parse(content: String, source: MDMSource) -> (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord]) {
        if let structured = parseStructured(content: content, source: source) {
            return structured
        }

        let payloadType = extractPayloadType(from: content) ?? "com.apple.unknown"
        let payloadName = cleanPayloadName(extractPayloadName(from: content)) ?? payloadType
        let payload = MDMPayloadRecord(
            id: payloadType,
            name: payloadName,
            payloadType: payloadType,
            category: nil,
            platforms: extractPlatforms(from: content),
            introduced: nil,
            deprecated: nil,
            sources: [source]
        )

        let keyNames = extractKeys(from: content)
        let keys = keyNames.map { key in
            let keyPath = key
            return MDMKeyRecord(
                id: MDMKeyRecord.signature(payloadType: payloadType, keyPath: keyPath),
                key: key,
                keyPath: keyPath,
                payloadType: payloadType,
                payloadName: payloadName,
                platforms: payload.platforms,
                sources: [source],
                introduced: nil,
                deprecated: nil,
                publicationDate: nil,
                keyType: nil,
                keyDescription: nil,
                required: nil,
                defaultValue: nil,
                possibleValues: nil
            )
        }

        return ([payload], keys)
    }

    private static func parseStructured(content: String, source: MDMSource) -> (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord])? {
        #if canImport(Yams)
        guard let yaml = try? Yams.load(yaml: content) else { return nil }
        guard let root = yaml as? [String: Any] else { return nil }

        let payloadType = findString(in: root, keys: ["payloadType", "PayloadType"]) ?? "com.apple.unknown"
        let payloadName = cleanPayloadName(findString(in: root, keys: ["title", "name", "payloadName"])) ?? payloadType
        let platforms = findPlatforms(in: root)

        let payload = MDMPayloadRecord(
            id: payloadType,
            name: payloadName,
            payloadType: payloadType,
            category: nil,
            platforms: platforms,
            introduced: nil,
            deprecated: nil,
            sources: [source]
        )

        let keyEntries = findKeyEntries(in: root)
        let keys = keyEntries.map { entry in
            let keyPath = entry.key
            return MDMKeyRecord(
                id: MDMKeyRecord.signature(payloadType: payloadType, keyPath: keyPath),
                key: entry.key,
                keyPath: keyPath,
                payloadType: payloadType,
                payloadName: payloadName,
                platforms: platforms,
                sources: [source],
                introduced: entry.introduced,
                deprecated: entry.deprecated,
                publicationDate: entry.publicationDate,
                keyType: entry.keyType,
                keyDescription: entry.description,
                required: entry.required,
                defaultValue: entry.defaultValue,
                possibleValues: entry.possibleValues
            )
        }

        return ([payload], keys)
        #else
        return nil
        #endif
    }

    private static func extractPayloadType(from content: String) -> String? {
        let patterns = [
            "(?im)^\\s*payloadtype:\\s*([^\\n\\r]+)",
            "\\\"payloadtype\\\"\\s*:\\s*\\\"([^\\\"]+)\\\""
        ]
        return firstMatch(in: content, patterns: patterns)
    }

    #if canImport(Yams)
    private struct YAMLKeyEntry {
        let key: String
        let keyType: String?
        let description: String?
        let required: Bool?
        let defaultValue: String?
        let possibleValues: [String]?
        let introduced: String?
        let deprecated: String?
        let publicationDate: String?
    }

    private static func findString(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String { return value }
        }
        for value in dict.values {
            if let nested = value as? [String: Any], let found = findString(in: nested, keys: keys) {
                return found
            }
            if let array = value as? [Any] {
                for item in array {
                    if let nested = item as? [String: Any], let found = findString(in: nested, keys: keys) {
                        return found
                    }
                }
            }
        }
        return nil
    }

    private static func findKeyEntries(in dict: [String: Any]) -> [YAMLKeyEntry] {
        var results: [YAMLKeyEntry] = []

        if let keys = dict["payloadKeys"] as? [[String: Any]] {
            for key in keys {
                guard let name = key["key"] as? String else { continue }
                let required = parseRequired(from: key)
                let description = (key["description"] as? String) ?? (key["title"] as? String)
                let possibleValues = parsePossibleValues(from: key)
                let entry = YAMLKeyEntry(
                    key: name,
                    keyType: key["type"] as? String,
                    description: description,
                    required: required,
                    defaultValue: stringify(key["default"]),
                    possibleValues: possibleValues,
                    introduced: stringify(key["introduced"]),
                    deprecated: stringify(key["deprecated"]),
                    publicationDate: stringify(key["published"]) ?? stringify(key["publicationDate"]) ?? stringify(key["lastModified"])
                )
                results.append(entry)
            }
        }

        for value in dict.values {
            if let nested = value as? [String: Any] {
                results.append(contentsOf: findKeyEntries(in: nested))
            } else if let array = value as? [Any] {
                for item in array {
                    if let nested = item as? [String: Any] {
                        results.append(contentsOf: findKeyEntries(in: nested))
                    }
                }
            }
        }

        let unique = Dictionary(grouping: results, by: { $0.key }).compactMap { $0.value.first }
        return unique.sorted { $0.key < $1.key }
    }

    private static func parsePossibleValues(from dict: [String: Any]) -> [String]? {
        if let values = dict["allowedValues"] as? [Any] {
            return values.compactMap { stringify($0) }
        }
        if let values = dict["possibleValues"] as? [Any] {
            return values.compactMap { stringify($0) }
        }
        if let values = dict["rangeList"] as? [Any] {
            return values.compactMap { stringify($0) }
        }
        return nil
    }

    private static func parseRequired(from dict: [String: Any]) -> Bool? {
        if let required = dict["required"] as? Bool { return required }
        if let presence = dict["presence"] as? String {
            return presence.lowercased() == "required"
        }
        return nil
    }

    private static func stringify(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let str = value as? String { return str }
        return "\(value)"
    }

    private static func findPlatforms(in dict: [String: Any]) -> [String] {
        var platforms: [String] = []
        if let os = dict["supportedOS"] as? [String] {
            platforms = os
        } else if let os = dict["supportedOS"] as? [String: Any] {
            platforms = os.keys.map { $0 }
        } else if let os = dict["supportedPlatforms"] as? [String] {
            platforms = os
        }

        if platforms.isEmpty {
            let flattened = dict.values.map { "\($0)" }.joined(separator: " ")
            if flattened.localizedCaseInsensitiveContains("iOS") { platforms.append("iOS") }
            if flattened.localizedCaseInsensitiveContains("iPadOS") { platforms.append("iPadOS") }
            if flattened.localizedCaseInsensitiveContains("macOS") { platforms.append("macOS") }
            if flattened.localizedCaseInsensitiveContains("tvOS") { platforms.append("tvOS") }
            if flattened.localizedCaseInsensitiveContains("watchOS") { platforms.append("watchOS") }
            if flattened.localizedCaseInsensitiveContains("visionOS") { platforms.append("visionOS") }
        }

        return platforms.isEmpty ? ["iOS"] : Array(Set(platforms)).sorted()
    }
    #endif

    private static func extractPayloadName(from content: String) -> String? {
        let patterns = [
            "(?im)^\\s*title:\\s*([^\\n\\r]+)",
            "(?im)^\\s*name:\\s*([^\\n\\r]+)",
            "\\\"name\\\"\\s*:\\s*\\\"([^\\\"]+)\\\""
        ]
        return firstMatch(in: content, patterns: patterns)
    }

    private static func extractPlatforms(from content: String) -> [String] {
        var platforms: [String] = []
        if content.localizedCaseInsensitiveContains("iOS") { platforms.append("iOS") }
        if content.localizedCaseInsensitiveContains("iPadOS") { platforms.append("iPadOS") }
        if content.localizedCaseInsensitiveContains("macOS") { platforms.append("macOS") }
        if content.localizedCaseInsensitiveContains("tvOS") { platforms.append("tvOS") }
        if content.localizedCaseInsensitiveContains("watchOS") { platforms.append("watchOS") }
        if content.localizedCaseInsensitiveContains("visionOS") { platforms.append("visionOS") }
        return platforms.isEmpty ? ["iOS"] : platforms
    }

    private static func extractKeys(from content: String) -> [String] {
        var results: [String] = []
        let pattern = "(?im)^\\s*-\\s*key:\\s*([A-Za-z0-9_.-]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        regex?.enumerateMatches(in: content, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1,
                  let keyRange = Range(match.range(at: 1), in: content) else { return }
            let key = String(content[keyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty { results.append(key) }
        }
        return Array(Set(results)).sorted()
    }

    private static func firstMatch(in content: String, patterns: [String]) -> String? {
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            if let match = regex?.firstMatch(in: content, options: [], range: range),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: content) {
                return String(content[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    private static func cleanPayloadName(_ name: String?) -> String? {
        guard var cleaned = name else { return nil }
        
        // Remove surrounding single quotes
        if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        // Remove surrounding double quotes
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}

// MARK: - Profile payload extraction

private enum ProfilePayloadExtractor {
    private static let skipKeys: Set<String> = [
        "PayloadType",
        "PayloadUUID",
        "PayloadIdentifier",
        "PayloadVersion",
        "PayloadDisplayName",
        "PayloadDescription",
        "PayloadOrganization",
        "PayloadScope",
        "PayloadRemovalDisallowed",
        "PayloadEnabled",
        "PayloadExpirationDate",
        "PayloadContent",
        "PayloadEnabled",
        "PayloadRemovalDisallowed"
    ]

    static func extract(from data: Data, source: MDMSource) -> (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord]) {
        let plistData: Data
        if let stripped = try? SignatureStripper.strip(data: data).0 {
            plistData = stripped
        } else {
            plistData = data
        }

        var format: PropertyListSerialization.PropertyListFormat = .xml
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: &format),
              let root = plist as? [String: Any] else {
            return ([], [])
        }

        let payloadContent = root["PayloadContent"] as? [[String: Any]] ?? []
        var payloads: [MDMPayloadRecord] = []
        var keys: [MDMKeyRecord] = []

        for payload in payloadContent {
            guard let payloadType = payload["PayloadType"] as? String else { continue }
            let payloadName = cleanPayloadName(payload["PayloadDisplayName"] as? String) ?? payloadType
            let payloadRecord = MDMPayloadRecord(
                id: payloadType,
                name: payloadName,
                payloadType: payloadType,
                category: nil,
                platforms: [],
                introduced: nil,
                deprecated: nil,
                sources: [source]
            )
            payloads.append(payloadRecord)

            let flattened = flatten(payload, prefix: "", results: [])
            for keyPath in flattened where !skipKeys.contains(keyPath.key) {
                let signature = MDMKeyRecord.signature(payloadType: payloadType, keyPath: keyPath.path)
                let record = MDMKeyRecord(
                    id: signature,
                    key: keyPath.key,
                    keyPath: keyPath.path,
                    payloadType: payloadType,
                    payloadName: payloadName,
                    platforms: [],
                    sources: [source],
                    introduced: nil,
                    deprecated: nil,
                    publicationDate: nil,
                    keyType: nil,
                    keyDescription: nil,
                    required: nil,
                    defaultValue: nil,
                    possibleValues: nil
                )
                keys.append(record)
            }
        }

        return (payloads, keys)
    }

    private struct KeyPathEntry {
        let key: String
        let path: String
    }

    private static func flatten(_ value: Any, prefix: String, results: [KeyPathEntry]) -> [KeyPathEntry] {
        var results = results

        if let dict = value as? [String: Any] {
            for (key, value) in dict {
                let path = prefix.isEmpty ? key : "\(prefix).\(key)"
                results.append(KeyPathEntry(key: key, path: path))
                results = flatten(value, prefix: path, results: results)
            }
        } else if let array = value as? [Any] {
            for item in array {
                let path = prefix.isEmpty ? "[]" : "\(prefix).[]"
                results = flatten(item, prefix: path, results: results)
            }
        }

        return results
    }
    
    private static func cleanPayloadName(_ name: String?) -> String? {
        guard var cleaned = name else { return nil }
        
        // Remove surrounding single quotes
        if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        // Remove surrounding double quotes
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}

// MARK: - ProfileManifests catalog extraction

private enum ProfileManifestCatalogExtractor {
    private static let minVersionKeys = [
        "pfm_macos_min",
        "pfm_ios_min",
        "pfm_ipados_min",
        "pfm_tvos_min",
        "pfm_watchos_min",
        "pfm_visionos_min"
    ]

    private static let deprecatedVersionKeys = [
        "pfm_macos_deprecated",
        "pfm_ios_deprecated",
        "pfm_ipados_deprecated",
        "pfm_tvos_deprecated",
        "pfm_watchos_deprecated",
        "pfm_visionos_deprecated"
    ]

    static func extract(
        from data: Data,
        source: MDMSource,
        category: String?
    ) -> (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord]) {
        var format: PropertyListSerialization.PropertyListFormat = .xml
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: &format),
              let root = plist as? [String: Any] else {
            return ([], [])
        }

        guard let payloadType = string(in: root, keys: ["pfm_domain", "PFMDomain", "payloadType", "PayloadType"]) else {
            return ([], [])
        }

        let payloadName = cleanPayloadName(string(in: root, keys: ["pfm_title", "PFMTitle", "pfm_name", "PFMName"]))
            ?? payloadType
        let payloadPlatforms = platforms(from: root)
        let introduced = firstVersion(in: root, keys: minVersionKeys)
        let deprecated = firstVersion(in: root, keys: deprecatedVersionKeys)
        let publicationDate = stringValue(root["pfm_last_modified"])
        let summary = string(in: root, keys: ["pfm_description", "PFMDescription"])
        let discussion = string(in: root, keys: ["pfm_description_reference", "PFMDescriptionReference"])

        let payload = MDMPayloadRecord(
            id: payloadType,
            name: payloadName,
            payloadType: payloadType,
            category: category ?? string(in: root, keys: ["pfm_subcategory", "PFMSubcategory"]),
            platforms: payloadPlatforms,
            introduced: introduced,
            deprecated: deprecated,
            sources: [source],
            summary: summary,
            discussion: discussion,
            profileExample: nil,
            profileExampleSyntax: nil
        )

        var keysByID: [String: MDMKeyRecord] = [:]
        let subkeys = dictionaryArray(in: root, keys: ["pfm_subkeys", "PFMSubkeys"])
        collectSubkeys(
            from: subkeys,
            payloadType: payloadType,
            payloadName: payloadName,
            source: source,
            payloadPlatforms: payloadPlatforms,
            inheritedIntroduced: introduced,
            inheritedDeprecated: deprecated,
            publicationDate: publicationDate,
            prefix: "",
            keysByID: &keysByID
        )

        return ([payload], Array(keysByID.values))
    }

    private static func collectSubkeys(
        from subkeys: [[String: Any]],
        payloadType: String,
        payloadName: String,
        source: MDMSource,
        payloadPlatforms: [String],
        inheritedIntroduced: String?,
        inheritedDeprecated: String?,
        publicationDate: String?,
        prefix: String,
        keysByID: inout [String: MDMKeyRecord]
    ) {
        for item in subkeys {
            guard let name = string(in: item, keys: ["pfm_name", "PFMName"]), !name.isEmpty else { continue }
            let keyPath = prefix.isEmpty ? name : "\(prefix).\(name)"
            let keyType = string(in: item, keys: ["pfm_type", "PFMType"])
            let keyDescription = string(in: item, keys: ["pfm_description", "PFMDescription"])
            let required = requiredValue(in: item)
            let defaultValue = stringValue(item["pfm_default"] ?? item["PFMDefault"])
            let possibleValues = possibleValues(in: item)
            let keyPlatforms = platforms(from: item).isEmpty ? payloadPlatforms : platforms(from: item)
            let introduced = firstVersion(in: item, keys: minVersionKeys) ?? inheritedIntroduced
            let deprecated = firstVersion(in: item, keys: deprecatedVersionKeys) ?? inheritedDeprecated

            let record = MDMKeyRecord(
                id: MDMKeyRecord.signature(payloadType: payloadType, keyPath: keyPath),
                key: name,
                keyPath: keyPath,
                payloadType: payloadType,
                payloadName: payloadName,
                platforms: keyPlatforms,
                sources: [source],
                introduced: introduced,
                deprecated: deprecated,
                publicationDate: publicationDate,
                keyType: keyType,
                keyDescription: keyDescription,
                required: required,
                defaultValue: defaultValue,
                possibleValues: possibleValues
            )
            keysByID[record.id] = record

            let nested = dictionaryArray(in: item, keys: ["pfm_subkeys", "PFMSubkeys"])
            guard !nested.isEmpty else { continue }

            let nestedPrefix: String
            if isArrayType(keyType) {
                nestedPrefix = "\(keyPath).[]"
            } else {
                nestedPrefix = keyPath
            }

            collectSubkeys(
                from: nested,
                payloadType: payloadType,
                payloadName: payloadName,
                source: source,
                payloadPlatforms: keyPlatforms,
                inheritedIntroduced: introduced,
                inheritedDeprecated: deprecated,
                publicationDate: publicationDate,
                prefix: nestedPrefix,
                keysByID: &keysByID
            )
        }
    }

    private static func isArrayType(_ type: String?) -> Bool {
        guard let lowered = type?.lowercased() else { return false }
        return lowered.contains("array") || lowered == "["
    }

    private static func requiredValue(in dict: [String: Any]) -> Bool? {
        if let required = dict["pfm_required"] as? Bool {
            return required
        }

        if let requireValue = dict["pfm_require"] ?? dict["PFMRequire"] {
            if let boolValue = requireValue as? Bool {
                return boolValue
            }
            if let text = stringValue(requireValue)?.lowercased() {
                if ["always", "required", "true", "yes"].contains(text) { return true }
                if ["never", "optional", "false", "no"].contains(text) { return false }
            }
        }

        return nil
    }

    private static func possibleValues(in dict: [String: Any]) -> [String]? {
        let candidates: [Any?] = [
            dict["pfm_range_list"],
            dict["PFMRangeList"],
            dict["pfm_values"],
            dict["PFMValues"]
        ]

        for candidate in candidates {
            guard let array = candidate as? [Any] else { continue }
            let values = array.compactMap { value -> String? in
                if let dictValue = value as? [String: Any] {
                    return string(in: dictValue, keys: ["pfm_value", "value", "name"])
                }
                return stringValue(value)
            }
            if !values.isEmpty {
                return values
            }
        }

        return nil
    }

    private static func platforms(from dict: [String: Any]) -> [String] {
        let candidates: [Any?] = [dict["pfm_platforms"], dict["PFMPlatforms"]]
        for candidate in candidates {
            if let array = candidate as? [String], !array.isEmpty {
                return Array(Set(array)).sorted()
            }
            if let array = candidate as? [Any] {
                let values = array.compactMap { stringValue($0) }
                if !values.isEmpty {
                    return Array(Set(values)).sorted()
                }
            }
        }
        return []
    }

    private static func firstVersion(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = string(in: dict, keys: [key]) {
                return value
            }
        }
        return nil
    }

    private static func dictionaryArray(in dict: [String: Any], keys: [String]) -> [[String: Any]] {
        for key in keys {
            if let array = dict[key] as? [[String: Any]] {
                return array
            }
            if let array = dict[key] as? [Any] {
                let mapped = array.compactMap { $0 as? [String: Any] }
                if !mapped.isEmpty {
                    return mapped
                }
            }
        }
        return []
    }

    private static func string(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = stringValue(dict[key]) {
                return value
            }
        }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let value else { return nil }

        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let date = value as? Date {
            return ISO8601DateFormatter().string(from: date)
        }

        return "\(value)".trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
    
    private static func cleanPayloadName(_ name: String?) -> String? {
        guard var cleaned = name else { return nil }
        
        // Remove surrounding single quotes
        if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        // Remove surrounding double quotes
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}
