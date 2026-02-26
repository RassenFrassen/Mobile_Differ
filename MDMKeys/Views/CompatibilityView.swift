import SwiftUI

/// Compatibility checker for MDM keys across different OS versions.
///
/// **Dynamic Version Detection:**
/// This view automatically extracts OS versions from the MDM catalog by scanning
/// the "introduced" and "deprecated" fields of all keys. When Apple releases new
/// versions (e.g., 26.4, 26.5, or 27.0 beta), the app will automatically detect
/// and include them in the version picker as soon as the catalog is refreshed.
///
/// **Baseline Versions:**
/// The app maintains baseline versions (updated from https://support.apple.com/en-us/100100)
/// and merges them with dynamically discovered versions to ensure comprehensive coverage.
///
/// **Version Support:**
/// - Point releases: 26.3, 26.4, 26.5, etc.
/// - Major releases: 27.0, 28.0, etc.
/// - Beta versions: Preserved with full details (e.g., "27.0 Beta 1", "27.0 beta 2 (24A5279h)")
/// - Build numbers: Captured and displayed when available (e.g., "(24A5279h)")
///
/// **macOS naming history:**
/// - macOS Tahoe: 26.x | macOS Sequoia: 15.x | macOS Sonoma: 14.x
/// - macOS Ventura: 13.x | macOS Monterey: 12.x | macOS Big Sur: 11.x
struct CompatibilityView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedPlatform: String = "iOS"
    @State private var selectedMajor: Int = 26
    @State private var selectedMinor: Int = 3
    @State private var selectedPatch: Int = 0
    @State private var selectedBeta: String? = nil
    @State private var searchText = ""
    @State private var selectedKey: MDMKeyRecord? = nil
    @State private var showCompatibilityFilter: CompatibilityFilter = .all
    
    enum CompatibilityFilter: String, CaseIterable {
        case all = "All"
        case compatible = "Compatible"
        case incompatible = "Incompatible"
    }
    
    private var selectedVersion: String {
        var version = "\(selectedMajor).\(selectedMinor)"
        if selectedPatch > 0 {
            version += ".\(selectedPatch)"
        }
        if let beta = selectedBeta {
            version += " \(beta)"
        }
        return version
    }
    
    private let platforms = ["iOS", "iPadOS", "macOS", "tvOS", "visionOS", "watchOS"]
    
    private var versionOptions: [String] {
        // Get versions dynamically from catalog data
        let dynamicVersions = extractVersionsFromCatalog(for: selectedPlatform)
        
        // Merge with baseline versions
        let baselineVersions = baselineVersionOptions(for: selectedPlatform)
        
        // Combine and deduplicate
        let allVersions = Set(dynamicVersions + baselineVersions)
        
        // Sort by version number (descending)
        return allVersions.sorted { compareVersions($0, $1) }
    }
    
    // MARK: - Three-Picker Version System
    
    /// All available major versions for the selected platform
    private var availableMajorVersions: [Int] {
        let allVersions = versionOptions
        var majors = Set<Int>()
        
        for version in allVersions {
            let parsed = parseVersion(version)
            if let major = parsed.numbers.first {
                majors.insert(major)
            }
        }
        
        return majors.sorted(by: >)
    }
    
    /// Available minor versions for the currently selected major version
    private var availableMinorVersions: [Int] {
        let allVersions = versionOptions
        var minors = Set<Int>()
        
        for version in allVersions {
            let parsed = parseVersion(version)
            if parsed.numbers.count >= 2,
               parsed.numbers[0] == selectedMajor {
                minors.insert(parsed.numbers[1])
            }
        }
        
        let sorted = minors.sorted(by: >)
        
        // Validate that selectedMinor is in the available list
        if !sorted.isEmpty && !sorted.contains(selectedMinor) {
            // This will be called in the computed property, so we can't mutate state here
            // The onChange handlers will handle resetting
        }
        
        return sorted
    }
    
    /// Available patch versions for the currently selected major.minor version
    private var availablePatchVersions: [Int] {
        let allVersions = versionOptions
        var patches = Set<Int>()
        
        for version in allVersions {
            let parsed = parseVersion(version)
            
            // Match major and minor
            guard parsed.numbers.count >= 2,
                  parsed.numbers[0] == selectedMajor,
                  parsed.numbers[1] == selectedMinor else { continue }
            
            // If version has 3 parts (e.g., "26.3.1"), add the patch number
            if parsed.numbers.count >= 3 {
                patches.insert(parsed.numbers[2])
            } else {
                // If version is only "major.minor" (e.g., "26.3"), treat as .0
                patches.insert(0)
            }
        }
        
        // If no patches found, default to [0]
        if patches.isEmpty {
            patches.insert(0)
        }
        
        return patches.sorted(by: >)
    }
    
    /// Available beta versions for the currently selected version (major.minor.patch)
    private var availableBetaVersions: [String] {
        let allVersions = versionOptions
        var betas: [String] = []
        
        // Add "Release" option (no beta)
        betas.append("Release")
        
        for version in allVersions {
            let parsed = parseVersion(version)
            
            // Check if this version matches our selected major.minor.patch
            guard parsed.numbers.count >= 2,
                  parsed.numbers[0] == selectedMajor,
                  parsed.numbers[1] == selectedMinor else { continue }
            
            // Check patch match (if we have a patch version)
            if selectedPatch > 0 && parsed.numbers.count >= 3 {
                guard parsed.numbers[2] == selectedPatch else { continue }
            }
            
            // Extract beta tag if present
            if parsed.isBeta {
                // Extract the full beta string (e.g., "Beta 1", "beta 2 (24A5279h)")
                if let betaRange = version.range(of: #"(beta|Beta|alpha|Alpha|RC|rc)\s*\d+(?:\s*\([^)]+\))?"#, options: .regularExpression) {
                    let betaString = String(version[betaRange])
                    betas.append(betaString)
                }
            }
        }
        
        return betas
    }
    
    private func baselineVersionOptions(for platform: String) -> [String] {
        // Baseline versions - updated periodically from https://support.apple.com/en-us/100100
        // and https://support.apple.com/en-gb/122868
        switch platform {
        case "macOS":
            // macOS: Tahoe (26), Sequoia (15), Sonoma (14), Ventura (13), Monterey (12)
            return [
                "26.3", "26.2", "26.1", "26.0.1", "26.0",
                "15.7", "15.6", "15.5", "15.4", "15.3", "15.2", "15.1", "15.0",
                "14.8", "14.7", "14.6", "14.5", "14.4", "14.3", "14.2", "14.1", "14.0",
                "13.7", "13.6", "13.5", "13.4", "13.3", "13.2", "13.1", "13.0",
                "12.7", "12.6", "12.5", "12.4", "12.3", "12.2", "12.1", "12.0",
                "11.0", "10.15"
            ]
        case "iOS", "iPadOS":
            return [
                "26.3", "26.2", "26.1", "26.0.1", "26.0",
                "18.7", "18.6", "18.5", "18.4", "18.3", "18.2", "18.1", "18.0",
                "17.7", "17.6", "17.5", "17.4", "17.3", "17.2", "17.1", "17.0",
                "16.7", "16.6", "16.5", "16.4", "16.3", "16.2", "16.1", "16.0",
                "15.8", "15.7", "15.6", "15.5", "15.4", "15.3", "15.2", "15.1", "15.0",
                "14.0", "13.0", "12.0"
            ]
        case "watchOS":
            return [
                "26.3", "26.2", "26.1", "26.0",
                "11.0", "10.0", "9.0", "8.0", "7.0"
            ]
        case "tvOS":
            return [
                "26.3", "26.2", "26.1", "26.0",
                "18.0", "17.0", "16.0", "15.0", "14.0"
            ]
        case "visionOS":
            return [
                "26.3", "26.2", "26.1", "26.0",
                "2.0", "1.0"
            ]
        default:
            return ["26.3"]
        }
    }
    
    private func extractVersionsFromCatalog(for platform: String) -> [String] {
        var versions = Set<String>()
        
        // Extract from "introduced" field
        for key in appState.mdmKeys {
            guard key.platforms.contains(where: { normalizePlatform($0) == normalizePlatform(platform) }) else { continue }
            
            if let introduced = key.introduced, !introduced.isEmpty, introduced != "n/a" {
                if let version = extractVersionNumber(from: introduced, platform: platform) {
                    versions.insert(version)
                }
            }
            
            if let deprecated = key.deprecated, !deprecated.isEmpty {
                if let version = extractVersionNumber(from: deprecated, platform: platform) {
                    versions.insert(version)
                }
            }
        }
        
        return Array(versions)
    }
    
    private func extractVersionNumber(from text: String, platform: String) -> String? {
        // Extract full version including beta tags
        // Examples:
        // - "26.4" -> "26.4"
        // - "27.0 Beta 1" -> "27.0 Beta 1"
        // - "iOS 27.0 beta 2 (24A5279h)" -> "27.0 beta 2 (24A5279h)"
        // - "macOS 15.7" -> "15.7"
        
        // Pattern: version number, optional beta/alpha/rc label, optional build number
        let pattern = #"(\d+\.\d+(?:\.\d+)?)\s*(?:(beta|Beta|alpha|Alpha|RC|rc)\s*(\d+))?\s*(?:\(([^)]+)\))?"#
        
        if let match = text.range(of: pattern, options: .regularExpression) {
            let matchedText = String(text[match]).trimmingCharacters(in: .whitespaces)
            
            // Validate that the version makes sense for the platform
            if let versionNumber = parseVersion(matchedText).numbers.first {
                if !isValidVersionForPlatform(versionNumber, platform: platform) {
                    return nil
                }
            }
            
            return matchedText
        }
        
        // Fallback: just extract base version
        let simplePattern = #"\d+\.\d+(?:\.\d+)?"#
        if let range = text.range(of: simplePattern, options: .regularExpression) {
            let versionString = String(text[range])
            
            // Validate that the version makes sense for the platform
            if let versionNumber = parseVersion(versionString).numbers.first {
                if !isValidVersionForPlatform(versionNumber, platform: platform) {
                    return nil
                }
            }
            
            return versionString
        }
        
        return nil
    }
    
    /// Validates that a major version number makes sense for the given platform
    private func isValidVersionForPlatform(_ majorVersion: Int, platform: String) -> Bool {
        switch platform {
        case "macOS":
            // macOS has never had versions 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
            // Valid ranges: 10.x, 11-15, 26+
            if majorVersion >= 16 && majorVersion <= 25 {
                return false
            }
            return true
        case "iOS", "iPadOS":
            // iOS/iPadOS started at version 1 and increments sequentially
            // Currently at version 18, with 26+ being future versions
            return true
        case "watchOS":
            // watchOS versions: 1-11, 26+
            if majorVersion >= 12 && majorVersion <= 25 {
                return false
            }
            return true
        case "tvOS":
            // tvOS versions: 9-18, 26+
            // Note: tvOS started at version 9
            if majorVersion >= 19 && majorVersion <= 25 {
                return false
            }
            return true
        case "visionOS":
            // visionOS versions: 1-2, 26+
            if majorVersion >= 3 && majorVersion <= 25 {
                return false
            }
            return true
        default:
            return true
        }
    }
    
    private func normalizePlatform(_ platform: String) -> String {
        let lower = platform.lowercased()
        if lower.contains("ipad") { return "iPadOS" }
        if lower.contains("iphone") || lower.contains("ios") { return "iOS" }
        if lower.contains("mac") { return "macOS" }
        if lower.contains("watch") { return "watchOS" }
        if lower.contains("tv") { return "tvOS" }
        if lower.contains("vision") { return "visionOS" }
        return platform
    }

    /// Check if a key's platforms match the selected platform
    /// iOS and iPadOS are treated as interchangeable since Apple treats them similarly
    private func keyMatchesPlatform(_ key: MDMKeyRecord, _ selectedPlatform: String) -> Bool {
        // Direct match
        if key.platforms.contains(selectedPlatform) {
            return true
        }

        // iOS/iPadOS cross-compatibility: if selected is iPadOS, accept iOS keys (and vice versa)
        if selectedPlatform == "iPadOS" && key.platforms.contains("iOS") {
            return true
        }
        if selectedPlatform == "iOS" && key.platforms.contains("iPadOS") {
            return true
        }

        return false
    }
    
    private func compareVersions(_ v1: String, _ v2: String) -> Bool {
        // Compare version strings numerically with beta support
        // Examples:
        // "27.0" > "27.0 Beta 2" > "27.0 Beta 1" > "26.4" > "26.3"
        
        let parsed1 = parseVersion(v1)
        let parsed2 = parseVersion(v2)
        
        // Compare base version numbers first
        for i in 0..<max(parsed1.numbers.count, parsed2.numbers.count) {
            let p1 = i < parsed1.numbers.count ? parsed1.numbers[i] : 0
            let p2 = i < parsed2.numbers.count ? parsed2.numbers[i] : 0
            
            if p1 != p2 {
                return p1 > p2
            }
        }
        
        // Same base version - check beta/release status
        // Release versions come before beta versions
        if parsed1.isBeta != parsed2.isBeta {
            return !parsed1.isBeta // Release (not beta) comes first
        }
        
        // Both are beta or both are release - compare beta numbers
        if parsed1.isBeta && parsed2.isBeta {
            return parsed1.betaNumber > parsed2.betaNumber
        }
        
        // If everything is equal, compare alphabetically (for build numbers)
        return v1 > v2
    }
    
    private func parseVersion(_ version: String) -> (numbers: [Int], isBeta: Bool, betaNumber: Int) {
        // Extract base version numbers (e.g., "27.0.1 Beta 12" -> [27, 0, 1])
        // Handles versions like: 15.7.3, 26.4, 27.0 Beta 15, etc.
        
        // First, extract the base version (before any beta/alpha/rc text)
        let versionPattern = #"(\d+)(?:\.(\d+))?(?:\.(\d+))?"#
        var numbers: [Int] = []
        
        if let match = version.range(of: versionPattern, options: .regularExpression) {
            let versionPart = String(version[match])
            let components = versionPart.split(separator: ".")
            numbers = components.compactMap { Int($0) }
        }
        
        // Check if it's a beta version
        let lowerVersion = version.lowercased()
        let isBeta = lowerVersion.contains("beta") || 
                     lowerVersion.contains("alpha") ||
                     lowerVersion.contains("rc")
        
        // Extract beta number if present (can be 1-99+)
        var betaNumber = 0
        if isBeta {
            // Pattern supports double-digit beta numbers: "Beta 1", "Beta 12", "beta 15"
            let betaPattern = #"(?:beta|alpha|rc)\s*(\d{1,2})"#
            if let match = version.range(of: betaPattern, options: [.regularExpression, .caseInsensitive]) {
                let betaText = String(version[match])
                if let range = betaText.range(of: #"\d{1,2}"#, options: .regularExpression) {
                    betaNumber = Int(betaText[range]) ?? 0
                }
            }
        }
        
        return (numbers, isBeta, betaNumber)
    }
    
    private var compatibleKeys: [MDMKeyRecord] {
        appState.mdmKeys.filter { key in
            // Platform filter (iOS and iPadOS are treated as compatible)
            guard keyMatchesPlatform(key, selectedPlatform) else { return false }
            
            // Version filter - key must be introduced before or at selected version
            if let introduced = key.introduced, !introduced.isEmpty && introduced != "n/a" {
                if !isVersionCompatible(introduced: introduced, targetVersion: selectedVersion) {
                    return false
                }
            }
            
            // Not deprecated, or deprecated after selected version
            if let deprecated = key.deprecated, !deprecated.isEmpty {
                if !isVersionStillSupported(deprecated: deprecated, targetVersion: selectedVersion) {
                    return false
                }
            }
            
            // Search filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                return key.key.lowercased().contains(query)
                    || key.keyPath.lowercased().contains(query)
                    || (key.payloadName?.lowercased().contains(query) ?? false)
            }
            
            return true
        }
    }
    
    private var incompatibleKeys: [MDMKeyRecord] {
        appState.mdmKeys.filter { key in
            // Platform filter (iOS and iPadOS are treated as compatible)
            guard keyMatchesPlatform(key, selectedPlatform) else { return false }
            
            // Check if it's NOT compatible
            if let introduced = key.introduced, !introduced.isEmpty && introduced != "n/a" {
                if !isVersionCompatible(introduced: introduced, targetVersion: selectedVersion) {
                    return true
                }
            }
            
            if let deprecated = key.deprecated, !deprecated.isEmpty {
                if !isVersionStillSupported(deprecated: deprecated, targetVersion: selectedVersion) {
                    return true
                }
            }
            
            return false
        }.filter { key in
            // Apply search filter
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return key.key.lowercased().contains(query)
                || key.keyPath.lowercased().contains(query)
                || (key.payloadName?.lowercased().contains(query) ?? false)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform).tag(platform)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPlatform) { _, _ in
                        // Reset to first available version when platform changes
                        if let firstMajor = availableMajorVersions.first {
                            selectedMajor = firstMajor
                        }
                        if let firstMinor = availableMinorVersions.first {
                            selectedMinor = firstMinor
                        }
                        selectedPatch = 0
                        selectedBeta = nil
                    }
                    
                    HStack(spacing: 4) {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        // Major version picker
                        Picker("Major", selection: $selectedMajor) {
                            ForEach(availableMajorVersions, id: \.self) { major in
                                Text("\(major)").tag(major)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(minWidth: 40)
                        .fixedSize()
                        .onChange(of: selectedMajor) { _, _ in
                            // Reset minor/patch when major changes
                            if let firstMinor = availableMinorVersions.first {
                                selectedMinor = firstMinor
                            }
                            selectedPatch = 0
                            selectedBeta = nil
                        }
                        
                        Text(".")
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        
                        // Minor version picker
                        Picker("Minor", selection: $selectedMinor) {
                            ForEach(availableMinorVersions, id: \.self) { minor in
                                Text("\(minor)").tag(minor)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(minWidth: 40)
                        .fixedSize()
                        .onChange(of: selectedMinor) { _, _ in
                            // Reset patch when minor changes
                            selectedPatch = 0
                            selectedBeta = nil
                        }
                        
                        // Always show patch picker
                        Text(".")
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        
                        Picker("Patch", selection: $selectedPatch) {
                            ForEach(availablePatchVersions, id: \.self) { patch in
                                Text("\(patch)").tag(patch)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(minWidth: 40)
                        .fixedSize()
                        .onChange(of: selectedPatch) { _, _ in
                            selectedBeta = nil
                        }
                    }
                    
                    // Beta version picker (only show if beta versions exist)
                    if availableBetaVersions.count > 1 {
                        Picker("Release Type", selection: Binding(
                            get: { selectedBeta ?? "Release" },
                            set: { newValue in
                                selectedBeta = newValue == "Release" ? nil : newValue
                            }
                        )) {
                            ForEach(availableBetaVersions, id: \.self) { beta in
                                Text(beta).tag(beta)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Compatibility filter
                    Picker("Show", selection: $showCompatibilityFilter) {
                        ForEach(CompatibilityFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Filter")
                }
                
                // Show sections based on filter selection
                if showCompatibilityFilter == .all || showCompatibilityFilter == .compatible {
                    Section {
                        ForEach(compatibleKeys, id: \.id) { key in
                            NavigationLink(value: key) {
                                KeyRowView(key: key, isFavorite: false)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Compatible (\(compatibleKeys.count))")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                if showCompatibilityFilter == .all || showCompatibilityFilter == .incompatible {
                    if !incompatibleKeys.isEmpty {
                        Section {
                            ForEach(incompatibleKeys, id: \.id) { key in
                                NavigationLink(value: key) {
                                    KeyRowView(key: key, isFavorite: false)
                                        .opacity(0.6)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Not Available (\(incompatibleKeys.count))")
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Compatibility")
            .searchable(text: $searchText, prompt: "Search keys...")
            .navigationDestination(for: MDMKeyRecord.self) { key in
                KeyDetailView(key: key)
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 450, max: 600)
        } detail: {
            if let key = selectedKey {
                KeyDetailView(key: key)
            } else {
                ContentUnavailableView(
                    "Select a Key",
                    systemImage: "checkmark.shield",
                    description: Text("Choose a key to view compatibility details.")
                )
            }
        }
    }
    
    private func isVersionCompatible(introduced: String, targetVersion: String) -> Bool {
        // Simple version comparison - key must be introduced at or before target version
        let introducedNum = versionToNumber(introduced)
        let targetNum = versionToNumber(targetVersion)
        return introducedNum <= targetNum
    }
    
    private func isVersionStillSupported(deprecated: String, targetVersion: String) -> Bool {
        // Key is still supported if deprecated version is after target version
        let deprecatedNum = versionToNumber(deprecated)
        let targetNum = versionToNumber(targetVersion)
        return deprecatedNum > targetNum
    }
    
    private func versionToNumber(_ version: String) -> Double {
        // Convert version string to comparable number with beta support
        // 
        // Versioning scheme supports:
        // - Two-digit versions: 27.0, 26.4
        // - Three-digit versions: 15.7.3, 14.8.1 (security patches)
        // - Beta versions: 27.0 Beta 1, 27.0 Beta 12, 27.0 Beta 15
        //
        // Conversion examples:
        // "27.0"          -> 27.00000 (release)
        // "15.7.3"        -> 15.07003 (patch release)
        // "27.0 Beta 1"   -> 26.99901 (beta 1, less than release)
        // "27.0 Beta 12"  -> 26.99912 (beta 12, greater than beta 1)
        //
        // This ensures proper ordering:
        // 27.0 > 27.0 Beta 15 > 27.0 Beta 12 > 27.0 Beta 1 > 26.4 > 15.7.3 > 15.7.2
        
        let parsed = parseVersion(version)
        
        // Calculate base version number with proper precision
        var versionNumber: Double = 0
        
        if parsed.numbers.count >= 1 {
            let major = Double(parsed.numbers[0])
            versionNumber = major
            
            // Add minor version (e.g., 15.7 = 15 + 0.07)
            if parsed.numbers.count >= 2 {
                let minor = Double(parsed.numbers[1])
                versionNumber += (minor / 100.0)
                
                // Add patch version (e.g., 15.7.3 = 15.07 + 0.00003)
                if parsed.numbers.count >= 3 {
                    let patch = Double(parsed.numbers[2])
                    versionNumber += (patch / 100000.0)
                }
            }
        }
        
        // Beta versions are slightly less than release versions
        if parsed.isBeta {
            // Subtract based on beta number: Beta 1 = -0.00099, Beta 12 = -0.00088
            // Formula: -0.001 + (betaNumber / 100000)
            // This ensures: Release > Beta 15 > Beta 12 > Beta 2 > Beta 1
            let betaOffset = 0.001 - (Double(parsed.betaNumber) / 100000.0)
            versionNumber -= betaOffset
        }
        
        return versionNumber
    }
}
