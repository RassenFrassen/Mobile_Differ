# Microsoft MDM Payloads - File Index

**Location**: `/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/`
**Generated**: 2026-02-26
**Total Files**: 12 (180KB)

---

## Documentation Files

### 1. QUICK_START.md (8.0KB)
**Read this first!**
- Quick overview of what was done
- Summary statistics
- Sample extracted keys
- Integration options
- Next steps checklist

### 2. README.md (9.9KB)
**Comprehensive documentation**
- Full overview and source information
- Detailed application breakdowns
- File structure explanation
- Key features and metadata
- Usage recommendations
- Processing script details

### 3. ANALYSIS_REPORT.md (16KB)
**In-depth analysis**
- Executive summary
- Complete application analysis with key categories
- Comparison with existing seed
- Data quality assessment by tier
- Technical notes and recommendations
- Source file inventory

### 4. INDEX.md (this file)
**File directory and navigation**

---

## Data Files

### JSON Application Payloads (Individual)

#### com.microsoft.wdav.json (34KB)
- **Application**: Microsoft Defender for Endpoint
- **Keys**: 59
- **Quality**: Excellent (Official Microsoft Schema v101.25102.0001)
- **Categories**: Antivirus, Cloud Service, UI, EDR, Features, Tamper Protection, Device Control, Network Protection, DLP, Scheduled Scan

#### com.microsoft.OneDrive.json (6.2KB)
- **Application**: Microsoft OneDrive
- **Keys**: 13
- **Quality**: Good (Microsoft Learn Documentation)
- **Categories**: Personal sync control, tenant lists, Known Folder Move, disk space

#### com.microsoft.Outlook.json (3.4KB)
- **Application**: Microsoft Outlook
- **Keys**: 7
- **Quality**: Good (Microsoft Learn Documentation)
- **Categories**: Account restrictions, import/export, Teams integration, authentication

#### com.microsoft.office.json (3.2KB)
- **Application**: Microsoft Office (Suite)
- **Keys**: 6
- **Quality**: Good (Microsoft Learn Documentation)
- **Categories**: Auto sign-in, activation, user experience, cloud features

#### com.microsoft.autoupdate2.json (2.5KB)
- **Application**: Microsoft AutoUpdate (MAU)
- **Keys**: 4
- **Quality**: Good (Microsoft Learn + Jamf Documentation)
- **Categories**: Update channels, check behavior, forced updates, privacy

#### com.microsoft.Edge.json (2.2KB)
- **Application**: Microsoft Edge
- **Keys**: 4
- **Quality**: Basic (Example Plists)
- **Categories**: Startup behavior, homepage, extensions

### Combined Files

#### microsoft_all_combined.json (51KB)
**All applications and keys in one file**
- Structure: `{ "payloads": [...], "keys": [...] }`
- Total payloads: 6
- Total keys: 93
- Ready for direct integration or bulk processing

#### SUMMARY.json (1.3KB)
**Statistics and metadata**
```json
{
  "total_apps": 6,
  "total_keys": 93,
  "existing_apps": [...],
  "new_apps": [],
  "apps": { ... }
}
```

---

## Processing Script

### process_microsoft_mdm.py (16KB)
**Python script that generated all data files**

**Features**:
- Reads Microsoft JSON schemas and reference files
- Parses plist example files
- Maps Microsoft types to MDM catalog types
- Creates payload and key entries
- Checks existing seed for duplicates
- Generates individual and combined outputs

**Usage**:
```bash
cd /Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/
python3 process_microsoft_mdm.py
```

**Dependencies**: Python 3, standard library only (json, os, subprocess)

---

## Quick Navigation

### Start Here
1. Read **QUICK_START.md** for overview
2. Review **SUMMARY.json** for statistics
3. Check individual JSON files for specific apps

### Deep Dive
1. Read **README.md** for comprehensive docs
2. Read **ANALYSIS_REPORT.md** for detailed analysis
3. Review **process_microsoft_mdm.py** to understand data processing

### Integration
1. Review **microsoft_all_combined.json** for all data
2. Compare with existing seed entries
3. Follow integration options in QUICK_START.md

---

## File Purposes at a Glance

| File | Purpose | Audience |
|------|---------|----------|
| QUICK_START.md | Fast overview, samples, next steps | Everyone (start here) |
| README.md | Comprehensive documentation | Implementers |
| ANALYSIS_REPORT.md | Detailed analysis and recommendations | Technical decision makers |
| INDEX.md | File directory (this file) | Navigation |
| SUMMARY.json | Quick statistics | Automation/scripts |
| com.microsoft.*.json | Individual app payloads | Modular integration |
| microsoft_all_combined.json | All apps combined | Bulk integration |
| process_microsoft_mdm.py | Data generator | Reproducibility/updates |

---

## Key Statistics

```
Applications:         6
Total Keys:           93
Already in Seed:      6 (100%)
New Applications:     0

Data Source:          Microsoft Official Documentation
Highest Quality:      Microsoft Defender (Official Schema)
Documentation Links:  Included for all apps
```

---

## Integration Status

All 6 Microsoft applications **already exist** in the MDM catalog seed with source "ProfileCreator".

**Value Proposition**:
- Official Microsoft source attribution
- Direct documentation links
- Enhanced metadata (defaults, enums, constraints)
- Potentially new keys not in ProfileCreator

**Recommended Action**: Merge approach
1. Add "Microsoft" to sources
2. Add sourceDocumentation URLs
3. Merge new keys
4. Update metadata

---

## Source Attribution

All data extracted from:
- **Microsoft Official JSON Schema**: Microsoft Defender v101.25102.0001
- **Microsoft Learn Documentation**: OneDrive, Outlook, Office, AutoUpdate, Edge
- **Jamf Technical Papers**: AutoUpdate (supplementary)
- **Example Plists**: Validation and additional keys

---

## Platform Notes

- **Platform**: macOS only (preference domains)
- **iOS/iPadOS**: Not applicable (uses AppConfig, not covered here)
- **Bundle ID Variants**: OneDrive has `com.microsoft.OneDrive` and `com.microsoft.OneDrive-mac` (same keys)

---

## Next Actions

- [ ] Review QUICK_START.md
- [ ] Examine individual JSON files
- [ ] Compare with existing seed entries
- [ ] Decide on integration strategy
- [ ] Update seed with Microsoft attribution
- [ ] Test sample payloads in MDM

---

## Contact & Feedback

**Microsoft Defender Schema Feedback**: jmanifest@microsoft.com
**General Microsoft 365 Documentation**: Microsoft Learn
**This Analysis**: Generated 2026-02-26 for Mobile Differ project

---

**File Count**: 12 files
**Total Size**: 180KB
**Location**: `/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/`
