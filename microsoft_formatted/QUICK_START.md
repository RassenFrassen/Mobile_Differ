# Quick Start Guide - Microsoft MDM Formatted Payloads

## What Was Done

Analyzed Microsoft's official MDM documentation and created properly formatted JSON payloads for 6 Microsoft applications, extracting **93 total keys** with full metadata.

## Files You Need

### For Integration
- **`microsoft_all_combined.json`** - All apps and keys in one file (51KB)
- Individual app files if you prefer modular approach

### For Review
- **`SUMMARY.json`** - Quick statistics
- **`README.md`** - Detailed documentation
- **`ANALYSIS_REPORT.md`** - Comprehensive analysis

## Quick Stats

```
Applications Processed:  6
Total Keys Extracted:    93
All Already in Seed:     Yes (from ProfileCreator)
New Applications:        0
```

### Breakdown by Application

| Application | Bundle ID | Keys | Quality |
|------------|-----------|------|---------|
| Microsoft Defender | com.microsoft.wdav | 59 | Excellent (Official Schema) |
| Microsoft OneDrive | com.microsoft.OneDrive | 13 | Good (MS Learn Docs) |
| Microsoft Outlook | com.microsoft.Outlook | 7 | Good (MS Learn Docs) |
| Microsoft Office | com.microsoft.office | 6 | Good (MS Learn Docs) |
| Microsoft AutoUpdate | com.microsoft.autoupdate2 | 4 | Good (MS Learn Docs) |
| Microsoft Edge | com.microsoft.Edge | 4 | Basic (Example Plists) |

## Status: All Apps Already Exist

Good news: All 6 applications already exist in your MDM catalog seed!
- Current source: ProfileCreator
- New value: Official Microsoft attribution + documentation links

## What's Different/Better

### 1. Source Attribution
```json
Current: "sources": ["ProfileCreator"]
New:     "sources": ["Microsoft"]
```

### 2. Documentation Links
New payloads include:
```json
"sourceDocumentation": [
  "https://learn.microsoft.com/..."
]
```

### 3. Rich Metadata
Keys include:
- Default values
- Allowed values (enums)
- Min/max constraints
- Official descriptions

### 4. Example: Before vs After

**Before (ProfileCreator):**
```json
{
  "id": "com.microsoft.wdav.PayloadType",
  "key": "PayloadType",
  "valueType": "string",
  "sources": ["ProfileCreator"]
}
```

**After (Microsoft):**
```json
{
  "id": "com.microsoft.wdav.antivirusEngine.enforcementLevel",
  "key": "antivirusEngine.enforcementLevel",
  "keyPath": "antivirusEngine.enforcementLevel",
  "payloadType": "com.microsoft.wdav",
  "payloadName": "Microsoft Defender for Endpoint",
  "keyDescription": "Antivirus engine enforcement mode",
  "valueType": "string",
  "defaultValue": "real_time",
  "allowedValues": ["passive", "on_demand", "real_time"],
  "platforms": ["macOS"],
  "sources": ["Microsoft"]
}
```

## Integration Options

### Option 1: Merge (Recommended)
1. Add "Microsoft" to sources array of existing entries
2. Add sourceDocumentation URLs
3. Merge in new keys not already present
4. Update metadata where Microsoft provides better info

### Option 2: Replace
1. Replace existing ProfileCreator entries entirely
2. Use pure Microsoft-sourced data
3. Risk: May lose keys ProfileCreator had that MS doesn't document

### Option 3: Dual Entries
1. Keep both ProfileCreator and Microsoft versions
2. Different entry IDs
3. Let users choose

## Sample Extracted Keys

### Microsoft Defender (59 keys total)

**Antivirus Engine:**
- `antivirusEngine.enforcementLevel` - Mode: passive, on_demand, real_time
- `antivirusEngine.enableRealTimeProtection` - Real-time scanning
- `antivirusEngine.exclusions` - Scan exclusions (paths, extensions, processes)
- `antivirusEngine.passiveMode` - Run in passive mode

**Cloud Service:**
- `cloudService.enabled` - Cloud-delivered protection
- `cloudService.diagnosticLevel` - Data collection: optional, required
- `cloudService.automaticSampleSubmissionConsent` - Sample submission: none, safe, all

**Network Protection:**
- `networkProtection.enforcementLevel` - disabled, audit, block
- `networkProtection.disableDnsParsing` - Disable DNS inspection
- `networkProtection.disableHttpParsing` - Disable HTTP inspection

### Microsoft OneDrive (13 keys)
- `DisablePersonalSync` - Block personal accounts
- `AllowTenantList` - Allowed tenant GUIDs
- `BlockTenantList` - Blocked tenant GUIDs
- `KFMSilentOptIn` - Silent Known Folder Move
- `MinDiskSpaceLimitInMB` - Disk space threshold

### Microsoft Outlook (7 keys)
- `DefaultEmailAddressOrDomain` - Pre-fill account setup
- `AllowedEmailDomains` - Domain allowlist
- `DisallowedEmailDomains` - Domain blocklist
- `DisableImport` - Prevent data import
- `DisableExport` - Prevent data export
- `DisableBasic` - Block Basic authentication

### Microsoft Office (6 keys)
- `OfficeAutoSignIn` - Auto sign-in with system creds
- `OfficeActivationEmailAddress` - Pre-fill activation email
- `ShowWhatsNewOnLaunch` - Show What's New dialog
- `DefaultsToLocalOpenSave` - Default to local files
- `DisableCloudFonts` - Disable cloud fonts

### Microsoft AutoUpdate (4 keys)
- `ChannelName` - Update channel: Current, Preview, Beta
- `HowToCheck` - Manual, AutomaticDownload, AutomaticDownloadAndInstall
- `UpdateDeadline.DaysBeforeForcedQuit` - Force update after N days
- `AcknowledgedDataCollectionPolicy` - Privacy acknowledgment

### Microsoft Edge (4 keys)
- `RestoreOnStartup` - Startup behavior
- `RestoreOnStartupURLs` - URLs to open on startup
- `HomepageLocation` - Home button URL
- `ExtensionInstallForcelist` - Force-installed extensions

## How to Use These Files

### Viewing Individual Apps
```bash
cd /Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/

# View specific app
cat com.microsoft.OneDrive.json | jq

# Count keys in an app
cat com.microsoft.wdav.json | jq '.keys | length'

# See all key names
cat com.microsoft.Outlook.json | jq '.keys[].key'
```

### Viewing Combined File
```bash
# See all payloads
cat microsoft_all_combined.json | jq '.payloads'

# Count total keys
cat microsoft_all_combined.json | jq '.keys | length'

# Find specific key
cat microsoft_all_combined.json | jq '.keys[] | select(.key == "DisablePersonalSync")'
```

### Statistics
```bash
# View summary
cat SUMMARY.json | jq

# Apps in seed vs new
cat SUMMARY.json | jq '{existing: .existing_apps, new: .new_apps}'
```

## File Structure

```
microsoft_formatted/
├── README.md                          # Comprehensive documentation
├── ANALYSIS_REPORT.md                 # Detailed analysis
├── QUICK_START.md                     # This file
├── SUMMARY.json                       # Statistics
├── process_microsoft_mdm.py           # Processing script
├── com.microsoft.wdav.json           # Defender (59 keys)
├── com.microsoft.OneDrive.json       # OneDrive (13 keys)
├── com.microsoft.Outlook.json        # Outlook (7 keys)
├── com.microsoft.office.json         # Office (6 keys)
├── com.microsoft.autoupdate2.json    # AutoUpdate (4 keys)
├── com.microsoft.Edge.json           # Edge (4 keys)
└── microsoft_all_combined.json       # All apps combined
```

## Next Steps

1. **Review** the generated JSON files
2. **Decide** on merge strategy (Option 1 recommended)
3. **Compare** with existing seed entries
4. **Update** seed with Microsoft attribution
5. **Test** with a sample MDM deployment
6. **Document** any changes made

## Key Decisions Needed

- [ ] Merge, replace, or dual-entry approach?
- [ ] How to handle Microsoft Defender nested keys?
- [ ] Keep existing ProfileCreator entries?
- [ ] Add sourceDocumentation to all entries?
- [ ] Download Edge Universal Policy for complete coverage?

## Questions?

Refer to:
- **README.md** - Full documentation
- **ANALYSIS_REPORT.md** - Detailed analysis and recommendations
- **SUMMARY.json** - Quick statistics

## Processing Script

To regenerate or modify:
```bash
cd /Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/
python3 process_microsoft_mdm.py
```

The script:
1. Reads Microsoft JSON schemas and reference files
2. Parses example plists
3. Maps types to MDM catalog format
4. Generates formatted JSON payloads
5. Checks existing seed for duplicates
6. Creates individual and combined outputs

---

**Generated**: 2026-02-26
**Total Keys**: 93 across 6 applications
**All apps already in seed** - New value is official Microsoft attribution
