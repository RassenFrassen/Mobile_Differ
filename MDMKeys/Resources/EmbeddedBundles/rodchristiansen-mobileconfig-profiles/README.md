# macOS Configuration Profiles

A curated collection of `.mobileconfig` profiles for managing macOS devices via MDM (Jamf Pro, Microsoft Intune, Mosyle, etc.) or manual installation.

All profiles are fully genericized and ready to adapt to your environment. Replace `com.example.profiles` with your organization's reverse-domain namespace, `ExampleOrganization` with your org name, and generate fresh UUIDs with `uuidgen` before deploying.

---

## Categories

Profiles are organized into four categories based on deployment scope and device context.

### Apps (53 profiles)

Per-application preference management and TCC/PPPC (Privacy Preferences Policy Control) permissions. Each profile targets a specific application's preference domain and, where required, grants privacy access such as Full Disk Access, Accessibility, or Screen Capture.

Deploy these to any Mac that runs the corresponding application.

| Profile | Description |
|---------|-------------|
| AbletonLivePrefs | Ableton Live music production preferences |
| AcrobatPrefs | Adobe Acrobat preferences and update behavior |
| AcrobatReaderPrefs | Adobe Acrobat Reader preferences and update behavior |
| AirMediaPrefs | Crestron AirMedia wireless display preferences and TCC |
| AppStorePrefs | Mac App Store automatic update settings |
| ArduinoPrefs | Arduino IDE preferences and TCC |
| AstropadStudioPrefs | Astropad Studio drawing tablet preferences and TCC |
| AudacityPrefs | Audacity audio editor preferences |
| BBEditPrefs | BBEdit text editor preferences and TCC |
| BlenderPrefs | Blender 3D modeling preferences |
| BooksPrefs | Apple Books preferences |
| CalendarPrefs | Apple Calendar preferences |
| ChromePrefs | Google Chrome browser policy and preferences |
| CompressorPrefs | Apple Compressor preferences |
| CreativeCloudSDLPrefs | Adobe Creative Cloud Shared Device Licensing preferences |
| DefenderPrefs | Microsoft Defender: kernel/system extensions, web content filter, notifications, service management, TCC, and app configuration |
| DetectXPrefs | DetectX Swift system diagnostic preferences |
| FetchPrefs | Fetch FTP client preferences |
| FinalCutPrefs | Apple Final Cut Pro preferences |
| HarmonyPrefs | Toon Boom Harmony animation preferences and TCC |
| HomePrefs | Apple Home preferences |
| HuionPrefs | Huion drawing tablet TCC permissions |
| IINAPrefs | IINA video player preferences |
| ImageCapturePrefs | Apple Image Capture preferences |
| iMoviePrefs | Apple iMovie preferences |
| KeynotePrefs | Apple Keynote preferences |
| LingonPrefs | Lingon launchd editor preferences |
| LogicProPrefs | Apple Logic Pro preferences |
| MailPrefs | Apple Mail preferences |
| MalwarebytesPrefs | Malwarebytes endpoint protection preferences |
| ManagedPythonPrefs | Managed Python runtime preferences and TCC |
| MaxPrefs | Cycling '74 Max audio/visual programming preferences |
| MotionPrefs | Apple Motion preferences |
| NewsPrefs | Apple News preferences |
| NumbersPrefs | Apple Numbers preferences |
| OfficePrefs | Microsoft Office suite (Word, Excel, PowerPoint, OneNote, Outlook, AutoUpdate) and TCC |
| OmniDiskPrefs | OmniDiskSweeper preferences |
| OneDrivePrefs | Microsoft OneDrive sync client preferences |
| OpenTabletPrefs | OpenTabletDriver TCC permissions |
| OutlookPrefs | Microsoft Outlook standalone preferences |
| OutsetPrefs | Outset (open-source boot/login script runner) preferences and TCC |
| PagesPrefs | Apple Pages preferences |
| PCoIPrefs | Parallels Client preferences |
| PreviewPrefs | Apple Preview preferences |
| RedcineXProPrefs | RED Digital Cinema REDCINE-X PRO preferences |
| ScriptsMenuPrefs | macOS Scripts menu preferences |
| SilverfastPrefs | SilverFast scanner software preferences |
| TeamsPrefs | Microsoft Teams preferences |
| TerminalPrefs | macOS Terminal preferences |
| TextEditPrefs | Apple TextEdit preferences |
| VLCprefs | VLC media player preferences |
| WacomPrefs | Wacom drawing tablet TCC permissions |
| ZoomPrefs | Zoom video conferencing preferences and TCC |

### Assigned (11 profiles)

Profiles for one-to-one (1:1) devices where a single user is permanently associated with the Mac. These configure identity, authentication, disk encryption, enrollment behavior, and user experience tuned for personal device ownership.

| Profile | Description |
|---------|-------------|
| AssignedEnergySettings | Scheduled restart and wake times for assigned desktops |
| AssignedFileVaultPrefs | FileVault deferred enablement with recovery key escrowed to MDM |
| AssignedLoginWindow | Screensaver lock, login window text, admin host info display |
| AssignedManagedInstalls | Munki managed installs behavior (update aggressiveness, optional install visibility) |
| AssignedMenuBar | Menu bar customization (VPN menu extra visibility) |
| AssignedPasswordPolicy | Password complexity requirements (length, alphanumeric, special characters) |
| AssignedPlatformSingleSignOn | Platform SSO with Secure Enclave keys (Entra ID), admin authorization mode, user creation at login |
| AssignedSafari | Safari cross-site tracking relaxation and storage policy |
| AssignedSetupAssistant | Setup Assistant item suppression during Automated Device Enrollment |
| AssignedSingleSignOn | Extensible SSO extension for Entra ID (Microsoft SSO via Company Portal) |
| AssignedSoftwareUpdate | Automatic software update policy (check, download, install all updates) |

### Shared (32 profiles)

Profiles for multi-user devices (labs, kiosks, shared workstations) where many users log in to the same Mac. These manage login window behavior, power schedules, update deferral, authentication, application lockdown, and user experience restrictions tuned for transient sessions.

| Profile | Description |
|---------|-------------|
| SharedAppStorePrefs | Restrict App Store to software updates only, disable app adoption |
| SharedAppsBlockList | Block specific applications from launching (Chess, FaceTime, Mail, Messages, etc.) |
| SharedAutoLogin | Auto-login as a shared user account with screen lock disabled |
| SharedAutoLogout | Automatic logout after inactivity period (configurable delay) |
| SharedBrowsersHomepage | Set homepage for Safari and Chrome to a specified URL |
| SharedChrome | Comprehensive Chrome lockdown: disable autofill, passwords, sync, notifications, auto-update |
| SharedDefenderPrefs | Microsoft Defender in passive mode: kernel/system extensions, TCC, service management, suppressed notifications |
| SharedDisableAmbientLightSensor | Disable automatic display brightness for kiosks and signage |
| SharedDisableScreenSaver | Disable screensaver entirely for kiosks and digital signage |
| SharedDisableSiri | Completely disable Siri (assistant, menu bar, and UI) |
| SharedDoNotDisturb | Do Not Disturb schedule configuration for lab environments |
| SharedEnergySettings | Scheduled startup/shutdown and energy saver settings for shared desktops |
| SharedFinder | Comprehensive Finder configuration: default view, sidebar, toolbar, sort order, trash behavior |
| SharedKioskEnergySettings | Always-on energy profile for kiosks (no sleep, auto-restart on power loss) |
| SharedKioskGlobalPrefs | Kiosk UX cleanup: hide menu bar, configure scrollbar behavior |
| SharedLoginWindow | Login window configuration: text message, admin host info, restart/shutdown restrictions |
| SharedManagedInstalls | Munki managed installs behavior for shared devices |
| SharedMenuBar | Menu bar lockdown: hide user switcher (Control Center), Time Machine menu extra |
| SharedMusicPrefs | iTunes/Music lockdown: disable Apple Music, radio, store, shared libraries, device sync |
| SharedPlatformSingleSignOn | Platform SSO with password authentication (Entra ID), standard user authorization mode |
| SharedRapidSecurityResponse | Prevent Rapid Security Response updates that could disrupt kiosk operation |
| SharedSafari | Comprehensive Safari lockdown: disable autofill, extensions, push notifications, private browsing default |
| SharedScreenSaver | Screensaver configuration with idle time and password delay settings |
| SharedSecurity | Prevent users from setting lock screen messages or resetting passwords |
| SharedSetupAssistant | Comprehensive Setup Assistant skip list (23 items including Intelligence, OSShowcase) |
| SharedSharingExtensions | Restrict sharing menu to AirDrop, Notes, and Photos only |
| SharedSoftwareUpdate | Software update catalog URL and major OS upgrade deferral (90 days) |
| SharedStageManager | Disable Stage Manager, click-to-show-desktop, widgets; show desktop icons |
| SharedSystemEvents | AppleEvents TCC for admin tools (Terminal, BBEdit to System Events) |
| SharedSystemPrefs | Hide specific System Preferences/Settings panes for shared devices |
| SharedSystemSettings | Comprehensive System Settings restrictions: disable account modification, Siri, Time Machine, biometric unlock, wallpaper changes, Universal Control, and more |
| SharedWallpaper | Locked wallpaper using a built-in system image |

### System (9 profiles)

Universal profiles applied to all managed Macs regardless of assignment model. These handle operating system behavior, security policy, network configuration, and baseline preferences.

| Profile | Description |
|---------|-------------|
| DiagnosticData | Apple diagnostic and usage data submission settings |
| ExtensionsAllowList | Allowed kernel and system extensions by team identifier |
| GlobalPrefs | Global macOS preferences (locale, units, date format, sidebar icon size) |
| NotificationsPrefs | Notification center settings for managed applications |
| PrivacyAllowList | TCC/PPPC allow list granting privacy access to managed applications |
| ServiceManagementPrefs | Managed login items and background task approval rules |
| SetupAssistant | Setup Assistant pane suppression for all device types |
| SoftwareUpdateDeferral | Minor OS update and security response deferral periods |
| WiFiCredentials | 802.1X Wi-Fi network configuration with certificate payload |

---

## Template

[MainProfileTemplate.mobileconfig](MainProfileTemplate.mobileconfig) is an annotated template that documents every key in a configuration profile. It includes two inner payload examples: a standard preference domain payload and a TCC/PPPC payload. Use it as a starting point when creating new profiles from scratch.

---

## Profile Format

Configuration profiles are XML property lists (`.mobileconfig`) with this structure:

```
Outer dict (PayloadType: Configuration)
  PayloadIdentifier    -- unique reverse-domain ID for the profile
  PayloadUUID          -- generated with uuidgen
  PayloadScope         -- System or User
  PayloadContent[]     -- array of inner payload dicts
    Inner dict 1
      PayloadType      -- preference domain or policy type
      PayloadUUID      -- unique per inner payload
      (managed keys)   -- the actual settings
    Inner dict 2
      ...
```

Common PayloadType values for inner payloads:

- Direct domain (e.g. `com.apple.Safari`) -- manage app preferences directly
- `com.apple.TCC.configuration-profile-policy` -- Privacy/PPPC permissions
- `com.apple.system-extension-policy` -- system extension allow-listing
- `com.apple.servicemanagement` -- background task and login item management
- `com.apple.notificationsettings` -- notification center management
- `com.apple.extensiblesso` -- SSO extensions (Platform SSO, Entra ID)
- `com.apple.ManagedClient.preferences` -- MCX-wrapped preference management
- `com.apple.loginwindow` -- login window behavior
- `com.apple.screensaver` -- screensaver and lock screen
- `com.apple.applicationaccess` -- feature restrictions and OS deferral
- `com.apple.applicationaccess.new` -- application launch blocklist
- `com.apple.MCX` -- energy saver schedules
- `com.apple.controlcenter` -- Control Center visibility

---

## Validation

Validate profile XML before deployment:

```sh
# Lint a single profile
plutil -lint MyProfile.mobileconfig

# Lint all profiles in the repo
find . -name "*.mobileconfig" -exec plutil -lint {} \;
```

Install and remove profiles locally for testing (requires admin):

```sh
# Install
sudo profiles install -path MyProfile.mobileconfig

# List installed profiles
sudo profiles list

# Remove by identifier
sudo profiles remove -identifier com.example.profiles.MyProfile
```

---

## Tools

- [iMazing Profile Editor](https://imazing.com/profile-editor) -- free GUI editor for macOS profiles
- [Apple Configurator 2](https://apps.apple.com/app/apple-configurator-2/id1037126344) -- Apple's official profile and device management tool
- [ProfileDocs](https://profiledocs.com) -- searchable reference for Apple profile payloads
- [ProfileCreator](https://github.com/ProfileCreator/ProfileCreator) -- open-source profile editor (community maintained)

---

## Adapting to Your Environment

1. Replace `com.example.profiles` with your organization's namespace (e.g. `com.contoso.profiles`).
2. Replace `ExampleOrganization` with your organization name.
3. Replace `YOURTEAMID00` with real Apple Developer Team IDs (found in the signing certificate or via `codesign -dr - /path/to/app`).
4. Generate fresh PayloadUUID values with `uuidgen` for every dict.
5. In WiFiCredentials, replace `ExampleWiFi` with your SSID and update certificate/credential data.
6. Review TCC/PPPC entries in PrivacyAllowList and DefenderPrefs to match the applications and bundle identifiers deployed in your environment.
7. In SharedAutoLogin, replace the `student` username with your shared account name.
8. In SharedBrowsersHomepage/SharedChrome/SharedSafari, replace homepage URLs and cookie domain allowlists with your organization's domains.
9. In AssignedSingleSignOn/SharedPlatformSingleSignOn, update the SSO extension bundle ID allowlists to match your managed app namespace.

---

## License

See [LICENSE](LICENSE).

