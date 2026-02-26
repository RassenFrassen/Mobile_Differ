# App Store Metadata - Differ

Complete metadata for App Store Connect submission.

---

## App Information

**App Name:** Differ - MDM Keys

**Subtitle:** Apple MDM Configuration Reference

**Bundle ID:** (Your bundle ID from project.yml)

---

## Description

### Primary Text (4000 char limit)

Browse the complete catalog of Apple Mobile Device Management (MDM) configuration profile keys. Differ aggregates data from official Apple documentation and community sources, providing IT administrators and developers with a comprehensive offline reference.

**Features:**

• 1,973+ MDM Keys - Complete catalog from official sources
• 126 Documented Payloads - Browse keys grouped by configuration area
• Offline-First - Full catalog bundled with the app, no internet required
• Smart Search - Find keys by name, payload type, platform, or description
• Advanced Filtering - Filter by platform (iOS, iPadOS, macOS, tvOS, visionOS, watchOS), payload type, or source
• Compatibility Checker - View which keys work on specific OS versions
• Background Updates - Optional daily refresh for latest changes
• Change Notifications - Get alerted when new or updated keys are discovered
• Profile Examples - View auto-generated XML configuration profile samples
• Platform Badges - See supported platforms at a glance
• Source Attribution - Full transparency on data sources with proper licensing

**Perfect For:**

- Enterprise IT administrators deploying MDM solutions
- Mobile device management developers
- Configuration profile authors
- Apple system administrators
- Security compliance teams
- Anyone working with Apple MDM

**Data Sources:**

All data comes from properly licensed sources:
- Apple device-management (MIT License)
- Apple Developer Documentation (Official)
- ProfileManifests (MIT License)
- Community profile repositories (MIT License)

**Privacy:**
- No tracking or analytics
- All data stored locally on your device
- Optional GitHub token stored securely in iOS Keychain
- No data shared with third parties

**No Subscription Required**
Pay once, use forever. All features included.

---

## What's New (Version 1.0)

Initial release of Differ - MDM Keys Reference

• Complete MDM catalog with 1,973+ keys
• Browse by payload or key
• Compatibility checker for version-specific keys
• Background refresh with notifications
• Offline-first architecture
• iPad split-view optimization
• VoiceOver and accessibility support
• Profile XML examples
• Search and advanced filtering

---

## Keywords (100 char limit, comma-separated)

mdm,mobile device management,configuration profile,apple,enterprise,it admin,payload,mobileconfig,device,security

---

## Support URL

(Replace with your actual URL)
https://github.com/yourusername/differ/issues

---

## Marketing URL

(Replace with your actual URL)
https://github.com/yourusername/differ

---

## Privacy Policy URL

(Replace with your actual URL - REQUIRED before submission)
https://yourwebsite.com/privacy

---

## App Privacy Information

Complete these in App Store Connect:

### Data Collection
**Data Not Collected**
- No user data is collected by the app
- All data is stored locally on device

### Third-Party APIs Used
**GitHub API**
- Purpose: Fetch latest MDM documentation from public repositories
- Data accessed: Public repository content only
- Authentication: Optional user-provided token (stored in Keychain)
- No user tracking or analytics

### Privacy Manifest
- Included: PrivacyInfo.xcprivacy
- Declares: UserDefaults usage (CA92.1 - app-only data storage)

---

## App Store Categories

**Primary Category:** Developer Tools

**Secondary Category:** Productivity

---

## Age Rating

**Rating:** 4+
- No objectionable content
- Professional/educational tool

---

## Screenshots Requirements

### iPhone (6.7" - Required)
Devices: iPhone 15 Pro Max, iPhone 15 Plus, iPhone 14 Plus

**Screenshot 1:** Payloads List View
- Show browsing payloads by category
- Display platform badges
- Text overlay: "1,973+ MDM Keys from Official Sources"

**Screenshot 2:** Keys Browser with Search
- Show search results with filters active
- Display key details in split view (landscape)
- Text overlay: "Smart Search & Filtering"

**Screenshot 3:** Key Detail View
- Show detailed key information
- Display platform compatibility badges
- Text overlay: "Complete Documentation"

**Screenshot 4:** Compatibility Checker
- Show version-specific compatibility view
- Display compatible/incompatible sections
- Text overlay: "Check Version Compatibility"

**Screenshot 5:** Updates/Notifications
- Show notification log with changes
- Display added/updated/removed badges
- Text overlay: "Track Changes & Updates"

**Screenshot 6:** Profile Example
- Show XML profile example generated from key
- Text overlay: "Auto-Generated Profile Examples"

### iPad Pro (12.9" - Required)
Devices: iPad Pro (12.9-inch)

**Screenshot 1:** Split view showing payload list + detail
- Text overlay: "Optimized for iPad"

**Screenshot 2:** Keys browser in landscape with filters
- Text overlay: "Advanced Filtering"

**Screenshot 3:** Compatibility view showing version picker
- Text overlay: "Version Compatibility"

**Screenshot 4:** Documentation view expanded
- Text overlay: "Complete Documentation"

### Design Guidelines for Screenshots:
- Use light mode for consistency
- Add subtle text overlays (white text with shadow or dark background)
- Show realistic data from actual app
- Include platform badges where visible
- Display the app in action, not just static screens

---

## Promotional Text (170 char limit)

The complete MDM reference for Apple platforms. 1,973+ keys, offline browsing, version compatibility, and automatic update notifications.

---

## App Review Information

### Contact Information
**First Name:** (Your name)
**Last Name:** (Your name)
**Phone Number:** (Your phone)
**Email:** (Your email)

### Demo Account (if applicable)
Not required - app works without authentication

### Notes for Reviewers:

```
Differ is an MDM configuration reference tool for IT professionals.

Key features to test:
1. Launch app - onboarding shows on first launch
2. Browse Payloads tab - see 126 payloads grouped by category
3. Browse Keys tab - search and filter 1,973+ keys
4. Tap any key - view detailed information and XML examples
5. Compatibility tab - check version-specific key availability
6. Settings - optional GitHub token increases API rate limits
7. Pull to refresh - manually update catalog (requires network)
8. Background refresh - enable in Settings (triggers ~daily via iOS)

All data is bundled offline - no internet required for browsing.
GitHub token is optional and only used for public API calls to GitHub.
No user tracking or data collection.

The app works best on real devices due to background refresh and notifications.
```

---

## Export Compliance

**Is your app exempt from encryption?** YES

**Explanation:** This app only uses encryption for:
- HTTPS network calls to public APIs (GitHub API)
- Standard iOS Keychain for storing optional GitHub token

These uses qualify for exemption under standard HTTPS exception.

**Export Compliance Code:** Not required (standard exemption)

---

## App Icon Requirements

Ensure app icon is provided in all required sizes in Assets.xcassets:
- iPhone: 60pt @2x, 60pt @3x
- iPad: 76pt @2x, 83.5pt @2x
- App Store: 1024pt @1x

---

## Build Information

**Version Number:** 1.0
**Build Number:** 1 (increment for each upload)

**Supported Devices:**
- iPhone (iOS 18.0+)
- iPad (iPadOS 18.0+)

**Supported Orientations:**
- iPhone: Portrait, Landscape
- iPad: All orientations

---

## Pre-Submission Checklist

Before submitting to App Store:

- [ ] Update Privacy Policy URL in SettingsView.swift:202
- [ ] Update Support URL in SettingsView.swift:206
- [ ] Create privacy policy web page
- [ ] Create support/contact web page
- [ ] Complete App Privacy questionnaire in App Store Connect
- [ ] Take all required screenshots (6 for iPhone, 4+ for iPad)
- [ ] Test on real devices (background refresh, notifications)
- [ ] Verify app icon in all sizes
- [ ] Run final build in Release configuration
- [ ] Test with TestFlight beta first
- [ ] Update version/build numbers in project.yml
- [ ] Run validation script: `python3 scripts/validate_seed.py`
- [ ] Archive and upload to App Store Connect

---

## Localization

**Initial Release:** English (U.S.)

**Future Localizations (Suggested):**
- English (U.K.)
- Spanish
- French
- German
- Japanese
- Chinese (Simplified)
- Chinese (Traditional)

---

## Pricing & Availability

**Price Tier:** (Your choice - suggest $2.99-4.99 or Free)

**Availability:** All territories

**Release Date:** Manual release (after approval)

---

## End of Metadata Document

This file contains all the information needed for App Store Connect submission.
Update the placeholder URLs and contact information before submitting.
