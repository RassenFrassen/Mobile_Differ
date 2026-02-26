# Microsoft MDM Keys Analysis Report

**Generated**: 2026-02-26
**Project**: Mobile Differ - MDM Catalog Seed Enhancement

---

## Executive Summary

This report analyzes Microsoft MDM sources and compares the extracted keys against the existing MDM catalog seed. All 6 Microsoft applications were successfully processed, yielding **93 total keys** from official Microsoft documentation and schemas.

### Key Findings

- **All 6 applications already exist** in the seed (sourced from ProfileCreator)
- **93 Microsoft-official keys** extracted with proper documentation
- **Comprehensive metadata** including default values, allowed values, and constraints
- **Official source attribution** with Microsoft Learn documentation links
- **Highest quality data** from Microsoft Defender (official JSON schema v101.25102.0001)

---

## Applications Analyzed

### 1. Microsoft Defender for Endpoint
**Bundle ID**: `com.microsoft.wdav`
**Keys Extracted**: 59
**Status**: Exists in seed
**Data Source**: Official Microsoft JSON Schema (v101.25102.0001)

#### Key Categories
- **Antivirus Engine** (18 keys): Enforcement level, real-time protection, exclusions, passive mode, allowed threats, threat type settings, scan settings
- **Cloud Service** (7 keys): Cloud protection, diagnostic level, sample submission, security intelligence updates, cloud block level, proxy
- **User Interface** (3 keys): Status menu icon, user feedback, consumer experience
- **EDR** (2 keys): Device tags, group identifiers
- **Features** (4 keys): Data loss prevention, scheduled scan, behavior monitoring, offline updates
- **Tamper Protection** (2 keys): Enforcement level, exclusions
- **Device Control** (1 key): Policy configuration
- **Network Protection** (12 keys): Enforcement level, protocol parsing controls
- **DLP** (2 keys): Exclusions, features
- **Scheduled Scan** (8 keys): Daily/weekly configuration, scan options

#### Data Quality
- **Excellent**: Official schema with full metadata
- Includes default values, enum constraints, min/max ranges
- Direct Microsoft documentation links for each key
- Nested keys properly flattened with dot notation

#### Sample Keys
```
antivirusEngine.enforcementLevel (string) - Default: "real_time", Allowed: ["passive", "on_demand", "real_time"]
cloudService.diagnosticLevel (string) - Default: "optional", Allowed: ["optional", "required"]
networkProtection.enforcementLevel (string) - Default: "audit", Allowed: ["disabled", "audit", "block"]
```

---

### 2. Microsoft OneDrive
**Bundle ID**: `com.microsoft.OneDrive`
**Status**: Exists in seed
**Keys Extracted**: 13
**Data Source**: Microsoft Learn documentation

#### Key Categories
- Account Control (3 keys): Personal sync, tenant lists
- Sync Restrictions (2 keys): External sync, default folder
- Auto-Configuration (1 key): Disable auto config
- Known Folder Move (7 keys): Wizard, silent opt-in, notifications, folder selection, opt-out prevention

#### Data Quality
- **Good**: Based on Microsoft Learn docs
- Keys validated against example plists
- Descriptions enhanced for clarity

#### Sample Keys
```
DisablePersonalSync (boolean) - Prevents users from adding or syncing personal OneDrive accounts
KFMSilentOptIn (string) - Tenant ID to silently enable Known Folder Move without user interaction
MinDiskSpaceLimitInMB (integer) - Minimum free disk space in MB before blocking downloads
```

#### Documentation Sources
- https://learn.microsoft.com/en-us/sharepoint/deploy-and-configure-on-macos
- https://learn.microsoft.com/en-us/sharepoint/redirect-known-folders-macos

---

### 3. Microsoft Outlook
**Bundle ID**: `com.microsoft.Outlook`
**Status**: Exists in seed
**Keys Extracted**: 7
**Data Source**: Microsoft Learn documentation

#### Key Categories
- Account Restrictions (3 keys): Default email/domain, allowed/disallowed domains
- Import/Export Controls (2 keys): Import, export
- Meeting Integration (1 key): Teams meetings
- Security (1 key): Basic authentication

#### Data Quality
- **Good**: Based on Microsoft Learn docs
- Keys validated against example plists

#### Sample Keys
```
DefaultEmailAddressOrDomain (string) - Pre-fill default email address or domain for account setup
AllowedEmailDomains (array) - List of allowed email domains for adding accounts
DisableBasic (boolean) - Disable Basic authentication for Exchange accounts
```

#### Documentation Sources
- https://learn.microsoft.com/en-us/microsoft-365-apps/mac/deploy-preferences-for-office-for-mac

---

### 4. Microsoft AutoUpdate (MAU)
**Bundle ID**: `com.microsoft.autoupdate2`
**Status**: Exists in seed
**Keys Extracted**: 4
**Data Source**: Microsoft Learn & Jamf documentation

#### Key Categories
- Update Channels (1 key): Channel name
- Update Behavior (1 key): How to check
- Forced Updates (1 key): Deadline before forced quit
- Privacy (1 key): Data collection policy acknowledgment

#### Data Quality
- **Good**: Based on Microsoft Learn and Jamf docs
- Core MAU settings covered

#### Sample Keys
```
ChannelName (string) - Update channel (Current, Preview, Beta) for Microsoft apps
HowToCheck (string) - Update check behavior (Manual, AutomaticDownload, AutomaticDownloadAndInstall)
UpdateDeadline.DaysBeforeForcedQuit (integer) - Number of days before forcing app quit to install updates
```

#### Documentation Sources
- https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-office-current/page/Microsoft_AutoUpdate_Default_Preference_Keys.html
- https://learn.microsoft.com/en-us/microsoft-365-apps/privacy/mac-privacy-preferences

---

### 5. Microsoft Office
**Bundle ID**: `com.microsoft.office`
**Status**: Exists in seed
**Keys Extracted**: 6
**Data Source**: Microsoft Learn documentation

#### Key Categories
- Authentication (2 keys): Auto sign-in, activation email
- User Experience (2 keys): What's New, template gallery
- File Handling (1 key): Local open/save
- Cloud Features (1 key): Cloud fonts

#### Data Quality
- **Good**: Based on Microsoft Learn docs
- Suite-wide Office settings

#### Sample Keys
```
OfficeAutoSignIn (boolean) - Automatically sign in users to Office apps using system credentials
ShowWhatsNewOnLaunch (boolean) - Show What's New dialog when launching Office apps
DisableCloudFonts (boolean) - Disable cloud-based fonts in Office applications
```

#### Documentation Sources
- https://learn.microsoft.com/en-us/microsoft-365-apps/mac/deploy-preferences-for-office-for-mac
- https://learn.microsoft.com/en-us/microsoft-365-apps/privacy/mac-privacy-preferences

---

### 6. Microsoft Edge
**Bundle ID**: `com.microsoft.Edge`
**Status**: Exists in seed
**Keys Extracted**: 4
**Data Source**: Example plists & Microsoft Learn docs

#### Key Categories
- Startup Behavior (2 keys): Restore on startup, startup URLs
- Navigation (1 key): Homepage location
- Extensions (1 key): Force-install list

#### Data Quality
- **Basic**: Limited keys from plist examples
- Full Edge policy manifest available separately (300+ policies)

#### Sample Keys
```
RestoreOnStartup (integer) - Action on startup (1=Restore last session, 4=Open list of URLs, 5=Open New Tab)
HomepageLocation (string) - Home button URL
ExtensionInstallForcelist (array) - Force-install Edge extensions (format: extension_id;update_url)
```

#### Documentation Sources
- https://learn.microsoft.com/en-us/deployedge/configure-microsoft-edge-on-mac
- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies

#### Note
Microsoft Edge publishes a comprehensive `policy_manifest.json` via the Edge for Business Universal Policy download, containing 300+ policies. This analysis includes only the most common keys from example plists. Consider downloading the full policy manifest for complete coverage.

---

## Comparison with Existing Seed

### Current State in Seed
All 6 Microsoft applications are present with source attribution: `"sources": ["ProfileCreator"]`

### Differences

#### 1. Source Attribution
- **Existing**: ProfileCreator (third-party manifest collection)
- **New**: Microsoft (official documentation and schemas)

#### 2. Documentation Links
- **Existing**: No source documentation URLs
- **New**: Direct Microsoft Learn documentation links included

#### 3. Key Coverage
Analysis of key overlap not performed (would require detailed comparison of existing seed keys vs extracted keys)

#### 4. Metadata Quality
**Existing** (ProfileCreator):
- Basic key definitions
- Limited metadata

**New** (Microsoft sources):
- Default values included
- Allowed values (enums) specified
- Min/max constraints for numbers
- Official descriptions from Microsoft

#### 5. Microsoft Defender Specifics
- **Existing**: Likely has flatter key structure
- **New**: Nested keys with dot notation (e.g., `antivirusEngine.enforcementLevel`)
- **New**: Full schema with 59 keys and comprehensive metadata

---

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Applications | 6 |
| Total Keys Extracted | 93 |
| Applications in Seed | 6 (100%) |
| New Applications | 0 |
| Highest Key Count | Microsoft Defender (59) |
| Lowest Key Count | Microsoft AutoUpdate (4) |
| Average Keys per App | 15.5 |

### Keys by Application

| Application | Keys | Percentage |
|-------------|------|------------|
| Microsoft Defender | 59 | 63.4% |
| Microsoft OneDrive | 13 | 14.0% |
| Microsoft Outlook | 7 | 7.5% |
| Microsoft Office | 6 | 6.5% |
| Microsoft AutoUpdate | 4 | 4.3% |
| Microsoft Edge | 4 | 4.3% |

---

## Data Quality Assessment

### Tier 1: Excellent (Official Schema)
- **Microsoft Defender for Endpoint**: Official JSON schema v101.25102.0001
  - Full metadata with defaults, enums, ranges
  - Version tracking available
  - Feedback email: jmanifest@microsoft.com

### Tier 2: Good (Official Documentation)
- **Microsoft OneDrive**: Microsoft Learn docs + validated plists
- **Microsoft Outlook**: Microsoft Learn docs + validated plists
- **Microsoft AutoUpdate**: Microsoft Learn + Jamf docs
- **Microsoft Office**: Microsoft Learn docs + validated plists

### Tier 3: Basic (Example-based)
- **Microsoft Edge**: Example plists only
  - Full policy manifest available separately
  - Recommend obtaining Universal Policy download for complete data

---

## Recommendations

### 1. Immediate Actions

#### Update Source Attribution
For all 6 Microsoft applications in the seed:
```json
"sources": ["ProfileCreator", "Microsoft"]
```

#### Add Documentation URLs
Include `sourceDocumentation` field with Microsoft Learn links

### 2. Key Integration Strategy

#### Option A: Merge Approach (Recommended)
- Keep existing ProfileCreator keys
- Add Microsoft-sourced keys that are missing
- Flag duplicates and use Microsoft version if conflicts exist
- Preserve both sources in attribution

#### Option B: Replace Approach
- Replace ProfileCreator entries entirely with Microsoft-official data
- Provides cleaner, single-source attribution
- Risk: May lose keys that ProfileCreator included but Microsoft doesn't document

#### Option C: Dual Entry Approach
- Maintain separate entries for same payload type
- One from ProfileCreator, one from Microsoft
- Allows users to choose preferred source

### 3. Microsoft Defender Special Handling

Microsoft Defender keys use nested structure. Choose handling:

**Option 1: Dot Notation** (Current)
```
antivirusEngine.enforcementLevel
cloudService.diagnosticLevel
```

**Option 2: Separate Nested Keys**
```
antivirusEngine → enforcementLevel
cloudService → diagnosticLevel
```

Recommend: Keep dot notation as it matches how keys are actually configured in MDM.

### 4. Future Enhancements

#### Microsoft Edge
- Download Edge Universal Policy package
- Extract full `policy_manifest.json`
- Process all 300+ policies for comprehensive coverage

#### Individual Office Apps
- Check for app-specific preferences:
  - `com.microsoft.Excel`
  - `com.microsoft.Word`
  - `com.microsoft.Powerpoint`
- Currently only suite-wide `com.microsoft.office` keys included

#### iOS/iPadOS
- These macOS preference domain keys do NOT apply to iOS
- iOS uses AppConfig (Managed App Configuration)
- Consider separate processing if Microsoft publishes iOS AppConfig schemas

### 5. Validation Steps

Before merging into seed:
1. Validate JSON structure matches seed schema
2. Test a sample payload in MDM environment
3. Verify nested keys (especially Defender) parse correctly
4. Check for duplicate IDs if merging with existing entries
5. Ensure all documentation links are accessible

---

## Technical Notes

### Type Mappings Used

| Microsoft Type | MDM Catalog Type |
|----------------|------------------|
| bool/boolean | boolean |
| string | string |
| int/integer/number | integer |
| array | array |
| array[string] | array |
| dict/object | dictionary |

### Nested Key Handling

Microsoft Defender uses nested preference structure. Example:

**Schema Structure:**
```json
{
  "properties": {
    "antivirusEngine": {
      "properties": {
        "enforcementLevel": {
          "type": "string",
          "default": "real_time"
        }
      }
    }
  }
}
```

**Flattened Key:**
```json
{
  "key": "antivirusEngine.enforcementLevel",
  "keyPath": "antivirusEngine.enforcementLevel",
  "valueType": "string",
  "defaultValue": "real_time"
}
```

This matches how preferences are actually set in configuration profiles.

### Platform Considerations

- All keys are **macOS only** (`preference domains`)
- iOS/iPadOS use different mechanisms (AppConfig, not preference domains)
- Some apps have variant bundle IDs:
  - OneDrive: `com.microsoft.OneDrive` (standard), `com.microsoft.OneDrive-mac` (Mac App Store)
  - Both use same preference keys

---

## Source File Inventory

### Input Files Used

#### JSON Reference Files
- `com.microsoft.wdav.schema.json` (51KB) - Official schema
- `com.microsoft.OneDrive.keys.reference.json` - Key list
- `com.microsoft.Outlook.keys.reference.json` - Key list
- `com.microsoft.autoupdate2.keys.reference.json` - Key list
- `com.microsoft.office.keys.reference.json` - Key list
- `com.microsoft.Edge.policy_manifest.pointer.json` - Pointer to full manifest

#### Plist Example Files
- `com.microsoft.wdav.plist` - Example preferences
- `com.microsoft.OneDrive.plist` - Example preferences
- `com.microsoft.Outlook.plist` - Example preferences
- `com.microsoft.autoupdate2.plist` - Example preferences
- `com.microsoft.office.plist` - Example preferences
- `com.microsoft.Edge.plist` - Example preferences

### Output Files Generated

- **Individual App Files** (6): `com.microsoft.*.json`
- **Combined File**: `microsoft_all_combined.json` (51KB)
- **Summary**: `SUMMARY.json` (1.3KB)
- **Documentation**: `README.md` (9.9KB)
- **This Report**: `ANALYSIS_REPORT.md`
- **Processing Script**: `process_microsoft_mdm.py` (16KB)

---

## Next Steps Checklist

- [ ] Review individual JSON files for accuracy
- [ ] Decide on merge vs replace strategy
- [ ] Update existing seed entries with Microsoft source attribution
- [ ] Add sourceDocumentation URLs to payloads
- [ ] Integrate new keys not present in existing entries
- [ ] Test Microsoft Defender nested keys in MDM
- [ ] Consider downloading Edge Universal Policy for complete coverage
- [ ] Check for individual Office app preferences (Excel, Word, PowerPoint)
- [ ] Validate all JSON against seed schema
- [ ] Document merge decisions and rationale

---

## Conclusion

This analysis successfully extracted **93 MDM keys** from official Microsoft sources for 6 applications. The data is properly formatted, includes comprehensive metadata, and provides direct links to Microsoft documentation.

All applications already exist in the seed (from ProfileCreator), so the primary value is:
1. **Official source attribution** - Microsoft vs third-party
2. **Documentation links** - Direct to Microsoft Learn
3. **Enhanced metadata** - Defaults, enums, constraints
4. **Potential new keys** - Keys Microsoft documents that ProfileCreator may have missed

The highest quality data comes from Microsoft Defender's official JSON schema. Other applications derive from Microsoft Learn documentation and validated example plists.

Integration into the MDM catalog seed should follow a merge approach to combine the best of both ProfileCreator and Microsoft sources.

---

**Report Generated**: 2026-02-26
**Data Source**: Microsoft official documentation and schemas
**Processing Script**: `process_microsoft_mdm.py`
**Output Location**: `/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/`
