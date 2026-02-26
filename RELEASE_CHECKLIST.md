# Release Checklist

Use this checklist for every release to ensure App Store compliance and quality.

## Pre-Release Checklist

### Version Management
- [ ] **Version bump** - Update `MARKETING_VERSION` in `project.yml` (line 50)
- [ ] **Build number bump** - Increment `CURRENT_PROJECT_VERSION` in `project.yml` (line 51)
- [ ] **Info.plist sync** - Verify `CFBundleShortVersionString` and `CFBundleVersion` match in `Info.plist`
- [ ] **Update changelog** - Add release notes to `CHANGELOG.md`

### Privacy & Legal Compliance
- [ ] **Privacy manifest present** - Verify `MDMKeys/PrivacyInfo.xcprivacy` exists and is in build
- [ ] **Privacy policy URL updated** - Update placeholder in `SettingsView.swift:192` if needed
- [ ] **Support URL updated** - Update placeholder in `SettingsView.swift:196` if needed
- [ ] **App Privacy labels** - Update in App Store Connect to match PrivacyInfo.xcprivacy
- [ ] **License compliance** - Verify all sources in `LicensesView.swift` are current
- [ ] **LICENSES.md updated** - Ensure all third-party dependencies documented

### Data Integrity
- [ ] **Seed file validation** - Run `python3 scripts/validate_seed.py` to check schema
- [ ] **No unlicensed sources** - Verify seed contains only: Apple device-management, Apple Developer Documentation, ProfileManifests, rtrouton/profiles
- [ ] **Source enum matches** - All sources in `MDMCatalog.swift` enum have proper licenses

### Configuration & Build
- [ ] **project.yml synced** - No drift between project.yml and .pbxproj
- [ ] **Bundle ID correct** - `com.notmoby.differ.app` in all configs
- [ ] **Clean build** - `xcodebuild clean build` succeeds with no warnings
- [ ] **Archive build** - Create archive for TestFlight upload
- [ ] **Code signing** - Development team and provisioning profiles configured

### Testing
- [ ] **Unit tests pass** - All tests green
- [ ] **Manual smoke test** - Test all critical paths:
  - [ ] App launches and loads seed catalog
  - [ ] Browse payloads and keys works
  - [ ] Settings toggle (auto-refresh) works correctly
  - [ ] GitHub token can be saved (Keychain)
  - [ ] Manual refresh works
  - [ ] Notifications work (if enabled)
  - [ ] Documentation view renders
  - [ ] Licenses view shows all attributions
- [ ] **iPad testing** - Test all 4 orientations work
- [ ] **Background refresh** - Verify toggle controls background updates

### Metadata & Assets
- [ ] **App icon present** - `AppIcon120.png` in Resources
- [ ] **Screenshots ready** - Prepare for App Store Connect (iPhone & iPad)
- [ ] **App description** - Review/update App Store description
- [ ] **What's New** - Prepare release notes for users
- [ ] **Keywords** - Review App Store search keywords

## TestFlight Release

- [ ] **Upload to TestFlight** - Via Xcode or Transporter
- [ ] **Add build notes** - Document what changed for testers
- [ ] **Internal testing** - Test with internal group (1-3 days)
- [ ] **External testing** - Release to beta testers (optional)
- [ ] **Collect feedback** - Monitor crash reports and feedback
- [ ] **Fix critical issues** - Address any blockers before production

## Production Release

### Pre-Submission
- [ ] **TestFlight validated** - No critical bugs found
- [ ] **Rollback plan documented** - See `CHANGELOG.md` for rollback criteria
- [ ] **Review notes prepared** - Add notes for App Review team if needed
- [ ] **Export compliance** - Verify ITSAppUsesNonExemptEncryption = false

### Submission
- [ ] **Submit for review** - Via App Store Connect
- [ ] **Phased release enabled** - Start with 1% rollout
- [ ] **Monitor initial rollout** - Check crash rates and reviews

### Post-Release
- [ ] **Monitor crash reports** - First 24-48 hours critical
- [ ] **Monitor reviews** - Respond to user feedback
- [ ] **Track metrics** - Downloads, engagement, retention
- [ ] **Gradual rollout** - Increase to 100% if stable

### Rollback Criteria

Stop/pause rollout if any occur:
- Crash rate >5%
- Critical bug affecting >10% of users
- App Review rejection
- Security vulnerability discovered
- Legal/compliance issue identified

### Rollback Process

1. Pause phased release in App Store Connect
2. Identify issue and create hotfix branch
3. Fix critical issue
4. Fast-track TestFlight build
5. Submit hotfix for expedited review
6. Document incident in CHANGELOG.md

## Review Notes Template

Use this template when submitting to App Review:

```
App: Differ - MDM Keys Reference

This app provides a reference catalog of Apple Mobile Device Management (MDM) configuration profile keys for IT administrators and developers.

Features:
- Browse 1,973 MDM keys from official Apple documentation
- View payload documentation and examples
- Search and filter capabilities
- Offline-first with bundled catalog
- Optional background refresh for updates

Third-Party Content:
- All data sources are MIT-licensed or official Apple documentation
- Full attribution available in-app (Settings > Licenses & Attribution)
- See LICENSES.md in repository for details

Privacy:
- GitHub token (optional) stored in iOS Keychain for security
- No user data collected or transmitted except optional GitHub API calls
- No tracking or analytics
- Privacy manifest included (PrivacyInfo.xcprivacy)

Testing Notes:
- Default catalog works offline immediately
- Optional GitHub token enables higher API rate limits (Settings > GitHub Token)
- Background refresh can be disabled in Settings
- All orientations supported on iPad

Contact: [YOUR SUPPORT EMAIL]
```

## Post-Release Documentation

After successful release:
- [ ] **Tag release** - `git tag v1.0.0 && git push --tags`
- [ ] **Update CHANGELOG.md** - Mark version as released with date
- [ ] **Archive build** - Save .xcarchive for potential rollback
- [ ] **Document metrics** - Record baseline crash rate, downloads
- [ ] **Plan next release** - Update roadmap based on feedback
