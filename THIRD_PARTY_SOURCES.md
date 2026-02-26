# Third-Party MDM Sources Guide

This document explains how third-party MDM configuration sources are integrated into the Differ app and how to add new sources.

## Current Third-Party Sources

The app currently includes the following third-party sources:

1. **ProfileManifests** (formerly ProfileCreator)
   - Repository: https://github.com/ProfileManifests/ProfileManifests
   - Icon: Magnifying glass with document
   - License: MIT
   - Contains: Community-maintained manifest files for MDM payloads

2. **rtrouton/profiles**
   - Repository: https://github.com/rtrouton/profiles
   - Icon: Person icon
   - License: MIT
   - Contains: Sample configuration profiles for macOS management
   - Includes: Microsoft Outlook, Microsoft AutoUpdate, and many Apple settings

## How Third-Party Sources Are Displayed

### Icon System

Each payload and key displays an icon based on:

1. **App-specific icons** (highest priority)
   - Firefox → Flame icon (orange)
   - Chrome → Hexagon grid (blue)
   - Privileges → Person with shield (green)
   - Microsoft Outlook → Envelope badge (blue)
   - Safari → Compass (blue)
   - And many more...

2. **Multiple sources indicator**
   - When a payload/key appears in multiple sources, a small blue badge with stacked documents appears in the bottom-right corner of the icon
   - This indicates that the information is available from multiple repositories

3. **Source-based fallback icons**
   - Apple sources → Apple logo
   - ProfileManifests only → Magnifying glass + document
   - rtrouton only → Person icon

### Examples in Current Seed Data

From the current `mdm_catalog_seed.json`:

```json
{
  "name": "Microsoft Outlook",
  "payloadType": "com.microsoft.Outlook",
  "sources": ["rtrouton/profiles"]
}
```
This will display with an envelope badge icon (Microsoft-specific) in blue.

```json
{
  "name": "Wi-Fi Managed Settings",
  "payloadType": "com.apple.MCX",
  "sources": ["Apple device-management", "rtrouton/profiles"]
}
```
This will display with the Apple logo AND a blue multi-source badge.

## How to Add Third-Party App Support

### For Apps in Existing Sources

If an app profile already exists in ProfileManifests or rtrouton/profiles but isn't in your seed data:

1. The app will automatically appear when you refresh the catalog from the Settings view
2. The `MDMSourceIngestor` will fetch the latest data from the repositories
3. New payloads and keys will be merged into the catalog

### Adding Icons for New Apps

To add custom icons for new third-party apps, edit `PayloadIconView.swift`:

```swift
// Add to iconName computed property (around line 20)
if type.contains("firefox") || type.contains("mozilla") {
    return "flame"
}
if type.contains("yourapp") {
    return "your.sf.symbol.name"
}

// Add to iconColor computed property (around line 290)
if type.contains("firefox") || type.contains("mozilla") {
    return .orange
}
if type.contains("yourapp") {
    return .blue  // or any Color
}
```

### Common Third-Party Apps Already Supported

The following apps have custom icons configured:

**Browsers:**
- Firefox (flame, orange)
- Chrome (hexagon grid, blue)
- Safari (compass, blue)

**Productivity:**
- Microsoft Outlook (envelope badge, blue)
- Zoom (video, blue)
- Slack (chat bubbles, purple)

**Development:**
- Git (code brackets, orange)
- Docker (stacked cubes, blue)
- VS Code (code brackets, orange)

**Management:**
- Jamf (shield, indigo)
- Munki (shipping box, orange)
- Kandji (cube, mint)
- Mosyle (grid, cyan)
- Addigy (link, teal)
- Privileges (person + shield, green)

**Storage:**
- Dropbox (stacked boxes, blue)
- OneDrive (cloud, blue)

**Creative:**
- Adobe (paintbrush, red)

## Adding New Source Repositories

To add a completely new source repository (beyond the current four), you would need to:

1. **Add to MDMSource enum** in `MDMCatalog.swift`:
```swift
enum MDMSource: String, CaseIterable, Identifiable, Codable {
    case newSource = "New Source Name"

    var repoURL: String {
        case .newSource: return "https://github.com/owner/repo"
    }

    var icon: String {
        case .newSource: return "custom.icon"
    }
}
```

2. **Add ingestor method** in `MDMSourceIngestor.swift`:
```swift
private func fetchNewSource(token: String?) async -> SourceResult? {
    // Implementation to fetch and parse the source data
}
```

3. **Update fetchAll** to include the new source:
```swift
if enabledSources.contains(.newSource) {
    group.addTask { await self.fetchNewSource(token: token) }
}
```

## Refreshing Third-Party Data

To refresh all sources including third-party repositories:

1. Open the app
2. Go to Settings → About
3. Tap "Refresh Catalog"
4. The app will fetch latest data from all enabled sources

## Data Location

- **Seed data**: `MDMKeys/Resources/mdm_catalog_seed.json`
- **Embedded bundles**: `MDMKeys/Resources/EmbeddedBundles/`
  - `apple-device-management/`
  - `rtrouton-profiles/`
  - `rodchristiansen-mobileconfig-profiles/`

## License Information

All third-party sources maintain their own licenses:
- Apple device-management: MIT
- ProfileManifests: MIT
- rtrouton/profiles: MIT

The app displays license information in:
- Settings → Licenses view
- Individual source metadata in the catalog

## Future Additions

Potential third-party sources to consider:

1. **Homebrew cask configurations**
2. **Community MDM repositories**
3. **Vendor-specific configurations** (Mozilla Firefox Enterprise, Google Chrome Enterprise, etc.)
4. **Custom organizational profiles**

Each would need proper parsing logic and attribution in the UI.
