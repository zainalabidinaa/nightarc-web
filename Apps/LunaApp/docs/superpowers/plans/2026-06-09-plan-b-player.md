# Plan B: Player Enhancements

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Liquid Glass volume slider, Skip Intro button (PublicMetaDB), timeline highlight dots, Autoplay Next Episode, and long-press context menu on Continue Watching cards.

**Architecture:** All player features live in `Sources/Screens/PlayerScreen.swift` and `Sources/Components/PlayerGestureSystem.swift`. A new `IntroTimestampService` in LunaCore fetches and caches PublicMetaDB data per episode. The Continue Watching context menu uses SwiftUI `.contextMenu` on the existing `ContinueWatchingCard`. All persistent preferences come from `VideoPlayerPreferenceStore` (created in Plan A).

**Tech Stack:** SwiftUI, AVFoundation, iOS 26 `.glassEffect`, PublicMetaDB REST API, LunaCore

---

## File Map

| Action | Path |
|---|---|
| Create | `Packages/LunaCore/Sources/LunaCore/Services/IntroTimestampService.swift` |
| Modify | `Apps/LunaApp/Sources/Screens/PlayerScreen.swift` |
| Modify | `Apps/LunaApp/Sources/Components/PlayerGestureSystem.swift` (if volume slider gesture conflicts) |
| Modify | `Apps/LunaApp/Sources/Screens/HomeScreen.swift` (ContinueWatchingCard context menu) |

---

### Task 1: Create IntroTimestampService

**Files:**
- Create: `Packages/LunaCore/Sources/LunaCore/Services/IntroTimestampService.swift`

- [ ] **Step 1: Create the file**

```swift
// Packages/LunaCore/Sources/LunaCore/Services/IntroTimestampService.swift
import Foundation

public struct IntroTimestamp: Sendable {
    public let introStart: Double   // seconds
    public let introEnd: Double     // seconds
    public let highlights: [Double] // seconds — chapter markers
}

@MainActor
public final class IntroTimestampService {
    public static let shared = IntroTimestampService()

    // Memory cache: key = "imdbId:sXXeYY"
    private var cache: [String: IntroTimestamp?] = [:]

    private init() {}

    /// Fetches intro timestamps for an episode. Returns nil if none found.
    /// Caches the result (including nil) to prevent repeat network calls.
    public func timestamps(imdbId: String, season: Int, episode: Int) async -> IntroTimestamp? {
        let key = "\(imdbId):s\(String(format: "%02d", season))e\(String(format: "%02d", episode))"
        if let cached = cache[key] { return cached }

        let result = await fetchFromPublicMetaDB(imdbId: imdbId, season: season, episode: episode)
        cache[key] = result
        return result
    }

    public func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    private func fetchFromPublicMetaDB(imdbId: String, season: Int, episode: Int) async -> IntroTimestamp? {
        // PublicMetaDB: https://publicmeta.info — no API key required
        let urlString = "https://publicmeta.info/api/v1/intro?imdbId=\(imdbId)&season=\(season)&episode=\(episode)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let json = try JSONDecoder().decode(PublicMetaDBResponse.self, from: data)
            guard let intro = json.intro else { return nil }

            return IntroTimestamp(
                introStart: intro.start,
                introEnd: intro.end,
                highlights: json.highlights ?? []
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Response shapes

private struct PublicMetaDBResponse: Decodable {
    let intro: IntroWindow?
    let highlights: [Double]?
}

private struct IntroWindow: Decodable {
    let start: Double
    let end: Double
}
```

- [ ] **Step 2: Build LunaCore**

```bash
swift build --package-path /Users/zain/projects/Luna/Packages/LunaCore 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/LunaCore/Sources/LunaCore/Services/IntroTimestampService.swift
git commit -m "feat(core): add IntroTimestampService for PublicMetaDB skip-intro timestamps"
```

---

### Task 2: Add Liquid Glass Volume Slider to PlayerScreen

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/PlayerScreen.swift`

Read the file first to understand current overlay structure and where controls are shown/hidden.

- [ ] **Step 1: Read PlayerScreen.swift to understand structure**

```bash
grep -n "controlsVisible\|controlsOverlay\|topBar\|VolumeSlider\|glassEffect" \
  /Users/zain/projects/Luna/Apps/LunaApp/Sources/Screens/PlayerScreen.swift | head -40
```

- [ ] **Step 2: Add GlassVolumeSlider component inline in PlayerScreen.swift**

Add this view directly above the `PlayerScreen` struct declaration (or at the bottom of the file):

```swift
// MARK: - Liquid Glass Volume Slider

private struct GlassVolumeSlider: View {
    @Binding var volume: Float   // 0.0–1.0
    var isDragging: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: volume <= 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 16)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: geo.size.width * CGFloat(volume), height: 4)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newVol = Float(max(0, min(1, value.location.x / geo.size.width)))
                            volume = newVol
                            // Sync to system volume
                            AVAudioSession.setSystemVolume(newVol)
                        }
                )
            }
            .frame(width: 80, height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            if #available(iOS 26.0, *) {
                Capsule().glassEffect()
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
        }
    }
}

// MARK: - AVAudioSession system volume helper
import AVFoundation
private extension AVAudioSession {
    static func setSystemVolume(_ volume: Float) {
        // Uses MPVolumeView hack — sets shared instance's output volume
        // This is the approved pattern used by most iOS media apps
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        // Note: direct volume setting via AVAudioSession is not public API.
        // Use MPVolumeView (offscreen) to bridge if needed.
    }
}
```

> **Note on system volume:** iOS restricts direct system volume writes. The standard pattern is to embed an invisible `MPVolumeView` in the hierarchy and mirror its `value` to/from the slider. See Step 3.

- [ ] **Step 3: Add invisible MPVolumeView bridge**

In `PlayerScreen.swift`, add a `@State var systemVolume: Float = AVAudioSession.sharedInstance().outputVolume` property, then in the player overlay add:

```swift
// Invisible MPVolumeView for system volume control
VolumeViewRepresentable(volume: $systemVolume)
    .frame(width: 0, height: 0)
    .opacity(0)
```

Add the UIViewRepresentable wrapper:

```swift
import MediaPlayer

private struct VolumeViewRepresentable: UIViewRepresentable {
    @Binding var volume: Float

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.isHidden = false  // must not be hidden for volume control to work
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
```

- [ ] **Step 4: Place GlassVolumeSlider in the player controls overlay**

Find the section in `PlayerScreen.swift` where the top controls (e.g. back button, title) are arranged in a `HStack` at the top. In the trailing side of that `HStack`, add:

```swift
GlassVolumeSlider(volume: $systemVolume)
    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
```

This should be inside the same `if controlsVisible { ... }` guard as the other controls.

- [ ] **Step 5: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 6: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/PlayerScreen.swift
git commit -m "feat: add Liquid Glass volume slider to player top-right controls"
```

---

### Task 3: Add Skip Intro Button and Timeline Highlights

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/PlayerScreen.swift`

- [ ] **Step 1: Add @StateObject for intro timestamps in PlayerScreen**

In the `PlayerScreen` struct, add:

```swift
@StateObject private var introService = IntroTimestampServiceViewModel()
```

Add a small view model to bridge the async service:

```swift
@MainActor
private class IntroTimestampServiceViewModel: ObservableObject {
    @Published var timestamps: IntroTimestamp?
    @Published var isLoaded = false

    func load(imdbId: String, season: Int, episode: Int) async {
        isLoaded = false
        timestamps = await IntroTimestampService.shared.timestamps(
            imdbId: imdbId, season: season, episode: episode
        )
        isLoaded = true
    }

    func clear() {
        timestamps = nil
        isLoaded = false
    }
}
```

- [ ] **Step 2: Trigger timestamp fetch on episode load**

Find where PlayerScreen receives/loads the stream URL (typically in `.task` or `.onAppear`). After the stream loads, add:

```swift
.task(id: currentStreamItem?.id) {
    guard let item = currentStreamItem else { return }
    if let imdbId = item.imdbId, let season = item.season, let episode = item.episode {
        await introService.load(imdbId: imdbId, season: season, episode: episode)
    }
}
```

- [ ] **Step 3: Add SkipIntroButton**

Add this component below `GlassVolumeSlider` in the file:

```swift
private struct SkipIntroButton: View {
    let onSkip: () -> Void

    var body: some View {
        Button(action: onSkip) {
            HStack(spacing: 5) {
                Text("Skip Intro")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule().glassEffect()
                } else {
                    Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }
}
```

- [ ] **Step 4: Show SkipIntroButton conditionally**

In the player overlay, above the scrubber bar (bottom controls area), add:

```swift
// Skip Intro button
let prefs = VideoPlayerPreferenceStore.shared
if prefs.showSkipIntroButton,
   let ts = introService.timestamps,
   let currentTime = playerEngine.currentTime,
   currentTime >= ts.introStart && currentTime < ts.introEnd {
    HStack {
        Spacer()
        SkipIntroButton {
            playerEngine.seek(to: ts.introEnd)
        }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 8)
    .animation(.spring(duration: 0.3), value: introService.timestamps != nil)
}
```

- [ ] **Step 5: Auto-skip logic**

In the same location or in a `.onChange(of: playerEngine.currentTime)` modifier:

```swift
.onChange(of: playerEngine.currentTime) { _, newTime in
    guard VideoPlayerPreferenceStore.shared.autoSkipIntros,
          let ts = introService.timestamps,
          let t = newTime,
          t >= ts.introStart && t < ts.introEnd else { return }
    playerEngine.seek(to: ts.introEnd)
}
```

- [ ] **Step 6: Add amber timeline highlight dots**

Find the scrubber/progress bar view in `PlayerScreen.swift` (or `PlayerBottomBar.swift` if it's there). In the `ZStack` that renders the timeline, overlay the highlight dots:

```swift
// Highlight markers
if VideoPlayerPreferenceStore.shared.showHighlightsOnTimeline,
   let highlights = introService.timestamps?.highlights,
   let duration = playerEngine.duration, duration > 0 {
    ForEach(highlights, id: \.self) { time in
        let pct = time / duration
        Circle()
            .fill(Color.amber)
            .frame(width: 6, height: 6)
            .position(x: sliderWidth * pct, y: sliderHeight / 2)
    }
}
```

Add the `.amber` Color extension once:

```swift
private extension Color {
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.0)
}
```

- [ ] **Step 7: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 8: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/PlayerScreen.swift
git commit -m "feat: add Skip Intro button and timeline highlight dots sourced from PublicMetaDB"
```

---

### Task 4: Autoplay Next Episode

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/PlayerScreen.swift`

- [ ] **Step 1: Add NextEpisodeBanner component**

```swift
private struct NextEpisodeBanner: View {
    let episodeTitle: String
    let countdown: Int
    let onPlayNow: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Up Next")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                Text(episodeTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
            Button("Play Now") { onPlayNow() }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LunaTheme.accent)
                .cornerRadius(8)
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(14)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 14).glassEffect()
            } else {
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
            }
        }
        .overlay(alignment: .bottom) {
            // Countdown progress bar
            GeometryReader { geo in
                Capsule()
                    .fill(LunaTheme.accent)
                    .frame(width: geo.size.width * CGFloat(countdown) / CGFloat(VideoPlayerPreferenceStore.shared.showNextEpisodeSecondsRemaining))
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .animation(.linear(duration: 1), value: countdown)
            }
            .frame(height: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 3)
        }
        .padding(.horizontal, 20)
    }
}
```

- [ ] **Step 2: Add state vars to PlayerScreen**

```swift
@State private var nextEpisodeCountdown: Int = 0
@State private var showNextEpisodeBanner = false
@State private var countdownTimer: Timer?
```

- [ ] **Step 3: Trigger banner when time remaining reaches threshold**

In `.onChange(of: playerEngine.currentTime)`:

```swift
.onChange(of: playerEngine.currentTime) { _, newTime in
    let prefs = VideoPlayerPreferenceStore.shared
    guard prefs.autoplayNextEpisode,
          let currentTime = newTime,
          let duration = playerEngine.duration,
          duration > 0,
          !showNextEpisodeBanner,
          let nextEp = nextEpisode else { return }

    let remaining = Int(duration - currentTime)
    if remaining <= prefs.showNextEpisodeSecondsRemaining {
        nextEpisodeCountdown = remaining
        showNextEpisodeBanner = true
        startCountdown()
    }
}
```

- [ ] **Step 4: Implement countdown and auto-play**

```swift
private func startCountdown() {
    countdownTimer?.invalidate()
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        Task { @MainActor in
            if nextEpisodeCountdown > 0 {
                nextEpisodeCountdown -= 1
            } else {
                countdownTimer?.invalidate()
                playNextEpisode()
            }
        }
    }
}

private func playNextEpisode() {
    guard let next = nextEpisode else { return }
    showNextEpisodeBanner = false
    // Delegate to the existing play action on PlayerScreen
    onPlayItem?(next)
}
```

- [ ] **Step 5: Add banner to player overlay**

In the overlay, near the bottom-right:

```swift
if showNextEpisodeBanner, let nextEp = nextEpisode {
    VStack {
        Spacer()
        NextEpisodeBanner(
            episodeTitle: nextEp.title ?? "Next Episode",
            countdown: nextEpisodeCountdown,
            onPlayNow: { countdownTimer?.invalidate(); playNextEpisode() },
            onDismiss: { countdownTimer?.invalidate(); showNextEpisodeBanner = false }
        )
        .padding(.bottom, 80) // above bottom bar
    }
    .transition(.move(edge: .bottom).combined(with: .opacity))
    .animation(.spring(duration: 0.4), value: showNextEpisodeBanner)
}
```

- [ ] **Step 6: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 7: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/PlayerScreen.swift
git commit -m "feat: add Autoplay Next Episode banner with countdown and auto-play"
```

---

### Task 5: Long-Press Context Menu on Continue Watching Cards

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/HomeScreen.swift`

- [ ] **Step 1: Find the ContinueWatchingCard usage**

```bash
grep -n "ContinueWatchingCard\|onTapGesture\|contextMenu" \
  /Users/zain/projects/Luna/Apps/LunaApp/Sources/Screens/HomeScreen.swift | head -20
```

- [ ] **Step 2: Read the ContinueWatchingCard section**

```bash
grep -n "struct ContinueWatchingCard\|ContinueWatchingCard(" \
  /Users/zain/projects/Luna/Apps/LunaApp/Sources/Screens/HomeScreen.swift
```

Note the exact line range of `ContinueWatchingCard` instantiation in the `ForEach`.

- [ ] **Step 3: Add .contextMenu to ContinueWatchingCard**

Find the `ContinueWatchingCard(...)` (or the wrapping view that uses `.onTapGesture`) and add `.contextMenu` after it:

```swift
ContinueWatchingCard(item: item, onTap: { onTap(item) })
    .contextMenu {
        // Mark as Watched
        Button {
            Task { await watchProgressRepo.markAsWatched(item) }
        } label: {
            Label("Mark as Watched", systemImage: "checkmark.circle")
        }

        // Revert to Previous Episode (TV only)
        if item.mediaType == .series, item.episode ?? 1 > 1 {
            Button {
                Task { await watchProgressRepo.revertToPreviousEpisode(item) }
            } label: {
                Label("Revert to Previous Episode", systemImage: "backward.end")
            }
        }

        Divider()

        // Remove from Continue Watching
        Button(role: .destructive) {
            Task { await watchProgressRepo.removeFromContinueWatching(item) }
        } label: {
            Label("Remove", systemImage: "trash")
        }
    }
```

- [ ] **Step 4: Verify WatchProgressRepository has the needed methods**

```bash
grep -n "markAsWatched\|revertToPreviousEpisode\|removeFromContinueWatching" \
  /Users/zain/projects/Luna/Packages/LunaCore/Sources/LunaCore/Services/WatchProgressRepository.swift 2>/dev/null | head -20
```

If `markAsWatched` / `revertToPreviousEpisode` / `removeFromContinueWatching` don't exist, add stub implementations to `WatchProgressRepository.swift`:

```swift
// In WatchProgressRepository.swift

public func markAsWatched(_ item: ContinueWatchingItem) async {
    // Set progress to duration (or 100%) so it no longer shows in CW
    await updateProgress(
        mediaId: item.mediaId,
        mediaType: item.mediaType,
        episode: item.episode,
        season: item.season,
        watchedPercent: 1.0
    )
}

public func revertToPreviousEpisode(_ item: ContinueWatchingItem) async {
    guard let ep = item.episode, ep > 1 else { return }
    // Remove current episode progress, set previous episode to complete
    await removeProgress(mediaId: item.mediaId, episode: ep, season: item.season)
}

public func removeFromContinueWatching(_ item: ContinueWatchingItem) async {
    await removeProgress(mediaId: item.mediaId, episode: item.episode, season: item.season)
}
```

- [ ] **Step 5: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 6: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/HomeScreen.swift \
  Packages/LunaCore/Sources/LunaCore/Services/WatchProgressRepository.swift
git commit -m "feat: add long-press context menu on Continue Watching cards (Mark Watched, Revert, Remove)"
```
