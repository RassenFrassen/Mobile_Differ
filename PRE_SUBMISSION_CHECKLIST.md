# Pre-Submission Checklist

Use this checklist to track your progress toward App Store submission.

---

## ✅ Code Implementation (COMPLETE)

- [x] Onboarding view for first launch
- [x] Empty state views for all lists
- [x] Improved error handling
- [x] Accessibility labels and VoiceOver support
- [x] iPad layout optimization
- [x] Haptic feedback
- [x] Pull-to-refresh
- [x] Loading states
- [x] Build succeeds without errors

---

## 🚨 Critical Blockers (MUST DO)

### Privacy Policy
- [ ] Create privacy policy web page
- [ ] Host it at a public URL
- [ ] Update `MDMKeys/Views/SettingsView.swift` line 202
- [ ] Replace `https://yourwebsite.com/privacy` with actual URL

**What to include in privacy policy:**
```
- What data is collected: GitHub token (optional, stored locally in Keychain)
- How it's used: Only sent to GitHub API for public repository access
- Data storage: All data stored locally on device
- No tracking or analytics
- No data shared with third parties
- Contact information for privacy questions
```

### Support URL
- [ ] Create support page OR use GitHub Issues
- [ ] Update `MDMKeys/Views/SettingsView.swift` line 206
- [ ] Replace `https://yourwebsite.com/support` with actual URL

**Suggested options:**
- GitHub Issues: `https://github.com/yourusername/differ/issues`
- GitHub Discussions: `https://github.com/yourusername/differ/discussions`
- Simple contact page with email
- Support email: `mailto:your.email@example.com`

### App Store Screenshots
- [ ] iPhone 6.7" (iPhone 15 Pro Max) - 6 screenshots
  - [ ] Screenshot 1: Payloads list view
  - [ ] Screenshot 2: Keys browser with search
  - [ ] Screenshot 3: Key detail view
  - [ ] Screenshot 4: Compatibility checker
  - [ ] Screenshot 5: Updates/notifications
  - [ ] Screenshot 6: Profile XML example
- [ ] iPad 12.9" (iPad Pro) - 4 screenshots
  - [ ] Screenshot 1: Split view (payloads)
  - [ ] Screenshot 2: Keys with filters
  - [ ] Screenshot 3: Compatibility view
  - [ ] Screenshot 4: Documentation view

**Screenshot tips:**
- Use light mode for consistency
- Add text overlays (optional but recommended)
- Show real data from actual app
- Capture at required sizes (use Simulator)
- Export at 100% scale

---

## 📱 Testing (RECOMMENDED)

### On Real Devices
- [ ] Test on iPhone (iOS 18+)
- [ ] Test on iPad (iPadOS 18+)
- [ ] Verify onboarding shows on first launch
- [ ] Test pull-to-refresh on all tabs
- [ ] Verify haptic feedback works
- [ ] Test VoiceOver navigation
- [ ] Test all search and filter combinations

### Functionality Testing
- [ ] Background refresh works (enable in Settings)
- [ ] Notifications appear when catalog changes
- [ ] GitHub token saves to Keychain
- [ ] Offline browsing works (airplane mode)
- [ ] All navigation flows work correctly
- [ ] Share functionality works
- [ ] Profile examples generate correctly
- [ ] Empty states appear when expected

### Performance Testing
- [ ] App launches quickly
- [ ] Scrolling is smooth
- [ ] Search is responsive
- [ ] No memory leaks
- [ ] Background refresh doesn't drain battery

---

## 📄 App Store Connect Setup

### App Information
- [ ] Create app in App Store Connect
- [ ] Set app name: "Differ - MDM Keys"
- [ ] Set subtitle: "Apple MDM Configuration Reference"
- [ ] Add app icon (1024x1024)
- [ ] Choose categories: Developer Tools, Productivity

### Version Information (1.0)
- [ ] Copy description from `APP_STORE_METADATA.md`
- [ ] Add keywords (see metadata file)
- [ ] Write "What's New" text
- [ ] Add promotional text (optional)
- [ ] Set support URL (after creating page)
- [ ] Set marketing URL (optional)

### Privacy
- [ ] Complete App Privacy questionnaire
  - [ ] Select "Data Not Collected"
  - [ ] Declare GitHub API usage
  - [ ] Add privacy policy URL
- [ ] Verify PrivacyInfo.xcprivacy is included in build

### Pricing & Availability
- [ ] Choose price tier (suggest $2.99-4.99 or Free)
- [ ] Select all territories (or specific ones)
- [ ] Set release date (manual release recommended)

### Age Rating
- [ ] Complete questionnaire
- [ ] Should result in 4+ rating
- [ ] No objectionable content

---

## 🔧 Build Configuration

### Project Settings
- [ ] Update marketing version in `project.yml`
- [ ] Update build number (starts at 1)
- [ ] Verify bundle ID is correct
- [ ] Check code signing is configured
- [ ] Verify all required capabilities are enabled

### Pre-Archive Checks
- [ ] Run `python3 scripts/validate_seed.py`
- [ ] Build in Release configuration succeeds
- [ ] No warnings in build log
- [ ] Archive validation passes
- [ ] TestFlight upload succeeds

---

## 🧪 TestFlight Beta (RECOMMENDED)

### Upload Build
- [ ] Archive app in Xcode
- [ ] Upload to App Store Connect
- [ ] Wait for processing to complete
- [ ] Add build to TestFlight

### Beta Testing
- [ ] Add external testers (2-3 minimum)
- [ ] Write beta testing notes
- [ ] Send to testers
- [ ] Collect feedback
- [ ] Fix critical bugs (if any)
- [ ] Upload new build if needed

### What to Ask Testers
- Can you complete onboarding?
- Does search work well?
- Are filters intuitive?
- Do notifications work?
- Is the app useful for your work?
- Any bugs or crashes?
- Anything confusing?

---

## 📋 Final Submission

### Pre-Submit Checks
- [ ] All screenshots uploaded
- [ ] App description complete
- [ ] Privacy policy URL working
- [ ] Support URL working
- [ ] Keywords added
- [ ] Age rating complete
- [ ] Pricing set
- [ ] Build selected
- [ ] App Privacy complete

### App Review Information
- [ ] Add contact name
- [ ] Add contact phone number
- [ ] Add contact email
- [ ] Add notes for reviewer (see APP_STORE_METADATA.md)
- [ ] No demo account needed

### Export Compliance
- [ ] Select "Yes" for uses encryption
- [ ] Select "Yes" for encryption exempt (HTTPS only)
- [ ] No export compliance code needed

### Submit
- [ ] Review all information one final time
- [ ] Click "Submit for Review"
- [ ] Monitor review status
- [ ] Respond to any reviewer questions within 24 hours

---

## ⏱️ Timeline Estimates

**Before TestFlight:** 2-4 hours
- Create privacy policy: 30-60 minutes
- Create support page: 15-30 minutes
- Update URLs in code: 5 minutes
- Take screenshots: 60-90 minutes
- Archive and upload: 30 minutes

**TestFlight Beta:** 3-7 days
- Tester feedback: 2-5 days
- Bug fixes: 1-2 days (if needed)

**App Store Review:** 1-3 days (typical)
- Review time: 24-48 hours
- Back-and-forth: 0-24 hours

**Total time to App Store:** 1-2 weeks

---

## 🆘 If Rejected

Common rejection reasons and fixes:

### Incomplete Metadata
- **Fix:** Complete all required fields in App Store Connect

### Broken Links
- **Fix:** Verify privacy policy and support URLs load correctly

### Privacy Issues
- **Fix:** Ensure privacy policy matches App Privacy questionnaire

### Crashes
- **Fix:** Test on real devices, fix crashes, resubmit

### Guideline Violations
- **Fix:** Read rejection message carefully, address specific issue

### Metadata Issues
- **Fix:** Update description/screenshots to be more clear

---

## 📞 Getting Help

If you get stuck:

1. **Apple Documentation:** https://developer.apple.com/app-store/review/
2. **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
3. **Privacy Requirements:** https://developer.apple.com/app-store/user-privacy-and-data-use/
4. **TestFlight:** https://developer.apple.com/testflight/

---

## ✨ You're Almost There!

The hard work is done. Just complete the blockers and you'll be in the App Store!

**Current status:** Code complete, build successful ✅
**Remaining:** Privacy policy, support URL, screenshots
**Estimated time to submit:** 2-4 hours of work

Good luck! 🚀

---

*Last updated: 2026-02-25*
