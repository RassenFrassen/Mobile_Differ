# How to Refresh the MDM Catalog

## Quick Steps

1. **Build the app** (already done ✅)
   
2. **Run the app in Xcode:**
   - Click the Play button in Xcode, or
   - Press Cmd+R

3. **Navigate to Settings:**
   - Tap the gear icon (⚙️) in the toolbar

4. **Tap "Refresh Catalog":**
   - Scroll down to the "About" section
   - Tap the "Refresh Catalog" button
   - Wait for the progress indicator to complete (may take 30-60 seconds)

5. **Verify the refresh:**
   - Go back to the main Keys view
   - Search for "firefox" or "chrome" or "privileges"
   - You should now see these third-party apps with their custom icons!

## What to Expect

### Before Refresh:
- ~19 items from ProfileManifests
- Only Microsoft Outlook and AutoUpdate from third-party apps
- Missing: Firefox, Chrome, Privileges, Zoom, Slack, Docker, etc.

### After Refresh:
- 100+ items from ProfileManifests
- Third-party apps with custom icons:
  - 🔥 Firefox (orange flame)
  - ⬡ Chrome (blue hexagon)
  - 🛡️ Privileges (green shield)
  - 📧 Microsoft apps (blue envelope badge)
  - 📹 Zoom (blue video)
  - 💬 Slack (purple bubbles)
  - 🐳 Docker (blue cubes)
  - And 50+ more!

## Checking the Results

After refresh, run these commands to verify:

```bash
# Count ProfileManifests items
jq '.sources[] | select(.source == "ProfileManifests" or .source == "ProfileCreator") | .itemCount' MDMKeys/Resources/mdm_catalog_seed.json

# Should show 100+ instead of 19

# List third-party apps
jq -r '.keys[] | select(.payloadType | startswith("com.") and (startswith("com.apple") | not)) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json | sort -u

# Should show: firefox, chrome, privileges, zoom, slack, docker, etc.
```

## Troubleshooting

If you don't see the new data:

1. **Check which sources are enabled:**
   - In Settings, make sure "ProfileManifests" is checked
   - All 4 sources should be enabled by default

2. **Check the embedded bundle:**
   ```bash
   ls MDMKeys/Resources/EmbeddedBundles/ProfileManifests-ProfileManifests/Manifests/ManagedPreferencesApplications/ | wc -l
   ```
   Should show 100+ plist files

3. **Clean and rebuild:**
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Rebuild and try again

4. **Check Xcode console for errors:**
   - Look for messages containing "ProfileManifests" or "fetchProfileManifestsFromBundle"
