# Differ - MDM Keys Reference

iOS/iPadOS app providing a comprehensive reference catalog of Apple Mobile Device Management (MDM) configuration profile keys for IT administrators and developers.

## Features

- 📚 **1,973 MDM Keys** from official Apple documentation and curated sources
- 🔍 **Search & Filter** - Find keys by payload type, platform, or keyword
- 📱 **126 Payloads** documented with examples
- ⚡ **Offline-First** - Full catalog bundled with app
- 🔄 **Optional Sync** - Background refresh for latest updates
- 📖 **Documentation** - View key descriptions, types, and examples
- 🎨 **Native SwiftUI** - Fast, modern interface

## Data Sources

All data comes from properly licensed sources:

- **Apple device-management** (MIT License) - Official Apple repository
- **Apple Developer Documentation** (Apple Terms of Service) - Official docs
- **ProfileManifests** (MIT License) - Community manifest source
- **rtrouton/profiles** (MIT License) - Community profile samples

See [LICENSES.md](./LICENSES.md) for full attribution.

## Requirements

- iOS/iPadOS 26.0+
- Xcode 16.0+
- Swift 5.9+

## Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/differ.git
cd differ

# Open in Xcode
open Differ.xcodeproj

# Build and run
⌘R
```

## Project Structure

```
Differ/
├── MDMKeys/
│   ├── App/              # App entry point and state
│   ├── Models/           # Data models
│   ├── Services/         # Business logic and networking
│   ├── Views/            # SwiftUI views
│   ├── Resources/        # Assets and seed data
│   └── PrivacyInfo.xcprivacy
├── .github/workflows/    # CI/CD pipelines
├── scripts/              # Build and validation scripts
├── RELEASE_CHECKLIST.md  # Pre-release validation checklist
├── RELEASE_PROCESS.md    # Complete release workflow
├── CHANGELOG.md          # Version history
└── LICENSES.md           # Third-party attribution
```

## Release Process

We follow a structured release process to ensure quality and App Store compliance:

1. **Read** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md) for complete workflow
2. **Follow** [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) before each release
3. **Update** [CHANGELOG.md](./CHANGELOG.md) with version details
4. **TestFlight First** - All releases go through beta testing
5. **Phased Rollout** - Gradual rollout to production (1% → 100%)

### Quick Release Commands

```bash
# Validate before release
python3 scripts/validate_seed.py

# Create release branch
git checkout -b release/1.1.0

# Update version in project.yml
# MARKETING_VERSION: 1.1.0
# CURRENT_PROJECT_VERSION: [increment]

# Build and archive
xcodebuild clean build -project Differ.xcodeproj -scheme Differ

# Tag and push
git tag v1.1.0
git push origin main --tags
```

## CI/CD

Automated checks run on every push/PR:

- ✅ Build validation (Debug & Release)
- ✅ Unit tests
- ✅ Privacy manifest presence check
- ✅ License compliance validation
- ✅ Seed file schema validation
- ✅ Bundle ID consistency check
- ✅ Security scans

See [.github/workflows/ci.yml](./.github/workflows/ci.yml) for details.

## Testing

```bash
# Run tests in Xcode
⌘U

# Run tests from command line
xcodebuild test \
  -project Differ.xcodeproj \
  -scheme Differ \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Privacy & Security

- **Keychain Storage**: GitHub tokens stored securely in iOS Keychain
- **Privacy Manifest**: PrivacyInfo.xcprivacy declares data access
- **No Tracking**: No analytics or user tracking
- **Local First**: All data stored on-device

## App Store Compliance

This app has been prepared for App Store submission with:

- ✅ Privacy manifest (PrivacyInfo.xcprivacy)
- ✅ In-app licenses & attribution
- ✅ Privacy policy and support links (update placeholders before release)
- ✅ Proper data source licensing
- ✅ iPad orientation support
- ✅ Background refresh toggle compliance

**Before submitting to App Store:**
1. Update privacy policy URL in `SettingsView.swift:192`
2. Update support URL in `SettingsView.swift:196`
3. Complete App Privacy questionnaire in App Store Connect
4. Add screenshots and app description

## Contributing

This is currently a solo project, but contributions are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/differ/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/differ/discussions)

## License

App source code: Proprietary - All rights reserved

Third-party data: See [LICENSES.md](./LICENSES.md)

## Acknowledgments

Special thanks to:

- Apple for device-management repository and developer documentation
- ProfileManifests community
- Rich Trouton (rtrouton/profiles)
- All contributors to open-source MDM documentation

## Roadmap

See [CHANGELOG.md](./CHANGELOG.md) for completed features and upcoming releases.

---

Made with ❤️ for Apple IT administrators and developers
