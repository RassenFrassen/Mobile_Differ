# Adding EmbeddedBundles to Xcode Project

## Problem Identified ✅

The `EmbeddedBundles` directory exists on disk but is **NOT included in the Xcode project**, which is why the app can't access the 100+ third-party application manifests.

### Current State:
- ✅ **On Disk**: `MDMKeys/Resources 2/EmbeddedBundles/` (552 files in ProfileManifests)
- ❌ **In Xcode**: Not visible in Project Navigator
- ❌ **In Build**: Not included in Differ.app bundle

## Solution: Add Folder Reference to Xcode

### Option 1: Via Xcode GUI (Recommended - 2 minutes)

1. **Open the project in Xcode** if not already open

2. **In the Project Navigator (left sidebar)**:
   - Find and click on `MDMKeys` group
   - Then click on `Resources 2` to select it

3. **Right-click on `Resources 2`** and select **"Add Files to \"Differ\"..."**

4. **Navigate to the EmbeddedBundles folder**:
   - In the file picker, navigate to: `MDMKeys/Resources 2/EmbeddedBundles`
   - You should see 3 folders:
     - `ProfileManifests-ProfileManifests`
     - `apple-device-management`
     - `rtrouton-profiles`

5. **CRITICAL: Set options correctly**:
   - ✅ **Check**: "Create folder references" (BLUE folder icon)
   - ❌ **UNCHECK**: "Create groups" (yellow folder icon)
   - ✅ **Check**: "Copy items if needed" is NOT needed (files are already in project)
   - ✅ **Check**: Target "MDMKeys" is checked
   - ✅ **Check**: "Add to targets: MDMKeys"

6. **Click "Add"**

7. **Verify**:
   - You should now see a BLUE folder icon 📁 named `EmbeddedBundles` under `Resources 2`
   - If it's yellow, you did "Create groups" instead - delete it and try again

8. **Build the project** (Cmd+B)

9. **Verify it's in the built app**:
   ```bash
   ls ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphoneos/Differ.app/ | grep Embedded
   ```
   Should show: `EmbeddedBundles/`

### Option 2: Via Command Line (Advanced)

```bash
cd /Users/mike/Documents/Github/Mobile_Differ

# This will be automated - for now use GUI method above
```

## After Adding the Bundles

### Step 1: Rebuild
```bash
# In Xcode:
# Product → Clean Build Folder (Shift+Cmd+K)
# Product → Build (Cmd+B)
```

### Step 2: Run and Refresh
1. Run the app (Cmd+R)
2. Go to Settings
3. Tap "Refresh Catalog"
4. Wait for completion

### Step 3: Verify Success

Search for third-party apps that should now appear:

```bash
# After refresh, check the updated seed file:
cd /Users/mike/Documents/Github/Mobile_Differ

# Count items from ProfileManifests
jq '.sources[] | select(.source == "ProfileCreator" or .source == "ProfileManifests") | "Items: \(.itemCount)"' MDMKeys/Resources/mdm_catalog_seed.json

# Should show 100+ instead of 19

# List third-party apps
jq -r '.keys[] | select(.payloadType | contains("mozilla") or contains("chrome") or contains("privileges") or contains("zoom") or contains("slack")) | .payloadType' MDMKeys/Resources/mdm_catalog_seed.json | sort -u
```

Expected results:
- `com.google.Chrome`
- `com.tinyspeck.slackmacgap` (Slack)
- `corp.sap.privileges`
- `org.mozilla.firefox`
- `us.zoom.config`

## Troubleshooting

### If bundles still don't appear:

**Check 1**: Verify folder reference (blue folder icon)
```
In Xcode Project Navigator:
Resources 2/
  └── 📁 EmbeddedBundles  ← Should be BLUE, not yellow
```

**Check 2**: Verify target membership
- Click on `EmbeddedBundles` in Project Navigator
- Check File Inspector (right sidebar)
- "Target Membership" should show "MDMKeys" checked

**Check 3**: Verify it's a folder reference
- Click on `EmbeddedBundles`
- In File Inspector, "Type" should be "folder reference" not "group"

**Check 4**: Check build output
```bash
# Find the built app
find ~/Library/Developer/Xcode/DerivedData -name "Differ.app" -type d | head -1

# Check contents
ls -la "$(find ~/Library/Developer/Xcode/DerivedData -name "Differ.app" -type d | head -1)/"
```

Should include:
```
EmbeddedBundles/
  ProfileManifests-ProfileManifests/
  apple-device-management/
  rtrouton-profiles/
```

### If EmbeddedBundles folder is yellow (group) instead of blue (folder reference):

1. Delete it from Xcode (right-click → Delete → "Remove Reference")
2. Try adding again, making sure to select "Create folder references"

## What This Fixes

✅ **Before**: 19 items from ProfileManifests (broken)
✅ **After**: 100+ items including:
- Firefox, Chrome, Brave, Edge
- Privileges, Jamf, CrowdStrike, Santa
- Zoom, Slack, Microsoft Office
- Docker, 1Password, and 50+ more

✅ **Icons will appear automatically** for all third-party apps
✅ **Multi-source badges** will show on items from multiple repos
✅ **App works offline** using embedded bundles

## Technical Details

The `RepositoryBundleService` expects bundles at:
```swift
Bundle.main.url(
    forResource: "ProfileManifests-ProfileManifests",
    withExtension: nil,
    subdirectory: "EmbeddedBundles"
)
```

This only works if `EmbeddedBundles` is added as a **folder reference** (blue folder), not a **group** (yellow folder).

- **Folder reference** = Real directory structure maintained in bundle
- **Group** = Virtual organization in Xcode, files copied to bundle root
