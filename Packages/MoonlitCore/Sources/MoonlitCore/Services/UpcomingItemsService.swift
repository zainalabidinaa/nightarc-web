import Foundation

public struct UpcomingInfo: Sendable {
    public let mediaId: String
    public let isUpcoming: Bool
    public let releaseDate: Date?
    public let seasonNumber: Int?
    public let badge: String
    public let episodeLabel: String?

    public init(
        mediaId: String,
        isUpcoming: Bool,
        releaseDate: Date?,
        seasonNumber: Int?,
        badge: String,
        episodeLabel: String? = nil
    ) {
        self.mediaId = mediaId
        self.isUpcoming = isUpcoming
        self.releaseDate = releaseDate
        self.seasonNumber = seasonNumber
        self.badge = badge
        self.episodeLabel = episodeLabel
    }
}

@MainActor
public final class UpcomingItemsService: ObservableObject {
    public static let shared = UpcomingItemsService()

    @Published public private(set) var upcomingInfo: [String: UpcomingInfo] = [:]
    @Published public private(set) var traktUpcomingItems: [LikedItem] = []

    private let base = "https://api.themoviedb.org/3"
    private var apiKey: String? { MetadataIntegrationStore.shared.effectiveTMDBAPIKey }

    private let lastRefreshKey = "moonlit.upcoming.lastRefresh"
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

    // MARK: - Trakt calendar merge

    private func mergeTraktItems(likedItems: [LikedItem]) async {
        guard TraktAuthService.shared.isConnected,
              let token = TraktAuthService.shared.accessToken else {
            traktUpcomingItems = []
            return
        }

        // Use calendar endpoints — these return only items actually airing in the future,
        // with exact air dates from Trakt rather than TMDB guesses.
        async let calendarShows = TraktService.shared.fetchUpcomingShows(accessToken: token, days: 90)
        async let calendarMovies = TraktService.shared.fetchUpcomingMovies(accessToken: token, days: 90)
        let (shows, movies) = await (calendarShows, calendarMovies)

        let today = Calendar.current.startOfDay(for: Date())
        let likedMediaIds = Set(likedItems.map(\.mediaId))
        let likedTmdbIds = Set(likedItems.compactMap(\.tmdbId))

        var merged: [LikedItem] = []
        var extra: [String: UpcomingInfo] = upcomingInfo

        for show in shows {
            guard let airDate = show.firstAired, airDate > today else { continue }
            if likedMediaIds.contains(show.mediaId) { continue }
            if let t = show.showTmdbId, likedTmdbIds.contains(t) { continue }
            let item = LikedItem(
                mediaId: show.mediaId,
                mediaType: "series",
                name: show.showTitle,
                poster: nil,
                tmdbId: show.showTmdbId
            )
            merged.append(item)
            let badge = "S\(show.seasonNumber)E\(show.episodeNumber) · \(formatted(airDate))"
            extra[show.mediaId] = UpcomingInfo(
                mediaId: show.mediaId,
                isUpcoming: true,
                releaseDate: airDate,
                seasonNumber: show.seasonNumber,
                badge: badge,
                episodeLabel: "S\(show.seasonNumber)E\(show.episodeNumber)"
            )
        }

        for movie in movies {
            guard let releaseDate = movie.released, releaseDate > today else { continue }
            if likedMediaIds.contains(movie.mediaId) { continue }
            if let t = movie.tmdbId, likedTmdbIds.contains(t) { continue }
            let item = LikedItem(
                mediaId: movie.mediaId,
                mediaType: "movie",
                name: movie.title,
                poster: nil,
                tmdbId: movie.tmdbId
            )
            merged.append(item)
            extra[movie.mediaId] = UpcomingInfo(
                mediaId: movie.mediaId,
                isUpcoming: true,
                releaseDate: releaseDate,
                seasonNumber: nil,
                badge: formatted(releaseDate)
            )
        }

        traktUpcomingItems = merged
        upcomingInfo = extra
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
    public func episodeLabel(for mediaId: String) -> String? { upcomingInfo[mediaId]?.episodeLabel }
    public func releaseDate(for mediaId: String) -> Date? { upcomingInfo[mediaId]?.releaseDate }

    /// Whole days from today until the release. 0 = today, 1 = tomorrow.
    public func daysUntil(_ mediaId: String) -> Int? {
        guard let date = upcomingInfo[mediaId]?.releaseDate else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: date)).day
    }

    /// Human "how soon" label: "Today", "Tomorrow", "in 5 days", "in 3 weeks"…
    public func daysLabel(for mediaId: String) -> String? {
        guard let d = daysUntil(mediaId) else { return nil }
        switch d {
        case ..<0:    return nil
        case 0:       return "Today"
        case 1:       return "Tomorrow"
        case 2..<7:   return "in \(d) days"
        case 7..<14:  return "in 1 week"
        case 14..<30: return "in \(d / 7) weeks"
        case 30..<60: return "in 1 month"
        default:      return "in \(d / 30) months"
        }
    }

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
        let episodeLabel = nextEp.episodeNumber.map { "S\(season)E\($0)" } ?? "Season \(season)"
        let releaseDate = nextEp.airDate.flatMap { dateFrom($0) }
        let badge: String
        if let releaseDate { badge = "\(episodeLabel) · \(formatted(releaseDate))" }
        else { badge = "\(episodeLabel) · No air date yet" }
        let isUpcoming = releaseDate.map { $0 > today } ?? true
        return UpcomingInfo(mediaId: mediaId, isUpcoming: isUpcoming, releaseDate: releaseDate, seasonNumber: season, badge: badge, episodeLabel: episodeLabel)
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
    let episodeNumber: Int?
    let airDate: String?
    enum CodingKeys: String, CodingKey { case seasonNumber = "season_number"; case episodeNumber = "episode_number"; case airDate = "air_date" }
}
