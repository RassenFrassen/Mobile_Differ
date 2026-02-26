import Foundation

/// Service for managing custom MDM documentation sources
actor CustomSourceService {
    static let shared = CustomSourceService()
    
    private let fileURL: URL
    private var customSources: [CustomMDMSource] = []
    
    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsURL.appendingPathComponent("custom_sources.json")
        Task {
            await loadSources()
        }
    }
    
    // MARK: - Public API
    
    func getSources() async -> [CustomMDMSource] {
        customSources
    }
    
    func addSource(_ source: CustomMDMSource) async throws {
        // Validate URL
        guard URL(string: source.repoURL) != nil else {
            throw CustomSourceError.invalidURL
        }
        
        // Check for duplicates
        if customSources.contains(where: { $0.id == source.id }) {
            throw CustomSourceError.duplicateSource
        }
        
        customSources.append(source)
        await saveSources()
        logInfo("CustomSourceService: Added source '\(source.name)'")
    }
    
    func removeSource(_ sourceID: UUID) async {
        customSources.removeAll { $0.id == sourceID }
        await saveSources()
        logInfo("CustomSourceService: Removed source")
    }
    
    func updateSource(_ source: CustomMDMSource) async throws {
        guard let index = customSources.firstIndex(where: { $0.id == source.id }) else {
            throw CustomSourceError.sourceNotFound
        }
        
        customSources[index] = source
        await saveSources()
        logInfo("CustomSourceService: Updated source '\(source.name)'")
    }
    
    func toggleEnabled(_ sourceID: UUID) async {
        guard let index = customSources.firstIndex(where: { $0.id == sourceID }) else {
            return
        }
        
        customSources[index].isEnabled.toggle()
        await saveSources()
    }
    
    func clearAll() async {
        customSources.removeAll()
        await saveSources()
    }
    
    // MARK: - Persistence
    
    private func loadSources() async {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([CustomMDMSource].self, from: data)
            customSources = decoded
            logInfo("CustomSourceService: Loaded \(decoded.count) custom sources")
        } catch {
            logError("Failed to load custom sources: \(error)")
            customSources = []
        }
    }
    
    private func saveSources() async {
        do {
            let data = try JSONEncoder().encode(customSources)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logError("Failed to save custom sources: \(error)")
        }
    }
}

// MARK: - Models

struct CustomMDMSource: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var repoURL: String
    var description: String
    var icon: String
    var isEnabled: Bool
    var sourceType: CustomSourceType
    var lastFetched: Date?
    var itemCount: Int?
    
    init(
        id: UUID = UUID(),
        name: String,
        repoURL: String,
        description: String,
        icon: String = "doc.text",
        isEnabled: Bool = true,
        sourceType: CustomSourceType = .github
    ) {
        self.id = id
        self.name = name
        self.repoURL = repoURL
        self.description = description
        self.icon = icon
        self.isEnabled = isEnabled
        self.sourceType = sourceType
        self.lastFetched = nil
        self.itemCount = nil
    }
}

enum CustomSourceType: String, Codable {
    case github
    case url
    case local
}

enum CustomSourceError: LocalizedError {
    case invalidURL
    case duplicateSource
    case sourceNotFound
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .duplicateSource:
            return "A source with this URL already exists"
        case .sourceNotFound:
            return "Source not found"
        case .fetchFailed:
            return "Failed to fetch data from source"
        }
    }
}
