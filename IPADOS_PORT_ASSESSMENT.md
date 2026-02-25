# Differ — iPadOS Port Assessment

**Source App:** Differ for macOS v1.1.0
**Assessment Date:** 2026-02-25
**Target Platform:** iPadOS 16.0+

---

## Executive Summary

Differ is an MDM profile comparison tool built almost entirely in SwiftUI, which makes an iPadOS port **technically feasible**. The core business logic (diff engine, parsers, MDM catalog, networking) is platform-agnostic and would carry over with zero or minimal changes. The main work lies in replacing macOS-specific shell/process/AppKit APIs, rethinking the navigation model for touch input, and adapting the file access model to iOS sandbox constraints.

**Rough effort estimate:** Medium–High. The logic layer is ~70% portable as-is; the UI/platform layer needs significant re-work.

---

## 1. What Ports With No Changes

These files are pure Swift with no platform-specific imports. Copy them in and they compile.

| File | Why It Ports |
|---|---|
| `DiffEngine.swift` | Pure actor-based Swift logic, no platform APIs |
| `BatchDiffEngine.swift` | Same — pure computation |
| `ProfileParser.swift` | Foundation-only (Data, String, XMLParser) |
| `SignatureStripper.swift` | Data manipulation only |
| `XMLValidator.swift` | Foundation XML APIs |
| `ProfileLibraryStore.swift` | JSONEncoder/Decoder + FileManager — all available on iOS |
| `MDMCatalogStore.swift` | JSON persistence + Application Support path — works on iOS |
| `GitHubService.swift` | URLSession + async/await — fully cross-platform |
| `MDMNotificationService.swift` | UNUserNotificationCenter exists on iOS |
| `ProfileKeyValidator.swift` | Pure logic |
| `ProfileAnalytics.swift` | Pure logic |
| `BulkImporter.swift` | Pure logic |
| `IntuneZipParser.swift` | ZIPFoundation is cross-platform |
| `AppLogger.swift` | FileHandle + os.log — both on iOS |
| `IssueReportService.swift` | Log aggregation only |
| `ProfileTemplateService.swift` | Pure data |
| `RepositoryBundleService.swift` | Bundle resource loading — works on iOS |
| **All Models** | `Profile.swift`, `DiffResult.swift`, `MDMCatalog.swift`, `MDMNotificationLog.swift` — Codable structs, platform-agnostic |
| **SPM Dependencies** | `ZIPFoundation` and `Yams` both support iOS |
| **Embedded Resources** | `ProfileManifests-master/`, `mdm_catalog_seed.json` — bundle resources, no changes needed |

---

## 2. What Ports With Modifications

These files compile on iOS but require targeted changes to specific code paths.

### 2.1 `AppState.swift` (~2,100 lines — central state)

**Ports:** All @Published state, ObservableObject pattern, async methods, Codable persistence, URLSession calls.

**Changes needed:**
- Remove the `--mdm-background-refresh-agent` process-launch path (no child processes on iOS). Replace with `BGAppRefreshTask` which `MDMUpdateService` already partially supports.
- Remove Jamf credentials storage that assumes Keychain with macOS entitlements — use iOS Keychain APIs (`kSecClass`, `SecItemAdd`) instead, or SecureEnclave.
- The `openWindow(id:)` environment action is not available on iPadOS. Remove or replace with `NavigationPath` / `.sheet`.

### 2.2 `MDMUpdateService.swift`

**Ports:** The `BGAppRefreshTask` branch (`#if os(iOS)`) already exists and compiles.

**Changes needed:**
- Remove the `#if os(macOS)` branch that spawns a separate process via `Process` / `NSTask`.
- Register `BGAppRefreshTask` identifier in iPadOS `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`).

### 2.3 `MDMSourceIngestor.swift`

**Ports:** All URLSession fetching and parsing.

**Changes needed:** None in logic; verify HTTPS-only requirement still holds (it does — `NSAllowsArbitraryLoads: false` applies on iOS too).

### 2.4 `DiffExporter.swift`

**Ports:** Markdown, HTML, JSON, CSV, Plain Text export.

**Needs work:**
- PDF export uses `AppKit` (`NSAttributedString` + `NSPrintInfo`). On iPadOS use `UIGraphicsPDFRenderer` or `WebKit` → PDF instead. `PDFKit` itself is available on iOS but the AppKit rendering pipeline is not.
- `exportToFile(to: URL)` writes to an arbitrary path. On iOS, writes must go to the app sandbox or to a user-picked location via `UIDocumentPickerViewController` / SwiftUI `.fileExporter`.

### 2.5 `PlatformColors.swift`

**Ports:** The concept — mapping semantic colors to platform colours.

**Needs work:** Replace every `NSColor.*` call with `UIColor.*` equivalents:
```swift
// macOS
Color(nsColor: NSColor.windowBackgroundColor)
// iPadOS
Color(uiColor: UIColor.systemBackground)
```
This is a mechanical find-and-replace, not a design decision.

### 2.6 `TestPlan.swift` — `DeviceInfo`

**Ports:** `TestPlan`, `TestCategory`, `TestCase`, `TestStatus` — all pure models.

**Needs work:**
- `DeviceInfo` uses `sysctl()` for hardware model and `IORegistry` (`IOServiceGetMatchingService`, `IOPlatformExpertDevice`) for serial number — both unavailable on iOS.
- Replace with:
  - `UIDevice.current.model` → device model string
  - `UIDevice.current.systemVersion` → OS version
  - Serial number is not accessible from iPadOS apps; omit or use `UIDevice.current.identifierForVendor`.

### 2.7 `ContentView.swift`

**Ports:** All 12+ tab definitions, sub-views, test plan panel.

**Needs work:**
- Minimum window size of `1250×780` must be removed — iPadOS adapts to screen size.
- Tab bar works on iPadOS but consider `NavigationSplitView` (sidebar + detail) for large-screen iPads, which is the iPadOS HIG-recommended pattern for complex apps.
- The right-side Test Plan drawer (600pt fixed width) needs to become an adaptive panel or sheet.
- `.textSelection(.enabled)` and `.focusedSceneValue` work on iPadOS — no change needed.

### 2.8 `ProfilePickerSheet.swift` / `ImportSourceSheet.swift`

**Ports:** Sheet presentation, list UI.

**Needs work:** File import currently relies on SwiftUI `fileImporter` which is cross-platform. Verify that the profile picker's "open from Desktop/Documents/Downloads" logic is replaced with the SwiftUI file importer modifier — direct path access (`~/Desktop`, `~/Documents`) is not available in the iOS sandbox.

### 2.9 `ProfileManifestService.swift`

**Ports:** The core manifest parsing and caching.

**Needs work:** Any path that writes to `~/Library/Application Support/Differ/` must use `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` — this API works on iOS, but verify it's consistently used rather than hardcoded macOS paths.

### 2.10 `JamfService.swift`

**Ports:** URLSession Jamf API calls.

**Needs work:** Credential storage must use iOS Keychain, not macOS Keychain entitlements. The Hardened Runtime entitlement (`ENABLE_HARDENED_RUNTIME`) doesn't apply to iOS.

### 2.11 `GitHubPickerTab.swift` / `GitHubIntegrationView.swift`

**Ports:** All SwiftUI view code.

**Needs work:** GitHub token storage — ensure it uses iOS Keychain, not macOS-specific secure storage.

### 2.12 Keyboard Shortcuts (`DifferApp.swift`)

**Ports:** iPadOS supports `keyboardShortcut()` for external keyboards.

**Needs work:** `CommandMenu` and `CommandGroup` are macOS concepts tied to the app menu bar. On iPadOS these are ignored; shortcuts still fire with external keyboards via `.keyboardShortcut()` on buttons/controls, but the menu bar entries won't appear. Users need discoverability via a keyboard shortcut sheet instead.

---

## 3. What Does Not Port (macOS-Only)

These features have no direct iPadOS equivalent and must be dropped, reimagined, or replaced.

### 3.1 Menu Bar Helper (`MenuBarHelper/DifferMenuBarHelperApp.swift`) — **Drop**

The entire `MenuBarHelper` target is macOS-only:
- `MenuBarExtra` → Not available on iPadOS
- `NSApp.setActivationPolicy(.accessory)` → No concept on iOS
- `LSUIElement = true` (background app) → No concept on iOS
- `NSWorkspace` to launch/activate another app → Not available on iOS
- 30-second polling loop to check for notification updates → iOS background execution model is fundamentally different

**iPadOS replacement:** Push notifications via `UNUserNotificationCenter` (already partially implemented in `MDMNotificationService`), and a badge on the app icon for unread MDM changes. The in-app `MDMNotificationLogView` handles history.

### 3.2 Background Refresh Agent Process — **Replace**

The macOS app spawns itself as a child process with `--mdm-background-refresh-agent` using `NSTask`/`Process`. This is not available on iOS.

**iPadOS replacement:** `BGAppRefreshTask` (the iOS branch already exists in `MDMUpdateService.swift`) scheduled with `BGTaskScheduler`. This is functionally equivalent for the use case (periodic background catalog refresh) though with stricter OS-controlled scheduling.

### 3.3 `NSWorkspace` — **No equivalent**

Used in `DifferMenuBarHelperApp` to open/activate the main app. With no separate helper app on iPadOS this entire code path is eliminated.

### 3.4 `NSRunningApplication` — **No equivalent**

Used to check if the main Differ app is running from the menu bar helper. Eliminated with the helper app.

### 3.5 `NSApplication` / `NSApplicationDelegate` — **No equivalent**

- `applicationShouldTerminateAfterLastWindowClosed()` returning `false` is macOS-only. UIKit lifecycle manages this automatically on iOS.
- `NSApplication.setActivationPolicy(.prohibited)` / `.accessory` — iOS has no equivalent; the OS manages app lifecycle.
- `NSApplication.shared.activate(ignoringOtherApps:)` — iOS apps cannot force-activate themselves.

**iPadOS replacement:** Use `UIApplicationDelegate` / `@UIApplicationDelegateAdaptor` and SwiftUI `App` lifecycle, which is already the pattern used — just remove the macOS-specific AppKit overlay.

### 3.6 `sysctl()` Hardware Detection — **No equivalent**

Used in `TestPlan.swift → DeviceInfo` for hardware model string. Not available in the iOS sandbox.

**iPadOS replacement:** `UIDevice.current.model` and `ProcessInfo.processInfo.operatingSystemVersionString`. Serial number cannot be retrieved — use `UIDevice.current.identifierForVendor` as a stable device identifier.

### 3.7 `IOKit` (IORegistry) — **No equivalent**

Used for serial number retrieval via `IOServiceGetMatchingService`, `IOPlatformExpertDevice`, `IORegistryEntryCreateCFProperty`. The `IOKit` framework is not available on iOS.

**iPadOS replacement:** See 3.6 above.

### 3.8 Direct File System Access (Desktop / Documents / Downloads) — **Sandboxed**

The macOS app has entitlements for direct folder access (`NSDesktopFolderUsageDescription`, etc.). iOS apps are sandboxed; users must explicitly grant access to files via:
- SwiftUI `.fileImporter` modifier
- SwiftUI `.fileExporter` modifier
- `UIDocumentPickerViewController`

The app's existing `ProfilePickerSheet` and `ImportSourceSheet` UI needs to funnel all file operations through these pickers.

### 3.9 `PDFKit` / AppKit PDF Rendering — **Partially available**

`PDFKit.framework` exists on iOS, but `DiffExporter` uses the AppKit rendering pipeline (`NSAttributedString` with `NSPrintInfo`, `NSView`). This must be rewritten using `UIGraphicsPDFRenderer`.

### 3.10 `openWindow(id:)` — **Not on iPadOS**

The environment action for opening new windows is macOS/visionOS only. iPadOS apps are single-window (with some multi-window opt-in via `UISceneDelegate`, but not the same model).

**iPadOS replacement:** Sheets (`.sheet`), full-screen covers (`.fullScreenCover`), or navigation pushes.

### 3.11 `NSColor` — **No equivalent**

`PlatformColors.swift` wraps `NSColor.*` semantic colours. On iOS use `UIColor.*` equivalents. This is a mechanical replacement, but it must be done.

### 3.12 Hardened Runtime & macOS Entitlements — **Not applicable**

`ENABLE_HARDENED_RUNTIME` and the file-access entitlements in `project.yml` are macOS-only. iOS uses a different entitlement model; remove the macOS entitlements and add iOS-specific ones (`com.apple.developer.icloud-container-identifiers` if CloudKit sync is desired, etc.).

### 3.13 `ProcessInfo.processInfo.arguments` for Launch Mode — **Remove**

The mechanism for detecting the `--mdm-background-refresh-agent` argument to switch the app into a headless background-only mode has no purpose on iOS (no child processes). The entire launch-mode-detection block in `DifferApp.swift` should be removed and replaced by `BGTaskScheduler` registration.

---

## 4. Feature Parity Assessment by Tab

| Tab | Port Status | Notes |
|---|---|---|
| **Diff** | ✅ Full port | Core DiffEngine ports; view needs touch-friendly sizing |
| **Validator** | ✅ Full port | Pure SwiftUI + ProfileKeyValidator |
| **Freehand Builder** | ✅ Full port | SwiftUI form — works on iPadOS |
| **Profile Library** | ✅ Full port | JSON persistence works; file import via picker |
| **Advanced Search** | ✅ Full port | MDM catalog search, pure SwiftUI |
| **Apple MDM Library** | ✅ Full port | Static data, SwiftUI views |
| **GitHub Integration** | ✅ Full port | URLSession + token storage (use Keychain) |
| **Batch Diff** | ✅ Full port | BatchDiffEngine is platform-agnostic |
| **Analytics** | ✅ Full port | Pure computation + SwiftUI charts |
| **Templates** | ✅ Full port | Pure data + SwiftUI |
| **Settings** | 🔶 Partial | Remove macOS-specific options (menu bar helper, background agent toggle); keep GitHub token, text size, MDM sources, tab visibility |
| **Menu Bar Helper** | ❌ Drop | No menu bar on iPadOS; replace with push notifications + badge |
| **Background MDM Refresh** | 🔶 Replace | Reimplement as `BGAppRefreshTask` |
| **PDF Export** | 🔶 Replace | Rewrite AppKit PDF path with `UIGraphicsPDFRenderer` |
| **Jamf Integration** | 🔶 Partial | API calls port; Keychain storage needs iOS APIs |
| **Log Viewer** | ✅ Full port | File-based logging works on iOS |
| **Test Plan** | 🔶 Partial | Models port; `DeviceInfo` needs UIDevice replacements |
| **Issue Report** | 🔶 Partial | Log export needs file exporter picker |

---

## 5. UI/UX Adaptations Required for iPadOS

Beyond API changes, the interface needs touch-first thinking:

1. **Navigation Model:** Switch from a flat `TabView` to `NavigationSplitView` (sidebar + content + detail) to match the iPadOS HIG for complex apps. This uses screen real estate better on 11" and 13" iPads.

2. **Touch Target Sizes:** Many toolbar buttons and diff-list rows are sized for mouse precision. Ensure all interactive elements are ≥44×44pt per HIG.

3. **Context Menus:** Right-click menus become long-press context menus on iPadOS (`contextMenu` modifier is cross-platform in SwiftUI).

4. **Drag & Drop:** iPadOS supports drag & drop for importing profiles. Add `.dropDestination` to the profile library and diff panes.

5. **Window Constraints:** Remove the `1250×780` minimum window size. The app should work at `768pt` wide (iPad mini landscape).

6. **Pointer Support:** iPadOS supports pointer (trackpad/mouse). The existing hover states should work but should be tested.

7. **Keyboard Shortcut Discovery:** Replace macOS menu bar shortcuts with a `.keyboardShortcut` discoverability sheet (slide-in overlay listing available shortcuts) since the menu bar doesn't exist.

8. **File Picker Integration:** Every "open file" flow must use SwiftUI's `.fileImporter` and every "save file" flow must use `.fileExporter`. No direct path access.

9. **Split View / Stage Manager:** The app should test gracefully in Stage Manager (iPadOS 16+) and iPad Split View/Slide Over. Remove fixed frame constraints that prevent flexible layout.

---

## 6. Recommended Porting Strategy

### Phase 1 — Logic Layer (No UI changes)
1. Create a new iPadOS target in Xcode pointing at the same Swift sources.
2. Add `#if os(macOS)` / `#if os(iOS)` guards around macOS-only code (NSWorkspace, IOKit, sysctl, Process).
3. Fix `PlatformColors.swift` with UIColor equivalents.
4. Fix `TestPlan.swift` DeviceInfo with UIDevice.
5. Confirm all SPM packages build for iOS (ZIPFoundation ✅, Yams ✅).
6. Achieve a clean compile for the logic layer.

### Phase 2 — Platform Services
7. Register `BGAppRefreshTask` and wire up the existing iOS branch in `MDMUpdateService`.
8. Replace file export paths in `DiffExporter` with `.fileExporter` / `UIGraphicsPDFRenderer`.
9. Replace Keychain storage with iOS Keychain APIs.
10. Remove `MenuBarHelper` target and all references.
11. Remove launch-argument background agent logic from `DifferApp.swift`.

### Phase 3 — UI Adaptation
12. Replace `WindowGroup` constraints with responsive layout.
13. Implement `NavigationSplitView` sidebar for iPad.
14. Add drag-and-drop targets.
15. Audit touch target sizes.
16. Replace menu bar keyboard shortcut discovery with an in-app sheet.

### Phase 4 — Polish & Testing
17. Test on iPad mini (smallest common target), 11" iPad Pro, 13" iPad Pro.
18. Test Stage Manager multi-window.
19. Test with external keyboard.
20. Test `BGAppRefreshTask` lifecycle.

---

## 7. Dependency & Framework Summary

| Dependency | iPadOS Available | Action |
|---|---|---|
| SwiftUI | ✅ Yes | No change |
| Foundation | ✅ Yes | No change |
| UserNotifications | ✅ Yes | No change |
| BackgroundTasks | ✅ Yes | Wire up iOS branch |
| PDFKit | ✅ Yes (partial) | Rewrite AppKit rendering path |
| ZIPFoundation (SPM) | ✅ Yes | No change |
| Yams (SPM) | ✅ Yes | No change |
| AppKit | ❌ No | Remove all usage |
| IOKit | ❌ No | Remove (DeviceInfo only) |
| Darwin `sysctl` | ❌ No | Remove (DeviceInfo only) |
| NSWorkspace | ❌ No | Remove (MenuBarHelper only) |
| NSRunningApplication | ❌ No | Remove (MenuBarHelper only) |
| Process / NSTask | ❌ No | Remove (background agent only) |

---

## 8. Estimated Effort Breakdown

| Area | Effort |
|---|---|
| Logic layer compile fixes (guards, DeviceInfo, colors) | Small (1–2 days) |
| Background task migration | Small (1 day) |
| PDF export rewrite | Small–Medium (1–2 days) |
| File import/export via pickers | Small (1–2 days) |
| Remove MenuBarHelper target + references | Small (<1 day) |
| NavigationSplitView sidebar | Medium (3–5 days) |
| Touch target audit + responsive layout | Medium (3–4 days) |
| Drag & drop support | Small–Medium (1–2 days) |
| Keychain / credential storage | Small (1 day) |
| Testing (devices, orientations, Stage Manager) | Medium (3–5 days) |
| **Total** | **~3–4 weeks** |

---

## Conclusion

The Differ codebase is well-structured for cross-platform expansion. Approximately **70% of the codebase** (all models, all core services, most views) ports to iPadOS with zero or trivial changes. The remaining work is concentrated in three areas: eliminating the macOS process/workspace/menu-bar layer, adapting file access to the iOS sandbox model, and rethinking the navigation layout for touch. None of the blockers are fundamental — they are all mechanical substitutions with well-documented iPadOS equivalents.
