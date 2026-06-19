# Plan A: Role System + Settings Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 4-tier profile role system, redesign SettingsScreen with modern icon-chip rows and role-gated sections, create VideoPlayerSettingsScreen and SubtitleAppearanceScreen, remove AppearanceSettingsScreen.

**Architecture:** Extend `ProfileRole` enum in MoonlitCore's `ProfileModels.swift` and `RoleManager`. New preference stores (`VideoPlayerPreferenceStore`, `SubtitleAppearanceStore`) follow the existing `StreamAutoplayPreferenceStore` UserDefaults pattern. `SettingsScreen` is rebuilt as a grouped list using a reusable `SettingsRow` component. Settings subscreens are added to a new `Sources/Screens/Settings/` folder.

**Tech Stack:** SwiftUI, MoonlitCore, UserDefaults

---

## File Map

| Action | Path |
|---|---|
| Modify | `Packages/MoonlitCore/Sources/MoonlitCore/Models/ProfileModels.swift` |
| Modify | `Packages/MoonlitCore/Sources/MoonlitCore/Services/RoleManager.swift` |
| Create | `Packages/MoonlitCore/Sources/MoonlitCore/Services/VideoPlayerPreferenceStore.swift` |
| Create | `Packages/MoonlitCore/Sources/MoonlitCore/Services/SubtitleAppearanceStore.swift` |
| Modify | `Apps/MoonlitApp/Sources/Screens/SettingsScreen.swift` |
| Create | `Apps/MoonlitApp/Sources/Screens/Settings/VideoPlayerSettingsScreen.swift` |
| Create | `Apps/MoonlitApp/Sources/Screens/Settings/SubtitleAppearanceScreen.swift` |
| Delete | `Apps/MoonlitApp/Sources/Screens/AppearanceSettingsScreen.swift` |
| Modify | `Apps/MoonlitApp/Sources/ContentView.swift` (remove Appearance nav link) |

---

### Task 1: Add ProfileRole enum to MoonlitCore

**Files:**
- Modify: `Packages/MoonlitCore/Sources/MoonlitCore/Models/ProfileModels.swift`

- [ ] **Step 1: Add ProfileRole enum after the MoonlitProfile struct**

Open `Packages/MoonlitCore/Sources/MoonlitCore/Models/ProfileModels.swift` and add after line 51 (after `public var isAdmin`):

```swift
public enum ProfileRole: String, Codable, Sendable, CaseIterable {
    case admin            = "admin"
    case friendsAndFamily = "friends_family"
    case premiumFull      = "premium_full"
    case premiumSelfManage = "premium_self_manage"
    case user             = "user"

    public var canManageOwnAddons: Bool {
        self == .admin || self == .premiumSelfManage
    }

    public var canManageCatalogs: Bool { self == .admin }
    public var showsAdminTab: Bool     { self == .admin }

    public var displayName: String {
        switch self {
        case .admin:             return "Admin"
        case .friendsAndFamily:  return "Friends & Family"
        case .premiumFull:       return "Premium"
        case .premiumSelfManage: return "Premium"
        case .user:              return "User"
        }
    }
}
```

Also add a computed property to `MoonlitProfile` right after `public var isAdmin`:

```swift
public var profileRole: ProfileRole {
    ProfileRole(rawValue: role) ?? .user
}
```

- [ ] **Step 2: Build the MoonlitCore package to verify no errors**

```bash
cd /Users/zain/projects/Moonlit
swift build --package-path Packages/MoonlitCore 2>&1 | tail -20
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/MoonlitCore/Sources/MoonlitCore/Models/ProfileModels.swift
git commit -m "feat(core): add ProfileRole enum with 4 tiers and MoonlitProfile.profileRole"
```

---

### Task 2: Update RoleManager to expose profileRole

**Files:**
- Modify: `Packages/MoonlitCore/Sources/MoonlitCore/Services/RoleManager.swift`

- [ ] **Step 1: Replace RoleManager body**

Replace the entire content of `Packages/MoonlitCore/Sources/MoonlitCore/Services/RoleManager.swift`:

```swift
import Foundation

@MainActor
public class RoleManager: ObservableObject {
    public static let shared = RoleManager()

    @Published public var isAdmin = false
    @Published public var profileRole: ProfileRole = .user

    private init() {}

    public func evaluateRole(profile: MoonlitProfile?) {
        let role = profile?.profileRole ?? .user
        profileRole = role
        isAdmin = role == .admin
    }

    public func setUserAsAdmin(profile: MoonlitProfile) async throws {
        let updated = MoonlitProfile(
            id: profile.id,
            userId: profile.userId,
            name: profile.name,
            avatarColor: profile.avatarColor,
            avatarId: profile.avatarId,
            profileIndex: profile.profileIndex,
            usesPrimaryAddons: profile.usesPrimaryAddons,
            pinEnabled: profile.pinEnabled,
            role: "admin",
            createdAt: profile.createdAt
        )
        try await ProfileManager.shared.updateProfile(updated)
        evaluateRole(profile: updated)
    }
}
```

- [ ] **Step 2: Build MoonlitCore**

```bash
swift build --package-path /Users/zain/projects/Moonlit/Packages/MoonlitCore 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/MoonlitCore/Sources/MoonlitCore/Services/RoleManager.swift
git commit -m "feat(core): extend RoleManager with profileRole published property"
```

---

### Task 3: Create VideoPlayerPreferenceStore

**Files:**
- Create: `Packages/MoonlitCore/Sources/MoonlitCore/Services/VideoPlayerPreferenceStore.swift`

- [ ] **Step 1: Create the file**

```swift
// Packages/MoonlitCore/Sources/MoonlitCore/Services/VideoPlayerPreferenceStore.swift
import Foundation

public enum PlayerEngine: String, Codable, Sendable, CaseIterable {
    case auto      = "auto"
    case avPlayer  = "avplayer"
    case ksPlayer  = "ksplayer"

    public var displayName: String {
        switch self {
        case .auto:     return "Auto-Detect"
        case .avPlayer: return "AVPlayer"
        case .ksPlayer: return "KSPlayer"
        }
    }
}

public enum CacheMode: String, Codable, Sendable, CaseIterable {
    case memory = "memory"
    case disk   = "disk"
    case off    = "off"

    public var displayName: String {
        switch self {
        case .memory: return "Memory"
        case .disk:   return "Disk"
        case .off:    return "Off"
        }
    }
}

@MainActor
public final class VideoPlayerPreferenceStore: ObservableObject {
    public static let shared = VideoPlayerPreferenceStore()

    private let defaults: UserDefaults
    private let prefix = "moonlit.videoPlayer"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Skip Intro
    public var showSkipIntroButton: Bool {
        get { defaults.object(forKey: "\(prefix).showSkipIntroButton") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).showSkipIntroButton") }
    }

    public var autoSkipIntros: Bool {
        get { defaults.object(forKey: "\(prefix).autoSkipIntros") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).autoSkipIntros") }
    }

    public var useIntroDB: Bool {
        get { defaults.object(forKey: "\(prefix).useIntroDB") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).useIntroDB") }
    }

    public var showHighlightsOnTimeline: Bool {
        get { defaults.object(forKey: "\(prefix).showHighlights") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).showHighlights") }
    }

    // MARK: - Autoplay
    public var autoplayNextEpisode: Bool {
        get { defaults.object(forKey: "\(prefix).autoplayNext") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).autoplayNext") }
    }

    public var showNextEpisodeSecondsRemaining: Int {
        get { defaults.object(forKey: "\(prefix).nextEpisodeSeconds") as? Int ?? 30 }
        set { defaults.set(newValue, forKey: "\(prefix).nextEpisodeSeconds") }
    }

    // MARK: - Players
    public var usePerTypePlayers: Bool {
        get { defaults.object(forKey: "\(prefix).usePerTypePlayers") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).usePerTypePlayers") }
    }

    public var moviePlayer: PlayerEngine {
        get { PlayerEngine(rawValue: defaults.string(forKey: "\(prefix).moviePlayer") ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).moviePlayer") }
    }

    public var seriesPlayer: PlayerEngine {
        get { PlayerEngine(rawValue: defaults.string(forKey: "\(prefix).seriesPlayer") ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).seriesPlayer") }
    }

    public var livePlayer: PlayerEngine {
        get { PlayerEngine(rawValue: defaults.string(forKey: "\(prefix).livePlayer") ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).livePlayer") }
    }

    // MARK: - Cache
    public var cacheMode: CacheMode {
        get { CacheMode(rawValue: defaults.string(forKey: "\(prefix).cacheMode") ?? "") ?? .memory }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).cacheMode") }
    }

    // MARK: - Previews
    public var autoplayPreviews: Bool {
        get { defaults.object(forKey: "\(prefix).autoplayPreviews") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).autoplayPreviews") }
    }

    public var playPreviewSound: Bool {
        get { defaults.object(forKey: "\(prefix).playPreviewSound") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).playPreviewSound") }
    }

    // MARK: - Compatibility
    public var showOnlyCompatibleFormats: Bool {
        get { defaults.object(forKey: "\(prefix).showOnlyCompatible") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).showOnlyCompatible") }
    }
}
```

- [ ] **Step 2: Build MoonlitCore**

```bash
swift build --package-path /Users/zain/projects/Moonlit/Packages/MoonlitCore 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/MoonlitCore/Sources/MoonlitCore/Services/VideoPlayerPreferenceStore.swift
git commit -m "feat(core): add VideoPlayerPreferenceStore for skip intro, player engine, cache mode"
```

---

### Task 4: Create SubtitleAppearanceStore

**Files:**
- Create: `Packages/MoonlitCore/Sources/MoonlitCore/Services/SubtitleAppearanceStore.swift`

- [ ] **Step 1: Create the file**

```swift
// Packages/MoonlitCore/Sources/MoonlitCore/Services/SubtitleAppearanceStore.swift
import Foundation

public enum SubtitlePreset: String, Codable, Sendable, CaseIterable {
    case standard = "standard"
    case boxed    = "boxed"
    case classic  = "classic"
    case minimal  = "minimal"

    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .boxed:    return "Boxed"
        case .classic:  return "Classic"
        case .minimal:  return "Minimal"
        }
    }

    public var description: String {
        switch self {
        case .standard: return "White text with black outline"
        case .boxed:    return "White text with dark background"
        case .classic:  return "Yellow text, cinema style"
        case .minimal:  return "Clean, subtle shadow only"
        }
    }
}

public enum SubtitleAlignment: String, Codable, Sendable {
    case left   = "left"
    case center = "center"
    case right  = "right"
}

@MainActor
public final class SubtitleAppearanceStore: ObservableObject {
    public static let shared = SubtitleAppearanceStore()

    private let defaults: UserDefaults
    private let prefix = "moonlit.subtitles"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var preset: SubtitlePreset {
        get { SubtitlePreset(rawValue: defaults.string(forKey: "\(prefix).preset") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).preset") }
    }

    public var fontSize: Double {
        get { defaults.object(forKey: "\(prefix).fontSize") as? Double ?? 32 }
        set { defaults.set(newValue, forKey: "\(prefix).fontSize") }
    }

    public var scale: Double {
        get { defaults.object(forKey: "\(prefix).scale") as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: "\(prefix).scale") }
    }

    public var isBold: Bool {
        get { defaults.object(forKey: "\(prefix).bold") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).bold") }
    }

    public var isItalic: Bool {
        get { defaults.object(forKey: "\(prefix).italic") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).italic") }
    }

    // Colors stored as hex strings
    public var textColorHex: String {
        get { defaults.string(forKey: "\(prefix).textColor") ?? "#FFFFFF" }
        set { defaults.set(newValue, forKey: "\(prefix).textColor") }
    }

    public var outlineColorHex: String {
        get { defaults.string(forKey: "\(prefix).outlineColor") ?? "#000000" }
        set { defaults.set(newValue, forKey: "\(prefix).outlineColor") }
    }

    public var backgroundColorHex: String {
        get { defaults.string(forKey: "\(prefix).backgroundColor") ?? "#000000" }
        set { defaults.set(newValue, forKey: "\(prefix).backgroundColor") }
    }

    public var backgroundOpacity: Double {
        get { defaults.object(forKey: "\(prefix).backgroundOpacity") as? Double ?? 0.0 }
        set { defaults.set(newValue, forKey: "\(prefix).backgroundOpacity") }
    }

    public var verticalPosition: Double {
        get { defaults.object(forKey: "\(prefix).verticalPosition") as? Double ?? 100 }
        set { defaults.set(newValue, forKey: "\(prefix).verticalPosition") }
    }

    public var horizontalAlignment: SubtitleAlignment {
        get { SubtitleAlignment(rawValue: defaults.string(forKey: "\(prefix).hAlignment") ?? "") ?? .center }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).hAlignment") }
    }

    public var horizontalMargin: Double {
        get { defaults.object(forKey: "\(prefix).hMargin") as? Double ?? 19 }
        set { defaults.set(newValue, forKey: "\(prefix).hMargin") }
    }

    public var textBlur: Double {
        get { defaults.object(forKey: "\(prefix).textBlur") as? Double ?? 0.0 }
        set { defaults.set(newValue, forKey: "\(prefix).textBlur") }
    }

    public var scaleWithWindowSize: Bool {
        get { defaults.object(forKey: "\(prefix).scaleWithWindow") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).scaleWithWindow") }
    }

    public func resetToDefaults() {
        let keys = ["preset","fontSize","scale","bold","italic","textColor","outlineColor",
                    "backgroundColor","backgroundOpacity","verticalPosition","hAlignment",
                    "hMargin","textBlur","scaleWithWindow"]
        keys.forEach { defaults.removeObject(forKey: "\(prefix).\($0)") }
    }
}
```

- [ ] **Step 2: Build MoonlitCore**

```bash
swift build --package-path /Users/zain/projects/Moonlit/Packages/MoonlitCore 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/MoonlitCore/Sources/MoonlitCore/Services/SubtitleAppearanceStore.swift
git commit -m "feat(core): add SubtitleAppearanceStore for font, color, position settings"
```

---

### Task 5: Create VideoPlayerSettingsScreen

**Files:**
- Create: `Apps/MoonlitApp/Sources/Screens/Settings/VideoPlayerSettingsScreen.swift`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p /Users/zain/projects/Moonlit/Apps/MoonlitApp/Sources/Screens/Settings
```

```swift
// Apps/MoonlitApp/Sources/Screens/Settings/VideoPlayerSettingsScreen.swift
import SwiftUI
import MoonlitCore

struct VideoPlayerSettingsScreen: View {
    @StateObject private var prefs = VideoPlayerPreferenceStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {

                settingsSectionLabel("Playback")
                VStack(spacing: 0) {
                    toggleRow("Autoplay next episode", isOn: Binding(
                        get: { prefs.autoplayNextEpisode },
                        set: { prefs.autoplayNextEpisode = $0 }
                    ))
                    Divider().background(Color.white.opacity(0.08))
                    pickerRow("Show Next Episode when", value: "\(prefs.showNextEpisodeSecondsRemaining)s remaining") {
                        Picker("", selection: Binding(
                            get: { prefs.showNextEpisodeSecondsRemaining },
                            set: { prefs.showNextEpisodeSecondsRemaining = $0 }
                        )) {
                            ForEach([15, 20, 30, 45, 60], id: \.self) { s in
                                Text("\(s) seconds").tag(s)
                            }
                        }
                    }
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)

                settingsSectionLabel("Skip Intro")
                VStack(spacing: 0) {
                    toggleRow("Show 'Skip Intro' when detected", isOn: Binding(
                        get: { prefs.showSkipIntroButton },
                        set: { prefs.showSkipIntroButton = $0 }
                    ))
                    Divider().background(Color.white.opacity(0.08))
                    toggleRow("Auto-skip intros when detected", isOn: Binding(
                        get: { prefs.autoSkipIntros },
                        set: { prefs.autoSkipIntros = $0 }
                    ))
                    Divider().background(Color.white.opacity(0.08))
                    toggleRow("Use IntroDB for TV episodes", isOn: Binding(
                        get: { prefs.useIntroDB },
                        set: { prefs.useIntroDB = $0 }
                    ))
                    Divider().background(Color.white.opacity(0.08))
                    toggleRow("Show highlights on timeline", isOn: Binding(
                        get: { prefs.showHighlightsOnTimeline },
                        set: { prefs.showHighlightsOnTimeline = $0 }
                    ))
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)

                Text("Skip timestamps sourced from PublicMetaDB. IntroDB provides additional crowdsourced intro data for TV shows.")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textTertiary)
                    .padding(.horizontal, 20)

                settingsSectionLabel("Format Compatibility")
                VStack(spacing: 0) {
                    toggleRow("Show only compatible formats", isOn: Binding(
                        get: { prefs.showOnlyCompatibleFormats },
                        set: { prefs.showOnlyCompatibleFormats = $0 }
                    ))
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)

                settingsSectionLabel("Media Type Players")
                VStack(spacing: 0) {
                    toggleRow("Use different players per media type", isOn: Binding(
                        get: { prefs.usePerTypePlayers },
                        set: { prefs.usePerTypePlayers = $0 }
                    ))
                    if prefs.usePerTypePlayers {
                        Divider().background(Color.white.opacity(0.08))
                        enginePickerRow("Movies", engine: Binding(
                            get: { prefs.moviePlayer },
                            set: { prefs.moviePlayer = $0 }
                        ))
                        Divider().background(Color.white.opacity(0.08))
                        enginePickerRow("Series", engine: Binding(
                            get: { prefs.seriesPlayer },
                            set: { prefs.seriesPlayer = $0 }
                        ))
                        Divider().background(Color.white.opacity(0.08))
                        enginePickerRow("Live", engine: Binding(
                            get: { prefs.livePlayer },
                            set: { prefs.livePlayer = $0 }
                        ))
                    }
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.2), value: prefs.usePerTypePlayers)

                Text("Auto-Detect: .m3u8/HLS uses AVPlayer; .mkv/.avi and complex formats use KSPlayer.")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textTertiary)
                    .padding(.horizontal, 20)

                settingsSectionLabel("Cache Mode")
                VStack(spacing: 0) {
                    pickerRow("Cache mode", value: prefs.cacheMode.displayName) {
                        Picker("", selection: Binding(
                            get: { prefs.cacheMode },
                            set: { prefs.cacheMode = $0 }
                        )) {
                            ForEach(CacheMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                    }
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)

                Text("Memory buffers in RAM for smooth playback. Disk caches segments for resume. Off streams live.")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textTertiary)
                    .padding(.horizontal, 20)

                settingsSectionLabel("Previews")
                VStack(spacing: 0) {
                    toggleRow("Autoplay previews in Home", isOn: Binding(
                        get: { prefs.autoplayPreviews },
                        set: { prefs.autoplayPreviews = $0 }
                    ))
                    Divider().background(Color.white.opacity(0.08))
                    toggleRow("Play preview sound", isOn: Binding(
                        get: { prefs.playPreviewSound },
                        set: { prefs.playPreviewSound = $0 }
                    ))
                }
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 16)

                Spacer().frame(height: 32)
            }
            .padding(.top, 16)
        }
        .background(MoonlitTheme.background)
        .navigationTitle("Video Player")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Row helpers

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func pickerRow<Content: View>(_ title: String, value: String, @ViewBuilder picker: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            picker()
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func enginePickerRow(_ label: String, engine: Binding<PlayerEngine>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: engine) {
                ForEach(PlayerEngine.allCases, id: \.self) { e in
                    Text(e.displayName).tag(e)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private func settingsSectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(MoonlitTheme.textTertiary)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 2)
}
```

- [ ] **Step 2: Build the app target**

```bash
cd /Users/zain/projects/Moonlit/Apps/MoonlitApp
xcodebuild -scheme MoonlitApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add Apps/MoonlitApp/Sources/Screens/Settings/VideoPlayerSettingsScreen.swift
git commit -m "feat: add VideoPlayerSettingsScreen with skip intro, player engine, cache mode settings"
```

---

### Task 6: Create SubtitleAppearanceScreen

**Files:**
- Create: `Apps/MoonlitApp/Sources/Screens/Settings/SubtitleAppearanceScreen.swift`

- [ ] **Step 1: Create the file**

```swift
// Apps/MoonlitApp/Sources/Screens/Settings/SubtitleAppearanceScreen.swift
import SwiftUI
import MoonlitCore

struct SubtitleAppearanceScreen: View {
    @StateObject private var store = SubtitleAppearanceStore.shared
    @Environment(\.dismiss) private var dismiss

    // Local state mirrors store so preview updates live
    @State private var fontSize: Double = SubtitleAppearanceStore.shared.fontSize
    @State private var scale: Double = SubtitleAppearanceStore.shared.scale
    @State private var isBold: Bool = SubtitleAppearanceStore.shared.isBold
    @State private var isItalic: Bool = SubtitleAppearanceStore.shared.isItalic
    @State private var verticalPosition: Double = SubtitleAppearanceStore.shared.verticalPosition
    @State private var horizontalMargin: Double = SubtitleAppearanceStore.shared.horizontalMargin
    @State private var textBlur: Double = SubtitleAppearanceStore.shared.textBlur
    @State private var alignment: SubtitleAlignment = SubtitleAppearanceStore.shared.horizontalAlignment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {

                    // ── PREVIEW ──────────────────────────────────────────
                    subtitlePreviewPanel

                    // ── PRESETS ──────────────────────────────────────────
                    sectionLabel("Quick Presets")
                    VStack(spacing: 0) {
                        ForEach(SubtitlePreset.allCases, id: \.self) { preset in
                            Button {
                                applyPreset(preset)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Text(preset.description)
                                            .font(.caption)
                                            .foregroundColor(MoonlitTheme.textSecondary)
                                    }
                                    Spacer()
                                    if store.preset == preset {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(MoonlitTheme.accent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            if preset != SubtitlePreset.allCases.last {
                                Divider().background(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── FONT ─────────────────────────────────────────────
                    sectionLabel("Font")
                    VStack(spacing: 0) {
                        sliderRow("Font Size", value: $fontSize, range: 12...72, step: 1, format: "%.0f") {
                            store.fontSize = fontSize
                        }
                        Divider().background(Color.white.opacity(0.08))
                        sliderRow("Scale", value: $scale, range: 0.5...2.0, step: 0.1, format: "%.1fx") {
                            store.scale = scale
                        }
                        Divider().background(Color.white.opacity(0.08))
                        toggleRow("Bold", isOn: Binding(
                            get: { isBold },
                            set: { isBold = $0; store.isBold = $0 }
                        ))
                        Divider().background(Color.white.opacity(0.08))
                        toggleRow("Italic", isOn: Binding(
                            get: { isItalic },
                            set: { isItalic = $0; store.isItalic = $0 }
                        ))
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── COLORS ───────────────────────────────────────────
                    sectionLabel("Colors")
                    VStack(spacing: 0) {
                        colorRow("Text Color", hex: store.textColorHex) { store.textColorHex = $0 }
                        Divider().background(Color.white.opacity(0.08))
                        colorRow("Outline Color", hex: store.outlineColorHex) { store.outlineColorHex = $0 }
                        Divider().background(Color.white.opacity(0.08))
                        colorRow("Background Color", hex: store.backgroundColorHex) { store.backgroundColorHex = $0 }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── POSITION ─────────────────────────────────────────
                    sectionLabel("Position")
                    VStack(spacing: 0) {
                        sliderRow("Vertical Position", value: $verticalPosition, range: 0...200, step: 1, format: "%.0f") {
                            store.verticalPosition = verticalPosition
                        }
                        Divider().background(Color.white.opacity(0.08))
                        alignmentRow
                        Divider().background(Color.white.opacity(0.08))
                        sliderRow("Horizontal Margin", value: $horizontalMargin, range: 0...100, step: 1, format: "%.0fpx") {
                            store.horizontalMargin = horizontalMargin
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── ADVANCED ─────────────────────────────────────────
                    sectionLabel("Advanced")
                    VStack(spacing: 0) {
                        sliderRow("Text Blur", value: $textBlur, range: 0...5, step: 0.1, format: "%.1f") {
                            store.textBlur = textBlur
                        }
                        Divider().background(Color.white.opacity(0.08))
                        toggleRow("Scale with Window Size", isOn: Binding(
                            get: { store.scaleWithWindowSize },
                            set: { store.scaleWithWindowSize = $0 }
                        ))
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── RESET ────────────────────────────────────────────
                    Button {
                        store.resetToDefaults()
                        fontSize = store.fontSize
                        scale = store.scale
                        isBold = store.isBold
                        isItalic = store.isItalic
                        verticalPosition = store.verticalPosition
                        horizontalMargin = store.horizontalMargin
                        textBlur = store.textBlur
                        alignment = store.horizontalAlignment
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 32)
                }
                .padding(.top, 8)
            }
            .background(MoonlitTheme.background)
            .navigationTitle("Subtitle Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Preview Panel

    private var subtitlePreviewPanel: some View {
        ZStack(alignment: .bottom) {
            // Static player screenshot background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundColor(Color.white.opacity(0.08))
                )
                .frame(height: 120)

            // Live subtitle preview
            Text("The quick brown fox jumps over the lazy dog")
                .font(.system(
                    size: min(fontSize * 0.45, 18),
                    weight: isBold ? .bold : .regular
                ))
                .italic(isItalic)
                .foregroundColor(Color(hex: store.textColorHex) ?? .white)
                .multilineTextAlignment(textAlignment)
                .shadow(color: Color(hex: store.outlineColorHex) ?? .black, radius: 2, x: 1, y: 1)
                .blur(radius: textBlur * 0.3)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    // MARK: - Alignment row

    private var alignmentRow: some View {
        HStack {
            Text("Horizontal Alignment")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: Binding(
                get: { alignment },
                set: { alignment = $0; store.horizontalAlignment = $0 }
            )) {
                Text("Left").tag(SubtitleAlignment.left)
                Text("Center").tag(SubtitleAlignment.center)
                Text("Right").tag(SubtitleAlignment.right)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Row helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(MoonlitTheme.textTertiary)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 2)
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String, onChange: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MoonlitTheme.accent)
            }
            Slider(value: value, in: range, step: step)
                .tint(MoonlitTheme.accent)
                .onChange(of: value.wrappedValue) { _, _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func colorRow(_ title: String, hex: String, onChange: @escaping (String) -> Void) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Circle()
                .fill(Color(hex: hex) ?? .white)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            Text(hex)
                .font(.caption.monospaced())
                .foregroundColor(MoonlitTheme.textSecondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MoonlitTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Preset application

    private func applyPreset(_ preset: SubtitlePreset) {
        store.preset = preset
        switch preset {
        case .standard:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        case .boxed:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.75
            store.isBold = false
        case .classic:
            store.textColorHex = "#FFFF00"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        case .minimal:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#00000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        }
        isBold = store.isBold
    }
}

// MARK: - Color+hex helper (app-level, not in MoonlitCore)
private extension Color {
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let intVal = UInt64(h, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255
        let g = Double((intVal >> 8) & 0xFF) / 255
        let b = Double(intVal & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme MoonlitApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add Apps/MoonlitApp/Sources/Screens/Settings/SubtitleAppearanceScreen.swift
git commit -m "feat: add SubtitleAppearanceScreen with live preview, presets, font/color/position controls"
```

---

### Task 7: Redesign SettingsScreen with modern rows and role-gating

**Files:**
- Modify: `Apps/MoonlitApp/Sources/Screens/SettingsScreen.swift`

- [ ] **Step 1: Replace the SettingsScreen body**

Replace `struct SettingsScreen: View` (lines 4–225) in `Apps/MoonlitApp/Sources/Screens/SettingsScreen.swift` with:

```swift
struct SettingsScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var metadataIntegrations = MetadataIntegrationStore.shared
    @State private var showAddons = false
    @State private var showCatalogManagement = false
    @State private var showSubtitleAppearance = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {

                    // ── PROFILE CARD ──────────────────────────────────
                    if let profile = profileManager.currentProfile {
                        HStack(spacing: 12) {
                            ProfileAvatarView(profile: profile, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(profile.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if roleManager.isAdmin {
                                        Text("ADMIN")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(MoonlitTheme.accent)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(MoonlitTheme.accent.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                }
                                if let email = profileManager.currentSession?.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(MoonlitTheme.textTertiary)
                                }
                            }
                            Spacer()
                            Button {
                                profileManager.currentProfile = nil
                            } label: {
                                Text("Switch")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(MoonlitTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(MoonlitTheme.accent.opacity(0.12))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 14)
                        .padding(.horizontal, 16)
                    }

                    // ── GENERAL ───────────────────────────────────────
                    settingsSectionLabel("General")
                    VStack(spacing: 0) {
                        settingsNavRow(icon: "icloud.fill", iconColor: .blue, title: "iCloud") {
                            Text("iCloud placeholder") // TODO: wire iCloud screen
                        }
                        settingsDivider()
                        settingsNavRow(icon: "person.fill", iconColor: Color(red: 0.17, green: 0.42, blue: 0.31), title: "Accounts") {
                            Text("Accounts placeholder")
                        }
                        settingsDivider()
                        NavigationLink {
                            MetadataIntegrationsScreen()
                        } label: {
                            settingsRowLabel(
                                icon: "key.horizontal.fill",
                                iconColor: Color(red: 0.43, green: 0.23, blue: 0.55),
                                title: "Metadata",
                                subtitle: metadataIntegrations.effectiveTVDBAPIKey == nil ? "TMDB" : "TVDB + TMDB"
                            )
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── CONTENT MANAGEMENT (admin only) ───────────────
                    if roleManager.isAdmin {
                        settingsSectionLabel("Content Management")
                        VStack(spacing: 0) {
                            Button { showAddons = true } label: {
                                settingsRowLabel(
                                    icon: "puzzlepiece.extension.fill",
                                    iconColor: MoonlitTheme.accent,
                                    title: "Addons",
                                    subtitle: "\(addonRepo.managedAddons.count) installed"
                                )
                            }
                            settingsDivider()
                            Button { showCatalogManagement = true } label: {
                                settingsRowLabel(icon: "folder.fill", iconColor: Color.orange, title: "Catalog Management")
                            }
                            settingsDivider()
                            NavigationLink { HeroManagementScreen() } label: {
                                settingsRowLabel(icon: "film.fill", iconColor: Color.blue, title: "Hero Management")
                            }
                        }
                        .glassCard(cornerRadius: 14)
                        .padding(.horizontal, 16)
                    }

                    // ── PLAYBACK ──────────────────────────────────────
                    settingsSectionLabel("Playback")
                    VStack(spacing: 0) {
                        NavigationLink { VideoPlayerSettingsScreen() } label: {
                            settingsRowLabel(
                                icon: "play.circle.fill",
                                iconColor: Color(red: 0.1, green: 0.42, blue: 0.8),
                                title: "Video Player",
                                subtitle: "Skip Intro · Auto-detect"
                            )
                        }
                        settingsDivider()
                        Button { showSubtitleAppearance = true } label: {
                            settingsRowLabel(
                                icon: "captions.bubble.fill",
                                iconColor: Color(red: 0.02, green: 0.37, blue: 0.27),
                                title: "Subtitles",
                                subtitle: SubtitleAppearanceStore.shared.preset.displayName
                            )
                        }
                        settingsDivider()
                        NavigationLink { StreamAutoplaySettingsScreen() } label: {
                            settingsRowLabel(
                                icon: "bolt.fill",
                                iconColor: Color(red: 0.49, green: 0.18, blue: 0.07),
                                title: "Stream Auto-Play",
                                value: streamAutoplaySummary
                            )
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── APP ───────────────────────────────────────────
                    settingsSectionLabel("App")
                    VStack(spacing: 0) {
                        settingsNavRow(icon: "photo.fill", iconColor: Color(white: 0.25), title: "Icon Packs") {
                            Text("Icon Packs placeholder")
                        }
                        settingsDivider()
                        settingsNavRow(icon: "info.circle.fill", iconColor: Color(white: 0.25), title: "About", subtitle: "Moonlit v1.0.0") {
                            aboutView
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    // ── SIGN OUT ──────────────────────────────────────
                    Button(role: .destructive) {
                        Task { await profileManager.signOut() }
                    } label: {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 40)
                }
                .padding(.top, 16)
            }
            .background(MoonlitTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddons) { AddonsScreen() }
            .sheet(isPresented: $showCatalogManagement) { CatalogManagementScreen() }
            .sheet(isPresented: $showSubtitleAppearance) { SubtitleAppearanceScreen() }
        }
    }

    // MARK: - Helpers

    private var streamAutoplaySummary: String {
        guard let profile = profileManager.currentProfile else { return "Manual" }
        switch StreamAutoplayPreferenceStore.shared.mode(profileId: profile.id) {
        case .manual: return "Manual"
        case .automatic: return "Automatic"
        }
    }

    private var aboutView: some View {
        VStack(spacing: 8) {
            Text("Moonlit v1.0.0")
                .font(.headline).foregroundColor(.white)
            Text("Built with the Stremio addon ecosystem")
                .font(.caption).foregroundColor(MoonlitTheme.textSecondary)
        }
    }

    @ViewBuilder
    private func settingsNavRow<Destination: View>(icon: String, iconColor: Color, title: String, subtitle: String? = nil, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            settingsRowLabel(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
        }
    }

    private func settingsRowLabel(icon: String, iconColor: Color, title: String, subtitle: String? = nil, value: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(MoonlitTheme.textTertiary)
                }
            }
            Spacer()
            if let value {
                Text(value)
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MoonlitTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func settingsDivider() -> some View {
        Divider().background(Color.white.opacity(0.08)).padding(.leading, 56)
    }
}

private func settingsSectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(MoonlitTheme.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 2)
}
```

- [ ] **Step 2: Remove AppearanceSettingsScreen navigation link from ContentView if present**

Search and remove any `NavigationLink` to `AppearanceSettingsScreen` in `Apps/MoonlitApp/Sources/ContentView.swift`.

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme MoonlitApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Apps/MoonlitApp/Sources/Screens/SettingsScreen.swift Apps/MoonlitApp/Sources/ContentView.swift
git commit -m "feat: redesign SettingsScreen with icon-chip rows and role-gated Content Management section"
```

---

### Task 8: Delete AppearanceSettingsScreen

**Files:**
- Delete: `Apps/MoonlitApp/Sources/Screens/AppearanceSettingsScreen.swift`

- [ ] **Step 1: Remove the file**

```bash
rm /Users/zain/projects/Moonlit/Apps/MoonlitApp/Sources/Screens/AppearanceSettingsScreen.swift
```

- [ ] **Step 2: Remove from Xcode project**

Open `MoonlitApp.xcodeproj` in Xcode and delete the `AppearanceSettingsScreen.swift` reference from the project navigator (Move to Trash). Or via command line — remove the file reference from the `.pbxproj`:

```bash
grep -n "AppearanceSettingsScreen" /Users/zain/projects/Moonlit/Apps/MoonlitApp/MoonlitApp.xcodeproj/project.pbxproj
```

Remove the lines referencing it.

- [ ] **Step 3: Build to verify no broken references**

```bash
xcodebuild -scheme MoonlitApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: remove AppearanceSettingsScreen (accent color picker unused)"
```
