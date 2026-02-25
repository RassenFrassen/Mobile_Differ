import Foundation

enum MDMNotificationLogChangeType: String, Codable, Hashable {
    case added
    case updated
    case removed

    var label: String {
        switch self {
        case .added: return "Added"
        case .updated: return "Updated"
        case .removed: return "Removed"
        }
    }
}

struct MDMNotificationLogChange: Identifiable, Codable, Hashable {
    let id: String
    let changeType: MDMNotificationLogChangeType
    let keyPath: String
    let payloadType: String
    let payloadName: String?
    let detail: String?
    let changedFields: [String]
    let platforms: [String]
    let sources: [String]
}

struct MDMNotificationLogEntry: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let title: String
    let body: String
    let newKeyCount: Int
    let updatedKeyCount: Int
    let removedKeyCount: Int
    let platforms: [String]
    let sources: [String]
    let changes: [MDMNotificationLogChange]

    var addedCount: Int {
        if newKeyCount > 0 { return newKeyCount }
        return changes.filter { $0.changeType == .added }.count
    }

    var updatedCount: Int {
        if updatedKeyCount > 0 { return updatedKeyCount }
        return changes.filter { $0.changeType == .updated }.count
    }

    var removedCount: Int {
        if removedKeyCount > 0 { return removedKeyCount }
        return changes.filter { $0.changeType == .removed }.count
    }

    var totalChangeCount: Int {
        addedCount + updatedCount + removedCount
    }

    init(
        id: UUID,
        createdAt: Date,
        title: String,
        body: String,
        newKeyCount: Int,
        updatedKeyCount: Int,
        removedKeyCount: Int,
        platforms: [String],
        sources: [String],
        changes: [MDMNotificationLogChange]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.body = body
        self.newKeyCount = newKeyCount
        self.updatedKeyCount = updatedKeyCount
        self.removedKeyCount = removedKeyCount
        self.platforms = platforms
        self.sources = sources
        self.changes = changes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case title
        case body
        case newKeyCount
        case updatedKeyCount
        case removedKeyCount
        case platforms
        case sources
        case changes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        newKeyCount = try container.decodeIfPresent(Int.self, forKey: .newKeyCount) ?? 0
        updatedKeyCount = try container.decodeIfPresent(Int.self, forKey: .updatedKeyCount) ?? 0
        removedKeyCount = try container.decodeIfPresent(Int.self, forKey: .removedKeyCount) ?? 0
        platforms = try container.decodeIfPresent([String].self, forKey: .platforms) ?? []
        sources = try container.decodeIfPresent([String].self, forKey: .sources) ?? []
        changes = try container.decodeIfPresent([MDMNotificationLogChange].self, forKey: .changes) ?? []
    }
}
