# Plan D: Library Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign LibraryScreen as a single scrollable page with three inline sections — Watchlist (🔖), Liked (❤️), and Upcoming (🗓). Upcoming auto-detects unreleased liked items using TMDB data, refreshed daily.

**Architecture:** `LibraryScreen.swift` becomes a single `ScrollView` with three `LibrarySection` views. A new `UpcomingItemsService` in LunaCore classifies liked items into released vs upcoming using TMDB `release_date` / `next_episode_to_air` / `status` fields. `LikedRepository` (created in Plan C) is the source of truth for liked items. `LibraryRepository` remains for watchlist items.

**Tech Stack:** SwiftUI, LunaCore, TMDB REST API, BackgroundTasks, UserDefaults

---

## File Map

| Action | Path |
|---|---|
| Create | `Packages/LunaCore/Sources/LunaCore/Services/UpcomingItemsService.swift` |
| Modify | `Apps/LunaApp/Sources/Screens/LibraryScreen.swift` |

---

### Task 1: Create UpcomingItemsService

**Files:**
- Create: `Packages/LunaCore/Sources/LunaCore/Services/UpcomingItemsService.swift`

- [ ] **Step 1: Create the file**

```swift
// Packages/LunaCore/Sources/LunaCore/Services/UpcomingItemsService.swift
import Foundation

public struct UpcomingInfo: Sendable {
    public let mediaId: String
    public let isUpcoming: Bool
    public let releaseDate: Date?     // nil = "No air date yet"
    public let seasonNumber: Int?     // for TV upcoming seasons
    public let badge: String          // display text, e.g. "Jun 15, 2026" or "Season 3 · 2026"
}

@MainActor
public final class UpcomingItemsService: ObservableObject {
    public static let shared = UpcomingItemsService()

    // mediaId → UpcomingInfo
    @Published public private(set) var upcomingInfo: [String: UpcomingInfo] = [:]

    private let base = "https://api.themoviedb.org/3"
    private var apiKey: String? {
        MetadataIntegrationStore.shared.effectiveTMDBAPIKey
    }

    private let lastRefreshKey = "luna.upcoming.lastRefresh"
    private var lastRefresh: Date? {
        get { UserDefaults.standard.object(forKey: lastRefreshKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastRefreshKey) }
    }

    private init() {}

    /// Refreshes upcoming status for all liked items. Skips if refreshed < 24h ago.
    public func refreshIfNeeded(likedItems: [LikedItem]) async {
        let now = Date()
        if let last = lastRefresh, now.timeIntervalSince(last) < 86_400 { return }
        await refresh(likedItems: likedItems)
    }

    /// Force refresh regardless of last refresh time.
    public func refresh(likedItems: [LikedItem]) async {
        guard let key = apiKey, !key.isEmpty else { return }

        var result: [String: UpcomingInfo] = [:]
        await withTaskGroup(of: (String, UpcomingInfo?).self) { group in
            for item in likedItems {
                guard let tmdbId = item.tmdbId else { continue }
                group.addTask {
                    let info = await self.fetchUpcomingInfo(
                        mediaId: item.mediaId,
                        tmdbId: tmdbId,
                        mediaType: item.mediaType,
                        apiKey: key
                    )
                    return (item.mediaId, info)
                }
            }
            for await (mediaId, info) in group {
                if let info { result[mediaId] = info }
            }
        }
        upcomingInfo = result
        lastRefresh = Date()
    }

    public func isUpcoming(_ mediaId: String) -> Bool {
        upcomingInfo[mediaId]?.isUpcoming ?? false
    }

    public func badge(for mediaId: String) -> String? {
        upcomingInfo[mediaId]?.badge
    }

    // MARK: - Private

    private func fetchUpcomingInfo(mediaId: String, tmdbId: Int, mediaType: String, apiKey: String) async -> UpcomingInfo? {
        let today = Calendar.current.startOfDay(for: Date())

        if mediaType == "movie" {
            return await fetchMovieUpcoming(mediaId: mediaId, tmdbId: tmdbId, apiKey: apiKey, today: today)
        } else {
            return await fetchSeriesUpcoming(mediaId: mediaId, tmdbId: tmdbId, apiKey: apiKey, today: today)
        }
    }

    private func fetchMovieUpcoming(mediaId: String, tmdbId: Int, apiKey: String, today: Date) async -> UpcomingInfo? {
        let urlString = "\(base)/movie/\(tmdbId)?api_key=\(apiKey)"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONDecoder().decode(TMDBMovieResponse.self, from: data) else { return nil }

        guard let releaseDateStr = json.releaseDate,
              let releaseDate = dateFrom(releaseDateStr) else {
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }

        let isUpcoming = releaseDate > today
        let badge = isUpcoming ? formatted(releaseDate) : ""
        return UpcomingInfo(mediaId: mediaId, isUpcoming: isUpcoming, releaseDate: releaseDate, seasonNumber: nil, badge: badge)
    }

    private func fetchSeriesUpcoming(mediaId: String, tmdbId: Int, apiKey: String, today: Date) async -> UpcomingInfo? {
        let urlString = "\(base)/tv/\(tmdbId)?api_key=\(apiKey)"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONDecoder().decode(TMDBSeriesResponse.self, from: data) else { return nil }

        // Ended series are never upcoming
        if json.status == "Ended" || json.status == "Canceled" {
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }

        guard let nextEp = json.nextEpisodeToAir else {
            // No next episode scheduled but not ended → could be in hiatus
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }

        let season = nextEp.seasonNumber
        let releaseDate = nextEp.airDate.flatMap { dateFrom($0) }

        var badge: String
        if let releaseDate {
            badge = "Season \(season) · \(formatted(releaseDate))"
        } else {
            badge = "Season \(season) · No air date yet"
        }

        // Only mark upcoming if the air date is in the future (or unknown — show as upcoming)
        let isUpcoming: Bool
        if let rd = releaseDate {
            isUpcoming = rd > today
        } else {
            isUpcoming = true // Unknown date but next episode exists
        }

        return UpcomingInfo(mediaId: mediaId, isUpcoming: isUpcoming, releaseDate: releaseDate, seasonNumber: season, badge: badge)
    }

    private func dateFrom(_ string: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: string)
    }

    private func formatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}

// MARK: - Response shapes

private struct TMDBMovieResponse: Decodable {
    let releaseDate: String?
    enum CodingKeys: String, CodingKey {
        case releaseDate = "release_date"
    }
}

private struct TMDBSeriesResponse: Decodable {
    let status: String?
    let nextEpisodeToAir: TMDBNextEpisode?
    enum CodingKeys: String, CodingKey {
        case status
        case nextEpisodeToAir = "next_episode_to_air"
    }
}

private struct TMDBNextEpisode: Decodable {
    let seasonNumber: Int
    let airDate: String?
    enum CodingKeys: String, CodingKey {
        case seasonNumber = "season_number"
        case airDate = "air_date"
    }
}
```

- [ ] **Step 2: Build LunaCore**

```bash
swift build --package-path /Users/zain/projects/Luna/Packages/LunaCore 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/LunaCore/Sources/LunaCore/Services/UpcomingItemsService.swift
git commit -m "feat(core): add UpcomingItemsService to classify liked items by TMDB release status"
```

---

### Task 2: Redesign LibraryScreen

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/LibraryScreen.swift`

- [ ] **Step 1: Read the current LibraryScreen structure**

```bash
grep -n "struct LibraryScreen\|LazyVGrid\|libraryItems\|BookmarkItem" \
  /Users/zain/projects/Luna/Apps/LunaApp/Sources/Screens/LibraryScreen.swift | head -20
```

Note the line range of the current `struct LibraryScreen` body to understand what to replace.

- [ ] **Step 2: Replace LibraryScreen body**

Replace the entire `struct LibraryScreen: View` body (keep imports + struct declaration) with:

```swift
struct LibraryScreen: View {
    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var likedRepo = LikedRepository.shared
    @StateObject private var upcomingService = UpcomingItemsService.shared
    @StateObject private var watchProgressRepo = WatchProgressRepository.shared

    // Per-section filters
    @State private var watchlistFilter: MediaFilter = .all
    @State private var likedFilter: MediaFilter = .all

    enum MediaFilter: String, CaseIterable {
        case all = "All"
        case movies = "Movies"
        case series = "Series"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── WATCHLIST ─────────────────────────────────
                    watchlistSection

                    // ── LIKED ─────────────────────────────────────
                    likedSection

                    // ── UPCOMING ──────────────────────────────────
                    if !upcomingItems.isEmpty {
                        upcomingSection
                    }

                    Spacer().frame(height: 40)
                }
            }
            .background(LunaTheme.background)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await libraryRepo.loadLibrary()
            await likedRepo.loadLibrary()
            await upcomingService.refreshIfNeeded(likedItems: likedRepo.likedItems)
        }
    }

    // MARK: - Computed

    private var filteredWatchlist: [LibraryItem] {
        switch watchlistFilter {
        case .all:     return libraryRepo.libraryItems
        case .movies:  return libraryRepo.libraryItems.filter { $0.mediaType == "movie" }
        case .series:  return libraryRepo.libraryItems.filter { $0.mediaType == "series" }
        }
    }

    private var availableLikedItems: [LikedItem] {
        let notUpcoming = likedRepo.likedItems.filter { !upcomingService.isUpcoming($0.mediaId) }
        switch likedFilter {
        case .all:     return notUpcoming
        case .movies:  return notUpcoming.filter { $0.mediaType == "movie" }
        case .series:  return notUpcoming.filter { $0.mediaType == "series" }
        }
    }

    private var upcomingItems: [LikedItem] {
        likedRepo.likedItems.filter { upcomingService.isUpcoming($0.mediaId) }
    }

    // MARK: - Watchlist Section

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(
                icon: "🔖",
                title: "Watchlist",
                count: libraryRepo.libraryItems.count
            )
            filterChips(selection: $watchlistFilter)

            if filteredWatchlist.isEmpty {
                emptyState(icon: "bookmark", message: "Nothing bookmarked yet.\nTap 🔖 on any title to add it.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 10)], spacing: 10) {
                    ForEach(filteredWatchlist, id: \.id) { item in
                        watchlistPosterCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func watchlistPosterCard(_ item: LibraryItem) -> some View {
        NavigationLink(destination: DetailScreen(mediaId: item.mediaId, mediaType: item.mediaType)) {
            ZStack(alignment: .bottomLeading) {
                CachedAsyncImage(url: URL(string: item.poster ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.05)
                }
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Progress bar
                if let progress = watchProgressRepo.progress(for: item.mediaId), progress > 0.02 {
                    VStack(spacing: 0) {
                        Spacer()
                        GeometryReader { geo in
                            Capsule()
                                .fill(LunaTheme.accent.opacity(0.9))
                                .frame(width: geo.size.width * CGFloat(progress), height: 3)
                        }
                        .frame(height: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Rating badges
                HStack(spacing: 3) {
                    if let rating = item.imdbRating {
                        ratingBadge(text: String(format: "%.1f", rating), color: Color(red: 0.96, green: 0.77, blue: 0.09))
                    }
                }
                .padding(5)
            }
            .frame(width: 100, height: 150)
        }
        .contextMenu {
            Button {
                Task { await libraryRepo.removeFromLibrary(mediaId: item.mediaId) }
            } label: {
                Label("Remove from Watchlist", systemImage: "bookmark.slash")
            }
        }
    }

    // MARK: - Liked Section

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(
                icon: "❤️",
                title: "Liked",
                count: availableLikedItems.count
            )
            filterChips(selection: $likedFilter)

            if availableLikedItems.isEmpty {
                emptyState(icon: "heart", message: "Nothing liked yet.\nTap ❤️ on any title to add it.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 10)], spacing: 10) {
                    ForEach(availableLikedItems, id: \.id) { item in
                        likedPosterCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func likedPosterCard(_ item: LikedItem) -> some View {
        NavigationLink(destination: DetailScreen(mediaId: item.mediaId, mediaType: item.mediaType)) {
            CachedAsyncImage(url: URL(string: item.poster ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.05)
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .contextMenu {
            Button(role: .destructive) {
                Task { await likedRepo.removeLiked(mediaId: item.mediaId) }
            } label: {
                Label("Remove from Liked", systemImage: "heart.slash")
            }
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(icon: "🗓", title: "Upcoming", count: upcomingItems.count)

            VStack(spacing: 0) {
                ForEach(upcomingItems, id: \.id) { item in
                    NavigationLink(destination: DetailScreen(mediaId: item.mediaId, mediaType: item.mediaType)) {
                        upcomingRow(item)
                    }
                    if item.id != upcomingItems.last?.id {
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 72)
                    }
                }
            }
            .glassCard(cornerRadius: 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private func upcomingRow(_ item: LikedItem) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: item.poster ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.05)
            }
            .frame(width: 44, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(item.mediaType == "movie" ? "Movie" : "Series")
                    .font(.caption)
                    .foregroundColor(LunaTheme.textTertiary)
            }

            Spacer()

            if let badge = upcomingService.badge(for: item.mediaId) {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LunaTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LunaTheme.accent.opacity(0.12))
                    .cornerRadius(6)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(LunaTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Shared helpers

    private func librarySectionHeader(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(LunaTheme.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func filterChips(selection: Binding<MediaFilter>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MediaFilter.allCases, id: \.self) { filter in
                    Button {
                        selection.wrappedValue = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selection.wrappedValue == filter ? .white : LunaTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(selection.wrappedValue == filter ? LunaTheme.accent : Color.white.opacity(0.08))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(Color.white.opacity(0.2))
            Text(message)
                .font(.subheadline)
                .foregroundColor(LunaTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }

    private func ratingBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color.opacity(0.9))
            .foregroundColor(.black)
            .cornerRadius(4)
    }
}
```

> **Note on DetailScreen navigation:** Replace `DetailScreen(mediaId: item.mediaId, mediaType: item.mediaType)` with the actual `DetailScreen` initializer in this codebase. Check by running:
> ```bash
> grep -n "struct DetailScreen\|init(" Apps/LunaApp/Sources/Screens/DetailScreen.swift | head -10
> ```

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -30
```

If `LibraryItem` doesn't have an `imdbRating` property, either remove that `ratingBadge` call or check the actual property name:

```bash
grep -n "imdbRating\|rating\|score\|struct LibraryItem" \
  /Users/zain/projects/Luna/Packages/LunaCore/Sources/LunaCore/Services/LibraryRepository.swift | head -10
```

Expected: `Build succeeded`

- [ ] **Step 4: Verify `WatchProgressRepository.progress(for:)` exists**

```bash
grep -n "func progress\|func watchProgress" \
  /Users/zain/projects/Luna/Packages/LunaCore/Sources/LunaCore/Services/WatchProgressRepository.swift | head -10
```

If the method signature differs (e.g., takes a `mediaId` + `type`), adjust the call in `watchlistPosterCard`:

```swift
// Adjust to match the actual signature — e.g.:
if let progress = watchProgressRepo.progress(for: item.mediaId, type: item.mediaType), progress > 0.02 {
```

- [ ] **Step 5: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/LibraryScreen.swift
git commit -m "feat: redesign LibraryScreen as single-page with Watchlist, Liked, Upcoming inline sections"
```
