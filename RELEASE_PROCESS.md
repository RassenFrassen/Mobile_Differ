# Release Process

Complete guide for shipping Differ updates safely and reliably.

## Table of Contents

1. [Overview](#overview)
2. [Pre-Release Phase](#pre-release-phase)
3. [TestFlight Release](#testflight-release)
4. [Production Release](#production-release)
5. [Post-Release Monitoring](#post-release-monitoring)
6. [Rollback Procedures](#rollback-procedures)
7. [Hotfix Process](#hotfix-process)

---

## Overview

### Release Strategy

- **TestFlight First**: All releases go through TestFlight for internal/external testing
- **Phased Rollout**: Production releases start at 1% and gradually increase
- **Quick Rollback**: Ability to pause/rollback releases within minutes
- **Automated Validation**: CI runs comprehensive checks before any release

### Release Types

1. **Patch (X.Y.Z)**: Critical bug fixes, security updates
   - Timeline: 1-2 days (can be expedited)
   - TestFlight: 24-48 hours minimum
   - Rollout: 7-day phased release

2. **Minor (X.Y.0)**: New features, improvements
   - Timeline: 1-2 weeks
   - TestFlight: 3-7 days
   - Rollout: 7-day phased release

3. **Major (X.0.0)**: Breaking changes, redesigns
   - Timeline: 2-4 weeks
   - TestFlight: 1-2 weeks
   - Rollout: 30-day phased release

---

## Pre-Release Phase

### Step 1: Version Preparation

```bash
# 1. Create release branch
git checkout -b release/1.1.0

# 2. Update version numbers
# Edit project.yml:
#   MARKETING_VERSION: 1.1.0
#   CURRENT_PROJECT_VERSION: 2

# 3. Update CHANGELOG.md
# Move items from [Unreleased] to [1.1.0] with today's date

# 4. Commit version bump
git add project.yml CHANGELOG.md
git commit -m "chore: bump version to 1.1.0"
```

### Step 2: Pre-Release Checklist

Run through `RELEASE_CHECKLIST.md` completely:

```bash
# Validate seed file
python3 scripts/validate_seed.py

# Run CI checks locally
xcodebuild clean build -project Differ.xcodeproj -scheme Differ

# Manual testing
# - Launch app and verify seed loads
# - Test all critical user paths
# - Verify settings toggles work
# - Test on iPad (all orientations)
```

### Step 3: CI Validation

Push to GitHub and ensure all CI checks pass:

```bash
git push origin release/1.1.0
```

Watch GitHub Actions:
- ✅ Build and Test
- ✅ Release Build Validation
- ✅ Static Policy Checks
- ✅ Security Scan

**Do not proceed if any CI checks fail.**

---

## TestFlight Release

### Step 1: Create Archive

In Xcode:

1. **Product → Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Select **App Store Connect**
5. Upload build

Or via command line:

```bash
xcodebuild archive \
  -project Differ.xcodeproj \
  -scheme Differ \
  -archivePath ./build/Differ.xcarchive

xcodebuild -exportArchive \
  -archivePath ./build/Differ.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### Step 2: Add TestFlight Build Information

In App Store Connect:

1. Navigate to build
2. Add **What to Test** notes:

```
Version 1.1.0 - What's New:

- [Feature 1 description]
- [Feature 2 description]
- [Bug fix 1]

Testing Focus:
- Verify [specific feature] works as expected
- Test [workflow] on both iPhone and iPad
- Confirm [setting] properly controls behavior

Known Issues:
- [Issue 1 if any]

Rollback Plan:
- Critical issues will trigger immediate rollback
- See CHANGELOG.md for rollback criteria
```

### Step 3: Internal Testing (1-3 days)

1. Release to internal testers
2. Test all critical paths personally
3. Monitor crash reports in TestFlight
4. Collect feedback from team

**Go/No-Go Decision**:
- No crashes? ✅ Proceed
- Any crashes? ❌ Fix and re-release to TestFlight

### Step 4: External Testing (Optional, 3-7 days)

1. Release to external beta testers
2. Monitor feedback and crash reports
3. Address any critical issues
4. Collect feature feedback for future releases

---

## Production Release

### Step 1: Prepare for Submission

```bash
# Merge release branch to main
git checkout main
git merge release/1.1.0

# Tag the release
git tag v1.1.0
git push origin main --tags
```

### Step 2: App Store Connect Setup

1. **Select build** in App Store Connect
2. **Update version information**:
   - Version number: 1.1.0
   - What's New in This Version:

```
• [User-facing feature 1]
• [User-facing feature 2]
• Bug fixes and performance improvements
```

3. **Screenshots** (if UI changed)
   - iPhone: 6.7" and 5.5"
   - iPad: 12.9" and 6.

"

4. **Review Information**:
   - Add notes for App Review (see template in RELEASE_CHECKLIST.md)
   - Demo account if needed
   - Contact information

5. **Phased Release**:
   - ✅ Enable phased release
   - Start with 1% rollout (Day 1)

### Step 3: Submit for Review

1. Click **Submit for Review**
2. Confirm all information is correct
3. Monitor review status

**Typical Review Times:**
- Standard: 24-48 hours
- Expedited (if needed): 24 hours
- Rejected: Fix and resubmit

### Step 4: Phased Rollout Schedule

Once approved:

- **Day 1**: 1% of users
- **Day 2**: 2% of users (if stable)
- **Day 3**: 5% of users
- **Day 4**: 10% of users
- **Day 5**: 20% of users
- **Day 6**: 50% of users
- **Day 7**: 100% of users

**Pause rollout if:**
- Crash rate >5%
- Critical bug reports
- Security issue
- App Store policy violation

---

## Post-Release Monitoring

### Day 1-3: Critical Monitoring

Monitor every 4-6 hours:

1. **Crash Reports** (App Store Connect → Analytics)
   - Goal: <2% crash rate
   - Alert threshold: >5% crash rate

2. **User Reviews** (App Store Connect → Ratings & Reviews)
   - Respond to negative reviews within 24 hours
   - Look for patterns in complaints

3. **Metrics** (App Store Connect → Analytics)
   - Downloads per day
   - Session duration
   - Retention rate

### Week 1: Active Monitoring

Monitor daily:

1. Continue crash report monitoring
2. Track overall rating trend
3. Monitor support requests
4. Document any issues in GitHub

### Week 2-4: Passive Monitoring

Monitor every 2-3 days:

1. Overall stability metrics
2. User feedback themes
3. Plan next release features

### Update CHANGELOG.md

After 1 week, add metrics to release entry:

```markdown
### Metrics (Post-Release)
- Crash rate: 1.2%
- Downloads (first week): 1,500
- Average rating: 4.7/5.0
- Key feedback: Users love [feature], requesting [enhancement]
```

---

## Rollback Procedures

### When to Rollback

Immediately pause/rollback if:

1. **Crash rate >5%** for more than 1 hour
2. **Critical bug** affecting core functionality
3. **Security vulnerability** discovered
4. **App Store policy** violation reported
5. **Data loss** or corruption reports

### Rollback Steps

#### Option 1: Pause Phased Release (Fastest)

1. **App Store Connect** → Your App → App Store tab
2. Click **Pause Phased Release**
3. Users who already updated keep the update
4. New users get previous version

#### Option 2: Submit Previous Version

If critical and Option 1 isn't sufficient:

1. **Prepare hotfix** from previous stable tag:

```bash
git checkout v1.0.9  # Previous stable version
git checkout -b hotfix/1.0.10
```

2. **Bump patch version**:
   - MARKETING_VERSION: 1.0.10
   - CURRENT_PROJECT_VERSION: [increment]

3. **Add hotfix notes** to CHANGELOG.md

4. **Fast-track TestFlight** (test for 24 hours minimum)

5. **Submit for expedited review**:
   - Check "Expedited Review" box
   - Explain critical nature of fix

---

## Hotfix Process

For critical bugs discovered in production:

### Step 1: Assess Severity

**Critical** (immediate hotfix):
- App crashes on launch
- Data loss or corruption
- Security vulnerability
- Core feature completely broken

**High** (hotfix within 1-2 days):
- Major feature broken
- Significant UX issue
- Performance degradation

**Medium/Low** (include in next regular release):
- Minor bugs
- Edge case issues
- Enhancement requests

### Step 2: Create Hotfix Branch

```bash
# Branch from last stable release tag
git checkout v1.1.0
git checkout -b hotfix/1.1.1

# Fix the issue
# ... make changes ...

# Test thoroughly
python3 scripts/validate_seed.py
xcodebuild clean build test

# Commit fix
git commit -m "fix: [description of critical fix]"
```

### Step 3: Version Bump

```bash
# Update project.yml
MARKETING_VERSION: 1.1.1
CURRENT_PROJECT_VERSION: [increment]

# Update CHANGELOG.md
## [1.1.1] - 2024-XX-XX

### Fixed
- Critical fix for [issue]

### Rollback Criteria
- Same as 1.1.0

git commit -m "chore: bump version to 1.1.1"
```

### Step 4: Expedited Release

1. **TestFlight** (24 hours minimum testing)
2. **Submit with Expedited Review request**
3. **Monitor closely** during rollout

### Step 5: Post-Hotfix

```bash
# Merge back to main
git checkout main
git merge hotfix/1.1.1

# Tag hotfix
git tag v1.1.1
git push origin main --tags

# Document incident
# Add post-mortem to CHANGELOG.md or separate doc
```

---

## Best Practices

### Do's

✅ **Always test on real devices** (iPhone and iPad)
✅ **Run full checklist** for every release
✅ **Start with small rollout** (1%)
✅ **Monitor actively** first 48 hours
✅ **Keep rollback plan ready**
✅ **Document everything** in CHANGELOG.md
✅ **Respond to reviews** quickly
✅ **Archive builds** for potential rollback

### Don'ts

❌ **Skip TestFlight** testing
❌ **Rush to 100% rollout**
❌ **Ignore crash reports**
❌ **Release on Friday** (weekend monitoring issue)
❌ **Make config changes** in production without testing
❌ **Update without backup** of previous version
❌ **Ignore user feedback**

---

## Contact & Support

- **Release Manager**: [Your Name/Team]
- **Engineering Lead**: [Name]
- **App Store Contact**: [Email]
- **Emergency Contact**: [Phone/Slack]

## Related Documentation

- [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) - Detailed pre-release checklist
- [CHANGELOG.md](./CHANGELOG.md) - Version history and rollback criteria
- [LICENSES.md](./LICENSES.md) - Third-party attribution
- [CI Configuration](./.github/workflows/ci.yml) - Automated validation
