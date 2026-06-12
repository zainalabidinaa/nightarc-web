# Plan C: Detail Screen Enhancements

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add description bottom sheet, larger portrait cast cards, heart/like button, and a full Actor Bio page with TMDB data (single photo + bio, info table, Known For backdrops, year-grouped Credits).

**Architecture:** `DetailScreen.swift` gets three additions: `DescriptionSheet`, portrait `CastCard`, and a `NavigationLink` to `ActorBioScreen`. `ActorBioScreen.swift` is a new file with its own `ActorBioViewModel` that calls `TMDBPersonService` (a new LunaCore service). Liked status is managed by a new `LikedRepository` (used by both Plan C and Plan D).

**Tech Stack:** SwiftUI, TMDB Person API, LunaCore, URLSession

---

## File Map

| Action | Path |
|---|---|
| Create | `Packages/LunaCore/Sources/LunaCore/Services/TMDBPersonService.swift` |
| Create | `Packages/LunaCore/Sources/LunaCore/Services/LikedRepository.swift` |
| Create | `Packages/LunaCore/Sources/LunaCore/Models/PersonModels.swift` |
| Modify | `Apps/LunaApp/Sources/Screens/DetailScreen.swift` |
| Create | `Apps/LunaApp/Sources/Screens/ActorBioScreen.swift` |

---

### Task 1: Create PersonModels

**Files:**
- Create: `Packages/LunaCore/Sources/LunaCore/Models/PersonModels.swift`

- [ ] **Step 1: Create the file**

```swift
// Packages/LunaCore/Sources/LunaCore/Models/PersonModels.swift
import Foundation

public struct PersonDetails: Sendable {
    public let id: Int
    public let name: String
    public let biography: String
    public let birthday: String?          // "1980-05-12"
    public let placeOfBirth: String?
    public let alsoKnownAs: [String]
    public let profilePath: String?       // TMDB relative path
    public let imdbId: String?
    public let credits: PersonCredits
}

public struct PersonCredits: Sendable {
    public let cast: [PersonCredit]
    public let crew: [PersonCredit]

    public var allCombined: [PersonCredit] {
        (cast + crew).sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
    }

    public var knownFor: [PersonCredit] {
        cast.sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }.prefix(5).map { $0 }
    }
}

public struct PersonCredit: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let mediaType: String           // "movie" or "tv"
    public let character: String?
    public let job: String?
    public let releaseDate: String?        // "2019-04-22"
    public let posterPath: String?
    public var backdropPath: String?       // fetched separately for knownFor
    public let voteAverage: Double?
    public let voteCount: Int?
    public let episodeCount: Int?
    public let popularity: Double?

    public var year: String? {
        releaseDate.flatMap { $0.components(separatedBy: "-").first }
    }

    public var creditType: String {
        if let job, !job.isEmpty { return job }
        return character != nil ? "Acting" : "Unknown"
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
git add Packages/LunaCore/Sources/LunaCore/Models/PersonModels.swift
git commit -m "feat(core): add PersonDetails and PersonCredit models for actor bio"
```

---

### Task 2: Create TMDBPersonService

**Files:**
- Create: `Packages/LunaCore/Sources/LunaCore/Services/TMDBPersonService.swift`

- [ ] **Step 1: Create the file**

Read the existing TMDB integration to get the API key access pattern first:

```bash
grep -rn "tmdbApiKey\|TMDBService\|MetadataIntegration" \
  /Users/zain/projects/Luna/Packages/LunaCore/Sources/LunaCore/ | head -20
```

Then create the service — replace `MetadataIntegrationStore.shared.tmdbApiKey` with whatever the actual property name is from the grep above:

```swift
// Packages/LunaCore/Sources/LunaCore/Services/TMDBPersonService.swift
import Foundation

@MainActor
public final class TMDBPersonService {
    public static let shared = TMDBPersonService()

    private let base = "https://api.themoviedb.org/3"
    private var apiKey: String? {
        MetadataIntegrationStore.shared.effectiveTMDBAPIKey
    }

    // Memory cache: person ID → PersonDetails
    private var cache: [Int: PersonDetails] = [:]
    // Person name → TMDB person ID (for lookup by name)
    private var nameToId: [String: Int] = [:]

    private init() {}

    public func personDetails(id: Int) async throws -> PersonDetails {
        if let cached = cache[id] { return cached }

        guard let key = apiKey, !key.isEmpty else {
            throw TMDBError.noAPIKey
        }

        let urlString = "\(base)/person/\(id)?api_key=\(key)&append_to_response=combined_credits"
        guard let url = URL(string: urlString) else { throw TMDBError.badURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let raw = try JSONDecoder().decode(TMDBPersonResponse.self, from: data)
        let person = mapToPerson(raw)
        cache[id] = person
        return person
    }

    public func personId(forName name: String) async throws -> Int? {
        if let cached = nameToId[name] { return cached }

        guard let key = apiKey, !key.isEmpty else { return nil }

        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "\(base)/search/person?api_key=\(key)&query=\(encoded)"
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(TMDBPersonSearchResponse.self, from: data)
        let id = result.results.first?.id
        if let id { nameToId[name] = id }
        return id
    }

    /// Fetches backdrop for a single credit (movie or TV). Falls back to poster.
    public func backdrop(for credit: PersonCredit) async -> String? {
        guard let key = apiKey, !key.isEmpty else { return credit.posterPath }

        let path = credit.mediaType == "movie"
            ? "\(base)/movie/\(credit.id)?api_key=\(key)"
            : "\(base)/tv/\(credit.id)?api_key=\(key)"
        guard let url = URL(string: path) else { return credit.posterPath }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONDecoder().decode(TMDBMediaBackdropResponse.self, from: data)
            return json.backdropPath ?? credit.posterPath
        } catch {
            return credit.posterPath
        }
    }

    public func imageURL(path: String?, size: String = "w185") -> URL? {
        guard let path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }

    public func clearCache() {
        cache.removeAll()
        nameToId.removeAll()
    }

    // MARK: - Mapping

    private func mapToPerson(_ raw: TMDBPersonResponse) -> PersonDetails {
        let castCredits = (raw.combinedCredits?.cast ?? []).map { mapCredit($0, mediaType: $0.mediaType ?? "movie") }
        let crewCredits = (raw.combinedCredits?.crew ?? []).map { mapCredit($0, mediaType: $0.mediaType ?? "movie") }
        return PersonDetails(
            id: raw.id,
            name: raw.name,
            biography: raw.biography ?? "",
            birthday: raw.birthday,
            placeOfBirth: raw.placeOfBirth,
            alsoKnownAs: raw.alsoKnownAs ?? [],
            profilePath: raw.profilePath,
            imdbId: raw.imdbId,
            credits: PersonCredits(cast: castCredits, crew: crewCredits)
        )
    }

    private func mapCredit(_ raw: TMDBCreditResponse, mediaType: String) -> PersonCredit {
        PersonCredit(
            id: raw.id,
            title: raw.title ?? raw.name ?? "Unknown",
            mediaType: mediaType,
            character: raw.character,
            job: raw.job,
            releaseDate: raw.releaseDate ?? raw.firstAirDate,
            posterPath: raw.posterPath,
            backdropPath: nil,
            voteAverage: raw.voteAverage,
            voteCount: raw.voteCount,
            episodeCount: raw.episodeCount,
            popularity: raw.popularity
        )
    }
}

public enum TMDBError: Error {
    case noAPIKey
    case badURL
    case notFound
}

// MARK: - Codable response shapes

private struct TMDBPersonResponse: Decodable {
    let id: Int
    let name: String
    let biography: String?
    let birthday: String?
    let placeOfBirth: String?
    let alsoKnownAs: [String]?
    let profilePath: String?
    let imdbId: String?
    let combinedCredits: TMDBCombinedCredits?

    enum CodingKeys: String, CodingKey {
        case id, name, biography, birthday
        case placeOfBirth = "place_of_birth"
        case alsoKnownAs = "also_known_as"
        case profilePath = "profile_path"
        case imdbId = "imdb_id"
        case combinedCredits = "combined_credits"
    }
}

private struct TMDBCombinedCredits: Decodable {
    let cast: [TMDBCreditResponse]?
    let crew: [TMDBCreditResponse]?
}

private struct TMDBCreditResponse: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let character: String?
    let job: String?
    let mediaType: String?
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
    let voteAverage: Double?
    let voteCount: Int?
    let episodeCount: Int?
    let popularity: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, name, character, job, popularity
        case mediaType = "media_type"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case episodeCount = "episode_count"
    }
}

private struct TMDBPersonSearchResponse: Decodable {
    let results: [TMDBPersonSearchResult]
}

private struct TMDBPersonSearchResult: Decodable {
    let id: Int
}

private struct TMDBMediaBackdropResponse: Decodable {
    let backdropPath: String?
    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
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
git add Packages/LunaCore/Sources/LunaCore/Services/TMDBPersonService.swift
git commit -m "feat(core): add TMDBPersonService for actor bio fetching with combined_credits"
```

---

### Task 3: Create LikedRepository

**Files:**
- Create: `Packages/LunaCore/Sources/LunaCore/Services/LikedRepository.swift`

Read LibraryRepository first for the exact pattern:

```bash
grep -n "struct LibraryItem\|class LibraryRepository\|func addToLibrary\|func loadLibrary" \
  /Users/zain/projects/Luna/Packages/LunaCore/Sources/LunaCore/Services/LibraryRepository.swift | head -20
```

- [ ] **Step 1: Create LikedRepository mirroring LibraryRepository**

```swift
// Packages/LunaCore/Sources/LunaCore/Services/LikedRepository.swift
import Foundation

public struct LikedItem: Codable, Identifiable, Sendable {
    public let id: String          // mediaId
    public let mediaId: String
    public let mediaType: String   // "movie" or "series"
    public let name: String
    public let poster: String?
    public let tmdbId: Int?
    public let likedAt: Date

    public init(mediaId: String, mediaType: String, name: String, poster: String?, tmdbId: Int?) {
        self.id = mediaId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.tmdbId = tmdbId
        self.likedAt = Date()
    }
}

@MainActor
public final class LikedRepository: ObservableObject {
    public static let shared = LikedRepository()

    @Published public private(set) var likedItems: [LikedItem] = []

    private let syncService = SyncService.shared
    private let storageKey = "luna.liked.items"

    private init() {
        loadFromLocal()
    }

    public func isLiked(_ mediaId: String) -> Bool {
        likedItems.contains { $0.mediaId == mediaId }
    }

    public func addLiked(_ item: LikedItem) async {
        guard !isLiked(item.mediaId) else { return }
        likedItems.insert(item, at: 0)
        saveToLocal()
        try? await syncService.syncLiked(likedItems)
    }

    public func removeLiked(mediaId: String) async {
        likedItems.removeAll { $0.mediaId == mediaId }
        saveToLocal()
        try? await syncService.syncLiked(likedItems)
    }

    public func loadLibrary() async {
        do {
            let remote = try await syncService.fetchLiked()
            if !remote.isEmpty { likedItems = remote }
        } catch {
            // Fall back to local
        }
        saveToLocal()
    }

    // MARK: - Local persistence

    private func loadFromLocal() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([LikedItem].self, from: data) else { return }
        likedItems = items
    }

    private func saveToLocal() {
        let data = try? JSONEncoder().encode(likedItems)
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
```

> **Note:** If `SyncService` doesn't yet have `syncLiked` / `fetchLiked` methods, add stubbed versions that store to UserDefaults and return empty arrays — the actual server integration is a backend concern.

- [ ] **Step 2: Build LunaCore**

```bash
swift build --package-path /Users/zain/projects/Luna/Packages/LunaCore 2>&1 | tail -10
```

If `SyncService` is missing methods, add stubs:

```swift
// In SyncService.swift (wherever other sync methods live) - ADD only these:
public func syncLiked(_ items: [LikedItem]) async throws { /* stub */ }
public func fetchLiked() async throws -> [LikedItem] { return [] }
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Packages/LunaCore/Sources/LunaCore/Services/LikedRepository.swift
git commit -m "feat(core): add LikedRepository for liked/heart items with local+sync persistence"
```

---

### Task 4: Modify DetailScreen — description sheet + portrait cast cards + heart button

**Files:**
- Modify: `Apps/LunaApp/Sources/Screens/DetailScreen.swift`

- [ ] **Step 1: Read the current description and cast sections**

```bash
grep -n "synopsis\|description\|cast\|CastCard\|person\." \
  /Users/zain/projects/Luna/Apps/LunaApp/Sources/Screens/DetailScreen.swift | head -40
```

Note the line numbers for: synopsis text, cast ForEach, and the action buttons row (bookmark).

- [ ] **Step 2: Add @State for description sheet and liked state**

In `DetailScreen`'s properties block:

```swift
@State private var showDescriptionSheet = false
@State private var isLiked = false
@StateObject private var likedRepo = LikedRepository.shared
```

- [ ] **Step 3: Replace synopsis block with truncated + Read more**

Find the `Text(media.synopsis)` or equivalent. Replace it with:

```swift
VStack(alignment: .leading, spacing: 4) {
    Text(media.synopsis ?? "")
        .font(.subheadline)
        .foregroundColor(LunaTheme.textSecondary)
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)

    if let synopsis = media.synopsis, synopsis.count > 200 {
        Button("Read more →") {
            showDescriptionSheet = true
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(LunaTheme.accent)
    }
}
.sheet(isPresented: $showDescriptionSheet) {
    DescriptionSheet(title: media.name ?? "", description: media.synopsis ?? "")
}
```

- [ ] **Step 4: Add DescriptionSheet component (bottom of DetailScreen.swift)**

```swift
private struct DescriptionSheet: View {
    let title: String
    let description: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(description)
                    .font(.body)
                    .foregroundColor(LunaTheme.textSecondary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(LunaTheme.surface)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
```

- [ ] **Step 5: Add heart button next to the bookmark button**

Find the bookmark button in the detail screen's action row (look for `Image(systemName: "bookmark")` or `bookmarkButton`). After it, add:

```swift
Button {
    Task {
        if isLiked {
            await likedRepo.removeLiked(mediaId: media.id)
        } else {
            await likedRepo.addLiked(LikedItem(
                mediaId: media.id,
                mediaType: media.type.rawValue,
                name: media.name ?? "",
                poster: media.poster,
                tmdbId: media.tmdbId
            ))
        }
        isLiked = likedRepo.isLiked(media.id)
    }
} label: {
    Image(systemName: isLiked ? "heart.fill" : "heart")
        .font(.title3)
        .foregroundColor(isLiked ? .red : .white)
        .frame(width: 44, height: 44)
}
.onAppear {
    isLiked = likedRepo.isLiked(media.id)
}
```

- [ ] **Step 6: Replace cast circles with 72×90pt portrait cards**

Find the ForEach in the cast section (around line 338-379). Change from circle layout to:

```swift
ForEach(cast, id: \.id) { person in
    NavigationLink {
        ActorBioScreen(
            name: person.name,
            tmdbPersonId: person.tmdbPersonId,
            characterName: person.character,
            showName: media.name ?? ""
        )
    } label: {
        VStack(spacing: 4) {
            CachedAsyncImage(url: person.photoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.white.opacity(0.05)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.2)))
            }
            .frame(width: 72, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(person.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(person.character ?? "")
                .font(.system(size: 10))
                .foregroundColor(LunaTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}
```

- [ ] **Step 7: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 8: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/DetailScreen.swift
git commit -m "feat: add description bottom sheet, heart button, and 72x90 portrait cast cards on DetailScreen"
```

---

### Task 5: Create ActorBioScreen

**Files:**
- Create: `Apps/LunaApp/Sources/Screens/ActorBioScreen.swift`

- [ ] **Step 1: Create the file**

```swift
// Apps/LunaApp/Sources/Screens/ActorBioScreen.swift
import SwiftUI
import LunaCore

struct ActorBioScreen: View {
    let name: String
    let tmdbPersonId: Int?
    let characterName: String?
    let showName: String

    @StateObject private var viewModel = ActorBioViewModel()
    @State private var creditsFilter: CreditFilter = .all

    enum CreditFilter: String, CaseIterable {
        case all = "All"
        case acting = "Acting"
        case directing = "Directing"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .tint(.white)
                } else if let person = viewModel.person {
                    // ── BIO HEADER ────────────────────────────────
                    bioHeader(person)

                    // ── INFO TABLE ────────────────────────────────
                    if person.birthday != nil || person.placeOfBirth != nil || !person.alsoKnownAs.isEmpty {
                        infoTable(person)
                            .padding(.top, 16)
                    }

                    // ── KNOWN FOR ─────────────────────────────────
                    if !viewModel.knownForItems.isEmpty {
                        sectionHeader("Known For")
                        knownForRow
                    }

                    // ── CREDITS ───────────────────────────────────
                    let allCredits = filteredCredits(person)
                    if !allCredits.isEmpty {
                        sectionHeader("Credits")
                        creditFilterChips
                        creditsGroupedList(allCredits)
                    }

                } else if let error = viewModel.error {
                    errorView(error)
                }

                Spacer().frame(height: 40)
            }
        }
        .background(LunaTheme.background)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(personId: tmdbPersonId, name: name)
        }
        .task(id: viewModel.person?.id) {
            guard let knownFor = viewModel.person?.credits.knownFor else { return }
            await viewModel.fetchKnownForBackdrops(knownFor)
        }
    }

    // MARK: - Bio Header

    private func bioHeader(_ person: PersonDetails) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Single photo
            CachedAsyncImage(url: TMDBPersonService.shared.imageURL(path: person.profilePath, size: "w185")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.05).overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.2)))
            }
            .frame(width: 90, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                if let character = characterName {
                    Text("as \(character)")
                        .font(.subheadline)
                        .foregroundColor(LunaTheme.textSecondary)
                }
                Spacer().frame(height: 4)
                if !person.biography.isEmpty {
                    Text(person.biography)
                        .font(.caption)
                        .foregroundColor(LunaTheme.textSecondary)
                        .lineLimit(6)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Info Table

    private func infoTable(_ person: PersonDetails) -> some View {
        VStack(spacing: 0) {
            if let birthday = person.birthday {
                infoRow(label: "Born", value: formatDate(birthday))
            }
            if let place = person.placeOfBirth {
                infoRow(label: "Birthplace", value: place)
            }
            if let first = person.alsoKnownAs.first {
                infoRow(label: "Also Known As", value: first)
            }
            if let imdbId = person.imdbId {
                infoRow(label: "IMDb", value: "imdb.com/name/\(imdbId)", isLink: true)
            }
        }
        .glassCard(cornerRadius: 12)
        .padding(.horizontal, 16)
    }

    private func infoRow(label: String, value: String, isLink: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(LunaTheme.textTertiary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(isLink ? LunaTheme.accent : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Known For

    private var knownForRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.knownForItems, id: \.id) { credit in
                    VStack(alignment: .leading, spacing: 4) {
                        CachedAsyncImage(
                            url: TMDBPersonService.shared.imageURL(
                                path: credit.backdropPath ?? credit.posterPath,
                                size: "w300"
                            )
                        ) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.white.opacity(0.05)
                        }
                        .frame(width: 180, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(credit.title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 180, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Credits

    private var creditFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CreditFilter.allCases, id: \.self) { filter in
                    Button {
                        creditsFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(creditsFilter == filter ? .white : LunaTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(creditsFilter == filter ? LunaTheme.accent : Color.white.opacity(0.08))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    private func filteredCredits(_ person: PersonDetails) -> [PersonCredit] {
        switch creditsFilter {
        case .all: return person.credits.allCombined
        case .acting: return person.credits.cast.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
        case .directing: return person.credits.crew.filter { $0.job?.lowercased().contains("direct") == true }
                                 .sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
        }
    }

    private func creditsGroupedList(_ credits: [PersonCredit]) -> some View {
        // Group by year
        let grouped: [(String, [PersonCredit])] = {
            var dict: [String: [PersonCredit]] = [:]
            for c in credits {
                let year = c.year ?? "Unknown"
                dict[year, default: []].append(c)
            }
            return dict.sorted { $0.key > $1.key }
        }()

        return LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(grouped, id: \.0) { year, yearCredits in
                Section {
                    ForEach(yearCredits, id: \.id) { credit in
                        creditRow(credit)
                        if credit.id != yearCredits.last?.id {
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 62)
                        }
                    }
                } header: {
                    Text(year)
                        .font(.caption.weight(.bold))
                        .foregroundColor(LunaTheme.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LunaTheme.background)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func creditRow(_ credit: PersonCredit) -> some View {
        HStack(spacing: 10) {
            CachedAsyncImage(url: TMDBPersonService.shared.imageURL(path: credit.posterPath, size: "w92")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.05).overlay(Image(systemName: "film").foregroundColor(.white.opacity(0.15)))
            }
            .frame(width: 38, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 2) {
                Text(credit.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(credit.creditType)
                        .font(.caption)
                        .foregroundColor(LunaTheme.textTertiary)
                    if let eps = credit.episodeCount, credit.mediaType == "tv" {
                        Text("· \(eps) ep")
                            .font(.caption)
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                }

                if let character = credit.character, !character.isEmpty {
                    Text("as \(character)")
                        .font(.system(size: 11))
                        .foregroundColor(LunaTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let score = credit.voteAverage, score > 0 {
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", score))
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                    Text("★")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundColor(LunaTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func formatDate(_ dateString: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: dateString) else { return dateString }
        df.dateStyle = .long
        df.dateFormat = nil
        return df.string(from: date)
    }
}

// MARK: - ViewModel

@MainActor
private class ActorBioViewModel: ObservableObject {
    @Published var person: PersonDetails?
    @Published var knownForItems: [PersonCredit] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(personId: Int?, name: String) async {
        isLoading = true
        error = nil
        do {
            let id: Int
            if let personId {
                id = personId
            } else if let found = try await TMDBPersonService.shared.personId(forName: name) {
                id = found
            } else {
                error = "Could not find '\(name)' on TMDB"
                isLoading = false
                return
            }
            person = try await TMDBPersonService.shared.personDetails(id: id)
        } catch TMDBError.noAPIKey {
            error = "TMDB API key not configured. Add it in Settings → Metadata."
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchKnownForBackdrops(_ credits: [PersonCredit]) async {
        var items = credits
        await withTaskGroup(of: (Int, String?).self) { group in
            for (idx, credit) in items.enumerated() {
                group.addTask {
                    let backdrop = await TMDBPersonService.shared.backdrop(for: credit)
                    return (idx, backdrop)
                }
            }
            for await (idx, backdrop) in group {
                items[idx].backdropPath = backdrop
            }
        }
        knownForItems = items
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -20
```

Expected: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add Apps/LunaApp/Sources/Screens/ActorBioScreen.swift
git commit -m "feat: add ActorBioScreen with TMDB bio, Known For backdrops, and year-grouped Credits"
```
