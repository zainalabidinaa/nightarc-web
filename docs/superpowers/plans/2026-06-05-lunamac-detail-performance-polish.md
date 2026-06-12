# LunaMac Detail Performance Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Center and neutralize LunaMac detail pages, restore episode artwork aliases, and remove a wasted home catalog loading pass.

**Architecture:** Keep the existing LunaMac SwiftUI screens and LunaCore parsing services. Make the smallest changes in place: metadata decoding normalizes season episode artwork, `MacDetailView` introduces a centered content rail and neutral button styling, and `MacHomeView` avoids loading catalog rows that are immediately discarded.

**Tech Stack:** Swift, SwiftUI, XCTest, LunaCore, XcodeGen-generated LunaMac Xcode project.

---

## File Structure

- Modify `Packages/LunaCore/Sources/LunaCore/Stremio/MetaService.swift`: decode raw seasons through local raw structs so episode aliases resolve to `MetaVideo.thumbnail`.
- Modify `Packages/LunaCore/Tests/LunaCoreTests/LunaCoreTests.swift`: add a failing test for `seasons[].episodes[].still/img/image` aliases.
- Modify `Apps/LunaMac/Sources/Screens/MacDetailView.swift`: add centered max-width layout, neutral detail buttons, and aligned episode rows.
- Modify `Apps/LunaMac/Sources/Screens/MacHomeView.swift`: remove `loadAllCatalogs` before `loadFromCollections` because it is overwritten.
- Modify `.gitignore`: ignore `.superpowers/` visual companion artifacts.

Do not commit unless the user explicitly asks for a commit.

---

### Task 1: Episode Artwork Alias Normalization

**Files:**
- Modify: `Packages/LunaCore/Tests/LunaCoreTests/LunaCoreTests.swift`
- Modify: `Packages/LunaCore/Sources/LunaCore/Stremio/MetaService.swift`

- [ ] **Step 1: Write the failing test**

Add this test to `Packages/LunaCore/Tests/LunaCoreTests/LunaCoreTests.swift` inside `extension LunaCoreTests`:

```swift
func testMetaResponseDecodesSeasonEpisodeArtworkAliases() throws {
    let json = """
    {
      "meta": {
        "id": "tt3581920",
        "type": "series",
        "name": "The Last of Us",
        "seasons": [
          {
            "id": "1",
            "number": 1,
            "name": "Season 1",
            "episodes": [
              { "id": "tt3581920:1:1", "title": "When You're Lost in the Darkness", "season": 1, "episode": 1, "still": "/still-one.jpg" },
              { "id": "tt3581920:1:2", "title": "Infected", "season": 1, "episode": 2, "img": "https://cdn.example.com/img-two.jpg" },
              { "id": "tt3581920:1:3", "title": "Long, Long Time", "season": 1, "episode": 3, "image": "/image-three.jpg" }
            ]
          }
        ]
      }
    }
    """

    let detail = try MetaService.decodeMetaResponse(
        json: json,
        type: "series",
        id: "tt3581920",
        baseURL: "https://addon.example.com"
    )

    let thumbnails = detail.seasons?.first?.episodes?.map(\.thumbnail)
    XCTAssertEqual(thumbnails, [
        "https://addon.example.com/still-one.jpg",
        "https://cdn.example.com/img-two.jpg",
        "https://addon.example.com/image-three.jpg"
    ])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path "Packages/LunaCore" --filter LunaCoreTests/testMetaResponseDecodesSeasonEpisodeArtworkAliases`

Expected: FAIL because current `seasons` decoding bypasses `RawVideo` alias normalization and only decodes `Season` directly.

- [ ] **Step 3: Implement minimal metadata normalization**

In `MetaService.decodeMetaResponse`, replace `let seasons: [Season]?` in `RawMeta` with raw season decoding and map it through the same `MetaVideo` builder used for `videos`.

Use this shape:

```swift
struct RawSeason: Codable {
    let id: String?
    let number: Int
    let name: String?
    let episodes: [RawVideo]?
}
```

Add a local helper near the existing `videos` mapping:

```swift
func mapVideo(_ raw: RawVideo) -> MetaVideo {
    MetaVideo(
        id: raw.id ?? "",
        title: raw.title ?? raw.name ?? "",
        released: raw.released ?? raw.firstAired,
        thumbnail: resolve(raw.thumbnail ?? raw.still ?? raw.img ?? raw.image, base: baseURL),
        season: raw.season,
        episode: raw.episode ?? raw.number,
        overview: raw.overview ?? raw.description,
        runtime: raw.runtime,
        streams: (raw.streams ?? (raw.stream.map { [$0] } ?? [])).map { mapStream($0, addonName: nil, addonId: nil) },
        trailerStreams: raw.trailerStreams?.map { mapStream($0, addonName: nil, addonId: nil) }
    )
}
```

Then set:

```swift
let videos = meta?.videos?.map(mapVideo)
let seasons = meta?.seasons?.map { rawSeason in
    Season(
        id: rawSeason.id ?? String(rawSeason.number),
        number: rawSeason.number,
        name: rawSeason.name,
        episodes: rawSeason.episodes?.map(mapVideo)
    )
}
```

And in the `MetaDetail` initializer use:

```swift
seasons: seasons ?? Self.seasons(from: videos),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path "Packages/LunaCore" --filter LunaCoreTests/testMetaResponseDecodesSeasonEpisodeArtworkAliases`

Expected: PASS.

- [ ] **Step 5: Run LunaCore regression tests**

Run: `swift test --package-path "Packages/LunaCore"`

Expected: PASS.

---

### Task 2: Centered Native Detail Layout

**Files:**
- Modify: `Apps/LunaMac/Sources/Screens/MacDetailView.swift`

- [ ] **Step 1: Add local layout constants**

Inside `MacDetailView`, add:

```swift
private let contentMaxWidth: CGFloat = 1120
private let contentHorizontalPadding: CGFloat = 28
```

- [ ] **Step 2: Add centered rail helper**

Inside `MacDetailView`, add:

```swift
@ViewBuilder
private func contentRail<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    HStack {
        content()
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
        Spacer(minLength: 0)
    }
    .padding(.horizontal, contentHorizontalPadding)
}
```

- [ ] **Step 3: Align hero content and back button to the centered rail**

In `MacDetailView.body`, replace direct `.padding(.horizontal, 24)` calls for the back button and hero poster/title row with `contentRail { ... }` so both align to the same max-width rail.

Back button content should become:

```swift
contentRail {
    HStack {
        Button { onBack() } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        Spacer()
    }
}
.padding(.top, 16)
```

Hero metadata content should become:

```swift
contentRail {
    HStack(alignment: .bottom, spacing: 18) {
        posterView(for: detail.poster)
        VStack(alignment: .leading, spacing: 5) {
            Text(detail.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            if let info = detail.releaseInfo {
                Text(info)
                    .font(.subheadline)
                    .foregroundColor(LunaTheme.textSecondary)
            }
        }
    }
}
.padding(.bottom, 20)
```

- [ ] **Step 4: Extract detail poster view**

Inside `MacDetailView`, add:

```swift
@ViewBuilder
private func posterView(for poster: String?) -> some View {
    if let poster, let url = URL(string: poster) {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LunaTheme.surfaceElevated
            }
        }
        .frame(width: 118, height: 177)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}
```

- [ ] **Step 5: Neutralize action buttons and align sections**

Wrap the actions, overview, genres, cast, season tabs, and episodes in `contentRail` instead of full-width `.padding(.horizontal, 24)`.

Use neutral play button styling:

```swift
.background(Color.white)
.foregroundColor(.black)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
```

Use neutral secondary buttons:

```swift
.background(LunaTheme.surface)
.foregroundColor(libraryRepo.isInLibrary(mediaId: detail.id) ? .white : LunaTheme.textSecondary)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
```

Keep watched state green:

```swift
.foregroundColor(watchedRepo.isWatched(mediaId: detail.id) ? .green : LunaTheme.textSecondary)
```

- [ ] **Step 6: Verify with build**

Run: `xcodebuild -project "Apps/LunaMac/LunaMac.xcodeproj" -scheme LunaMac -configuration Debug build`

Expected: `** BUILD SUCCEEDED **`.

---

### Task 3: Remove Wasted Home Catalog Load

**Files:**
- Modify: `Apps/LunaMac/Sources/Screens/MacHomeView.swift`

- [ ] **Step 1: Remove overwritten load call**

In `MacHomeView.task`, remove the `catalogAddon` calculation and the call to:

```swift
await catalogRepo.loadAllCatalogs(addons: catalogAddons)
```

Keep:

```swift
let enabled = addonRepo.enabledAddons
await catalogRepo.loadFromCollections(collectionRepo: collectionRepo, addons: enabled)
startHeroTimer()
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project "Apps/LunaMac/LunaMac.xcodeproj" -scheme LunaMac -configuration Debug build`

Expected: `** BUILD SUCCEEDED **`.

---

### Task 4: Ignore Visual Companion Artifacts

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add ignore rule**

Add this under `# Misc` in `.gitignore`:

```gitignore
.superpowers/
```

- [ ] **Step 2: Check status**

Run: `git status --short`

Expected: `.superpowers/` files are not listed as untracked. Existing tracked app/spec/plan changes may still be listed.

---

### Task 5: Final Verification

**Files:**
- Verify all modified files.

- [ ] **Step 1: Run package tests**

Run: `swift test --package-path "Packages/LunaCore"`

Expected: PASS.

- [ ] **Step 2: Run app build**

Run: `xcodebuild -project "Apps/LunaMac/LunaMac.xcodeproj" -scheme LunaMac -configuration Debug build`

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Manual smoke test**

Open the built app:

```bash
open "/Users/zain/Library/Developer/Xcode/DerivedData/LunaMac-amaibvkyteopjmfvgmhfmhaiwovt/Build/Products/Debug/LunaMac.app"
```

Verify:

- Home loads rows without an initial duplicated catalog pass.
- Movie detail page uses centered content and neutral buttons.
- Series detail page season tabs and episodes align with the centered rail.
- Episode images appear when metadata provides `thumbnail`, `still`, `img`, or `image`.
- Back button works.
- Play opens the source picker and launches the player window.
