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

    // MARK: - Settings

    @Published var githubToken: String = UserDefaults.standard.string(forKey: "githubToken") ?? ""
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
        
        // Try saved latest snapshot first, fall back to bundled seed
        if let latest = await MDMCatalogStore.shared.loadLatestSnapshot() {
            logInfo("loadInitialCatalog: Loaded latest snapshot with \(latest.keys.count) keys")
            apply(snapshot: latest)
        } else if let seed = await MDMCatalogStore.shared.loadBundledSnapshot() {
            logInfo("loadInitialCatalog: Loaded bundled seed with \(seed.keys.count) keys")
            apply(snapshot: seed)
        } else {
            logError("loadInitialCatalog: Failed to load any catalog snapshot")
        }
        
        logInfo("loadInitialCatalog: Complete. mdmKeys count = \(mdmKeys.count)")
        
        // Add a small delay to ensure smooth transition
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isInitializing = false
    }

    func refreshMDMCatalog() async {
        guard !isUpdatingMDMCatalog else { return }
        isUpdatingMDMCatalog = true
        mdmUpdateError = nil

        let token = githubToken.isEmpty ? nil : githubToken
        let latestSnapshot = await MDMCatalogStore.shared.loadLatestSnapshot()
        let bundledSnapshot = await MDMCatalogStore.shared.loadBundledSnapshot()
        let previous = latestSnapshot ?? bundledSnapshot

        let snapshot = await MDMUpdateService.shared.updateCatalog(
            token: token,
            enabledSources: enabledMDMSources
        )

        if let snapshot {
            await MDMCatalogStore.shared.promoteLatestToPrevious()
            await MDMCatalogStore.shared.saveLatestSnapshot(snapshot)

            let changes = await MDMCatalogStore.shared.diffKeyChanges(latest: snapshot, previous: previous)

            apply(snapshot: snapshot)
            mdmNewKeys = changes.added
            mdmLastUpdated = Date()

            if changes.totalCount > 0 {
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
            mdmUpdateError = "Could not refresh MDM catalog. Check your internet connection."
        }

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

    // MARK: - Settings Persistence

    func saveGithubToken(_ token: String) {
        githubToken = token
        UserDefaults.standard.set(token, forKey: "githubToken")
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
}
