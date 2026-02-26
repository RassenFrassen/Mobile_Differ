import Foundation
#if os(iOS)
import BackgroundTasks
#endif
#if os(macOS)
import Darwin
import ServiceManagement
#endif

actor MDMUpdateService {
    static let shared = MDMUpdateService()

    var taskIdentifier: String {
        let bundle = Bundle.main.bundleIdentifier ?? "com.differ.app"
        return "\(bundle).mdmrefresh"
    }

    func registerBackgroundTask() {
        #if os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task {
                await self.handleBackgroundRefresh(task: refreshTask)
            }
        }
        #endif
    }

    func scheduleBackgroundRefresh() {
        #if os(iOS)
        // Only schedule if auto-refresh is enabled
        guard isAutoRefreshEnabled() else {
            cancelBackgroundRefresh()
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date().addingTimeInterval(60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Non-fatal
        }
        #endif
    }
    
    func cancelBackgroundRefresh() {
        #if os(iOS)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        #endif
    }

    func updateCatalog(token: String?, enabledSources: Set<MDMSource>) async -> MDMSnapshot? {
        logInfo("Starting MDM catalog update with \(enabledSources.count) enabled sources")
        
        let results = await MDMSourceIngestor.shared.fetchAll(
            token: token,
            enabledSources: enabledSources
        )
        guard !results.isEmpty else {
            logWarning("MDM catalog update returned no results")
            return nil
        }

        logInfo("Fetched \(results.count) source results, merging data")
        let merged = merge(results: results)
        let sourceSnapshots = results.map { result in
            MDMSourceSnapshot(
                source: result.source,
                repoURL: result.source.repoURL,
                revision: result.revision,
                licenseName: result.licenseName,
                licenseURL: result.licenseURL,
                fetchedAt: Date(),
                itemCount: result.keys.count
            )
        }

        logInfo("Building snapshot with \(merged.payloads.count) payloads and \(merged.keys.count) keys")
        let snapshot = await MDMCatalogStore.shared.buildSnapshot(
            payloads: merged.payloads,
            keys: merged.keys,
            sources: sourceSnapshots
        )
        
        logInfo("MDM catalog update completed successfully")
        return snapshot
    }

    // MARK: - Private

    #if os(iOS)
    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Check if auto-refresh is still enabled
        guard isAutoRefreshEnabled() else {
            task.setTaskCompleted(success: true)
            return
        }

        let snapshot = await updateCatalog(
            token: try? KeychainService.get(key: "githubToken"),
            enabledSources: enabledSourcesFromDefaults()
        )
        if let snapshot {
            await MDMCatalogStore.shared.promoteLatestToPrevious()
            await MDMCatalogStore.shared.saveLatestSnapshot(snapshot)
        }

        scheduleBackgroundRefresh()
        task.setTaskCompleted(success: snapshot != nil)
    }
    #endif

    private func merge(results: [MDMSourceIngestor.SourceResult]) -> (payloads: [MDMPayloadRecord], keys: [MDMKeyRecord]) {
        var payloadIndex: [String: MDMPayloadRecord] = [:]
        var keyIndex: [String: MDMKeyRecord] = [:]

        // Sort results to prioritize Apple sources
        let sortedResults = results.sorted { lhs, rhs in
            isAppleSource(lhs.source) && !isAppleSource(rhs.source)
        }

        for result in sortedResults {
            for payload in result.payloads {
                if var existing = payloadIndex[payload.payloadType] {
                    let mergedSources = Array(Set(existing.sources + payload.sources)).sorted { sortSource($0) < sortSource($1) }
                    let mergedPlatforms = Array(Set(existing.platforms + payload.platforms)).sorted()
                    
                    // If current is Apple source, prefer its values; otherwise keep existing
                    let isCurrentApple = isAppleSource(result.source)
                    
                    existing = MDMPayloadRecord(
                        id: existing.id,
                        name: isCurrentApple && !payload.name.isEmpty ? payload.name : (existing.name.isEmpty ? payload.name : existing.name),
                        payloadType: existing.payloadType,
                        category: isCurrentApple ? (payload.category ?? existing.category) : (existing.category ?? payload.category),
                        platforms: mergedPlatforms,
                        introduced: isCurrentApple ? (payload.introduced ?? existing.introduced) : (existing.introduced ?? payload.introduced),
                        deprecated: isCurrentApple ? (payload.deprecated ?? existing.deprecated) : (existing.deprecated ?? payload.deprecated),
                        sources: mergedSources,
                        summary: isCurrentApple ? (payload.summary ?? existing.summary) : (existing.summary ?? payload.summary),
                        discussion: isCurrentApple ? (payload.discussion ?? existing.discussion) : (existing.discussion ?? payload.discussion),
                        profileExample: isCurrentApple ? (payload.profileExample ?? existing.profileExample) : (existing.profileExample ?? payload.profileExample),
                        profileExampleSyntax: isCurrentApple ? (payload.profileExampleSyntax ?? existing.profileExampleSyntax) : (existing.profileExampleSyntax ?? payload.profileExampleSyntax)
                    )
                    payloadIndex[payload.payloadType] = existing
                } else {
                    payloadIndex[payload.payloadType] = payload
                }
            }

            for key in result.keys {
                if var existing = keyIndex[key.id] {
                    let mergedSources = Array(Set(existing.sources + key.sources)).sorted { sortSource($0) < sortSource($1) }
                    let mergedPlatforms = Array(Set(existing.platforms + key.platforms)).sorted()
                    
                    // If current is Apple source, prefer its values; otherwise keep existing
                    let isCurrentApple = isAppleSource(result.source)
                    
                    existing = MDMKeyRecord(
                        id: existing.id,
                        key: existing.key,
                        keyPath: existing.keyPath,
                        payloadType: existing.payloadType,
                        payloadName: isCurrentApple ? (key.payloadName ?? existing.payloadName) : (existing.payloadName ?? key.payloadName),
                        platforms: mergedPlatforms,
                        sources: mergedSources,
                        introduced: isCurrentApple ? (key.introduced ?? existing.introduced) : (existing.introduced ?? key.introduced),
                        deprecated: isCurrentApple ? (key.deprecated ?? existing.deprecated) : (existing.deprecated ?? key.deprecated),
                        publicationDate: isCurrentApple ? (key.publicationDate ?? existing.publicationDate) : (existing.publicationDate ?? key.publicationDate),
                        keyType: isCurrentApple ? (key.keyType ?? existing.keyType) : (existing.keyType ?? key.keyType),
                        keyDescription: isCurrentApple ? (key.keyDescription ?? existing.keyDescription) : (existing.keyDescription ?? key.keyDescription),
                        required: isCurrentApple ? (key.required ?? existing.required) : (existing.required ?? key.required),
                        defaultValue: isCurrentApple ? (key.defaultValue ?? existing.defaultValue) : (existing.defaultValue ?? key.defaultValue),
                        possibleValues: isCurrentApple ? (key.possibleValues ?? existing.possibleValues) : (existing.possibleValues ?? key.possibleValues)
                    )
                    keyIndex[key.id] = existing
                } else {
                    keyIndex[key.id] = key
                }
            }
        }

        return (payloads: Array(payloadIndex.values), keys: Array(keyIndex.values))
    }

    private func isAppleSource(_ source: MDMSource) -> Bool {
        source == .appleDeviceManagement || source == .appleDeveloperDocumentation
    }

    private func sortSource(_ source: MDMSource) -> Int {
        // Apple sources come first in sorting
        switch source {
        case .appleDeviceManagement: return 0
        case .appleDeveloperDocumentation: return 1
        case .profileCreator: return 2
        case .rtroutonProfiles: return 3
        }
    }

    private func isAutoRefreshEnabled() -> Bool {
        // Default to true if never set
        if UserDefaults.standard.object(forKey: "autoRefreshEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
    }
    
    private func enabledSourcesFromDefaults() -> Set<MDMSource> {
        let key = "mdmEnabledSources"
        if let raw = UserDefaults.standard.array(forKey: key) as? [String] {
            let sources = raw.compactMap { rawValue -> MDMSource? in
                if let source = MDMSource(rawValue: rawValue) {
                    return source
                }

                switch rawValue {
                case "ProfileCreator", "profileCreator":
                    return .profileCreator
                default:
                    return nil
                }
            }
            if !sources.isEmpty { return Set(sources) }
        }
        return [.appleDeviceManagement, .appleDeveloperDocumentation]
    }
}

struct MDMBackgroundAgentStatus {
    let isEnabled: Bool
    let message: String
}

actor MDMMenuBarLoginItemService {
    static let shared = MDMMenuBarLoginItemService()

    #if os(macOS)
    func configure(enabled: Bool) -> MDMBackgroundAgentStatus {
        let service = loginItemService()

        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            let action = enabled ? "enable" : "disable"
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Could not \(action) login item helper: \(error.localizedDescription). Ensure Differ is in /Applications and signed."
            )
        }

        return status()
    }

    func status() -> MDMBackgroundAgentStatus {
        let service = loginItemService()
        switch service.status {
        case .enabled:
            return MDMBackgroundAgentStatus(
                isEnabled: true,
                message: "Always-on login item helper is active and running in the menu bar."
            )
        case .requiresApproval:
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Login item helper requires approval in System Settings > General > Login Items."
            )
        case .notRegistered:
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Login item helper is disabled."
            )
        case .notFound:
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Login item helper app could not be found. Reinstall Differ in /Applications."
            )
        @unknown default:
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Login item helper status is unknown."
            )
        }
    }

    private func loginItemService() -> SMAppService {
        let hostBundleID = Bundle.main.bundleIdentifier ?? "com.NotMoby.differ.app"
        let helperBundleID = "\(hostBundleID).helper"
        return SMAppService.loginItem(identifier: helperBundleID)
    }
    #else
    func configure(enabled: Bool) -> MDMBackgroundAgentStatus {
        MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Login item helper is only supported on macOS"
        )
    }

    func status() -> MDMBackgroundAgentStatus {
        MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Login item helper is only supported on macOS"
        )
    }
    #endif
}

actor MDMBackgroundAgentService {
    static let shared = MDMBackgroundAgentService()

    #if os(macOS)
    private let launchAgentLabel = "com.differ.app.mdmrefresh.agent"
    private let backgroundRefreshArgument = "--mdm-background-refresh-agent"
    private let refreshInterval: Int = 24 * 60 * 60

    func runNow() -> MDMBackgroundAgentStatus {
        guard let plistURL = launchAgentURL() else {
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Could not resolve LaunchAgents directory"
            )
        }

        guard FileManager.default.fileExists(atPath: plistURL.path) else {
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Launch agent is not installed. Enable Daily launch agent first."
            )
        }

        let domain = "gui/\(getuid())"
        let target = "\(domain)/\(launchAgentLabel)"

        if launchctl(["kickstart", "-k", target]) {
            return MDMBackgroundAgentStatus(
                isEnabled: true,
                message: "Triggered background refresh run. Check timeline in a moment."
            )
        }

        let bootstrapped = launchctl(["bootstrap", domain, plistURL.path])
        if bootstrapped, launchctl(["kickstart", "-k", target]) {
            return MDMBackgroundAgentStatus(
                isEnabled: true,
                message: "Triggered background refresh run. Check timeline in a moment."
            )
        }

        return MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Could not start launch agent run with launchctl."
        )
    }

    func configure(enabled: Bool) -> MDMBackgroundAgentStatus {
        guard let plistURL = launchAgentURL() else {
            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Could not resolve LaunchAgents directory"
            )
        }

        let domain = "gui/\(getuid())"
        if enabled {
            guard let executablePath = Bundle.main.executableURL?.path else {
                return MDMBackgroundAgentStatus(
                    isEnabled: false,
                    message: "Could not resolve app executable path for launch agent"
                )
            }

            do {
                try writeLaunchAgentPlist(executablePath: executablePath, to: plistURL)
            } catch {
                return MDMBackgroundAgentStatus(
                    isEnabled: false,
                    message: "Failed to write launch agent: \(error.localizedDescription)"
                )
            }

            _ = launchctl(["bootout", domain, plistURL.path])
            let bootstrapped = launchctl(["bootstrap", domain, plistURL.path])
            if bootstrapped {
                _ = launchctl(["enable", "\(domain)/\(launchAgentLabel)"])
                _ = launchctl(["kickstart", "-k", "\(domain)/\(launchAgentLabel)"])
                return MDMBackgroundAgentStatus(
                    isEnabled: true,
                    message: "Daily background update agent is active"
                )
            }

            return MDMBackgroundAgentStatus(
                isEnabled: false,
                message: "Launch agent file created, but launchctl bootstrap failed"
            )
        }

        _ = launchctl(["bootout", domain, plistURL.path])
        try? FileManager.default.removeItem(at: plistURL)
        return MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Daily background update agent is disabled"
        )
    }

    private func launchAgentURL() -> URL? {
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }

        let launchAgentsURL = libraryURL.appendingPathComponent("LaunchAgents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: launchAgentsURL.path) {
            try? FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        }
        return launchAgentsURL.appendingPathComponent("\(launchAgentLabel).plist")
    }

    private func writeLaunchAgentPlist(executablePath: String, to url: URL) throws {
        let outputPath = logFilePath(filename: "mdm_background_agent.log")
        let errorPath = logFilePath(filename: "mdm_background_agent.error.log")

        let plist: [String: Any] = [
            "Label": launchAgentLabel,
            "ProgramArguments": [executablePath, backgroundRefreshArgument],
            "StartInterval": refreshInterval,
            "RunAtLoad": true,
            "StandardOutPath": outputPath,
            "StandardErrorPath": errorPath
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: url, options: .atomic)
    }

    private func logFilePath(filename: String) -> String {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Differ", isDirectory: true)

        if let appSupport {
            if !FileManager.default.fileExists(atPath: appSupport.path) {
                try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            }
            return appSupport.appendingPathComponent(filename).path
        }

        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)
            .path
    }

    private func launchctl(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    #else
    func configure(enabled: Bool) -> MDMBackgroundAgentStatus {
        MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Daily launch agent is only supported on macOS"
        )
    }

    func runNow() -> MDMBackgroundAgentStatus {
        MDMBackgroundAgentStatus(
            isEnabled: false,
            message: "Daily launch agent is only supported on macOS"
        )
    }
    #endif
}
