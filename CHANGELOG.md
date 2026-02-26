# Changelog

All notable changes to Differ will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- iOS Keychain storage for GitHub tokens (migrated from UserDefaults)
- Privacy manifest file (PrivacyInfo.xcprivacy) for App Store compliance
- In-app Licenses & Attribution view showing all third-party data sources
- Privacy Policy and Support links in Settings (placeholders - update before release)
- LICENSES.md documentation for third-party content
- Comprehensive release checklist and CI pipeline
- Seed file validation script

### Changed
- iPad now supports all orientations (portrait + landscape)
- Background refresh toggle now properly controls background updates
- Removed unlicensed data sources (rodchristiansen, mobileconfig-profiles, Mac-Nerd)
- Updated mdm_catalog_seed.json to contain only licensed sources (1,973 keys from 3 sources)
- Synchronized project.yml with actual Xcode project configuration
- Updated documentation to accurately reflect app capabilities

### Fixed
- Data integrity: Removed source enum cases that caused decode failures
- Documentation accuracy: Removed false claims about embedded bundles
- Background refresh scheduling respects user toggle setting
- Bundle ID consistency across all configuration files

### Security
- GitHub tokens now stored in iOS Keychain instead of UserDefaults
- Automatic migration for existing users' tokens

### Removed
- Support for Mac-Nerd/Mac-profiles (no license found)
- Support for rodchristiansen repositories (no license)
- Embedded repository bundles (not actually included in build)

## [1.0.0] - YYYY-MM-DD

### Rollback Criteria
Stop rollout if:
- Crash rate exceeds 5%
- Critical bug affects >10% of users
- App Review rejection
- Security vulnerability discovered
- Legal/compliance issue identified

### Rollback Steps
1. Pause phased release in App Store Connect
2. Create hotfix branch from last stable tag
3. Fix critical issue
4. Fast-track TestFlight build
5. Submit for expedited review
6. Update this changelog with incident details

---

## Release Template

Copy this template for each new release:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Security
- Security improvements

### Deprecated
- Features marked for removal

### Removed
- Features removed

### Rollback Criteria
- Specific conditions that would trigger rollback

### Known Issues
- Issues being tracked for future releases

### Metrics (Post-Release)
- Crash rate: X.X%
- Downloads (first week): X
- Average rating: X.X/5.0
- Key feedback themes: [summarize]
```

---

## Version History

### How to Read Versions

- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
  - **MAJOR**: Incompatible API changes or major redesigns
  - **MINOR**: New features in a backwards-compatible manner
  - **PATCH**: Backwards-compatible bug fixes

### Release Cadence

- **Patch releases**: As needed for critical fixes (within days)
- **Minor releases**: Every 2-4 weeks for new features
- **Major releases**: 1-2 times per year for significant changes

---

## Links

- [App Store Page](https://apps.apple.com/app/idXXXXXXXXXX)
- [TestFlight](https://testflight.apple.com/join/XXXXXXXX)
- [GitHub Repository](https://github.com/yourusername/differ)
- [Issue Tracker](https://github.com/yourusername/differ/issues)
