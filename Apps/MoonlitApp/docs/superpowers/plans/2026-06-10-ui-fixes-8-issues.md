# UI Fixes — 8 Issues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 8 distinct UI/UX issues across ActorBioScreen, DetailScreen description/episode sheets, player controls, hero carousel, and library accent color.

**Architecture:** Targeted edits to existing screens — no new files except `GlassVolumeSlider.swift` extracted from PlayerScreen. Each task is independent and can be committed separately.

**Tech Stack:** SwiftUI, iOS 26 liquid glass APIs (`.glassEffect()`), MPVolumeView, UIKit UIViewRepresentable, TMDB person API

---

## File Map

| File | Changes |
|------|---------|
| `Sources/Screens/ActorBioScreen.swift` | Multi-photo row, Show More bio, remove IMDb, Personal Info labels, Known For posters, Credits filters |
| `Sources/Screens/DetailScreen.swift` | Description → sheet, episode description info button → sheet, season 0 filter |
| `Sources/Screens/PlayerScreen.swift` | X button size, controls pushed to bottom, skip intro button position/style, volume slider fix, audio button fix, matte glitch fix |
| `Sources/Components/PlayerBottomBar.swift` | Layout tweak if needed for audio button |
| `Sources/Components/ParallaxHero.swift` | Move page dots below title/metadata row |
| `Sources/Screens/LibraryScreen.swift` | Verify red color stays scoped to heart icon (already correct per research — just confirm) |

---

## Task 1: Season 0 Filter

**Files:**
- Modify: `Sources/Screens/DetailScreen.swift` — line 240

This is a one-liner. Filter out season 0 before sorting.

- [ ] **Step 1: Find and edit the season sort line**

In `DetailScreen.swift` at line ~240, the season picker reads:
```swift
let sorted = seasons.sorted { $0.number < $1.number }
```
Change it to:
```swift
let sorted = seasons.filter { $0.number != 0 }.sorted { $0.number < $1.number }
```

- [ ] **Step 2: Commit**
```bash
git add Sources/Screens/DetailScreen.swift
git commit -m "fix: filter out season 0 from season picker"
```

---

## Task 2: Description Liquid Glass Sheet

**Files:**
- Modify: `Sources/Screens/DetailScreen.swift` — ExpandableText usage (~line 229) and `ExpandableText` component (~line 1116–1135)

Currently tapping "More" expands inline with `expanded.toggle()`. Replace with a `.sheet` that slides up as a liquid glass bottom sheet.

**Data needed in sheet:** the full description string + the item title.

- [ ] **Step 1: Add sheet state to DetailScreen**

Find the state vars at the top of the `DetailScreen` body (or `struct`). Add:
```swift
@State private var showDescriptionSheet = false
```

- [ ] **Step 2: Replace ExpandableText with a tappable truncated Text + sheet**

Find the block that uses `ExpandableText` for the main description (around line 229). Replace the full block with:
```swift
if let overview = item.overview, !overview.isEmpty {
    VStack(alignment: .leading, spacing: 4) {
        Text(overview)
            .font(.subheadline)
            .foregroundColor(MoonlitTheme.textSecondary)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
        Button {
            showDescriptionSheet = true
        } label: {
            Text("More")
                .font(.caption.bold())
                .foregroundColor(MoonlitTheme.accent)
        }
    }
    .contentShape(Rectangle())
    .onTapGesture { showDescriptionSheet = true }
}
```

- [ ] **Step 3: Attach the sheet modifier to DetailScreen's root view**

Find the outermost `.sheet` or toolbar modifier chain on the DetailScreen root view and append:
```swift
.sheet(isPresented: $showDescriptionSheet) {
    DescriptionSheet(title: item.title ?? "", text: item.overview ?? "")
}
```

- [ ] **Step 4: Create DescriptionSheet view**

Add this new private struct at the bottom of `DetailScreen.swift` (before the last `}`):
```swift
private struct DescriptionSheet: View {
    let title: String
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .if(#available(iOS 26, *)) { view in
            view.presentationBackground(.ultraThinMaterial)
        }
    }
}
```

> **Note on `.if`:** If the codebase has a `.if` view modifier helper, use it. Otherwise wrap in `if #available(iOS 26.0, *) { ... } else { ... }` with `presentationBackground(.ultraThinMaterial)` for both.

- [ ] **Step 5: Episode description sheet**

Episode cards are in DetailScreen around line 1196–1214. The episode overview text is a 2-line truncated `Text` with no tap handler for description. Add a separate info button alongside each episode card to show the description:

Add state:
```swift
@State private var selectedEpisodeOverview: String? = nil
```

On each episode card, after the `Text(overview)` block, add a small info button:
```swift
Button {
    selectedEpisodeOverview = overview
} label: {
    Image(systemName: "info.circle")
        .font(.caption)
        .foregroundColor(MoonlitTheme.textSecondary)
}
```

Attach sheet to the episodes container:
```swift
.sheet(item: $selectedEpisodeOverview) { text in
    DescriptionSheet(title: "Episode", text: text)
}
```

> **Note:** `String` doesn't conform to `Identifiable`. Either use `.sheet(isPresented:)` with a separate bool state, or wrap the string in a small identifiable struct: `struct EpisodeOverview: Identifiable { let id = UUID(); let text: String }`.

Use this wrapper:
```swift
struct EpisodeOverview: Identifiable {
    let id = UUID()
    let text: String
}
```
And `@State private var selectedEpisode: EpisodeOverview? = nil`.

- [ ] **Step 6: Commit**
```bash
git add Sources/Screens/DetailScreen.swift
git commit -m "feat: replace description inline expand with liquid glass bottom sheet; add episode description sheet"
```

---

## Task 3: ActorBioScreen Redesign

**Files:**
- Modify: `Sources/Screens/ActorBioScreen.swift` (full rewrite of layout sections)

**Target layout (from reference screenshots):**
1. Horizontal row of up to 3 portrait photos at top (120×160, corner radius 12)
2. Name + department heading
3. Bio text — truncated to 4 lines, "Show More" button → expands inline or sheet
4. Personal Info glassCard — rows: Department/Area of Work, Born (date + age), Place of Birth, Also Known As. **Remove IMDb row entirely.**
5. Known For — horizontal `ScrollView` of poster `ContentCard`s (not backdrops)
6. Credits — grouped by year descending, with a filter segmented control (All / Acting / Directing), each row shows: poster thumbnail, title, year, type pill (Movie/TV), character name, episode count if TV, TMDB score

- [ ] **Step 1: Remove IMDb row**

Find the `infoRow(label: "IMDb", ...)` line (~line 113). Delete the entire `if let imdbId` block including the row.

- [ ] **Step 2: Multi-photo header**

Replace the single `CachedAsyncImage` block (lines ~68–79) with a horizontal row of up to 3 profile paths. TMDB provides only one `profilePath` per person from the basic API. Use a fallback approach: show the single profile photo 3 times at different sizes to simulate a photo strip, OR use `combinedCredits` backdrop images from the first 2 credits.

Practical approach — show main profile photo once at center with flanking placeholder/backdrop thumbnails:
```swift
HStack(spacing: 12) {
    // Left: first credit backdrop thumbnail if available
    if let firstBackdrop = viewModel.knownForCredits.first?.backdropPath {
        CachedAsyncImage(path: firstBackdrop, size: CGSize(width: 90, height: 120))
            .frame(width: 90, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(0.7)
    }
    // Center: main profile photo (larger)
    CachedAsyncImage(path: person.profilePath, size: CGSize(width: 110, height: 150))
        .frame(width: 110, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    // Right: second credit backdrop
    if let secondBackdrop = viewModel.knownForCredits.dropFirst().first?.backdropPath {
        CachedAsyncImage(path: secondBackdrop, size: CGSize(width: 90, height: 120))
            .frame(width: 90, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(0.7)
    }
}
.frame(maxWidth: .infinity)
.padding(.top, 20)
```

- [ ] **Step 3: Bio "Show More" expansion**

Currently bio is `.lineLimit(6)` with no expansion. Add a state and button:
```swift
@State private var bioExpanded = false
```

Replace the bio `Text` block:
```swift
VStack(alignment: .leading, spacing: 6) {
    Text(person.biography ?? "")
        .font(.subheadline)
        .foregroundColor(MoonlitTheme.textSecondary)
        .lineLimit(bioExpanded ? nil : 4)
        .animation(.easeInOut(duration: 0.2), value: bioExpanded)
    if (person.biography?.count ?? 0) > 200 {
        Button {
            bioExpanded.toggle()
        } label: {
            Text(bioExpanded ? "Show Less" : "Show More")
                .font(.caption.bold())
                .foregroundColor(MoonlitTheme.accent)
        }
    }
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
```

- [ ] **Step 4: Personal Info — fix row labels**

Find `infoTable()`. The rows should be:
- "Department" → `person.knownForDepartment`  
- "Born" → formatted birth date + " (age \(age))" computed from birth date  
- "Place of Birth" → `person.placeOfBirth`  
- "Also Known As" → `person.alsoKnownAs?.first` (or joined with comma)

Remove IMDb row (already done in Step 1).

Add age calculation helper:
```swift
private func age(from dateString: String?) -> Int? {
    guard let dateString,
          let dob = ISO8601DateFormatter().date(from: dateString + "T00:00:00Z") else { return nil }
    return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
}
```

Born row value:
```swift
let ageStr = age(from: person.birthday).map { " (age \($0))" } ?? ""
infoRow(label: "Born", value: (formatDate(person.birthday) ?? "") + ageStr)
```

- [ ] **Step 5: Known For — switch to poster cards**

Find the Known For `ScrollView` (lines ~136–170). Change from backdrop to poster style:
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(viewModel.knownForCredits.prefix(10)) { credit in
            VStack(alignment: .leading, spacing: 6) {
                CachedAsyncImage(path: credit.posterPath, size: CGSize(width: 100, height: 150))
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(credit.title ?? credit.name ?? "")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MoonlitTheme.textPrimary)
                    .lineLimit(2)
                    .frame(width: 100)
            }
        }
    }
    .padding(.horizontal, 20)
}
```

- [ ] **Step 6: Credits — filter picker + year grouping + character + ep count**

The current credit list groups by year already. Add a filter picker above:

Add state:
```swift
@State private var creditFilter: CreditFilter = .all
enum CreditFilter: String, CaseIterable { case all = "All"; case acting = "Acting"; case directing = "Directing" }
```

Add picker above the credits list:
```swift
Picker("Credits", selection: $creditFilter) {
    ForEach(CreditFilter.allCases, id: \.self) { f in
        Text(f.rawValue).tag(f)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal, 20)
```

Filter credits before year grouping:
```swift
let filtered = viewModel.allCredits.filter { credit in
    switch creditFilter {
    case .all: return true
    case .acting: return credit.department == "Acting"
    case .directing: return credit.department == "Directing"
    }
}
```

Each credit row should show:
```swift
HStack(spacing: 12) {
    CachedAsyncImage(path: credit.posterPath, size: CGSize(width: 36, height: 54))
        .frame(width: 36, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    VStack(alignment: .leading, spacing: 2) {
        HStack {
            Text(credit.title ?? credit.name ?? "")
                .font(.subheadline.weight(.medium))
                .foregroundColor(MoonlitTheme.textPrimary)
            Spacer()
            if let vote = credit.voteAverage, vote > 0 {
                Text(String(format: "%.1f", vote))
                    .font(.caption.bold())
                    .foregroundColor(MoonlitTheme.accent)
            }
        }
        HStack(spacing: 6) {
            Text(credit.mediaType == "tv" ? "TV" : "Film")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            if let char = credit.character, !char.isEmpty {
                Text("as \(char)")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textSecondary)
            }
            if let eps = credit.episodeCount, eps > 0 {
                Text("\(eps) ep\(eps == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textSecondary)
            }
        }
    }
}
```

- [ ] **Step 7: Commit**
```bash
git add Sources/Screens/ActorBioScreen.swift
git commit -m "feat(actor): redesign ActorBioScreen — multi-photo header, Show More bio, remove IMDb, poster Known For, credit filters"
```

---

## Task 4: Player Controls — Layout, X Button, Volume Slider Fix

**Files:**
- Modify: `Sources/Screens/PlayerScreen.swift`

**Issues to fix:**
1. X button too small (currently 40×40 frame, 15pt icon)
2. Controls have too much dead space above — need to push everything to bottom
3. Volume slider not working — GlassVolumeSlider is visual-only, MPVolumeView bridge is present but may not be syncing correctly
4. Volume slider should look like liquid glass pill

- [ ] **Step 1: Enlarge X button**

Find the X button definition (~line 326–335). Change frame and font:
```swift
Button {
    engine.stop()
    onDismiss()
} label: {
    Image(systemName: "xmark")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 52, height: 52)
}
.glassCircle(clear: true)
```

- [ ] **Step 2: Fix volume slider to actually control system volume**

The current `GlassVolumeSlider` uses a drag gesture to update `@State var systemVolume` but the MPVolumeView bridge is hidden at 0×0. The issue is the MPVolumeView isn't receiving the volume change — it auto-syncs FROM system but doesn't write TO system via the SwiftUI binding.

The correct fix: make MPVolumeView visible but clipped inside the glass pill, or use `AVAudioSession` setter. Since MPVolumeView is the only sanctioned way, restructure the slider so the MPVolumeView's built-in slider is hidden inside the pill and a transparent overlay captures visual state:

Replace `GlassVolumeSlider` (lines ~989–1029) with a UIViewRepresentable that wraps MPVolumeView in the pill shape:

```swift
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let v = MPVolumeView()
        v.showsRouteButton = false
        v.tintColor = .white
        // Style the slider thumb and track
        v.setVolumeThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        return v
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
```

Then in the playerTopBar, replace the GlassVolumeSlider + hidden MPVolumeView with:
```swift
HStack(spacing: 8) {
    Image(systemName: "speaker.wave.2.fill")
        .font(.system(size: 14))
        .foregroundColor(.white)
    SystemVolumeSlider()
        .frame(width: 180, height: 28)
}
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background {
    Capsule()
        .fill(.ultraThinMaterial)
        .glassEffect(in: .capsule)
}
```

- [ ] **Step 3: Push controls to bottom — reduce top dead space**

The `playerControlsLayer` uses a ZStack with alignment `.bottom` for the bottom area. The transport (play/pause buttons) is centered. If there's a large gap between the transport and the bottom bar, it's because the ZStack is filling the full screen height and transport is at `alignment: .center`.

Find `playerBottomArea` view (around line 279). Check if there's explicit `Spacer()` above the title/scrubber area. Remove or reduce top spacers. The playerTopBar should sit at the natural top with a reasonable padding; everything else should compress toward bottom.

If the transport is in a centered ZStack overlay, change the overlay's vertical alignment:
```swift
ZStack(alignment: .bottom) {
    // playerBottomArea anchored to bottom
    playerBottomArea
    // transport centered only vertically within the remaining space
    playerTransport
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
}
```

Adjust `.padding(.bottom, X)` on the bottom area to be around 24–32pt on devices without home button.

- [ ] **Step 4: Commit**
```bash
git add Sources/Screens/PlayerScreen.swift
git commit -m "fix(player): enlarge X button, fix volume slider to use MPVolumeView, reduce vertical dead space"
```

---

## Task 5: Skip Intro Button — Liquid Glass Centered Above Timeline

**Files:**
- Modify: `Sources/Screens/PlayerScreen.swift` — skip intro button rendering (~line 378–392, 1049–1073)

Currently the skip intro button is in a `HStack` inside the bottom area. Move it to a centered overlay above the timeline slider, styled as a liquid glass capsule.

**Plan B for when publicmeta.info has no data:** Show a configurable "Skip 85s" button that the user can set in Settings. Already exists as `VideoPlayerPreferenceStore`. Add a setting `skipIntroDuration: Int = 85` defaulting to 85 seconds.

- [ ] **Step 1: Move skip intro button to ZStack overlay above timeline**

Remove the button from its current HStack location. Add it as an overlay in `playerControlsLayer` positioned just above the scrubber:
```swift
// Above scrubber, horizontally centered
if showSkipIntroButton, let ts = introViewModel.timestamps {
    Button {
        engine.seek(to: ts.introEnd)
    } label: {
        Text("Skip Intro")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }
    .background {
        Capsule()
            .fill(.ultraThinMaterial)
            .glassEffect(in: .capsule)
    }
    .transition(.opacity.combined(with: .scale(scale: 0.9)))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .padding(.bottom, 80) // sits above scrubber row
}
```

The `showSkipIntroButton` computed var:
```swift
private var showSkipIntroButton: Bool {
    guard prefs.showSkipIntroButton,
          let ts = introViewModel.timestamps else { return false }
    return engine.currentPosition >= ts.introStart && engine.currentPosition < ts.introEnd
}
```

- [ ] **Step 2: Plan B fallback — configurable skip button**

In `VideoPlayerPreferenceStore`, add:
```swift
@Published var skipIntroDuration: Int {
    get { UserDefaults.standard.integer(forKey: "skipIntroDuration").nonZero ?? 85 }
    set { UserDefaults.standard.set(newValue, forKey: "skipIntroDuration") }
}
```

Show a "Skip +85s" button when `introViewModel.timestamps == nil` and playback position > 30s and < 300s (heuristic window):
```swift
else if prefs.showSkipIntroButton && introViewModel.timestamps == nil
     && engine.currentPosition > 30 && engine.currentPosition < 300 {
    Button {
        engine.seek(to: engine.currentPosition + Double(prefs.skipIntroDuration))
    } label: {
        Text("Skip +\(prefs.skipIntroDuration)s")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 10)
    }
    .background { Capsule().fill(.ultraThinMaterial).glassEffect(in: .capsule) }
    .transition(.opacity)
}
```

- [ ] **Step 3: Commit**
```bash
git add Sources/Screens/PlayerScreen.swift
git commit -m "feat(player): move skip intro to liquid glass pill centered above timeline; add configurable Plan B skip"
```

---

## Task 6: Audio Button Fix + Matte/Glass Glitch

**Files:**
- Modify: `Sources/Screens/PlayerScreen.swift` — audio button and `AudioTrackModal` presentation
- Possibly: `Sources/Components/PlayerModals/AudioTrackModal.swift`

**Known state:** Audio button was moved to a `...` menu or inline in the player top/bottom area. AudioTrackModal isn't presenting. There is also a visual glitch where a button goes matte then back to glass.

- [ ] **Step 1: Locate the audio button and its action**

In PlayerScreen, search for `AudioTrackModal` usage. The button should be calling something like:
```swift
showAudioModal = true
```
And the sheet bound with:
```swift
.sheet(isPresented: $showAudioModal) { AudioTrackModal(engine: engine) }
```

If `showAudioModal` is a `@State var` but the sheet is attached to a view that gets conditionally removed (e.g., inside an `if controls visible` block), the sheet will be dismissed as soon as the controls hide. Fix: attach the sheet to the outermost `ZStack` or `NavigationStack`, not to the button's parent.

Move the `.sheet(isPresented: $showAudioModal)` modifier to the root view of PlayerScreen.

- [ ] **Step 2: Fix matte/glass state glitch**

The glitch where the button appears matte momentarily then switches back to glass happens when a `.sheet` is presented and SwiftUI recalculates the glass state. 

Fix: Disable the glass effect animation on state change by wrapping the button's background in `Transaction`:
```swift
.onChange(of: showAudioModal) { _, _ in
    // Prevent glass recalculation flicker
}
```

More reliably: make sure the audio button itself doesn't sit inside a container that re-renders when `showAudioModal` changes. Extract the audio button into its own sub-view so its identity is stable.

Alternatively — if the button uses a custom `glassCircle(interactive:)` modifier with a pressed state — ensure the `isPressed` binding resets correctly after the sheet is presented. Check `PlayerGestureSystem.swift` if the gesture system is involved.

- [ ] **Step 3: Confirm AudioTrackModal shows audio tracks**

The modal needs `engine.audioTracks` to be non-empty. Add a debug Text in the modal during testing:
```swift
Text("Tracks: \(engine.audioTracks.count)")
```
If it shows 0, the stream hasn't loaded tracks yet. The modal presentation should be gated on `engine.isPlaying || engine.isPaused`.

- [ ] **Step 4: Commit**
```bash
git add Sources/Screens/PlayerScreen.swift Sources/Components/PlayerModals/AudioTrackModal.swift
git commit -m "fix(player): fix AudioTrackModal not presenting; fix glass/matte button glitch"
```

---

## Task 7: Hero Carousel — Page Dots Below Title + Layout Match

**Files:**
- Modify: `Sources/Components/ParallaxHero.swift`

**Current state:** Page dots exist at `.topTrailing` alignment (lines 99–112). User wants dots **below** the title/metadata/button row (like the reference screenshot showing dots centered under the content).

- [ ] **Step 1: Move page dots below content row**

Find the dots `HStack` (~line 99–112). Currently positioned in a ZStack overlay at topTrailing. 

Restructure the bottom content VStack (title + metadata + buttons) to include the dots at the bottom of that VStack:
```swift
VStack(alignment: .center, spacing: 16) {
    // ... existing title, metadata, genre chips, play/mylist buttons ...
    
    // Page dots — centered below buttons
    HStack(spacing: 6) {
        ForEach(0..<items.count, id: \.self) { i in
            Capsule()
                .fill(i == currentIndex ? Color.white : Color.white.opacity(0.35))
                .frame(width: i == currentIndex ? 20 : 6, height: 3)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
        }
    }
    .padding(.bottom, 4)
}
```

Remove the old dots overlay from the ZStack.

- [ ] **Step 2: Verify bookmark button action**

The research confirmed the bookmark button calls `onToggleLibrary(item)` which is wired to `libraryRepo.toggleLibrary(...)` in HomeScreen. This should be working. 

Quick check: confirm the button label updates reactively. If `libraryRepo.watchlist` is a `@Published` set, the button needs to observe it. The button label text should be conditional:
```swift
let isInList = libraryRepo.watchlist.contains(where: { $0.id == item.id })
Image(systemName: isInList ? "bookmark.fill" : "bookmark")
Text(isInList ? "In My List" : "My List")
```

If `ParallaxHero` doesn't have access to `libraryRepo`, add a `isInLibrary: Bool` parameter passed from HomeScreen:
```swift
// In ParallaxHero init
var isCurrentItemInLibrary: Bool = false

// In HomeScreen, when calling ParallaxHero:
isCurrentItemInLibrary: libraryRepo.watchlist.contains(where: { $0.id == items[safe: currentIndex]?.id })
```

- [ ] **Step 3: Commit**
```bash
git add Sources/Components/ParallaxHero.swift
git commit -m "feat(carousel): move page dots below content row; fix bookmark button state reactivity"
```

---

## Task 8: Red Accent Verification + MoonlitTheme Check

**Files:**
- Possibly: `Sources/Screens/LibraryScreen.swift`, any file defining `MoonlitTheme.accent`

**Research finding:** The red `Color(red:1, green:0.25, blue:0.35)` in LibraryScreen is only used for the heart.fill icon tint. Season pills use `MoonlitTheme.accent`. The user saw red in screenshots — this may be because `MoonlitTheme.accent` itself is red, or because the icon tint leaked via some parent modifier.

- [ ] **Step 1: Check MoonlitTheme.accent definition**

Find `MoonlitTheme.swift` and read the `accent` color definition. If it is red (or close to the heart tint), that explains why season pills appear red. The accent should be a blue/teal or brand color, not red.

If `MoonlitTheme.accent` is defined as red, change it to the intended brand color (e.g., a blue `Color(red: 0.2, green: 0.5, blue: 1.0)` or wherever the original brand color was).

- [ ] **Step 2: Scope the heart tint**

In LibraryScreen, the heart.fill tint is `Color(red:1, green:0.25, blue:0.35)`. Ensure it's applied only as `.foregroundColor` on the `Image(systemName: "heart.fill")` — not on any parent `HStack` or `VStack`. Verify by reading the surrounding code:

```swift
// GOOD — scoped:
Image(systemName: "heart.fill")
    .foregroundColor(Color(red: 1, green: 0.25, blue: 0.35))

// BAD — would leak to children:
HStack {
    Image(systemName: "heart.fill")
    Text("Liked")
}
.foregroundColor(Color(red: 1, green: 0.25, blue: 0.35))  // ← leaks to Text
```

If the tint is on a parent container, move it strictly onto the `Image`.

- [ ] **Step 3: Commit if changes made**
```bash
git add Sources/Screens/LibraryScreen.swift Packages/MoonlitCore/Sources/MoonlitCore/Theme/MoonlitTheme.swift
git commit -m "fix: scope heart icon tint to image only; verify MoonlitTheme.accent is correct brand color"
```

---

## Recommended Order

1. **Task 1** — Season 0 filter (trivial, one line)
2. **Task 8** — Red accent verification (read-first, may be trivial)
3. **Task 2** — Description sheet (medium, self-contained)
4. **Task 7** — Hero carousel dots (low risk layout change)
5. **Task 4** — Player controls + volume slider (medium risk, touch player)
6. **Task 5** — Skip intro position (depends on player layout from Task 4)
7. **Task 6** — Audio button fix (debug-first task)
8. **Task 3** — ActorBioScreen redesign (largest change, save for last)

---

## Notes on IntroDB

The user asked if skip intro is integrated with **IntroDB** (https://github.com/TheIntroDB). It is not — the current `IntroTimestampService` uses `publicmeta.info/api/v1/intro`. 

IntroDB appears to be a community GitHub project. If they expose a public HTTP API, we could switch. Based on the GitHub URL, the pattern would likely be something like `https://api.theintrodb.com/v1/intro?imdbId=&season=&episode=` — but this must be verified against their actual docs/README before changing the service. The `publicmeta.info` source is currently working and providing data. **Do not switch IntroDB until the API endpoint is confirmed.**

Plan B (configurable skip duration in Settings) covers cases where neither source has data.
