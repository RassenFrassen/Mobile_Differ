# Microsoft Source vs MDM Catalog Seed Comparison Report

**Analysis Date:** 2026-02-26 16:20:04

## Executive Summary

- **Total keys in seed:** 422
- **Total keys in Microsoft source:** 93
- **NEW keys in Microsoft (not in seed):** 64
- **Keys with ENHANCED metadata:** 5

## Recommendation

**KEEP** - The Microsoft source adds 64 new keys and enhances metadata for 5 existing keys. This represents valuable additional information.

---

## Detailed Payload Analysis

### com.microsoft.wdav

- **Keys in seed:** 17
- **Keys in Microsoft:** 59
- **NEW keys in Microsoft:** 59
- **Enhanced keys:** 0

#### New Keys (in Microsoft, not in seed)

- `networkProtection.disableRdpParsing`
- `antivirusEngine.scanArchives`
- `cloudService.definitionUpdatesInterval`
- `scheduledScan.weeklyConfiguration`
- `networkProtection.disableFtpParsing`
- `scheduledScan.runScanWhenIdle`
- `features.dataLossPrevention`
- `cloudService.enabled`
- `antivirusEngine.enableRealTimeProtection`
- `cloudService.automaticDefinitionUpdateEnabled`
- `networkProtection.disableHttpParsing`
- `networkProtection.disableTlsParsing`
- `scheduledScan.ignoreExclusions`
- `networkProtection.disableSshParsing`
- `antivirusEngine.scanHistoryMaximumItems`
- `networkProtection.disableDnsOverTcpParsing`
- `userInterface.hideStatusMenuIcon`
- `cloudService.definitionUpdateDue`
- `cloudService.diagnosticLevel`
- `tamperProtection.enforcementLevel`
- `antivirusEngine.threatTypeSettings`
- `cloudService.cloudBlockLevel`
- `scheduledScan.checkForDefinitionsUpdate`
- `edr.tags`
- `userInterface.consumerExperience`
- `dlp.exclusions`
- `scheduledScan.lowPriorityScheduledScan`
- `userInterface.userInitiatedFeedback`
- `dlp.features`
- `features.behaviorMonitoring`
- `antivirusEngine.threatTypeSettingsMergePolicy`
- `antivirusEngine.enableFileHashComputation`
- `antivirusEngine.offlineDefinitionUpdateFallbackToCloud`
- `antivirusEngine.scanResultsRetentionDays`
- `features.scheduledScan`
- `networkProtection.enforcementLevel`
- `antivirusEngine.exclusionsMergePolicy`
- `cloudService.proxy`
- `networkProtection.disableSmtpParsing`
- `antivirusEngine.disallowedThreatActions`
- `antivirusEngine.enforcementLevel`
- `antivirusEngine.maximumOnDemandScanThreads`
- `cloudService.automaticSampleSubmissionConsent`
- `antivirusEngine.passiveMode`
- `scheduledScan.dailyConfiguration`
- `networkProtection.disableIcmpParsing`
- `antivirusEngine.allowedThreats`
- `antivirusEngine.offlineDefinitionUpdate`
- `networkProtection.disableDnsParsing`
- `networkProtection.disableInboundConnectionFiltering`
- `antivirusEngine.exclusions`
- `scheduledScan.randomizeScanStartTime`
- `antivirusEngine.offlineDefinitionUpdateUrl`
- `features.offlineDefinitionUpdateVerifySig`
- `edr.groupIds`
- `tamperProtection.exclusions`
- `antivirusEngine.scanAfterDefinitionUpdate`
- `networkProtection.enableSetWarnToBlock`
- `deviceControl.policy`

**Example new keys with details:**

**`networkProtection.disableRdpParsing`**
- Type: `boolean`
- Description: Disables parsing of RDP traffic
- Default: `False`

**`antivirusEngine.scanArchives`**
- Type: `boolean`
- Description: If true, Defender will unpack archives and scan files inside them. Otherwise archive content will be skipped, that will improve scanning performance.
- Default: `True`

**`cloudService.definitionUpdatesInterval`**
- Type: `integer`
- Description: Specifies the time interval (in seconds) after which security intelligence updates will be checked.
- Default: `28800`

---

### com.microsoft.OneDrive

- **Keys in seed:** 39
- **Keys in Microsoft:** 13
- **NEW keys in Microsoft:** 2
- **Enhanced keys:** 2

#### New Keys (in Microsoft, not in seed)

- `DefaultFolder`
- `MinDiskSpaceLimitInMB`

**Example new keys with details:**

**`DefaultFolder`**
- Type: `dictionary`
- Description: Default OneDrive folder location and tenant configuration

**`MinDiskSpaceLimitInMB`**
- Type: `integer`
- Description: Minimum free disk space in MB before blocking downloads

#### Enhanced Keys (better metadata in Microsoft)

- Keys with new default values: 0
- Keys with new allowed values: 0
- Keys with new min/max constraints: 0
- Keys with better descriptions: 2

**Examples of enhanced keys:**

**`KFMOptInWithWizard`**
- Microsoft has more detailed description (54 chars vs 0 chars)

**`KFMSilentOptIn`**
- Microsoft has more detailed description (71 chars vs 0 chars)

---

### com.microsoft.Outlook

- **Keys in seed:** 40
- **Keys in Microsoft:** 7
- **NEW keys in Microsoft:** 2
- **Enhanced keys:** 0

#### New Keys (in Microsoft, not in seed)

- `DisableBasic`
- `DisallowedEmailDomains`

**Example new keys with details:**

**`DisableBasic`**
- Type: `boolean`
- Description: Disable Basic authentication for Exchange accounts

**`DisallowedEmailDomains`**
- Type: `string`
- Description: List of disallowed email domains for adding accounts

---

### com.microsoft.office

- **Keys in seed:** 40
- **Keys in Microsoft:** 6
- **NEW keys in Microsoft:** 1
- **Enhanced keys:** 0

#### New Keys (in Microsoft, not in seed)

- `DisableCloudFonts`

**Example new keys with details:**

**`DisableCloudFonts`**
- Type: `boolean`
- Description: Disable cloud-based fonts in Office applications

---

### com.microsoft.autoupdate2

- **Keys in seed:** 31
- **Keys in Microsoft:** 4
- **NEW keys in Microsoft:** 0
- **Enhanced keys:** 2

#### Enhanced Keys (better metadata in Microsoft)

- Keys with new default values: 0
- Keys with new allowed values: 0
- Keys with new min/max constraints: 0
- Keys with better descriptions: 2

**Examples of enhanced keys:**

**`HowToCheck`**
- Microsoft has more detailed description (78 chars vs 48 chars)

**`AcknowledgedDataCollectionPolicy`**
- Microsoft has more detailed description (45 chars vs 0 chars)

---

### com.microsoft.Edge

- **Keys in seed:** 255
- **Keys in Microsoft:** 4
- **NEW keys in Microsoft:** 0
- **Enhanced keys:** 1

#### Enhanced Keys (better metadata in Microsoft)

- Keys with new default values: 0
- Keys with new allowed values: 0
- Keys with new min/max constraints: 0
- Keys with better descriptions: 1

**Examples of enhanced keys:**

**`RestoreOnStartup`**
- Microsoft has more detailed description (79 chars vs 46 chars)

---

## Conclusion

The Microsoft source data provides **significant value** beyond what's in the ProfileCreator seed. It includes:
1. 64 completely new keys not present in the seed
2. Enhanced metadata (defaults, constraints, enums) for 5 existing keys

**Recommendation: KEEP the Microsoft sources** and merge them with the ProfileCreator data to create a more comprehensive catalog.