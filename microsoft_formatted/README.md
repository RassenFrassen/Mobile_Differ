# Microsoft MDM Catalog Formatted Payloads

## Overview

This directory contains formatted JSON payloads extracted from Microsoft's official MDM documentation and schemas for macOS applications. The data has been processed and structured to match the MDM catalog seed format used in the Mobile Differ project.

## Source Information

The data was extracted from two Microsoft source directories:

1. **microsoft_ios_apple_settings_json_reference/** - Contains JSON reference files and schemas from Microsoft Learn documentation
2. **microsoft_apple_managed_prefs_plists/** - Contains example plist files showing preference domain structures

### Source Authenticity

- **Microsoft Defender for Endpoint**: Uses official JSON schema (`com.microsoft.wdav.schema.json`) published by Microsoft at version 101.25102.0001
- **Other Applications**: Derived from Microsoft Learn documentation and Jamf reference materials
- All source documentation URLs are included in the payload entries

## Applications Processed

### 1. Microsoft Defender for Endpoint (`com.microsoft.wdav`)
- **Keys Extracted**: 59
- **Status**: Already exists in seed
- **Source**: Official Microsoft JSON schema
- **Categories**: Antivirus engine, cloud service, user interface, EDR, features, tamper protection, device control, network protection, DLP, scheduled scan

### 2. Microsoft OneDrive (`com.microsoft.OneDrive`)
- **Keys Extracted**: 13
- **Status**: Already exists in seed
- **Source**: Microsoft Learn documentation
- **Key Features**: Personal sync control, tenant lists, Known Folder Move (KFM), disk space management

### 3. Microsoft Outlook (`com.microsoft.Outlook`)
- **Keys Extracted**: 7
- **Status**: Already exists in seed
- **Source**: Microsoft Learn documentation
- **Key Features**: Account restrictions, import/export controls, Teams integration, Basic auth

### 4. Microsoft AutoUpdate (`com.microsoft.autoupdate2`)
- **Keys Extracted**: 4
- **Status**: Already exists in seed
- **Source**: Microsoft Learn and Jamf documentation
- **Key Features**: Update channels, check behavior, forced update deadlines

### 5. Microsoft Office (`com.microsoft.office`)
- **Keys Extracted**: 6
- **Status**: Already exists in seed
- **Source**: Microsoft Learn documentation
- **Key Features**: Auto sign-in, activation email, What's New, template gallery, cloud fonts

### 6. Microsoft Edge (`com.microsoft.Edge`)
- **Keys Extracted**: 4
- **Status**: Already exists in seed
- **Source**: Microsoft Edge policy documentation
- **Key Features**: Startup behavior, homepage, extension force-install

## File Structure

### Individual Application Files

Each application has its own JSON file with the following structure:

```json
{
  "payload": {
    "id": "com.microsoft.OneDrive",
    "payloadType": "com.microsoft.OneDrive",
    "name": "Microsoft OneDrive",
    "category": "Other",
    "platforms": ["macOS"],
    "summary": "Description of the application",
    "discussion": "",
    "isDeprecated": false,
    "sources": ["Microsoft"],
    "sourceDocumentation": [
      "https://learn.microsoft.com/..."
    ]
  },
  "keys": [
    {
      "id": "com.microsoft.OneDrive.DisablePersonalSync",
      "key": "DisablePersonalSync",
      "keyPath": "DisablePersonalSync",
      "payloadType": "com.microsoft.OneDrive",
      "payloadName": "Microsoft OneDrive",
      "keyDescription": "Prevents users from adding or syncing personal OneDrive accounts",
      "valueType": "boolean",
      "platforms": ["macOS"],
      "sources": ["Microsoft"]
    }
  ]
}
```

### Files Generated

- **`com.microsoft.wdav.json`** - Microsoft Defender for Endpoint
- **`com.microsoft.OneDrive.json`** - Microsoft OneDrive
- **`com.microsoft.Outlook.json`** - Microsoft Outlook
- **`com.microsoft.autoupdate2.json`** - Microsoft AutoUpdate
- **`com.microsoft.office.json`** - Microsoft Office
- **`com.microsoft.Edge.json`** - Microsoft Edge
- **`microsoft_all_combined.json`** - All applications combined into one file
- **`SUMMARY.json`** - Processing summary and statistics

## Key Features

### Proper Type Mapping

The processor correctly maps Microsoft type definitions to MDM catalog value types:

- `bool/boolean` → `boolean`
- `string` → `string`
- `int/integer/number` → `integer`
- `array` → `array`
- `dict/object` → `dictionary`

### Rich Metadata

Keys include comprehensive metadata when available:

- **defaultValue** - Default value from Microsoft schema
- **allowedValues** - Enumerated allowed values
- **minValue/maxValue** - Range constraints for numeric values
- **keyDescription** - Human-readable description

### Nested Key Handling

For Microsoft Defender, nested preference keys are properly flattened using dot notation:
- `antivirusEngine.enforcementLevel`
- `cloudService.diagnosticLevel`
- `networkProtection.enforcementLevel`

## Status in Existing Seed

All 6 Microsoft applications **already exist** in the MDM catalog seed at:
`/Users/mike/Documents/Github/Mobile_Differ/MDMKeys/Resources/mdm_catalog_seed.json`

However, the existing entries have limited key coverage:
- Existing entries show keys from ProfileCreator source
- These formatted payloads provide **Microsoft-official** keys with proper documentation links
- Total of **93 keys** extracted from official Microsoft sources

## Differences from Existing Seed

### Source Attribution
- **Existing**: `"sources": ["ProfileCreator"]`
- **New**: `"sources": ["Microsoft"]` with `sourceDocumentation` URLs

### Microsoft Defender (com.microsoft.wdav)
- **New format**: 59 keys with full nested structure from official schema
- Includes default values, allowed values, and min/max constraints
- Keys use dot notation for nested preferences (e.g., `antivirusEngine.enforcementLevel`)

### Key Descriptions
- Existing entries may have generic descriptions
- New entries include descriptions directly from Microsoft documentation

## Usage Recommendations

### Option 1: Update Existing Entries
Update the existing seed entries to include:
1. Add "Microsoft" to the sources array
2. Add sourceDocumentation URLs
3. Merge in new keys that don't already exist

### Option 2: Replace Entries
Replace existing entries entirely with the new formatted versions for:
- More comprehensive key coverage
- Official Microsoft documentation links
- Proper metadata (defaults, allowed values, ranges)

### Option 3: Hybrid Approach
Keep existing ProfileCreator entries and add Microsoft-sourced keys that are missing

## Data Quality Notes

### High Confidence
- **Microsoft Defender for Endpoint**: Official JSON schema with version info
- Keys include full metadata from source schema

### Good Confidence
- **OneDrive, Outlook, Office, AutoUpdate**: Derived from Microsoft Learn docs
- Keys cross-referenced with example plists
- Descriptions manually enhanced for clarity

### Basic Confidence
- **Microsoft Edge**: Limited keys from plist examples
- Full Edge policy manifest available but not included in source directory
- Consider downloading Edge Universal Policy for complete key list

## Platform Notes

### macOS Only
All extracted keys are for **macOS** (`preference domains`).

**iOS/iPadOS** use different mechanisms:
- Managed App Configuration (AppConfig)
- Mobile Application Management (MAM)
- iOS keys are NOT covered in these preference-domain JSONs

### Preference Domain Variants

Some apps have multiple bundle identifiers:
- **OneDrive**: `com.microsoft.OneDrive` (standard) and `com.microsoft.OneDrive-mac` (Mac App Store)
- Both use the same preference keys

## Processing Script

The data was generated using `process_microsoft_mdm.py`, which:
1. Reads Microsoft JSON schemas and reference files
2. Parses plist example files for additional keys
3. Maps Microsoft types to MDM catalog types
4. Generates properly formatted JSON payloads
5. Checks existing seed for duplicates
6. Creates individual and combined output files

## Next Steps

### For Integration into MDM Catalog Seed

1. **Review Generated Files**: Examine individual JSON files for accuracy
2. **Compare with Existing**: Check differences between new entries and existing seed entries
3. **Decide on Merge Strategy**: Choose update, replace, or hybrid approach
4. **Update Sources**: Ensure proper attribution to Microsoft
5. **Add Documentation Links**: Include sourceDocumentation URLs
6. **Test Formatting**: Validate JSON structure matches seed schema
7. **Merge Keys**: Integrate new keys into existing payload definitions

### For Future Updates

1. **Microsoft Edge**: Download Edge Universal Policy to get complete policy_manifest.json
2. **Excel, Word, PowerPoint**: Check for app-specific preferences (currently only suite-wide office keys included)
3. **iOS/iPadOS**: Consider separate processing for AppConfig schemas if Microsoft publishes them

## References

### Microsoft Documentation
- [Deploy and configure OneDrive on macOS](https://learn.microsoft.com/en-us/sharepoint/deploy-and-configure-on-macos)
- [Deploy preferences for Office for Mac](https://learn.microsoft.com/en-us/microsoft-365-apps/mac/deploy-preferences-for-office-for-mac)
- [Microsoft Defender for Endpoint on Mac](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/mac-preferences)
- [Configure Microsoft Edge on Mac](https://learn.microsoft.com/en-us/deployedge/configure-microsoft-edge-on-mac)
- [Microsoft Edge Policies](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies)

### Additional Resources
- [Jamf Microsoft Office Technical Paper](https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-office-current/)
- Microsoft Defender JSON Schema: Version 101.25102.0001

## Statistics

- **Total Applications**: 6
- **Total Keys Extracted**: 93
- **All Applications**: Already present in seed
- **New Keys**: Many keys from official Microsoft sources not in existing entries
- **Source Accuracy**: High (official schemas and Microsoft Learn docs)

## Contact

For questions about Microsoft MDM preferences:
- Microsoft Defender Schema Feedback: jmanifest@microsoft.com
- General Microsoft 365 Admin: Consult Microsoft Learn documentation
