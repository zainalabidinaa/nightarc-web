import Foundation

public struct UpcomingInfo: Sendable {
    public let mediaId: String
    public let isUpcoming: Bool
    public let releaseDate: Date?
    public let seasonNumber: Int?
    public let badge: String
}

@MainActor
public final class UpcomingItemsService: ObservableObject {
    public static let shared = UpcomingItemsService()

    @Published public private(set) var upcomingInfo: [String: UpcomingInfo] = [:]
    @Published public private(set) var traktUpcomingItems: [LikedItem] = []

    private let base = "https://api.themoviedb.org/3"
    private var apiKey: String? { MetadataIntegrationStore.shared.effectiveTMDBAPIKey }

    private let lastRefreshKey = "luna.upcoming.lastRefresh"
    private var lastRefresh: Date? {
        get { UserDefaults.standard.object(forKey: lastRefreshKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastRefreshKey) }
    }

    private init() {}

    public func refreshIfNeeded(likedItems: [LikedItem]) async {
        let now = Date()
        // Throttle to once per 4 hours (not 24) so likes made today show up soon.
        if let last = lastRefresh, now.timeIntervalSince(last) < 4 * 3600 { return }
        await refresh(likedItems: likedItems)
    }

    public func refresh(likedItems: [LikedItem]) async {
        guard let key = apiKey, !key.isEmpty else { return }
        var result: [String: UpcomingInfo] = [:]
        await withTaskGroup(of: (String, UpcomingInfo?).self) { group in
            for item in likedItems {
                group.addTask {
                    // Resolve TMDB ID: use stored value if available, otherwise look up
                    // from the IMDb ID via the /find endpoint.
                    let tmdbId: Int?
                    if let stored = item.tmdbId {
                        tmdbId = stored
                    } else {
                        tmdbId = await self.resolveTMDBId(imdbId: item.mediaId, mediaType: item.mediaType, apiKey: key)
                    }
                    guard let resolvedId = tmdbId else { return (item.mediaId, nil) }
                    let info = await self.fetchUpcomingInfo(mediaId: item.mediaId, tmdbId: resolvedId, mediaType: item.mediaType, apiKey: key)
                    return (item.mediaId, info)
                }
            }
            for await (mediaId, info) in group {
                if let info { result[mediaId] = info }
            }
        }
        upcomingInfo = result
        lastRefresh = Date()

        // Merge Trakt watchlist items if the user is connected
        await mergeTraktItems(likedItems: likedItems)
    }

    // MARK: - Trakt merge

    private func mergeTraktItems(likedItems: [LikedItem]) async {
        guard TraktAuthService.shared.isConnected,
              let token = TraktAuthService.shared.accessToken else {
            traktUpcomingItems = []
            return
        }
        let watchlist = await TraktService.shared.fetchWatchlist(accessToken: token)

        // Build a set of tmdbIds already in likedItems so we can deduplicate
        let likedTmdbIds = Set(likedItems.compactMap(\.tmdbId))

        var merged: [LikedItem] = []
        for entry in watchlist {
            // Skip if already represented in liked items by tmdbId
            if let tmdbId = entry.tmdbId, likedTmdbIds.contains(tmdbId) { continue }
            let mediaId = "trakt:\(entry.traktId)"
            let item = LikedItem(
                mediaId: mediaId,
                mediaType: entry.mediaType,
                name: entry.title,
                poster: nil,
                tmdbId: entry.tmdbId
            )
            merged.append(item)
        }
        traktUpcomingItems = merged

        // Also fetch upcoming info for Trakt items that have a TMDB id
        guard let key = apiKey, !key.isEmpty else { return }
        await withTaskGroup(of: (String, UpcomingInfo?).self) { group in
            for item in merged where item.tmdbId != nil {
                group.addTask {
                    guard let tmdbId = item.tmdbId else { return (item.mediaId, nil) }
                    let info = await self.fetchUpcomingInfo(mediaId: item.mediaId, tmdbId: tmdbId, mediaType: item.mediaType, apiKey: key)
                    return (item.mediaId, info)
                }
            }
            var extra = upcomingInfo
            for await (mediaId, info) in group {
                if let info { extra[mediaId] = info }
            }
            upcomingInfo = extra
        }
    }

    // MARK: - TMDB helpers

    private func resolveTMDBId(imdbId: String, mediaType: String, apiKey: String) async -> Int? {
        // Only attempt for plain IMDb IDs (tt\d+), not episode IDs.
        let rootId = imdbId.split(separator: ":").first.map(String.init) ?? imdbId
        guard rootId.hasPrefix("tt"), rootId.dropFirst(2).allSatisfy(\.isNumber) else { return nil }
        guard let url = URL(string: "\(base)/find/\(rootId)?api_key=\(apiKey)&external_source=imdb_id") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(TMDBFindResponse.self, from: data)
            if mediaType == "movie" { return result.movieResults.first?.id }
            return result.tvResults.first?.id
        } catch { return nil }
    }

    public func isUpcoming(_ mediaId: String) -> Bool { upcomingInfo[mediaId]?.isUpcoming ?? false }
    public func badge(for mediaId: String) -> String? { upcomingInfo[mediaId]?.badge }

    private func fetchUpcomingInfo(mediaId: String, tmdbId: Int, mediaType: String, apiKey: String) async -> UpcomingInfo? {
        let today = Calendar.current.startOfDay(for: Date())
        return mediaType == "movie"
            ? await fetchMovieUpcoming(mediaId: mediaId, tmdbId: tmdbId, apiKey: apiKey, today: today)
            : await fetchSeriesUpcoming(mediaId: mediaId, tmdbId: tmdbId, apiKey: apiKey, today: today)
    }

    private func fetchMovieUpcoming(mediaId: String, tmdbId: Int, apiKey: String, today: Date) async -> UpcomingInfo? {
        guard let url = URL(string: "\(base)/movie/\(tmdbId)?api_key=\(apiKey)"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONDecoder().decode(TMDBMovieResponse.self, from: data) else { return nil }
        guard let releaseDateStr = json.releaseDate, let releaseDate = dateFrom(releaseDateStr) else {
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }
        let isUpcoming = releaseDate > today
        return UpcomingInfo(mediaId: mediaId, isUpcoming: isUpcoming, releaseDate: releaseDate, seasonNumber: nil,
                            badge: isUpcoming ? formatted(releaseDate) : "")
    }

    private func fetchSeriesUpcoming(mediaId: String, tmdbId: Int, apiKey: String, today: Date) async -> UpcomingInfo? {
        guard let url = URL(string: "\(base)/tv/\(tmdbId)?api_key=\(apiKey)"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONDecoder().decode(TMDBSeriesResponse.self, from: data) else { return nil }
        if json.status == "Ended" || json.status == "Canceled" {
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }
        guard let nextEp = json.nextEpisodeToAir else {
            return UpcomingInfo(mediaId: mediaId, isUpcoming: false, releaseDate: nil, seasonNumber: nil, badge: "")
        }
        let season = nextEp.seasonNumber
        let releaseDate = nextEp.airDate.flatMap { dateFrom($0) }
        let badge: String
        if let releaseDate { badge = "Season \(season) · \(formatted(releaseDate))" }
        else { badge = "Season \(season) · No air date yet" }
        let isUpcoming = releaseDate.map { $0 > today } ?? true
        return UpcomingInfo(mediaId: mediaId, isUpcoming: isUpcoming, releaseDate: releaseDate, seasonNumber: season, badge: badge)
    }

    private func dateFrom(_ string: String) -> Date? {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df.date(from: string)
    }

    private func formatted(_ date: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none; return df.string(from: date)
    }
}

private struct TMDBFindResponse: Decodable {
    let movieResults: [TMDBFindResult]
    let tvResults: [TMDBFindResult]
    enum CodingKeys: String, CodingKey {
        case movieResults = "movie_results"
        case tvResults = "tv_results"
    }
}
private struct TMDBFindResult: Decodable { let id: Int }

private struct TMDBMovieResponse: Decodable {
    let releaseDate: String?
    enum CodingKeys: String, CodingKey { case releaseDate = "release_date" }
}

private struct TMDBSeriesResponse: Decodable {
    let status: String?
    let nextEpisodeToAir: TMDBNextEpisode?
    enum CodingKeys: String, CodingKey { case status; case nextEpisodeToAir = "next_episode_to_air" }
}

private struct TMDBNextEpisode: Decodable {
    let seasonNumber: Int
    let airDate: String?
    enum CodingKeys: String, CodingKey { case seasonNumber = "season_number"; case airDate = "air_date" }
}
