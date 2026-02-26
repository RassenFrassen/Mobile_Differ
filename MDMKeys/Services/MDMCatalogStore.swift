import Foundation

/// Persistent storage manager for MDM catalog snapshots.
/// Handles loading, saving, and diffing catalog versions.
/// Maintains both latest and previous snapshots to track key changes over time.
actor MDMCatalogStore {
    static let shared = MDMCatalogStore()

    private let schemaVersion = 1
    private let latestFilename = "mdm_catalog_latest.json"
    private let previousFilename = "mdm_catalog_previous.json"

    func loadBundledSnapshot() async -> MDMSnapshot? {
        logInfo("loadBundledSnapshot: Looking for mdm_catalog_seed.json in bundle")
        
        guard let url = Bundle.main.url(forResource: "mdm_catalog_seed", withExtension: "json") else {
            logError("loadBundledSnapshot: mdm_catalog_seed.json not found in bundle")
            logError("Bundle path: \(Bundle.main.bundlePath)")
            
            // List all JSON files in the bundle
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                    logInfo("JSON files in bundle: \(jsonFiles)")
                } catch {
                    logError("Could not list bundle contents: \(error)")
                }
            }
            
            return nil
        }
        
        logInfo("loadBundledSnapshot: Found seed file at \(url.path)")
        guard let snapshot = await loadSnapshot(from: url) else {
            logError("loadBundledSnapshot: Failed to decode snapshot from \(url.path)")
            return nil
        }
        
        // Migration: Check if bundled seed contains old docs.devicemanagement.* payload types
        if await needsMigration(snapshot) {
            logWarning("loadBundledSnapshot: Bundled seed has old format with docs.* payloads")
            logWarning("loadBundledSnapshot: App will need to fetch fresh data from sources")
            // Return nil so the app knows to fetch fresh data
            return nil
        }
        
        logInfo("loadBundledSnapshot: Successfully loaded snapshot with \(snapshot.keys.count) keys")
        return snapshot
    }

    func loadLatestSnapshot() async -> MDMSnapshot? {
        guard let url = latestURL() else { return nil }
        guard let snapshot = await loadSnapshot(from: url) else { return nil }
        
        // Migration: Check if snapshot contains old docs.devicemanagement.* payload types
        if await needsMigration(snapshot) {
            logInfo("Detected old docs.devicemanagement.* payload types - clearing cache for migration")
            await clearCache()
            return nil
        }
        
        return snapshot
    }

    func loadPreviousSnapshot() async -> MDMSnapshot? {
        guard let url = previousURL() else { return nil }
        return await loadSnapshot(from: url)
    }

    func saveLatestSnapshot(_ snapshot: MDMSnapshot) async {
        guard let url = latestURL() else { return }
        await saveSnapshot(snapshot, to: url)
    }

    func promoteLatestToPrevious() async {
        guard let latest = latestURL(), let previous = previousURL() else { return }
        let fm = FileManager.default
        if fm.fileExists(atPath: previous.path) {
            try? fm.removeItem(at: previous)
        }
        if fm.fileExists(atPath: latest.path) {
            try? fm.copyItem(at: latest, to: previous)
        }
    }
    
    func clearCache() async {
        let fm = FileManager.default
        
        // Remove latest snapshot
        if let latest = latestURL(), fm.fileExists(atPath: latest.path) {
            try? fm.removeItem(at: latest)
            logInfo("clearCache: Removed latest snapshot")
        }
        
        // Remove previous snapshot
        if let previous = previousURL(), fm.fileExists(atPath: previous.path) {
            try? fm.removeItem(at: previous)
            logInfo("clearCache: Removed previous snapshot")
        }
        
        logInfo("clearCache: Cache cleared successfully")
    }

    func diffNewKeys(latest: MDMSnapshot, previous: MDMSnapshot?) -> [MDMKeyRecord] {
        diffKeyChanges(latest: latest, previous: previous).added
    }

    func diffKeyChanges(latest: MDMSnapshot, previous: MDMSnapshot?) -> MDMCatalogKeyChanges {
        guard let previous else {
            return MDMCatalogKeyChanges(
                added: latest.keys,
                updated: [],
                removed: []
            )
        }

        let latestByID = Dictionary(uniqueKeysWithValues: latest.keys.map { ($0.id, $0) })
        let previousByID = Dictionary(uniqueKeysWithValues: previous.keys.map { ($0.id, $0) })

        let added = latestByID
            .filter { previousByID[$0.key] == nil }
            .map(\.value)
            .sorted { $0.keyPath < $1.keyPath }

        let removed = previousByID
            .filter { latestByID[$0.key] == nil }
            .map(\.value)
            .sorted { $0.keyPath < $1.keyPath }

        var updated: [MDMKeyUpdatedChange] = []
        for (id, latestKey) in latestByID {
            guard let previousKey = previousByID[id] else { continue }
            let deltas = keyDeltas(old: previousKey, new: latestKey)
            if !deltas.isEmpty {
                updated.append(
                    MDMKeyUpdatedChange(
                        before: previousKey,
                        after: latestKey,
                        deltas: deltas
                    )
                )
            }
        }
        updated.sort { $0.after.keyPath < $1.after.keyPath }

        return MDMCatalogKeyChanges(
            added: added,
            updated: updated,
            removed: removed
        )
    }

    func buildSnapshot(
        payloads: [MDMPayloadRecord],
        keys: [MDMKeyRecord],
        sources: [MDMSourceSnapshot]
    ) -> MDMSnapshot {
        MDMSnapshot(
            schemaVersion: schemaVersion,
            generatedAt: Date(),
            sources: sources,
            payloads: payloads,
            keys: keys
        )
    }

    // MARK: - Private

    private func loadSnapshot(from url: URL) async -> MDMSnapshot? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(MDMSnapshot.self, from: data)
            return cleanSnapshot(snapshot)
        } catch {
            return nil
        }
    }
    
    private func cleanSnapshot(_ snapshot: MDMSnapshot) -> MDMSnapshot {
        let cleanedPayloads = snapshot.payloads.map { payload in
            MDMPayloadRecord(
                id: payload.id,
                name: cleanQuotedString(payload.name) ?? payload.payloadType,
                payloadType: payload.payloadType,
                category: payload.category,
                platforms: payload.platforms,
                introduced: payload.introduced,
                deprecated: payload.deprecated,
                sources: payload.sources,
                summary: payload.summary,
                discussion: payload.discussion,
                profileExample: payload.profileExample,
                profileExampleSyntax: payload.profileExampleSyntax
            )
        }
        
        let cleanedKeys = snapshot.keys.map { key in
            MDMKeyRecord(
                id: key.id,
                key: key.key,
                keyPath: key.keyPath,
                payloadType: key.payloadType,
                payloadName: cleanQuotedString(key.payloadName),
                platforms: key.platforms,
                sources: key.sources,
                introduced: key.introduced,
                deprecated: key.deprecated,
                publicationDate: key.publicationDate,
                keyType: key.keyType,
                keyDescription: key.keyDescription,
                required: key.required,
                defaultValue: key.defaultValue,
                possibleValues: key.possibleValues
            )
        }
        
        return MDMSnapshot(
            schemaVersion: snapshot.schemaVersion,
            generatedAt: snapshot.generatedAt,
            sources: snapshot.sources,
            payloads: cleanedPayloads,
            keys: cleanedKeys
        )
    }
    
    private func cleanQuotedString(_ value: String?) -> String? {
        guard var cleaned = value else { return nil }
        
        // Remove surrounding single quotes
        if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        // Remove surrounding double quotes
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func saveSnapshot(_ snapshot: MDMSnapshot, to url: URL) async {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try ensureDirectory(url.deletingLastPathComponent())
            try data.write(to: url, options: .atomic)
        } catch {
            // Non-fatal
        }
    }

    private func latestURL() -> URL? {
        appSupportURL()?.appendingPathComponent(latestFilename)
    }

    private func previousURL() -> URL? {
        appSupportURL()?.appendingPathComponent(previousFilename)
    }

    private func appSupportURL() -> URL? {
        let fm = FileManager.default
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private func ensureDirectory(_ url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func keyDeltas(old: MDMKeyRecord, new: MDMKeyRecord) -> [MDMKeyFieldDelta] {
        var deltas: [MDMKeyFieldDelta] = []

        captureDelta("Name", old: old.key, new: new.key, into: &deltas)
        captureDelta("Payload Name", old: old.payloadName, new: new.payloadName, into: &deltas)
        captureDelta("Platforms", old: listValue(old.platforms), new: listValue(new.platforms), into: &deltas)
        captureDelta(
            "Sources",
            old: listValue(old.sources.map(\.rawValue)),
            new: listValue(new.sources.map(\.rawValue)),
            into: &deltas
        )
        captureDelta("Introduced", old: old.introduced, new: new.introduced, into: &deltas)
        captureDelta("Deprecated", old: old.deprecated, new: new.deprecated, into: &deltas)
        captureDelta("Published", old: old.publicationDate, new: new.publicationDate, into: &deltas)
        captureDelta("Type", old: old.keyType, new: new.keyType, into: &deltas)
        captureDelta("Description", old: old.keyDescription, new: new.keyDescription, into: &deltas)
        captureDelta("Required", old: boolValue(old.required), new: boolValue(new.required), into: &deltas)
        captureDelta("Default", old: old.defaultValue, new: new.defaultValue, into: &deltas)
        captureDelta("Values", old: listValue(old.possibleValues), new: listValue(new.possibleValues), into: &deltas)

        return deltas
    }

    private func captureDelta(
        _ fieldName: String,
        old: String?,
        new: String?,
        into deltas: inout [MDMKeyFieldDelta]
    ) {
        let oldNormalized = normalize(old)
        let newNormalized = normalize(new)
        guard oldNormalized != newNormalized else { return }

        deltas.append(
            MDMKeyFieldDelta(
                fieldName: fieldName,
                oldValue: oldNormalized,
                newValue: newNormalized
            )
        )
    }

    private func listValue(_ values: [String]?) -> String? {
        guard let values else { return nil }
        let normalized = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
        guard !normalized.isEmpty else { return nil }
        return normalized.joined(separator: ", ")
    }

    private func boolValue(_ value: Bool?) -> String? {
        guard let value else { return nil }
        return value ? "Yes" : "No"
    }

    private func normalize(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }
    
    private func needsMigration(_ snapshot: MDMSnapshot) async -> Bool {
        // Check if we have a significant number of docs.devicemanagement.* payloads
        // This indicates the snapshot was created before the PayloadType extraction fix
        let docsPayloadCount = snapshot.payloads.filter { 
            $0.payloadType.hasPrefix("docs.devicemanagement.") 
        }.count
        
        // If more than 10 docs.* payloads exist, this is from the old format
        // (Topic pages will still have docs.* but there should only be a few)
        let needsMigration = docsPayloadCount > 10
        
        if needsMigration {
            logInfo("needsMigration: Found \(docsPayloadCount) docs.devicemanagement.* payloads - migration needed")
        }
        
        return needsMigration
    }
}
