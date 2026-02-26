# Refreshing the MDM Catalog to Get Third-Party App Data

## Current Status

Your current `mdm_catalog_seed.json` was generated on **2026-02-22** and contains:
- ✅ **1,735 items** from Apple device-management
- ✅ **272 items** from rtrouton/profiles (including Microsoft Outlook and AutoUpdate)
- ⚠️ **Only 19 items** from ProfileManifests (should be 100+)

## Missing Third-Party Applications

The embedded `ProfileManifests-ProfileManifests` bundle in your app contains manifests for over **100 third-party applications** including:

### Browsers
- Firefox (`org.mozilla.firefox.plist`)
- Chrome (`com.google.Chrome.plist`)
- Brave (`com.brave.Browser.plist`)
- Microsoft Edge (`com.microsoft.Edge.plist`)

### Security & MDM Tools
- **Privileges** (`corp.sap.privileges.plist`)
- CrowdStrike Falcon
- Jamf Connect (Login, Sync, Verify, Shares)
- Jamf Setup Manager
- Jamf Trust
- Santa (Google & North Pole Sec versions)
- Nudge
- SentinelOne
- Zscaler

### Password Managers
- 1Password (v7 and v8)
- Keeper Password Manager

### Communication
- Zoom (`us.zoom.config.plist`)
- Slack (`com.tinyspeck.slackmacgap.plist`)
- Skype
- Microsoft Teams (via Office365ServiceV2)

### Microsoft Applications
- Outlook
- Excel
- Word
- PowerPoint
- OneNote
- OneDrive
- OneDrive Updater
- Microsoft Defender
- Remote Desktop
- Skype for Business
- AutoUpdate

### Development Tools
- Docker (`com.docker.config.plist`)
- GitHub Desktop
- Visual Studio Code
- Unity Editor

### Cloud & VPN
- Cloudflare WARP
- Tailscale
- Firezone
- Twingate
- VPN Tracker

### Media & Creative
- Adobe applications
- HandBrake
- VLC
- Final Cut Pro
- Motion
- Compressor
- Logic Pro
- GarageBand
- iMovie

### Productivity
- Grammarly
- The Unarchiver
- Google Drive
- Dropbox
- Box

### Enterprise Management
- Munki
- MunkiReport
- Support Companion
- Outset
- Install or Defer
- Super
- macOS LAPS

And many more!

## How to Refresh the Catalog

### Option 1: Via the App (Easiest)

1. Open the Differ app
2. Go to **Settings** (gear icon)
3. Scroll to the **About** section
4. Tap **"Refresh Catalog"**
5. Wait for the refresh to complete (may take a minute)
6. Go back to the main view

The app will:
- Load data from the embedded `ProfileManifests-ProfileManifests` bundle
- Load data from the embedded `rtrouton-profiles` bundle
- Load data from the embedded `apple-device-management` bundle
- Merge everything with proper source attribution
- Save the new catalog to `mdm_catalog_seed.json`

### Option 2: Force Offline Bundle Load

The embedded bundles are located at:
```
MDMKeys/Resources/EmbeddedBundles/
├── ProfileManifests-ProfileManifests/
│   └── Manifests/
│       ├── ManagedPreferencesApplications/  ← 100+ third-party apps
│       ├── ManagedPreferencesApple/
│       ├── ManagedPreferencesDeveloper/
│       └── ManifestsApple/
├── rtrouton-profiles/
└── apple-device-management/
```

The app automatically uses these bundles when:
1. No internet connection is available
2. GitHub API is unavailable
3. First launch before any network fetch

## Verifying the Data

After refreshing, you can verify the data was loaded:

### Check Total Counts
```bash
jq '.sources[] | "\(.source): \(.itemCount) items"' MDMKeys/Resources/mdm_catalog_seed.json
```

Should show something like:
```
Apple device-management: 1735 items
ProfileCreator: 150+ items  ← Should be much higher than 19
rtrouton/profiles: 272 items
```

### Check for Specific Apps
```bash
# Check for Firefox
jq -r '.keys[] | select(.payloadType | contains("firefox")) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json

# Check for Chrome
jq -r '.keys[] | select(.payloadType | contains("chrome")) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json

# Check for Privileges
jq -r '.keys[] | select(.payloadType | contains("privileges")) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json

# List all non-Apple payload types
jq -r '.keys[] | select(.payloadType | startswith("com.") and (startswith("com.apple") | not)) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json | sort -u
```

## What Icons Will Appear

After refreshing, you should see:

### For Third-Party Apps with Custom Icons
- **Firefox** → Orange flame icon
- **Chrome** → Blue hexagon grid icon
- **Privileges** → Green person with shield icon
- **Microsoft apps** → Blue envelope badge icon
- **Zoom** → Blue video icon
- **Slack** → Purple chat bubble icon
- **Docker** → Blue stacked cubes icon
- And many more (see `PayloadIconView.swift` for full list)

### For Other Third-Party Apps
- Apps without custom icons → Document with magnifying glass (ProfileManifests icon)
- Apps from rtrouton only → Person icon

### Multi-Source Indicator
- Apps/payloads in multiple sources → Small blue badge with stacked document icon in bottom-right corner

## Why the Original Seed Had So Few Items

The original seed file (generated 2026-02-22) likely had an issue during ProfileManifests ingestion where:
1. The embedded bundle path wasn't found correctly
2. Or the bundle ingestion failed silently
3. Or only the ManifestsApple folder was processed instead of all folders

After refreshing, you should get 100+ payloads from ProfileManifests including all the third-party applications.

## Troubleshooting

If after refreshing you still don't see third-party apps:

1. **Check App Logs**
   - Look for errors in the Xcode console when refreshing
   - Search for "ProfileManifests" or "fetchProfileManifestsFromBundle"

2. **Verify Embedded Bundle Exists**
   ```bash
   ls -la MDMKeys/Resources/EmbeddedBundles/ProfileManifests-ProfileManifests/Manifests/ManagedPreferencesApplications/ | wc -l
   ```
   Should show 100+ plist files

3. **Check Bundle in Built App**
   - After building, check if the bundle is included in the app:
   ```bash
   ls -la /path/to/Differ.app/Contents/Resources/EmbeddedBundles/
   ```

4. **Force Clean Build**
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Rebuild the app
   - Try refreshing again
