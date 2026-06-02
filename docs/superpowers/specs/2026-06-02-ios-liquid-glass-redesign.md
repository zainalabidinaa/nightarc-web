# iOS Liquid Glass Redesign — Design Spec

## Overview

Comprehensive iOS app redesign applying iOS 26 Liquid Glass effects, adding a native AVPlayer
player screen, a Netflix-style profile picker, and full UI polish. Also fixes addon parity with
LunaWeb, enables landscape folder tiles, and wires up `PosterShape` rendering.

**Target:** iOS 17+ (with `#available(iOS 26, *)` guards for Liquid Glass).  
**No simulator-based testing** — real device and SwiftUI previews only.

---

## 1. Pre-Flight Fixes (Step 0)

These are correctness fixes that must land before any visual work. They don't change UI
appearance but fix broken/unused wiring.

### 1.1 Sync Default Addons with LunaWeb

**File:** `Packages/LunaCore/Sources/LunaCore/Supabase/SupabaseConfig.swift`

Replace the `aiostreams` default URL with the one from LunaWeb:

- **Current:** `https://aiostreams.elfhosted.com/stremio/4a17bbef-9114-4231-82fb-b6baac090c63/manifest.json`
- **New:** `https://aiostreams.elfhosted.com/stremio/7d3fcfe4-393e-430c-aea7-47235eef5df5/manifest.json`

Do NOT add Cinemeta (per user preference).

### 1.2 Wire `PosterShape` in ContentCard

**File:** `Apps/LunaApp/Sources/Components/ContentCard.swift`

The `MetaPreview.posterShape` enum is parsed from Stremio API but never consumed. The card
hardcodes 120×180. Change to:

```swift
private var cardWidth: CGFloat {
    switch resolvedShape {
    case .landscape: return 200
    case .square:    return 140
    case .postter:   return 120
    }
}

private var cardHeight: CGFloat {
    switch resolvedShape {
    case .landscape: return 112
    case .square:    return 140
    case .postter:   return 180
    }
}
```

Also fix the `aspectRatio` in the poster image and placeholder to use the resolved shape
dimensions, and use `cardWidth`/`cardHeight` for text frame widths.

### 1.3 Wire `tileShape` in FolderCell

**Files:**
- `Apps/LunaApp/Sources/Screens/HomeScreen.swift` (FolderCell, FolderGridSection)
- `Packages/LunaCore/Sources/LunaCore/Models/MetaModels.swift` (CatalogRow)

`CatalogRow.tileShape` (`String?`, values: `"poster"` / `"landscape"` / `"square"`)
is propagated from `DBFolder.tileShape` but never consumed.

Update `FolderCell`:
- If `row.tileShape == "landscape"` → use `aspectRatio(16/9)` instead of `aspectRatio(2/3)`
- Adjust text/font sizing proportionally for landscape tiles
- Adjust the grid item width to span 2 columns for landscape tiles (or adjust the LazyVGrid
  to use adaptive columns)

---

## 2. Design System Foundation (LunaCore)

### 2.1 App Icon Asset

Copy the app icon from the `.icns` file into iOS asset catalog. Replace all SF Symbol moon
icon usage with the app icon image throughout the app (auth screen branding, app icon setting).

File: `Apps/LunaApp/Assets.xcassets/AppIcon.appiconset/`  
File: `Apps/LunaApp/Assets.xcassets/luna-icon.imageset/` (for in-app use)

### 2.2 Glass View Modifiers

Add to `LunaCore/Theme/LunaTheme.swift` (or new `GlassModifiers.swift`):

```swift
extension View {
    func glassCard(cornerRadius: CGFloat = 12, interactive: Bool = false) -> some View
    func glassCapsule(interactive: Bool = false, clear: Bool = false) -> some View
    func glassCircle(clear: Bool = false) -> some View
    func glassProminentButtonStyle(tint: Color, cornerRadius: CGFloat = 14) -> some View
    func appCardStyle(surfaceStyle: AppCardSurface = .regular, cornerRadius: CGFloat = 12) -> some View
}
```

All gate on `#available(iOS 26, *)` with `.ultraThinMaterial` fallbacks for iOS 17-25.

### 2.3 `AppCardSurface` Enum

```swift
enum AppCardSurface {
    case regular    // .regular tint — for adaptive/light backgrounds
    case darkGlass  // .clear in dark mode, .regular in light — for overlay cards on rich bg
}
```

### 2.4 Loading Skeleton Component

New component: `ShimmerCard` and `ShimmerRow`.

- Rounded rectangles with `.glassEffect(.regular)` or `.ultraThinMaterial` fallback
- Shimmer animation: a `LinearGradient` that translates across the view
- Shapes match the card dimensions they replace (landscape 200×112, portrait 120×180)
- Used in: HomeScreen, SearchScreen, LibraryScreen when data is loading

### 2.5 Empty State Component

New component: `EmptyStateView(icon:systemName, title:String, message:String, actionLabel:String?, action: (() -> Void)?)`.

- Center-aligned VStack
- Large SF Symbol icon in a glass circle background
- Title in white, message in `textSecondary`
- Optional action button with `.glassProminentButtonStyle`
- Used in: SearchScreen (no results), LibraryScreen (empty), HomeScreen (no catalogs)

### 2.6 Error State Component

New component: `ErrorStateView(message:String, onRetry: (() -> Void)?)`.

- Center-aligned VStack
- Warning icon in glass circle
- Error message in `textSecondary`
- "Retry" button when `onRetry` is provided
- Used wherever `errorMessage` is non-nil

---

## 3. Screen-by-Screen Redesign

### 3.1 AuthScreen

**File:** `Apps/LunaApp/Sources/Screens/AuthScreen.swift`

Changes:
- Replace moon SF Symbol with app icon image (`Image("luna-icon")`)
- Apply animated pulsing glow behind the icon
- Text fields: `.glassCard(cornerRadius: 12)` wrapping the `TextField` background
- Sign In/Up button: `.glassProminentButtonStyle(tint: LunaTheme.accent, cornerRadius: 12)`
- Toggle button: standard `.foregroundColor(LunaTheme.accent)`
- Background: subtle animated gradient or mesh instead of flat `LunaTheme.background`

### 3.2 Profile Picker (NEW)

**New file:** `Apps/LunaApp/Sources/Screens/ProfilePickerScreen.swift`

Design:
- "Who's watching?" title at top
- 2-column grid of profile avatars (like Netflix)
- Each avatar: 90pt glass circle with the profile's initial letter
  - Active/selected: gradient fill + white border + glow shadow
  - Inactive: subtle glass fill + subtle border
- Profile name below each avatar in `textSecondary`
- "Add Profile" tile: dashed border glass circle with `+` icon
- Bottom section: translucent bar with "Manage Profiles" button
- Background: `.glassEffect(.regular)` or dark gradient
- Navigation: replaces `ProfileSelectionScreen` in the auth flow, shown after login when
  `profileManager.currentProfile == nil && !profileManager.profiles.isEmpty`

Profile colors: Use the existing `profile.avatarColor` (hex string) mapped to a gradient.

### 3.3 Player Screen (NEW)

**New file:** `Apps/LunaApp/Sources/Screens/PlayerScreen.swift`

Uses native `AVPlayerViewController` (UIKit wrapped in `UIViewControllerRepresentable`) for
video playback, with a custom SwiftUI overlay for transport controls.

**Player overlay (SwiftUI layer on top of AVPlayer):**
- **Top bar:**
  - Back button (glass circle) on the left
  - Title + remaining time, centered
  - Ellipsis button (glass circle) on the right — opens popover with source info, stream quality
- **Center:** Large play/pause button (glass circle, fades after 3s of inactivity)
- **Bottom transport pill** (glass, full-width, pinned to bottom):
  - Progress bar: standard Slider on iOS 26 (native glass thumb), custom Capsule track on iOS 18
  - Time labels: current / total
  - Row 2: skip-back-15, play/pause, skip-forward-30 (center)
  - Row 3: speed button, volume slider toggle, PiP button, fullscreen toggle
- **Bottom action row:**
  - Subtitles selector
  - Playback speed picker
  - Picture in Picture (system PiP via AVPlayerViewController)
  - Audio track selector

**Source selection integration:**
- When navigating from DetailScreen, if multiple streams exist, show `StreamSelectionScreen`
  as a sheet BEFORE entering the player
- Player receives the selected stream URL

**Observations:**
- Tap anywhere to show/hide overlay (auto-hide after 4s)
- Lock screen / Now Playing integration via `MPNowPlayingInfoCenter`
- HLS preferred; fallback to direct URL
- Auto-resume from last watch progress position

### 3.4 HomeScreen

**File:** `Apps/LunaApp/Sources/Screens/HomeScreen.swift`

Changes:
- **HeroSection:** Remove flat gradient approach. Use:
  - Backdrop `AsyncImage` as the base layer
  - `.glassEffect(.clear.interactive(), in: .rect(cornerRadius: 22))` on iOS 26
  - `.ultraThinMaterial` fallback on iOS 18
  - Title + metadata + buttons inside the glass card
  - Profile avatar pill replaces toolbar profile button (moves inline to top-right)
- **ContinueWatchingRow:** Wrap cards in `GlassEffectContainer(spacing: 10)`
- **CatalogRowView:** Cards use updated `ContentCard` that respects `posterShape`
- **FolderGridSection:**
  - FolderCell now reads `row.tileShape` — landscape folders render 16:9
  - Grid columns: 2 for landscape tiles, native 4 for portrait tiles (use adaptive grid with
    landscape tiles spanning 2 columns)
- **Loading state:** Replace `ProgressView()` with `ShimmerCard` rows (3 skeleton rows)
- **Empty state:** Show `EmptyStateView` when all catalogs are empty
- **Error state:** Show `ErrorStateView` when catalog loading fails

### 3.5 DetailScreen

**File:** `Apps/LunaApp/Sources/Screens/DetailScreen.swift`

Changes:
- Backdrop hero: `.glassEffect(.clear)` overlay on the image
- Play/Bookmark/Watched buttons: `.glassCard(cornerRadius: 12, interactive: true)`
  - Play button gets `.glassProminentButtonStyle` treatment
- Genre chips: `.glassCapsule()` with color tint
- Cast circle avatars: `.glassCircle()` backgrounds
- Season selector pills: `.glassCapsule(interactive: true)`
- Episode cards: `.glassCard(cornerRadius: 10)` thumbnails with play button overlay
- Network/studio chips: `.glassCapsule()`
- Back button styled as glass circle
- Loading state: shimmer skeleton (backdrop + button row + text placeholders)
- Error state: `ErrorStateView` with retry

### 3.6 SearchScreen

**File:** `Apps/LunaApp/Sources/Screens/SearchScreen.swift`

Changes:
- Search field: `.glassCard(cornerRadius: 14)` background with search icon
- Add filter chips row below search bar:
  - "Trending", "Movies", "Shows" — `.glassCapsule(interactive: true)`
  - Active chip gets accent tint
- Results grid: updated `ContentCard` components (already fixed for posterShape)
- Empty state: `EmptyStateView` with magnifying glass icon
- Loading state: shimmer grid (3×3 skeleton cards)
- Add debounced search (300ms) instead of on-submit-only

### 3.7 LibraryScreen

**File:** `Apps/LunaApp/Sources/Screens/LibraryScreen.swift`

Changes:
- Cards: `.glassCard(cornerRadius: 8)` wrapping poster + name
- Add `.swipeActions` for swipe-to-delete (replaces context menu as primary action)
- Keep context menu as secondary (long-press)
- Empty state: `EmptyStateView` with bookmark icon, "Your library is empty" message,
  "Browse Popular" action button that switches to Home tab
- Loading state: shimmer grid

### 3.8 SettingsScreen

**File:** `Apps/LunaApp/Sources/Screens/SettingsScreen.swift`

Changes:
- Replace `List` with `ScrollView` + `VStack` for full control over glass styling
- Each section is a `.glassCard(cornerRadius: 14)` wrapping a `VStack`
- Profile section: avatar circle with gradient fill, name + role text
- Addon section: shows count badge, navigates to existing `AddonsScreen`
- Account section: "Switch Profile" and "Sign Out" rows
- Footer: version text in `textTertiary`
- `AddonsScreen`: same glass card treatment for addon rows

### 3.9 AdminDashboard

**File:** `Apps/LunaApp/Sources/Screens/Admin/AdminDashboard.swift`

Changes:
- Apply `.glassCard()` to section containers for visual consistency
- No functional changes

---

## 4. Animations & Micro-Interactions

### 4.1 Hero Carousel
- Cross-fade transition between hero items (`.easeInOut(duration: 0.4)`)
- Subtle parallax on the backdrop image during transition

### 4.2 Navigation Transitions
- `matchedGeometryEffect` from `ContentCard` poster → `DetailScreen` poster
- Spring animation on tab switching (`.interpolatingSpring(stiffness: 300, damping: 25)`)

### 4.3 Haptics
- Light impact on card tap (`.sensoryFeedback(.impact(weight: .light), trigger: ...)`)
- Medium impact on play/bookmark/watched toggle
- Success notification on "Added to Library"

### 4.4 Pull-to-Refresh
- Add `.refreshable` to HomeScreen ScrollView
- Add `.refreshable` to SearchScreen results ScrollView
- Add `.refreshable` to LibraryScreen ScrollView

### 4.5 Scroll-to-Top
- On tapping the active tab again, scroll to top with animation
- Use programmatic `ScrollViewReader` + `scrollTo`

---

## 5. iPad Adaptation

- Use `NavigationSplitView` for iPad (regular horizontal size class)
  - Sidebar: tab navigation icons + labels
  - Detail: content area
- Fall back to `TabView` for iPhone (compact horizontal size class)
- Adaptive grid columns: 6-8 columns on iPad vs 3-4 on iPhone
- Player screen: full-screen on iPhone, resizable window on iPad (Stage Manager compatible)

---

## 6. Fallback Strategy (iOS 17-25)

Every `.glassEffect()` call is gated with `#available(iOS 26, *)`. Fallbacks:

| iOS 26 | iOS 17-25 fallback |
|--------|--------------------|
| `.glassEffect(.regular, in: shape)` | `.ultraThinMaterial` + stroke + shadow |
| `.glassEffect(.clear, in: shape)` | `.ultraThinMaterial` + stroke |
| `.glassEffect(.clear.interactive(), in: Circle())` | `.fill(Color.white.opacity(0.10-0.15))` + circle |
| `.buttonStyle(.glassProminent)` | `.buttonStyle(.borderedProminent)` + `.tint(color)` |
| Native Slider glass thumb | Custom Capsule track + Circle thumb |
| System popover/sheet glass | `.presentationBackground(.ultraThinMaterial)` |
| `GlassEffectContainer` | No-op (skip the container, render children directly) |

---

## 7. Out of Scope

- Playback DRM / FairPlay
- Offline downloads
- Push notifications
- tvOS / watchOS / visionOS
- Simulator testing (per user instruction)
- Unit tests for UI components (SwiftUI previews only)

---

## 8. Implementation Order

| # | Task | Dependencies |
|---|------|-------------|
| 0a | Sync aiostreams URL | None |
| 0b | Wire PosterShape in ContentCard | None |
| 0c | Wire tileShape in FolderCell | None |
| 0d | Add app icon asset | None |
| 0e | Build glass modifiers in LunaTheme | None |
| 0f | Build ShimmerCard, EmptyStateView, ErrorStateView | 0e |
| 1 | AuthScreen redesign | 0d, 0e |
| 2 | ProfilePickerScreen (new) | 0e |
| 3 | HomeScreen redesign | 0a-f |
| 4 | DetailScreen redesign | 0b, 0e |
| 5 | PlayerScreen (new) | None (AVPlayer is system API) |
| 6 | SearchScreen redesign | 0b, 0e, 0f |
| 7 | LibraryScreen redesign | 0e, 0f |
| 8 | SettingsScreen redesign | 0e |
| 9 | AdminDashboard consistency | 0e |
| 10 | Animations + haptics pass | 1-9 |
| 11 | iPad adaptation | 1-9 |
