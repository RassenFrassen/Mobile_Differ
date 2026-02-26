import Foundation

/// Service for tracking historical changes to MDM keys
actor KeyHistoryService {
    static let shared = KeyHistoryService()

    private let fileURL: URL
    private var history: [String: [KeyHistoryEntry]] = [:]

    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsURL.appendingPathComponent("key_history.json")
        Task {
            await loadHistory()
        }
    }

    // MARK: - Public API

    /// Record changes from catalog update
    func recordChanges(from changes: MDMCatalogKeyChanges, timestamp: Date = Date()) async {
        // Record added keys
        for key in changes.added {
            let entry = KeyHistoryEntry(
                timestamp: timestamp,
                changeType: .added,
                keyID: key.id,
                keyPath: key.keyPath,
                payloadType: key.payloadType,
                snapshot: KeySnapshot(from: key)
            )
            appendEntry(entry, for: key.id)
        }

        // Record updated keys
        for change in changes.updated {
            let entry = KeyHistoryEntry(
                timestamp: timestamp,
                changeType: .updated,
                keyID: change.after.id,
                keyPath: change.after.keyPath,
                payloadType: change.after.payloadType,
                snapshot: KeySnapshot(from: change.after),
                changedFields: change.deltas.map { $0.fieldName }
            )
            appendEntry(entry, for: change.after.id)
        }

        // Record removed keys
        for key in changes.removed {
            let entry = KeyHistoryEntry(
                timestamp: timestamp,
                changeType: .removed,
                keyID: key.id,
                keyPath: key.keyPath,
                payloadType: key.payloadType,
                snapshot: KeySnapshot(from: key)
            )
            appendEntry(entry, for: key.id)
        }

        await saveHistory()
    }

    /// Get history for a specific key
    func getHistory(for keyID: String) async -> [KeyHistoryEntry] {
        history[keyID]?.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
    }

    /// Get all history entries
    func getAllHistory() async -> [KeyHistoryEntry] {
        history.values.flatMap { $0 }.sorted(by: { $0.timestamp > $1.timestamp })
    }

    /// Get recent changes (last N days)
    func getRecentChanges(days: Int = 30) async -> [KeyHistoryEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return await getAllHistory().filter { $0.timestamp >= cutoff }
    }

    /// Clear all history
    func clearHistory() async {
        history.removeAll()
        await saveHistory()
    }

    // MARK: - Private Helpers

    private func appendEntry(_ entry: KeyHistoryEntry, for keyID: String) {
        if history[keyID] == nil {
            history[keyID] = []
        }
        history[keyID]?.append(entry)

        // Keep only last 50 entries per key to prevent unbounded growth
        if let count = history[keyID]?.count, count > 50 {
            history[keyID] = Array(history[keyID]!.suffix(50))
        }
    }

    private func loadHistory() async {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: [KeyHistoryEntry]].self, from: data)
            history = decoded
            logInfo("KeyHistoryService: Loaded history for \(decoded.keys.count) keys")
        } catch {
            logError("Failed to load key history: \(error)")
            history = [:]
        }
    }

    private func saveHistory() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logError("Failed to save key history: \(error)")
        }
    }
}

// MARK: - Models

struct KeyHistoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let changeType: MDMKeyChangeType
    let keyID: String
    let keyPath: String
    let payloadType: String
    let snapshot: KeySnapshot
    let changedFields: [String]?

    init(
        timestamp: Date,
        changeType: MDMKeyChangeType,
        keyID: String,
        keyPath: String,
        payloadType: String,
        snapshot: KeySnapshot,
        changedFields: [String]? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.changeType = changeType
        self.keyID = keyID
        self.keyPath = keyPath
        self.payloadType = payloadType
        self.snapshot = snapshot
        self.changedFields = changedFields
    }
}

struct KeySnapshot: Codable {
    let key: String
    let keyPath: String
    let payloadType: String
    let platforms: [String]
    let sources: [String]
    let keyType: String?
    let keyDescription: String?
    let required: Bool?
    let defaultValue: String?
    let deprecated: String?
    let introduced: String?

    init(from record: MDMKeyRecord) {
        self.key = record.key
        self.keyPath = record.keyPath
        self.payloadType = record.payloadType
        self.platforms = record.platforms
        self.sources = record.sources.map { $0.rawValue }
        self.keyType = record.keyType
        self.keyDescription = record.keyDescription
        self.required = record.required
        self.defaultValue = record.defaultValue
        self.deprecated = record.deprecated
        self.introduced = record.introduced
    }
}
