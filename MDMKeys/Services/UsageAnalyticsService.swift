import Foundation

/// Privacy-respecting local analytics service for tracking key usage patterns
actor UsageAnalyticsService {
    static let shared = UsageAnalyticsService()
    
    private let fileURL: URL
    private var analytics: UsageAnalytics
    
    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsURL.appendingPathComponent("usage_analytics.json")
        self.analytics = UsageAnalytics()
        Task {
            await loadAnalytics()
        }
    }
    
    // MARK: - Public API
    
    /// Record a key view
    func recordKeyView(_ keyID: String, keyPath: String, payloadType: String) async {
        let now = Date()
        
        // Update or create key stats
        if var stats = analytics.keyStats[keyID] {
            stats.viewCount += 1
            stats.lastViewed = now
            analytics.keyStats[keyID] = stats
        } else {
            analytics.keyStats[keyID] = KeyUsageStats(
                keyID: keyID,
                keyPath: keyPath,
                payloadType: payloadType,
                viewCount: 1,
                firstViewed: now,
                lastViewed: now
            )
        }
        
        // Update daily stats
        let dateKey = dayKey(for: now)
        analytics.dailyViews[dateKey, default: 0] += 1
        
        // Update payload stats
        analytics.payloadTypeViews[payloadType, default: 0] += 1
        
        await saveAnalytics()
    }
    
    /// Get most viewed keys
    func getMostViewedKeys(limit: Int = 10) async -> [KeyUsageStats] {
        Array(analytics.keyStats.values
            .sorted { $0.viewCount > $1.viewCount }
            .prefix(limit))
    }
    
    /// Get recently viewed keys
    func getRecentlyViewedKeys(limit: Int = 10) async -> [KeyUsageStats] {
        Array(analytics.keyStats.values
            .sorted { $0.lastViewed > $1.lastViewed }
            .prefix(limit))
    }
    
    /// Get stats for a specific key
    func getKeyStats(_ keyID: String) async -> KeyUsageStats? {
        analytics.keyStats[keyID]
    }
    
    /// Get most viewed payload types
    func getMostViewedPayloadTypes(limit: Int = 10) async -> [(type: String, count: Int)] {
        analytics.payloadTypeViews
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (type: $0.key, count: $0.value) }
    }
    
    /// Get daily view counts for the last N days
    func getDailyViewCounts(days: Int = 30) async -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var results: [(date: Date, count: Int)] = []
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            let key = dayKey(for: date)
            let count = analytics.dailyViews[key] ?? 0
            results.append((date: date, count: count))
        }
        
        return results.reversed()
    }
    
    /// Get total statistics
    func getTotalStats() async -> TotalUsageStats {
        let totalViews = analytics.keyStats.values.reduce(0) { $0 + $1.viewCount }
        let uniqueKeys = analytics.keyStats.count
        let uniquePayloads = analytics.payloadTypeViews.count
        
        return TotalUsageStats(
            totalViews: totalViews,
            uniqueKeysViewed: uniqueKeys,
            uniquePayloadsViewed: uniquePayloads
        )
    }
    
    /// Clear all analytics data
    func clearAll() async {
        analytics = UsageAnalytics()
        await saveAnalytics()
    }
    
    // MARK: - Private Helpers
    
    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func loadAnalytics() async {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            analytics = try decoder.decode(UsageAnalytics.self, from: data)
            logInfo("UsageAnalyticsService: Loaded analytics for \(analytics.keyStats.count) keys")
        } catch {
            logError("Failed to load usage analytics: \(error)")
            analytics = UsageAnalytics()
        }
    }
    
    private func saveAnalytics() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(analytics)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logError("Failed to save usage analytics: \(error)")
        }
    }
}

// MARK: - Models

struct UsageAnalytics: Codable {
    var keyStats: [String: KeyUsageStats] = [:]
    var dailyViews: [String: Int] = [:]
    var payloadTypeViews: [String: Int] = [:]
}

struct KeyUsageStats: Codable, Identifiable {
    let keyID: String
    let keyPath: String
    let payloadType: String
    var viewCount: Int
    let firstViewed: Date
    var lastViewed: Date
    
    var id: String { keyID }
}

struct TotalUsageStats {
    let totalViews: Int
    let uniqueKeysViewed: Int
    let uniquePayloadsViewed: Int
}
