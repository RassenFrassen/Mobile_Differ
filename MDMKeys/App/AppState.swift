import SwiftUI

/// Central state for Differ — MDM catalog browsing and notifications.
@MainActor
class AppState: ObservableObject {

    // MARK: - MDM Catalog

    @Published var mdmSnapshot: MDMSnapshot?
    @Published var mdmKeys: [MDMKeyRecord] = []
    @Published var mdmPayloads: [MDMPayloadRecord] = []
    @Published var mdmNewKeys: [MDMKeyRecord] = []
    @Published var mdmNotificationLog: [MDMNotificationLogEntry] = []
    @Published var mdmNotificationUnreadCount: Int = UserDefaults.standard.integer(forKey: "mdmNotificationUnreadCount")
    @Published var isUpdatingMDMCatalog = false
    @Published var mdmUpdateError: String?
    @Published var mdmLastUpdated: Date?
    @Published var isInitializing = true
    @Published var catalogRefreshStatus: String?
    @Published var favoriteKeys: Set<String> = []

    // MARK: - Settings

    @Published var githubToken: String = AppState.loadGithubToken()
    @Published var enabledMDMSources: Set<MDMSource> = AppState.loadEnabledMDMSources()
    @Published var autoRefreshEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "autoRefreshEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
    }()

    // MARK: - Init

    init() {
        // Initial catalog loading is handled by MDMKeysApp.task modifier
        // to ensure proper ordering with UI lifecycle
    }

    // MARK: - Catalog Loading

    func loadInitialCatalog() async {
        logInfo("loadInitialCatalog: Starting catalog load")
        isInitializing = true
        
        // Check if this is first launch
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        // On first launch, load bundled seed then immediately refresh to extract embedded bundles
        if isFirstLaunch {
            logInfo("loadInitialCatalog: First launch detected")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            // Load bundled seed to show something during refresh
            if let seed = await MDMCatalogStore.shared.loadBundledSnapshot() {
                logInfo("loadInitialCatalog: Loaded bundled seed with \(seed.keys.count) keys")
                apply(snapshot: seed)
            }
            
            // Keep showing loading screen while refreshing to extract embedded bundles
            logInfo("loadInitialCatalog: Refreshing catalog to extract embedded bundles")
            await refreshMDMCatalog(silentFirstLaunch: true)
            isInitializing = false
            return
        }
        
        // Subsequent launches: Try saved latest snapshot first, fall back to bundled seed
        if let latest = await MDMCatalogStore.shared.loadLatestSnapshot() {
            logInfo("loadInitialCatalog: Loaded latest snapshot with \(latest.keys.count) keys")
            apply(snapshot: latest)
        } else if let seed = await MDMCatalogStore.shared.loadBundledSnapshot() {
            logInfo("loadInitialCatalog: Loaded bundled seed with \(seed.keys.count) keys")
            apply(snapshot: seed)
        } else {
            logWarning("loadInitialCatalog: No valid cached data found (migration may have cleared old format)")
            logInfo("loadInitialCatalog: Will trigger automatic refresh to fetch fresh data")
            // Migration scenario: cached data was cleared, need to fetch fresh
            isInitializing = false
            await refreshMDMCatalog()
            return
        }
        
        logInfo("loadInitialCatalog: Complete. mdmKeys count = \(mdmKeys.count)")
        
        // Add a small delay to ensure smooth transition
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isInitializing = false
    }

    func refreshMDMCatalog(silentFirstLaunch: Bool = false) async {
        guard !isUpdatingMDMCatalog else { return }
        isUpdatingMDMCatalog = true
        mdmUpdateError = nil
        catalogRefreshStatus = "Preparing to refresh..."

        let token = githubToken.isEmpty ? nil : githubToken
        let latestSnapshot = await MDMCatalogStore.shared.loadLatestSnapshot()
        let bundledSnapshot = await MDMCatalogStore.shared.loadBundledSnapshot()
        let previous = latestSnapshot ?? bundledSnapshot

        catalogRefreshStatus = "Extracting embedded bundles..."
        
        let snapshot = await MDMUpdateService.shared.updateCatalog(
            token: token,
            enabledSources: enabledMDMSources
        )
        
        catalogRefreshStatus = "Processing catalog data..."

        if let snapshot {
            await MDMCatalogStore.shared.promoteLatestToPrevious()
            await MDMCatalogStore.shared.saveLatestSnapshot(snapshot)

            let changes = await MDMCatalogStore.shared.diffKeyChanges(latest: snapshot, previous: previous)

            apply(snapshot: snapshot)
            mdmNewKeys = changes.added
            mdmLastUpdated = Date()

            // Detect suspicious diff (likely data corruption or format change)
            let isSuspicious = previous != nil && 
                               changes.added.count > 1000 && 
                               changes.removed.count > 1000 &&
                               abs(changes.added.count - changes.removed.count) < 500
            
            if isSuspicious {
                logWarning("refreshMDMCatalog: Suspicious diff detected - \(changes.added.count) added, \(changes.removed.count) removed. Likely data corruption. Skipping notification.")
            }
            
            // Record changes in history
            await KeyHistoryService.shared.recordChanges(from: changes)

            // Skip notifications on first launch (massive initial diff)
            let shouldNotify = !silentFirstLaunch && changes.totalCount > 0 && !isSuspicious

            if shouldNotify {
                let platforms = Array(Set(
                    changes.added.flatMap(\.platforms) +
                    changes.updated.flatMap { $0.after.platforms } +
                    changes.removed.flatMap(\.platforms)
                )).sorted()

                let sources = Array(Set(
                    changes.added.flatMap { $0.sources.map(\.rawValue) } +
                    changes.updated.flatMap { $0.after.sources.map(\.rawValue) } +
                    changes.removed.flatMap { $0.sources.map(\.rawValue) }
                )).sorted()

                let logChanges: [MDMNotificationLogChange] = changes.added.map {
                    MDMNotificationLogChange(
                        id: $0.id,
                        changeType: .added,
                        keyPath: $0.keyPath,
                        payloadType: $0.payloadType,
                        payloadName: $0.payloadName,
                        detail: $0.keyDescription,
                        changedFields: [],
                        platforms: $0.platforms,
                        sources: $0.sources.map(\.rawValue)
                    )
                } + changes.removed.map {
                    MDMNotificationLogChange(
                        id: $0.id,
                        changeType: .removed,
                        keyPath: $0.keyPath,
                        payloadType: $0.payloadType,
                        payloadName: $0.payloadName,
                        detail: nil,
                        changedFields: [],
                        platforms: $0.platforms,
                        sources: $0.sources.map(\.rawValue)
                    )
                } + changes.updated.map {
                    MDMNotificationLogChange(
                        id: $0.after.id,
                        changeType: .updated,
                        keyPath: $0.after.keyPath,
                        payloadType: $0.after.payloadType,
                        payloadName: $0.after.payloadName,
                        detail: $0.deltas.map { "\($0.fieldName): \($0.newValue ?? "—")" }.joined(separator: "; "),
                        changedFields: $0.deltas.map(\.fieldName),
                        platforms: $0.after.platforms,
                        sources: $0.after.sources.map(\.rawValue)
                    )
                }

                await MDMNotificationService.shared.sendCatalogChangesNotification(
                    addedCount: changes.added.count,
                    updatedCount: changes.updated.count,
                    removedCount: changes.removed.count,
                    platforms: platforms,
                    sources: sources,
                    changes: logChanges
                )
            }

            mdmNotificationLog = await MDMNotificationService.shared.loadLog()
            mdmNotificationUnreadCount = await MDMNotificationService.shared.loadUnreadCount()
        } else {
            mdmUpdateError = "Unable to refresh the catalog. Please check your internet connection and try again. If you have rate limits, consider adding a GitHub token in Settings."
        }

        catalogRefreshStatus = nil
        isUpdatingMDMCatalog = false
    }

    func markNotificationsRead() async {
        await MDMNotificationService.shared.markAllAsRead()
        mdmNotificationUnreadCount = 0
    }

    func loadNotificationData() async {
        mdmNotificationLog = await MDMNotificationService.shared.loadLog()
        mdmNotificationUnreadCount = await MDMNotificationService.shared.loadUnreadCount()
    }

    func loadFavorites() async {
        favoriteKeys = await FavoritesService.shared.getAllFavorites()
    }

    func toggleFavorite(_ keyID: String) async {
        await FavoritesService.shared.toggleFavorite(keyID)
        favoriteKeys = await FavoritesService.shared.getAllFavorites()
    }

    func isFavorite(_ keyID: String) -> Bool {
        favoriteKeys.contains(keyID)
    }
    
    func clearCacheAndReload() async {
        // Clear cached snapshots
        await MDMCatalogStore.shared.clearCache()
        
        // Clear notification log and reset badge
        await MDMNotificationService.shared.clearLog()
        await MDMNotificationService.shared.markAllAsRead()
        mdmNotificationLog = []
        mdmNotificationUnreadCount = 0
        
        // Reload from bundled seed
        if let seed = await MDMCatalogStore.shared.loadBundledSnapshot() {
            apply(snapshot: seed)
            mdmLastUpdated = nil
            mdmNewKeys = []
            logInfo("clearCacheAndReload: Reloaded from bundled seed with \(seed.keys.count) keys")
        }
    }

    // MARK: - Settings Persistence

    func saveGithubToken(_ token: String) {
        githubToken = token
        // Save to Keychain for security
        try? KeychainService.save(key: "githubToken", value: token)
        // Remove from UserDefaults if it was stored there previously
        UserDefaults.standard.removeObject(forKey: "githubToken")
    }

    func toggleSource(_ source: MDMSource) {
        if enabledMDMSources.contains(source) {
            enabledMDMSources.remove(source)
        } else {
            enabledMDMSources.insert(source)
        }
        saveEnabledMDMSources()
    }

    // MARK: - Private Helpers

    private func apply(snapshot: MDMSnapshot) {
        mdmSnapshot = snapshot
        mdmKeys = snapshot.keys.sorted { $0.keyPath < $1.keyPath }
        mdmPayloads = snapshot.payloads.sorted { $0.name < $1.name }
    }

    private func saveEnabledMDMSources() {
        let raw = enabledMDMSources.map(\.rawValue)
        UserDefaults.standard.set(raw, forKey: "mdmEnabledSources")
    }

    static func loadEnabledMDMSources() -> Set<MDMSource> {
        if let raw = UserDefaults.standard.array(forKey: "mdmEnabledSources") as? [String] {
            let sources = raw.compactMap { MDMSource(rawValue: $0) }
            if !sources.isEmpty { return Set(sources) }
        }
        return Set(MDMSource.allCases)
    }
    
    static func loadGithubToken() -> String {
        // Try to load from Keychain first
        if let token = try? KeychainService.get(key: "githubToken"), !token.isEmpty {
            return token
        }
        
        // Migrate from UserDefaults if it exists
        if let token = UserDefaults.standard.string(forKey: "githubToken"), !token.isEmpty {
            // Save to Keychain
            try? KeychainService.save(key: "githubToken", value: token)
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: "githubToken")
            return token
        }
        
        return ""
    }
}
