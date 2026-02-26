import SwiftUI
import ZIPFoundation

/// Displays an icon for a payload or key based on its type and sources
struct PayloadIcon: View {
    let payloadType: String
    let sources: [MDMSource]
    
    @State private var appIconImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let appIconImage {
                // Use actual app icon image
                Image(uiImage: appIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                // Fallback to SF Symbol
                Circle()
                    .fill(iconColor.opacity(0.15))
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            
            // Multiple sources indicator
            if sources.count > 1 {
                Circle()
                    .fill(.blue)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 2, y: 2)
            }
        }
        .task {
            await loadAppIcon()
        }
    }
    
    private func loadAppIcon() async {
        // Try to load the actual app icon from embedded bundles
        let iconFileName = "\(payloadType).png"
        let iconSubdirs = ["ManagedPreferencesApplications", "ManifestsApple", "ManagedPreferencesApple"]
        
        // First, try to load from Application Support (extracted bundles)
        if let appSupportDir = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) {
            // Possible paths where icons might be extracted
            let possibleBasePaths = [
                // Direct extraction
                appSupportDir.appendingPathComponent("MDMKeys/Bundles/ProfileManifests-ProfileManifests/Icons", isDirectory: true),
                // With nested directory from ZIP
                appSupportDir.appendingPathComponent("MDMKeys/Bundles/ProfileManifests-ProfileManifests/ProfileManifests-ProfileManifests/Icons", isDirectory: true)
            ]
            
            for basePath in possibleBasePaths {
                for subdir in iconSubdirs {
                    let iconPath = basePath
                        .appendingPathComponent(subdir, isDirectory: true)
                        .appendingPathComponent(iconFileName)
                    
                    if let image = UIImage(contentsOfFile: iconPath.path) {
                        appIconImage = image
                        return
                    }
                }
            }
        }
        
        // Fallback: Try to extract icon directly from the ZIP in the app bundle
        guard let zipURL = Bundle.main.url(forResource: "ProfileManifests-ProfileManifests", withExtension: "zip") else {
            return
        }
        
        // Try to read the icon directly from the ZIP without full extraction
        await extractIconFromZip(zipURL: zipURL, iconFileName: iconFileName, iconSubdirs: iconSubdirs)
    }
    
    private func extractIconFromZip(zipURL: URL, iconFileName: String, iconSubdirs: [String]) async {
        guard let archive = Archive(url: zipURL, accessMode: .read) else { return }
        
        for subdir in iconSubdirs {
            let iconEntryPath = "ProfileManifests-ProfileManifests/Icons/\(subdir)/\(iconFileName)"
            
            guard let entry = archive[iconEntryPath] else { continue }
            
            var imageData = Data()
            _ = try? archive.extract(entry) { data in
                imageData.append(data)
            }
            
            if let image = UIImage(data: imageData) {
                await MainActor.run {
                    appIconImage = image
                }
                return
            }
        }
    }
    
    private var iconName: String {
        let type = payloadType.lowercased()
        
        // Third-party applications
        if type.contains("firefox") || type.contains("mozilla") {
            return "flame"
        }
        if type.contains("chrome") || type.contains("google") {
            return "circle.hexagongrid.circle"
        }
        if type.contains("privileges") {
            return "person.badge.shield.checkmark"
        }
        if type.contains("microsoft") || type.contains("outlook") {
            return "envelope.badge"
        }
        if type.contains("zoom") {
            return "video"
        }
        if type.contains("slack") {
            return "bubble.left.and.bubble.right"
        }
        if type.contains("munki") {
            return "shippingbox"
        }
        if type.contains("jamf") {
            return "shield.lefthalf.filled"
        }
        if type.contains("kandji") {
            return "cube.transparent"
        }
        if type.contains("mosyle") {
            return "square.grid.3x3.square"
        }
        if type.contains("addigy") {
            return "link.circle"
        }
        if type.contains("adobe") {
            return "paintbrush"
        }
        if type.contains("dropbox") {
            return "square.stack.3d.down.right"
        }
        if type.contains("onedrive") {
            return "cloud"
        }
        if type.contains("box") {
            return "shippingbox.circle"
        }
        if type.contains("git") {
            return "chevron.left.forwardslash.chevron.right"
        }
        if type.contains("docker") {
            return "square.stack.3d.up"
        }
        if type.contains("visual.studio") || type.contains("vscode") {
            return "chevron.left.forwardslash.chevron.right"
        }
        
        // Apple app-specific icons
        if type.contains("safari") {
            return "safari"
        }
        if type.contains("mail") && !type.contains("microsoft") {
            return "envelope"
        }
        if type.contains("calendar") {
            return "calendar"
        }
        if type.contains("contact") || type.contains("carddav") {
            return "person.crop.square"
        }
        if type.contains("finder") {
            return "folder"
        }
        if type.contains("messages") {
            return "message"
        }
        if type.contains("facetime") {
            return "video"
        }
        if type.contains("photos") {
            return "photo.stack"
        }
        if type.contains("music") || type.contains("itunes") {
            return "music.note"
        }
        if type.contains("appstore") || type.contains("app.store") {
            return "appstore"
        }
        if type.contains("wifi") || type.contains("wi-fi") {
            return "wifi"
        }
        if type.contains("vpn") {
            return "network"
        }
        if type.contains("certificate") || type.contains("cert") {
            return "checkmark.seal"
        }
        if type.contains("security") || type.contains("passcode") || type.contains("password") {
            return "lock.shield"
        }
        if type.contains("screensaver") {
            return "photo.on.rectangle"
        }
        if type.contains("firewall") {
            return "shield"
        }
        if type.contains("notification") {
            return "bell"
        }
        if type.contains("print") {
            return "printer"
        }
        if type.contains("bluetooth") {
            return "antenna.radiowaves.left.and.right"
        }
        if type.contains("airplay") {
            return "airplayvideo"
        }
        if type.contains("network") {
            return "network"
        }
        if type.contains("proxy") {
            return "arrow.triangle.2.circlepath"
        }
        if type.contains("ldap") {
            return "building.columns"
        }
        if type.contains("exchange") {
            return "arrow.left.arrow.right"
        }
        if type.contains("caldav") {
            return "calendar.badge.clock"
        }
        if type.contains("subscribed") {
            return "calendar.badge.plus"
        }
        if type.contains("web") || type.contains("webclip") {
            return "link"
        }
        if type.contains("font") {
            return "textformat"
        }
        if type.contains("applock") || type.contains("app.lock") {
            return "lock.app.dashed"
        }
        if type.contains("configuration") {
            return "gearshape"
        }
        if type.contains("energy") {
            return "bolt"
        }
        if type.contains("wallpaper") {
            return "photo"
        }
        if type.contains("accessibility") {
            return "accessibility"
        }
        if type.contains("dock") {
            return "dock.rectangle"
        }
        if type.contains("finder") {
            return "folder"
        }
        if type.contains("sso") || type.contains("single.sign") {
            return "person.badge.key"
        }
        if type.contains("kerberos") {
            return "ticket"
        }
        if type.contains("scep") {
            return "key"
        }
        if type.contains("dns") {
            return "server.rack"
        }
        if type.contains("content.filter") || type.contains("contentfilter") {
            return "shield.lefthalf.filled"
        }
        if type.contains("airprint") {
            return "printer.dotmatrix"
        }
        if type.contains("mdm") {
            return "gearshape.2"
        }
        if type.contains("app") || type.contains("application") {
            return "app"
        }
        if type.contains("domain") {
            return "globe"
        }
        if type.contains("directory") {
            return "folder.badge.gearshape"
        }
        if type.contains("activation") {
            return "sparkles"
        }
        if type.contains("identity") {
            return "person.text.rectangle"
        }
        if type.contains("restrictions") || type.contains("restriction") {
            return "hand.raised"
        }
        if type.contains("extension") {
            return "puzzlepiece.extension"
        }
        if type.contains("smb") {
            return "externaldrive.connected.to.line.below"
        }
        if type.contains("software.update") || type.contains("softwareupdate") {
            return "arrow.down.circle"
        }
        if type.contains("filevault") {
            return "lock.fill"
        }
        if type.contains("gatekeeper") {
            return "checkmark.shield.fill"
        }
        if type.contains("logging") {
            return "list.bullet.clipboard"
        }
        if type.contains("login") {
            return "rectangle.portrait.and.arrow.right"
        }
        if type.contains("globalpreferences") {
            return "globe.americas"
        }
        if type.contains("desktop") {
            return "desktopcomputer"
        }
        if type.contains("keyboard") {
            return "keyboard"
        }
        if type.contains("mouse") || type.contains("trackpad") {
            return "cursorarrow.click.2"
        }
        if type.contains("timezone") || type.contains("time.zone") {
            return "clock"
        }
        if type.contains("systemmigration") {
            return "arrow.triangle.2.circlepath.circle"
        }
        if type.contains("setup") {
            return "wrench.and.screwdriver"
        }
        
        // Default based on source
        if hasAppleSource {
            return "apple.logo"
        }
        if sources.contains(.profileCreator) {
            return "doc.text.magnifyingglass"
        }
        if sources.contains(.rtroutonProfiles) {
            return "person.fill"
        }
        
        // Generic fallback
        return "doc.text"
    }
    
    private var iconColor: Color {
        let type = payloadType.lowercased()
        
        // Third-party application colors
        if type.contains("firefox") || type.contains("mozilla") {
            return .orange
        }
        if type.contains("chrome") || type.contains("google") {
            return .blue
        }
        if type.contains("privileges") {
            return .green
        }
        if type.contains("microsoft") || type.contains("outlook") {
            return .blue
        }
        if type.contains("zoom") {
            return .blue
        }
        if type.contains("slack") {
            return .purple
        }
        if type.contains("munki") {
            return .orange
        }
        if type.contains("jamf") {
            return .indigo
        }
        if type.contains("kandji") {
            return .mint
        }
        if type.contains("mosyle") {
            return .cyan
        }
        if type.contains("addigy") {
            return .teal
        }
        if type.contains("adobe") {
            return .red
        }
        if type.contains("dropbox") {
            return .blue
        }
        if type.contains("onedrive") {
            return .blue
        }
        if type.contains("git") {
            return .orange
        }
        if type.contains("docker") {
            return .blue
        }
        
        // Apple app-specific colors
        if type.contains("safari") {
            return .blue
        }
        if type.contains("mail") && !type.contains("microsoft") {
            return .blue
        }
        if type.contains("calendar") {
            return .red
        }
        if type.contains("contact") || type.contains("carddav") {
            return .blue
        }
        if type.contains("finder") {
            return .blue
        }
        if type.contains("messages") {
            return .green
        }
        if type.contains("facetime") {
            return .green
        }
        if type.contains("photos") {
            return .blue
        }
        if type.contains("music") || type.contains("itunes") {
            return .red
        }
        if type.contains("appstore") || type.contains("app.store") {
            return .blue
        }
        if type.contains("wifi") {
            return .blue
        }
        if type.contains("vpn") {
            return .orange
        }
        if type.contains("certificate") || type.contains("cert") || type.contains("scep") {
            return .green
        }
        if type.contains("security") || type.contains("passcode") || type.contains("password") {
            return .red
        }
        if type.contains("firewall") {
            return .red
        }
        if type.contains("restrictions") {
            return .orange
        }
        if type.contains("mdm") {
            return .purple
        }
        if type.contains("app") {
            return .blue
        }
        if type.contains("filevault") {
            return .yellow
        }
        if type.contains("gatekeeper") {
            return .green
        }
        
        // Source-based colors
        if hasAppleSource {
            return .primary
        }
        if sources.contains(.profileCreator) {
            return .purple
        }
        if sources.contains(.rtroutonProfiles) {
            return .orange
        }
        
        // Default
        return .secondary
    }
    
    private var hasAppleSource: Bool {
        sources.contains(.appleDeviceManagement) || sources.contains(.appleDeveloperDocumentation)
    }
}
