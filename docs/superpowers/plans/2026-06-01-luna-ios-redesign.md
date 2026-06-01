# Luna iOS Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the iOS/macOS SwiftUI home screen (cinematic hero rotation, real CW artwork, folder grids) and detail page (horizontal episode cards, network/production section).

**Architecture:** Four targeted file changes in LunaCore + LunaApp. `HomeRepository` fixes the CW data fetch. `HomeScreen` gains a hero section + folder grid layout. `DetailScreen` gets horizontal episode cards. No new files needed.

**Tech Stack:** SwiftUI, LunaCore, Combine/async-await, Timer

---

## File Map

| File | Change |
|------|---------|
| `Packages/LunaCore/Sources/LunaCore/Services/HomeRepository.swift` | Fetch real `name` + `poster` for CW items via MetaRepository |
| `Apps/LunaApp/Sources/Screens/HomeScreen.swift` | Add `HeroSection`, hero rotation timer, folder grid, fix CW card artwork |
| `Apps/LunaApp/Sources/Screens/DetailScreen.swift` | Horizontal episode cards, network/production section |

---

## Task 1: HomeRepository — Fetch Real CW Name + Poster

**Files:**
- Modify: `Packages/LunaCore/Sources/LunaCore/Services/HomeRepository.swift`

Currently `loadContinueWatching` sets `name: entry.mediaId` and leaves `poster` as `nil`. Fix: call `MetaRepository.shared.fetchMeta` for each CW entry to get the real name and poster.

- [ ] **Step 1: Update `loadContinueWatching` to call MetaRepository**

Replace the entire `loadContinueWatching` function:

```swift
public func loadContinueWatching(profileId: String) async {
    isLoadingContinueWatching = true
    defer { isLoadingContinueWatching = false }

    do {
        let progress = try await syncService.pullWatchProgress(profileId: profileId)
        let incomplete = progress
            .filter { !$0.completed && $0.positionSeconds > 0 }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(10)

        // Fetch meta for each entry in parallel to get real name + poster
        let metaRepo = MetaRepository.shared
        var items: [ContinueWatchingItem] = []

        await withTaskGroup(of: ContinueWatchingItem.self) { group in
            for entry in incomplete {
                group.addTask {
                    let meta = try? await metaRepo.fetchMeta(
                        type: entry.mediaType,
                        id: entry.mediaId
                    )
                    return ContinueWatchingItem(
                        mediaId: entry.mediaId,
                        mediaType: entry.mediaType,
                        name: meta?.name ?? entry.mediaId,
                        poster: meta?.poster,
                        resumePositionMs: entry.positionSeconds * 1000,
                        durationMs: entry.durationSeconds * 1000,
                        progressFraction: entry.progressFraction
                    )
                }
            }
            for await item in group {
                items.append(item)
            }
        }

        // Re-sort by updatedAt since task group doesn't preserve order
        let sortedIds = incomplete.map(\.mediaId)
        continueWatchingItems = items.sorted {
            let ia = sortedIds.firstIndex(of: $0.mediaId) ?? Int.max
            let ib = sortedIds.firstIndex(of: $1.mediaId) ?? Int.max
            return ia < ib
        }
    } catch {
        continueWatchingItems = []
    }
}
```

- [ ] **Step 2: Check that `MetaRepository.fetchMeta(type:id:)` exists**

```bash
grep -n "func fetchMeta" Packages/LunaCore/Sources/LunaCore/Services/MetaRepository.swift
```

If the method signature differs (e.g. it uses addon parameter), adjust the call to match. The key is to get `MetaDetail?` back containing `.name` and `.poster`.

- [ ] **Step 3: Build to verify no compile errors**

```bash
xcodebuild -scheme LunaApp -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Packages/LunaCore/Sources/LunaCore/Services/HomeRepository.swift
git commit -m "fix(ios): fetch real name and poster for Continue Watching items"
```

---

## Task 2: HomeScreen — Hero Section + Hero Rotation

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/HomeScreen.swift`

Add a `HeroSection` view at the top of the home screen that auto-rotates through the top 5 items (by popularity) across the 4 main rows.

- [ ] **Step 1: Add constants and hero item selection logic inside `HomeScreen`**

Add this computed property and constant inside the `HomeScreen` struct (before `body`):

```swift
private let mainRowNames: Set<String> = [
    "Popular Movies", "Popular TV Shows",
    "Trending Movies", "Trending TV Shows"
]

/// Top 5 items by popularity across the 4 main rows, deduplicated by id.
private var featuredItems: [MetaPreview] {
    let mainRows = catalogRepo.catalogRows.filter { mainRowNames.contains($0.title) }
    var seen = Set<String>()
    var candidates: [MetaPreview] = []
    for row in mainRows {
        for item in row.items where !seen.contains(item.id) {
            seen.insert(item.id)
            candidates.append(item)
        }
    }
    return candidates
        .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
        .prefix(5)
        .map { $0 }
}
```

- [ ] **Step 2: Add hero rotation state to `HomeScreen`**

Add these `@State` properties inside `HomeScreen`:

```swift
@State private var heroIndex = 0
@State private var heroTimer: Timer? = nil
```

- [ ] **Step 3: Add `HeroSection` view (add as a new struct below `HomeScreen`)**

```swift
struct HeroSection: View {
    let item: MetaPreview
    let onTap: () -> Void
    let dotCount: Int
    let activeIndex: Int
    let onDotTap: (Int) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            if let banner = item.banner ?? item.poster, let url = URL(string: banner) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.black
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
            } else {
                Rectangle()
                    .fill(LunaTheme.surface)
                    .frame(height: 420)
            }

            // Gradient overlays
            LinearGradient(
                colors: [.clear, LunaTheme.background.opacity(0.6), LunaTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)

            LinearGradient(
                colors: [LunaTheme.background.opacity(0.7), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 420)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Source label
                Text(item.type == .movie ? "Popular Movies" : "Popular TV Shows")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(LunaTheme.accent)
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.bottom, 8)

                // Title
                Text(item.name)
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.bottom, 6)

                // Meta row
                HStack(spacing: 8) {
                    if let rating = item.imdbRating {
                        Label(rating, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    if let release = item.releaseInfo {
                        Text(release)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    if let genres = item.genres?.prefix(2) {
                        Text(genres.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 16)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: onTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Watch Now")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }

                    Button(action: onTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("My List")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rotation dots (bottom trailing)
            if dotCount > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<dotCount, id: \.self) { i in
                        Button {
                            onDotTap(i)
                        } label: {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i == activeIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: i == activeIndex ? 20 : 6, height: 3)
                        }
                        .animation(.easeInOut(duration: 0.25), value: activeIndex)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 420)
        .clipped()
    }
}
```

- [ ] **Step 4: Insert `HeroSection` into `HomeScreen.body` and wire the timer**

Replace the `body` property of `HomeScreen`:

```swift
var body: some View {
    NavigationStack {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                let featured = featuredItems
                if !featured.isEmpty {
                    HeroSection(
                        item: featured[heroIndex % featured.count],
                        onTap: {
                            selectedMedia = featured[heroIndex % featured.count]
                            showDetail = true
                        },
                        dotCount: featured.count,
                        activeIndex: heroIndex % featured.count,
                        onDotTap: { i in heroIndex = i }
                    )
                }

                // Continue Watching
                if !homeRepo.continueWatchingItems.isEmpty {
                    ContinueWatchingRow(items: homeRepo.continueWatchingItems) { item in
                        selectedMedia = MetaPreview(
                            id: item.mediaId,
                            type: item.mediaType == "movie" ? .movie : .series,
                            name: item.name,
                            poster: item.poster
                        )
                        showDetail = true
                    }
                }

                // Catalog rows — split main vs folder
                if !catalogRepo.catalogRows.isEmpty {
                    let mainRows = catalogRepo.catalogRows.filter { mainRowNames.contains($0.title) }
                    let folderRows = catalogRepo.catalogRows.filter { !mainRowNames.contains($0.title) }

                    LazyVStack(spacing: 24) {
                        // 4 main rows as horizontal scroll
                        ForEach(mainRows) { row in
                            CatalogRowView(row: row) { item in
                                selectedMedia = item
                                showDetail = true
                            }
                        }

                        // All other rows as folder grid
                        if !folderRows.isEmpty {
                            FolderGridSection(rows: folderRows) { item in
                                selectedMedia = item
                                showDetail = true
                            }
                        }
                    }
                } else if catalogRepo.isLoading {
                    VStack {
                        Spacer().frame(height: 80)
                        ProgressView().tint(LunaTheme.accent)
                        Spacer()
                    }
                }
            }
        }
        .background(LunaTheme.background)
        .navigationTitle("Luna")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let profile = profileManager.currentProfile {
                    Button {
                        profileManager.currentProfile = nil
                    } label: {
                        Circle()
                            .fill(profile.avatarColor.map { Color(hex: $0) } ?? LunaTheme.accent)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(profile.name.prefix(1)))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            if let media = selectedMedia {
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
        }
        .task {
            guard let profile = profileManager.currentProfile else { return }
            await addonRepo.loadAddons(profileId: profile.id)
            await collectionRepo.load()
            if collectionRepo.collections.isEmpty {
                await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
            } else {
                await catalogRepo.loadFromCollections(
                    collectionRepo: collectionRepo,
                    addons: addonRepo.enabledAddons
                )
            }
            await homeRepo.loadContinueWatching(profileId: profile.id)
            startHeroTimer()
        }
        .onDisappear {
            heroTimer?.invalidate()
            heroTimer = nil
        }
    }
}

private func startHeroTimer() {
    heroTimer?.invalidate()
    guard featuredItems.count > 1 else { return }
    heroTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
        withAnimation(.easeInOut(duration: 0.4)) {
            heroIndex = (heroIndex + 1) % featuredItems.count
        }
    }
}
```

- [ ] **Step 5: Add `FolderGridSection` struct (below `HeroSection`)**

```swift
struct FolderGridSection: View {
    let rows: [CatalogRow]
    let onTap: (MetaPreview) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(rows) { row in
                    FolderCell(row: row, onTap: onTap)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FolderCell: View {
    let row: CatalogRow
    let onTap: (MetaPreview) -> Void

    var body: some View {
        let coverURL: URL? = {
            if let ci = row.coverImage { return URL(string: ci) }
            if let p = row.items.first?.poster { return URL(string: p) }
            return nil
        }()

        Button {
            if let first = row.items.first { onTap(first) }
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LunaTheme.surfaceElevated)
                    .aspectRatio(2/3, contentMode: .fit)

                if let url = coverURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .aspectRatio(2/3, contentMode: .fit)
                }

                // Name label
                LinearGradient(
                    colors: [.black.opacity(0.75), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .aspectRatio(2/3, contentMode: .fit)

                Text(row.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 6: Fix `ContinueWatchingRow` to accept an `onTap` callback and show artwork**

Replace `ContinueWatchingRow` and `ContinueWatchingCard` in `HomeScreen.swift`:

```swift
struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]
    let onTap: (ContinueWatchingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continue Watching")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item)
                            .onTapGesture { onTap(item) }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
}

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                // Poster or backdrop
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LunaTheme.surfaceElevated)
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LunaTheme.surfaceElevated)
                    }
                }
                .frame(width: 192, height: 108)
                .clipped()
                .cornerRadius(8)

                // Play overlay
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    )
                    .padding(.bottom, 16)

                // Progress bar
                VStack(spacing: 0) {
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Rectangle()
                                .fill(LunaTheme.accent)
                                .frame(width: geo.size.width * item.progressFraction, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .cornerRadius(8)
            }
            .frame(width: 192, height: 108)

            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 192, alignment: .leading)

            Text("\(Int(item.progressFraction * 100))% watched")
                .font(.caption2)
                .foregroundColor(LunaTheme.textSecondary)
        }
    }
}
```

- [ ] **Step 7: Build**

```bash
xcodebuild -scheme LunaApp -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | grep -E "error:|Build succeeded"
```

Fix any compile errors (most likely: missing `Color(hex:)` extension or `MetaPreview` init — these already exist in the codebase).

- [ ] **Step 8: Run in simulator and verify**

- Hero shows at top with backdrop image and auto-rotates every 6s
- Rotation dots appear at bottom-right of hero
- Continue Watching shows artwork thumbnails (not blank rectangles)
- 4 main rows appear as horizontal scroll rows below CW
- Non-main rows appear as a 4-col `FolderGridSection`

- [ ] **Step 9: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/HomeScreen.swift
git commit -m "feat(ios): cinematic hero with rotation, CW artwork, folder grid on home screen"
```

---

## Task 3: DetailScreen — Horizontal Episode Cards + Network Section

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/DetailScreen.swift`

The detail screen already has a backdrop hero, genre chips, and a cast section. Two targeted changes:
1. Replace the vertical episode list with **horizontal scroll cards** (thumbnail + episode number + title + 2-line description)
2. Add **network / production** section from `detail.links`

- [ ] **Step 1: Find and replace the episode list section**

Locate the section in `DetailScreen.swift` that renders season episodes (it's inside the `if detail.type == .series` block and shows episodes from `detail.videos` or `detail.seasons`).

Replace that block with:

```swift
// Horizontal episode cards
if detail.type == .series {
    if let seasons = detail.seasons, !seasons.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episodes")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Season selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(seasons) { season in
                        Button {
                            selectedSeasonId = season.id
                        } label: {
                            Text("Season \(season.number)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedSeasonId == season.id
                                        ? Color.white
                                        : LunaTheme.surface
                                )
                                .foregroundColor(
                                    selectedSeasonId == season.id ? .black : LunaTheme.textSecondary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let activeSeason = seasons.first(where: { $0.id == (selectedSeasonId ?? seasons.first?.id) }),
               let episodes = activeSeason.episodes {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(episodes) { ep in
                            EpisodeCard(episode: ep) {
                                showStreamSelection = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    } else if let videos = detail.videos, !videos.isEmpty {
        // Series with flat video list (no seasons)
        VStack(alignment: .leading, spacing: 8) {
            Text("Episodes")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(videos) { ep in
                        EpisodeCard(episode: ep) {
                            showStreamSelection = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
```

You also need to add `@State private var selectedSeasonId: String? = nil` to `DetailScreen`.

- [ ] **Step 2: Add `EpisodeCard` struct (after `DetailScreen` in the same file)**

```swift
struct EpisodeCard: View {
    let episode: MetaVideo
    let onPlay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LunaTheme.surfaceElevated)
                    .frame(width: 208, height: 117)

                if let thumb = episode.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 208, height: 117)
                    .clipped()
                    .cornerRadius(10)
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title2)
                        .foregroundColor(LunaTheme.textTertiary)
                }

                // Play overlay
                Color.black.opacity(0.35)
                    .cornerRadius(10)
                Button(action: onPlay) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .offset(x: 1.5)
                        )
                }
            }
            .frame(width: 208, height: 117)

            // Labels
            if let epNum = episode.episode {
                Text("Episode \(epNum)")
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textTertiary)
            }

            Text(episode.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 208, alignment: .leading)

            if let overview = episode.overview {
                Text(overview)
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textSecondary)
                    .lineLimit(2)
                    .frame(width: 208, alignment: .leading)
            }
        }
    }
}
```

- [ ] **Step 3: Add network / production section from `detail.links`**

After the cast section in `DetailScreen`, add:

```swift
// Network + Production
if let links = detail.links, !links.isEmpty {
    let networks = links.filter { $0.category?.lowercased() == "network" }
    let studios = links.filter { $0.category?.lowercased() == "production" }

    if !networks.isEmpty || !studios.isEmpty {
        VStack(alignment: .leading, spacing: 16) {
            if !networks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NETWORK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(LunaTheme.textTertiary)
                        .tracking(1.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(networks, id: \.url) { link in
                                Text(link.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(LunaTheme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(LunaTheme.surface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }

            if !studios.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRODUCTION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(LunaTheme.textTertiary)
                        .tracking(1.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(studios, id: \.url) { link in
                                Text(link.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(LunaTheme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(LunaTheme.surface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Build**

```bash
xcodebuild -scheme LunaApp -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | grep -E "error:|Build succeeded"
```

Fix any compile errors. Common issues:
- `MetaLink` might not have `category` on the iOS model — check `MetaModels.swift`. If `MetaLink.category` is missing, add it: `public let category: String?`
- `selectedSeasonId` must be declared before it is used in `body`

- [ ] **Step 5: Run in simulator on a series detail page and verify**

- Episode cards are horizontal scroll (not vertical list)
- Thumbnails show (or grey placeholder if none)
- Network/production chips appear if the addon provides `links`
- Season tabs work

- [ ] **Step 6: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/DetailScreen.swift Packages/LunaCore/Sources/LunaCore/Models/MetaModels.swift
git commit -m "feat(ios): horizontal episode cards, network/production section on detail page"
```

---

## Self-Review Checklist

- [x] CW fetches real name + poster — Task 1, `HomeRepository` uses `MetaRepository` ✓
- [x] CW card shows artwork — Task 2, `ContinueWatchingCard` uses `AsyncImage` ✓
- [x] CW tap navigates to detail — Task 2, `onTap` callback → `showDetail = true` ✓
- [x] Hero shows at top of home — Task 2, `HeroSection` inserted before CW ✓
- [x] Hero uses backdrop/banner image — Task 2, `item.banner ?? item.poster` ✓
- [x] Hero rotates every 6s — Task 2, `Timer.scheduledTimer(withTimeInterval: 6)` ✓
- [x] Hero timer invalidated on disappear — Task 2, `.onDisappear` ✓
- [x] 4 main rows as horizontal scroll — Task 2, `CatalogRowView` for `mainRows` ✓
- [x] Non-main rows as folder grid — Task 2, `FolderGridSection` for `folderRows` ✓
- [x] No collapse/expand buttons — never existed, not added ✓
- [x] Horizontal episode cards — Task 3, `EpisodeCard` in horizontal `ScrollView` ✓
- [x] Season selector tabs — Task 3, `selectedSeasonId` state + button row ✓
- [x] Network/production section — Task 3, filters `detail.links` by category ✓
