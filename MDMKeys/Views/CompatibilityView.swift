import SwiftUI

struct CompatibilityView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedPlatform: String = "macOS"
    @State private var selectedVersion: String = "15.0"
    @State private var searchText = ""
    @State private var selectedKey: MDMKeyRecord? = nil
    
    private let platforms = ["iOS", "iPadOS", "macOS", "tvOS", "visionOS", "watchOS"]
    
    private var versionOptions: [String] {
        switch selectedPlatform {
        case "macOS":
            return ["15.0", "14.0", "13.0", "12.0", "11.0", "10.15", "10.14", "10.13"]
        case "iOS", "iPadOS":
            return ["18.0", "17.0", "16.0", "15.0", "14.0", "13.0", "12.0", "11.0"]
        case "watchOS":
            return ["11.0", "10.0", "9.0", "8.0", "7.0", "6.0"]
        case "tvOS":
            return ["18.0", "17.0", "16.0", "15.0", "14.0", "13.0"]
        case "visionOS":
            return ["2.0", "1.0"]
        default:
            return ["15.0"]
        }
    }
    
    private var compatibleKeys: [MDMKeyRecord] {
        appState.mdmKeys.filter { key in
            // Platform filter
            guard key.platforms.contains(selectedPlatform) else { return false }
            
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
            // Platform filter
            guard key.platforms.contains(selectedPlatform) else { return false }
            
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
                    
                    Picker("Version", selection: $selectedVersion) {
                        ForEach(versionOptions, id: \.self) { version in
                            Text(version).tag(version)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Filter")
                }
                
                Section {
                    ForEach(compatibleKeys, id: \.id) { key in
                        NavigationLink(value: key) {
                            KeyRowView(key: key)
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
                
                if !incompatibleKeys.isEmpty {
                    Section {
                        ForEach(incompatibleKeys, id: \.id) { key in
                            NavigationLink(value: key) {
                                KeyRowView(key: key)
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
            .navigationTitle("Compatibility")
            .searchable(text: $searchText, prompt: "Search keys...")
            .navigationDestination(for: MDMKeyRecord.self) { key in
                KeyDetailView(key: key)
            }
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
        // Convert version string to comparable number (e.g., "14.5" -> 14.5)
        let cleaned = version.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        let components = cleaned.split(separator: ".")
        if components.count >= 2 {
            let major = Double(components[0]) ?? 0
            let minor = Double(components[1]) ?? 0
            return major + (minor / 10.0)
        } else if let major = Double(cleaned) {
            return major
        }
        return 0
    }
}
