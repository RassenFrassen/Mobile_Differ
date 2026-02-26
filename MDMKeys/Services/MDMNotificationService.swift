import Foundation
import UserNotifications
import UIKit

actor MDMNotificationService {
    static let shared = MDMNotificationService()

    private let logFilename = "mdm_notification_log.json"
    private let unreadCountKey = "mdmNotificationUnreadCount"

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    /// Migrate notification log from UserDefaults to file storage if needed.
    /// This is called synchronously during app initialization to prevent UserDefaults overflow.
    static func migrateFromUserDefaultsIfNeeded() {
        // Check if legacy data exists in UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "mdmNotificationLog") else {
            return
        }
        
        print("MDMNotificationService: Found legacy notification log in UserDefaults (size: \(data.count) bytes)")
        
        // Try to decode and save to file
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let log = try? decoder.decode([MDMNotificationLogEntry].self, from: data) {
            print("MDMNotificationService: Decoded \(log.count) entries, migrating to file storage")
            
            // Save to file synchronously
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            if let encodedData = try? encoder.encode(log),
               let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("mdm_notification_log.json") {
                
                // Ensure directory exists
                let directory = url.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directory.path) {
                    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                
                // Write to file
                try? encodedData.write(to: url, options: .atomic)
                print("MDMNotificationService: Successfully saved to file")
            }
        } else {
            print("MDMNotificationService: Failed to decode legacy log, will be discarded")
        }
        
        // Remove from UserDefaults immediately to free up space
        UserDefaults.standard.removeObject(forKey: "mdmNotificationLog")
        print("MDMNotificationService: Removed legacy data from UserDefaults")
    }

    func sendCatalogChangesNotification(
        addedCount: Int,
        updatedCount: Int,
        removedCount: Int,
        platforms: [String],
        sources: [String],
        changes: [MDMNotificationLogChange]
    ) async {
        let normalizedChanges = uniqueChanges(changes)
        let effectiveCounts = normalizedCounts(
            added: addedCount,
            updated: updatedCount,
            removed: removedCount,
            changes: normalizedChanges
        )
        let totalCount = effectiveCounts.added + effectiveCounts.updated + effectiveCounts.removed
        guard totalCount > 0 else { return }

        let title = notificationTitle(
            addedCount: effectiveCounts.added,
            updatedCount: effectiveCounts.updated,
            removedCount: effectiveCounts.removed
        )
        let summary = summaryText(
            addedCount: effectiveCounts.added,
            updatedCount: effectiveCounts.updated,
            removedCount: effectiveCounts.removed
        )
        let platformText = platforms.isEmpty ? "All platforms" : platforms.joined(separator: ", ")
        let sourceText = formatSourceText(sources)
        let body = "\(summary)\nSource: \(sourceText)\nPlatforms: \(platformText)"

        await setUnreadCount(totalCount)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.badge = NSNumber(value: totalCount)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        let center = UNUserNotificationCenter.current()
        try? await center.add(request)

        await appendLog(
            title: title,
            body: body,
            newKeyCount: effectiveCounts.added,
            updatedKeyCount: effectiveCounts.updated,
            removedKeyCount: effectiveCounts.removed,
            platforms: platforms,
            sources: sources,
            changes: normalizedChanges
        )
    }

    func loadLog() -> [MDMNotificationLogEntry] {
        // Load from file (migration already happened in app init)
        guard let url = logFileURL(), FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MDMNotificationLogEntry].self, from: data)) ?? []
    }

    func loadUnreadCount() -> Int {
        max(0, UserDefaults.standard.integer(forKey: unreadCountKey))
    }

    func clearLog() {
        // Remove file
        if let url = logFileURL(), FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        // Clean up legacy UserDefaults entry
        UserDefaults.standard.removeObject(forKey: "mdmNotificationLog")
    }

    func deduplicateLog() async {
        let log = loadLog()
        guard !log.isEmpty else { return }

        var deduplicated: [MDMNotificationLogEntry] = []
        for entry in log {
            let isDupe = deduplicated.contains { existing in
                isDuplicate(existing, of: entry)
            }
            if !isDupe {
                deduplicated.append(entry)
            }
        }

        if deduplicated.count < log.count {
            saveLog(deduplicated)
        }
    }

    func markAllAsRead() async {
        await setUnreadCount(0)
    }

    func syncBadgeWithUnreadCount() async {
        await updateAppBadge(count: loadUnreadCount())
    }

    private func appendLog(
        title: String,
        body: String,
        newKeyCount: Int,
        updatedKeyCount: Int,
        removedKeyCount: Int,
        platforms: [String],
        sources: [String],
        changes: [MDMNotificationLogChange]
    ) async {
        var log = loadLog()
        let normalizedChanges = uniqueChanges(changes)
        let counts = normalizedCounts(
            added: newKeyCount,
            updated: updatedKeyCount,
            removed: removedKeyCount,
            changes: normalizedChanges
        )
        let entry = MDMNotificationLogEntry(
            id: UUID(),
            createdAt: Date(),
            title: title,
            body: body,
            newKeyCount: counts.added,
            updatedKeyCount: counts.updated,
            removedKeyCount: counts.removed,
            platforms: platforms,
            sources: sources,
            changes: normalizedChanges
        )
        if let latest = log.first, isDuplicate(latest, of: entry) {
            return
        }
        log.insert(entry, at: 0)
        if log.count > 200 { log = Array(log.prefix(200)) }

        saveLog(log)
    }

    private func notificationTitle(addedCount: Int, updatedCount: Int, removedCount: Int) -> String {
        if addedCount > 0, updatedCount == 0, removedCount == 0 {
            return "New MDM preferences found"
        }
        return "MDM catalog changes found"
    }

    private func summaryText(addedCount: Int, updatedCount: Int, removedCount: Int) -> String {
        var parts: [String] = []
        if addedCount > 0 { parts.append("\(addedCount) added") }
        if updatedCount > 0 { parts.append("\(updatedCount) updated") }
        if removedCount > 0 { parts.append("\(removedCount) removed") }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
    
    private func formatSourceText(_ sources: [String]) -> String {
        if sources.isEmpty {
            return "Multiple sources"
        }
        
        // Deduplicate sources first
        let uniqueSources = Array(Set(sources)).sorted()
        
        let shortSources = uniqueSources.map { source -> String in
            switch source {
            case "Apple device-management":
                return "Apple Device Management"
            case "Apple Developer Documentation":
                return "Apple Developer Docs"
            case "ProfileManifests":
                return "ProfileManifests"
            case "rtrouton/profiles":
                return "rtrouton"
            case "Mac-Nerd/Mac-profiles":
                return "Mac-Nerd"
            default:
                return source
            }
        }
        
        if shortSources.count == 1 {
            return shortSources[0]
        } else if shortSources.count == 2 {
            return shortSources.joined(separator: " & ")
        } else {
            return "\(shortSources.count) sources (\(shortSources.prefix(2).joined(separator: ", "))…)"
        }
    }

    private func uniqueChanges(_ changes: [MDMNotificationLogChange]) -> [MDMNotificationLogChange] {
        guard !changes.isEmpty else { return [] }
        var seen = Set<String>()
        return changes.filter { seen.insert($0.id).inserted }
    }

    private func normalizedCounts(
        added: Int,
        updated: Int,
        removed: Int,
        changes: [MDMNotificationLogChange]
    ) -> (added: Int, updated: Int, removed: Int) {
        let normalizedAdded = max(0, added)
        let normalizedUpdated = max(0, updated)
        let normalizedRemoved = max(0, removed)
        guard !changes.isEmpty else {
            return (normalizedAdded, normalizedUpdated, normalizedRemoved)
        }
        var addedCount = 0
        var updatedCount = 0
        var removedCount = 0
        for change in changes {
            switch change.changeType {
            case .added: addedCount += 1
            case .updated: updatedCount += 1
            case .removed: removedCount += 1
            }
        }
        return (max(0, addedCount), max(0, updatedCount), max(0, removedCount))
    }

    private func isDuplicate(_ entry: MDMNotificationLogEntry, of candidate: MDMNotificationLogEntry) -> Bool {
        let timeDifference = abs(entry.createdAt.timeIntervalSince(candidate.createdAt))
        guard timeDifference < 300 else { return false }
        guard entry.title == candidate.title else { return false }

        let totalEntry = entry.newKeyCount + entry.updatedKeyCount + entry.removedKeyCount
        let totalCandidate = candidate.newKeyCount + candidate.updatedKeyCount + candidate.removedKeyCount
        let countDifference = abs(totalEntry - totalCandidate)
        let threshold = max(50, Int(Double(totalEntry) * 0.05))
        guard countDifference <= threshold else { return false }

        guard Set(entry.platforms) == Set(candidate.platforms) else { return false }
        guard Set(entry.sources) == Set(candidate.sources) else { return false }
        return true
    }

    private func setUnreadCount(_ count: Int) async {
        let normalized = min(99999, max(0, count))
        UserDefaults.standard.set(normalized, forKey: unreadCountKey)
        await updateAppBadge(count: normalized)
    }

    private func updateAppBadge(count: Int) async {
        await MainActor.run {
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    // MARK: - File Storage Helpers
    
    private func saveLog(_ log: [MDMNotificationLogEntry]) {
        guard let url = logFileURL() else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(log)
            
            // Ensure directory exists
            try ensureDirectory(url.deletingLastPathComponent())
            
            // Write to file
            try data.write(to: url, options: .atomic)
        } catch {
            logError("Failed to save notification log: \(error)")
        }
    }
    
    private func logFileURL() -> URL? {
        let fm = FileManager.default
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(logFilename)
    }
    
    private func ensureDirectory(_ url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
