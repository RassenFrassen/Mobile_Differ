# Version Sources & Update Frequency

This document defines the data sources used for OS version information and the app's update check frequency.

---

## OS Version Sources

### Official Apple Documentation

All OS version numbers are sourced from official Apple support documentation:

#### Primary Source
- **URL**: https://support.apple.com/en-us/100100
- **Coverage**: All Apple platforms (iOS, iPadOS, macOS, tvOS, watchOS, visionOS)
- **Purpose**: Current release versions and point releases
- **Update frequency**: Updated by Apple with each OS release

#### Secondary Source (macOS Tahoe)
- **URL**: https://support.apple.com/en-gb/122868
- **Coverage**: macOS 26.x (Tahoe) specific releases
- **Purpose**: Detailed patch version information (e.g., 26.0.1, 26.0.2)
- **Update frequency**: Updated by Apple with each macOS point release

#### Beta Version Source (Apple Developer Release Notes)
- **URL Pattern**: `https://developer.apple.com/documentation/{platform}-release-notes/{platform}-{version}-release-notes`
- **Examples**:
  - [macOS 26.4 Beta 2](https://developer.apple.com/documentation/macos-release-notes/macos-26_4-release-notes)
  - [iOS & iPadOS 26.4 Beta 2](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26_4-release-notes)
  - [watchOS 26.4 Beta](https://developer.apple.com/go/?id=watchos-26_4-rn)
  - [tvOS 26.4 Beta](https://developer.apple.com/go/?id=tvos-26_4-rn)
  - [visionOS 26.4 Beta](https://developer.apple.com/news/releases/?id=02162026e)
- **Coverage**: All Apple platforms (iOS, iPadOS, macOS, tvOS, watchOS, visionOS)
- **Purpose**: Beta version release notes with build numbers
- **Update frequency**: Updated with each beta release (typically weekly during beta cycles)
- **Build number format**: e.g., "23E5207q" (iOS), "25E5218f" (macOS), "23T5209m" (watchOS)

### Version Detection Strategy

The app uses a **hybrid approach** combining:

1. **Baseline Versions** (hardcoded from Apple support pages)
   - Updated manually from official Apple documentation
   - Includes major, minor, and patch releases
   - Covers historical versions for backward compatibility

2. **Dynamic Versions** (extracted from MDM catalog)
   - Automatically discovered from the `introduced` and `deprecated` fields in MDM keys
   - Updates when catalog is refreshed from GitHub sources
   - **Parser supports beta versions** (e.g., "27.0 Beta 1", "27.0 beta 2 (24A5279h)")
   - **Current reality**: Apple's sources currently publish release versions only
   - Will automatically detect betas IF Apple includes them in future MDM documentation

3. **Version Deduplication**
   - Baseline and dynamic versions are merged
   - Duplicates removed
   - Sorted by version number (descending)

### Supported Version Formats

- **Major.Minor**: `26.3`, `18.0`
- **Major.Minor.Patch**: `26.0.1`, `15.7.3`
- **Beta Releases**: `27.0 Beta 1`, `27.0 beta 2 (24A5279h)` (parser-ready, awaiting source data)
- **Build Numbers**: Preserved when available (e.g., `(24A5279h)`)

### Beta Version & Platform Coverage

**Parser Capabilities**:
- ✅ **Beta version parsing**: Fully supports beta strings with build numbers
- ✅ **Version comparison**: Correctly orders Release > Beta 15 > Beta 12 > Beta 1
- ✅ **Platform coverage**: All Apple platforms (iOS, iPadOS, macOS, tvOS, watchOS, visionOS)
- ✅ **Dynamic updates**: New versions auto-detected from catalog on refresh

**Current Data Availability**:
- ❌ **Apple device-management**: Publishes release versions only (e.g., "26.0", "15.0")
- ❌ **Apple Developer Documentation**: Publishes release versions only
- ❌ **ProfileManifests**: Community source, release versions only
- ❌ **rtrouton/profiles**: Community source, release versions only

**What This Means**:
- **During beta season** (June-September): Apple publishes betas on [Developer Release Notes](https://developer.apple.com/news/releases/)
- **Beta data exists**: All platforms covered (iOS 26.4 beta, macOS 26.4 beta, tvOS 26.4 beta, watchOS 26.4 beta, visionOS 26.4 beta)
- **MDM sources lag behind**: Apple's MDM repos don't include beta versions in `introduced`/`deprecated` fields
- **Current workaround**: Manual baseline updates required until beta scraping is implemented
- **Future enhancement**: Automatic ingestion from Apple Developer Release Notes (requires JavaScript scraper)

### Current Baseline Versions (as of 2026-02-26)

#### macOS
- **26.x (Tahoe)**: 26.3, 26.2, 26.1, 26.0.1, 26.0
- **15.x (Sequoia)**: 15.7, 15.6, 15.5, 15.4, 15.3, 15.2, 15.1, 15.0
- **14.x (Sonoma)**: 14.8, 14.7, 14.6, 14.5, 14.4, 14.3, 14.2, 14.1, 14.0
- **13.x (Ventura)**: 13.7, 13.6, 13.5, 13.4, 13.3, 13.2, 13.1, 13.0
- **12.x (Monterey)**: 12.7, 12.6, 12.5, 12.4, 12.3, 12.2, 12.1, 12.0
- **Legacy**: 11.0, 10.15

#### iOS / iPadOS
- **26.x**: 26.3, 26.2, 26.1, 26.0.1, 26.0
- **18.x**: 18.7, 18.6, 18.5, 18.4, 18.3, 18.2, 18.1, 18.0
- **17.x**: 17.7, 17.6, 17.5, 17.4, 17.3, 17.2, 17.1, 17.0
- **16.x**: 16.7, 16.6, 16.5, 16.4, 16.3, 16.2, 16.1, 16.0
- **15.x**: 15.8, 15.7, 15.6, 15.5, 15.4, 15.3, 15.2, 15.1, 15.0
- **Legacy**: 14.0, 13.0, 12.0

#### watchOS
- **26.x**: 26.3, 26.2, 26.1, 26.0
- **Legacy**: 11.0, 10.0, 9.0, 8.0, 7.0

#### tvOS
- **26.x**: 26.3, 26.2, 26.1, 26.0
- **Legacy**: 18.0, 17.0, 16.0, 15.0, 14.0

#### visionOS
- **26.x**: 26.3, 26.2, 26.1, 26.0
- **Legacy**: 2.0, 1.0

---

## MDM Catalog Data Sources

The app aggregates MDM configuration profile data from multiple licensed sources:

### 1. Apple device-management
- **Type**: Official Apple Repository
- **URL**: https://github.com/apple/device-management
- **License**: MIT License
- **Priority**: Highest (data from this source takes precedence)
- **Content**: Official MDM payload definitions and keys
- **Update**: Monitored via GitHub API

### 2. Apple Developer Documentation
- **Type**: Official Apple Documentation
- **URL**: https://developer.apple.com/documentation/devicemanagement
- **License**: Apple Terms of Service
- **Priority**: Highest (official source)
- **Content**: MDM payload documentation and examples
- **Update**: Monitored via GitHub API

### 3. ProfileManifests
- **Type**: Community Repository
- **URL**: https://github.com/ProfileManifests/ProfileManifests
- **License**: MIT License
- **Priority**: Medium
- **Content**: Community-maintained MDM manifests
- **Update**: Monitored via GitHub API

### 4. rtrouton/profiles
- **Type**: Community Repository
- **URL**: https://github.com/rtrouton/profiles
- **License**: MIT License
- **Priority**: Low
- **Content**: Sample configuration profiles
- **Update**: Monitored via GitHub API

### Source Priority

When merging data from multiple sources:
1. **Apple sources** (device-management, Developer Documentation) always take precedence
2. Community sources fill in gaps where Apple data is missing
3. Platforms and sources are merged (union of all)
4. Metadata prefers Apple values when conflicts occur

---

## Update Check Frequency

### iOS/iPadOS

**Method**: Background App Refresh (BGTaskScheduler)

**Frequency**: 
- Minimum interval: **1 hour** between checks
- iOS controls actual execution (typically every 12-24 hours)
- Triggered when device is idle, connected to power, and on Wi-Fi

**User Control**:
- Toggle: Settings → "Background Refresh"
- Default: **Enabled**
- Can be disabled by user at any time

**Code Reference**:
```swift
// MDMKeys/Services/MDMUpdateService.swift:41
request.earliestBeginDate = Date().addingTimeInterval(60 * 60)  // 1 hour
```

### macOS

**Method**: Launch Agent (launchd)

**Frequency**: 
- **Every 24 hours** (86,400 seconds)
- Runs at load (on login)
- Continues running even when app is closed

**User Control**:
- Toggle: Settings → "Daily launch agent"
- Default: **Disabled** (user must opt-in)
- Alternative: "Always-on login item helper" for menu bar presence

**Code Reference**:
```swift
// MDMKeys/Services/MDMUpdateService.swift:325
private let refreshInterval: Int = 24 * 60 * 60  // 24 hours
```

**Launch Agent Location**:
- `~/Library/LaunchAgents/com.differ.app.mdmrefresh.agent.plist`
- Logs: `~/Library/Application Support/Differ/mdm_background_agent.log`

---

## Manual Update Options

Users can manually trigger updates via:

1. **Pull to Refresh**
   - Available on: Keys, Payloads, Notifications tabs
   - Triggers: Immediate catalog refresh from all enabled sources

2. **Settings → Refresh Catalog**
   - Button: "Refresh Catalog"
   - Triggers: Immediate catalog refresh with haptic feedback

3. **macOS Launch Agent → Run Now**
   - Button: "Run Now" (macOS only)
   - Triggers: Immediate background agent execution

---

## Network Requirements

### GitHub API Rate Limits

**Without Token**:
- 60 requests per hour per IP
- Shared across all apps using GitHub API
- May exhaust quickly with frequent updates

**With GitHub Token** (recommended):
- 5,000 requests per hour
- Personal access token stored securely in iOS Keychain
- Configure in Settings → "GitHub Personal Access Token"

### Data Transfer

- Initial app bundle: ~2-3 MB (seed catalog)
- Catalog update: ~500 KB - 1 MB
- Updates are incremental (only changed data)

### Offline Support

- **Fully offline**: Bundled seed catalog always available
- **No internet**: App remains functional with last cached data
- **Refresh fails**: Previous catalog data retained

---

## Version Update Timeline

### Expected Update Cadence

**Major Releases** (e.g., iOS 27, macOS 27):
- Announced: WWDC (June)
- Beta releases: June - September (Beta 1, Beta 2, ..., Beta 15+)
- Public release: September

**Minor Releases** (e.g., 26.1, 26.2):
- Frequency: Every 4-8 weeks
- Contains: New features, improvements

**Patch Releases** (e.g., 26.0.1, 26.0.2):
- Frequency: As needed for critical bugs/security
- Contains: Bug fixes, security updates

### App Update Process

1. **Apple releases new OS version** (e.g., macOS 26.4)
2. **Apple updates support documentation** (https://support.apple.com/en-us/100100)
3. **Baseline versions updated** in next app release (manual process)
4. **MDM catalog refreshes** from GitHub sources (automatic)
5. **Dynamic version detection** discovers new versions from catalog metadata
6. **Compatibility view updates** with new versions immediately

**Beta Version Handling**:
- **IF** Apple publishes beta versions in MDM sources → Auto-detected and displayed immediately
- **IF NOT** (current situation) → Manual baseline update required in next app version
- **Workaround**: Add known beta versions to baseline when WWDC announcements occur (June annually)

---

## Monitoring & Logging

### Update Logs (macOS)

- **Background agent log**: `~/Library/Application Support/Differ/mdm_background_agent.log`
- **Error log**: `~/Library/Application Support/Differ/mdm_background_agent.error.log`

### Notification Log (iOS/iPadOS/macOS)

- Location: Updates tab in app
- Shows: Added, updated, removed keys
- Badge: Total change count
- Persistent: Stored locally until manually cleared

---

## Privacy & Security

### Data Collection
- **None**: No analytics or tracking
- **All data stored locally** on device
- **GitHub token**: Optional, stored in iOS Keychain (AES-256)

### Network Requests
- **Only to GitHub API**: Fetch latest MDM catalog data
- **HTTPS only**: All requests encrypted
- **No third-party servers**: Direct GitHub communication only

---

## Future Considerations

### Planned Enhancements
- [ ] **Automatic beta version ingestion from Apple Developer Release Notes**
  - Source identified: `https://developer.apple.com/documentation/{platform}-release-notes/`
  - Covers all platforms: iOS, iPadOS, macOS, tvOS, watchOS, visionOS
  - Includes build numbers (e.g., "26.4 beta 2 (25E5218f)")
  - Requires: JavaScript-capable scraper or API integration
- [ ] Automatic baseline version updates from Apple support pages (web scraping)
- [ ] Notification when new major OS versions are announced (beta detection)
- [ ] Custom update interval (user-configurable)
- [ ] Diff viewer showing what changed in each version

### Version Source Expansion Identified
**Beta Versions** (discovered 2026-02-26):
- ✅ **Apple Developer Release Notes**: https://developer.apple.com/news/releases/
  - Published for all platforms during beta cycles
  - Example: macOS 26.4 beta (25E5207k), macOS 26.4 beta 2 (25E5218f)
  - Currently **not** integrated into MDM catalog sources
  - Potential future enhancement: Scrape or monitor RSS/API for beta announcements

**Other Potential Sources**:
- Apple Security Updates database
- Apple Developer Release Notes API (if available)
- Beta firmware release notes RSS feeds

---

*Last updated: 2026-02-26*
*Corresponds to app version: 1.0*
