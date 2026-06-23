import Foundation

// MARK: - Model

public struct TraktWatchlistItem: Sendable {
    public let id: String       // IMDB ID (tt...) if available, else "trakt:traktId"
    public let title: String
    public let mediaType: String   // "movie" or "series"
    public let tmdbId: Int?
    public let traktId: Int
    public let imdbId: String?
}

// MARK: - Private Decodable types

private struct TraktListEntry: Decodable {
    let movie: TraktMedia?
    let show: TraktMedia?
}

private struct TraktMedia: Decodable {
    let title: String
    let ids: TraktIds
}

private struct TraktIds: Decodable {
    let trakt: Int
    let tmdb: Int?
    let imdb: String?
}

// MARK: - Calendar models

public struct TraktCalendarShow: Sendable {
    public let showTitle: String
    public let showImdbId: String?
    public let showTmdbId: Int?
    public let traktId: Int
    public let mediaId: String  // IMDB if available, else "trakt:traktId"
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let episodeTitle: String?
    public let firstAired: Date?
}

public struct TraktCalendarMovie: Sendable {
    public let title: String
    public let imdbId: String?
    public let tmdbId: Int?
    public let traktId: Int
    public let mediaId: String  // IMDB if available, else "trakt:traktId"
    public let released: Date?
}

private struct TraktCalendarShowEntry: Decodable {
    let firstAired: String?
    let episode: TraktEpisode
    let show: TraktMedia

    enum CodingKeys: String, CodingKey {
        case firstAired = "first_aired"
        case episode, show
    }
}

private struct TraktEpisode: Decodable {
    let season: Int
    let number: Int
    let title: String?
}

private struct TraktCalendarMovieEntry: Decodable {
    let released: String?
    let movie: TraktMedia
}

// MARK: - TraktService

@MainActor
public final class TraktService {
    public static let shared = TraktService()

    private var clientId: String {
        MetadataIntegrationStore.shared.traktClientId
    }

    private init() {}

    // MARK: - Watchlist

    public func fetchWatchlist(accessToken: String) async -> [TraktWatchlistItem] {
        async let shows = fetchList(path: "/users/me/watchlist/shows", mediaType: "series", accessToken: accessToken)
        async let movies = fetchList(path: "/users/me/watchlist/movies", mediaType: "movie", accessToken: accessToken)
        let (s, m) = await (shows, movies)
        return s + m
    }

    // MARK: - Calendar

    /// Returns upcoming shows from Trakt calendar for the next `days` days.
    public func fetchUpcomingShows(accessToken: String, days: Int = 90) async -> [TraktCalendarShow] {
        let today = Self.todayString()
        guard let url = URL(string: "https://api.trakt.tv/users/me/calendar/shows/\(today)/\(days)") else { return [] }
        let request = traktRequest(url: url, accessToken: accessToken)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
            let entries = try JSONDecoder().decode([TraktCalendarShowEntry].self, from: data)
            return entries.map { e in
                let imdb = e.show.ids.imdb
                let mediaId = imdb ?? "trakt:\(e.show.ids.trakt)"
                return TraktCalendarShow(
                    showTitle: e.show.title,
                    showImdbId: imdb,
                    showTmdbId: e.show.ids.tmdb,
                    traktId: e.show.ids.trakt,
                    mediaId: mediaId,
                    seasonNumber: e.episode.season,
                    episodeNumber: e.episode.number,
                    episodeTitle: e.episode.title,
                    firstAired: Self.parseDateTime(e.firstAired)
                )
            }
        } catch {
            return []
        }
    }

    /// Returns upcoming movies from Trakt calendar for the next `days` days.
    public func fetchUpcomingMovies(accessToken: String, days: Int = 90) async -> [TraktCalendarMovie] {
        let today = Self.todayString()
        guard let url = URL(string: "https://api.trakt.tv/users/me/calendar/movies/\(today)/\(days)") else { return [] }
        let request = traktRequest(url: url, accessToken: accessToken)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
            let entries = try JSONDecoder().decode([TraktCalendarMovieEntry].self, from: data)
            return entries.map { e in
                let imdb = e.movie.ids.imdb
                let mediaId = imdb ?? "trakt:\(e.movie.ids.trakt)"
                return TraktCalendarMovie(
                    title: e.movie.title,
                    imdbId: imdb,
                    tmdbId: e.movie.ids.tmdb,
                    traktId: e.movie.ids.trakt,
                    mediaId: mediaId,
                    released: Self.parseDate(e.released)
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Private helpers

    private func fetchList(path: String, mediaType: String, accessToken: String) async -> [TraktWatchlistItem] {
        guard let url = URL(string: "https://api.trakt.tv\(path)") else { return [] }
        let request = traktRequest(url: url, accessToken: accessToken)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
            let entries = try JSONDecoder().decode([TraktListEntry].self, from: data)
            return entries.compactMap { entry -> TraktWatchlistItem? in
                let media = mediaType == "movie" ? entry.movie : entry.show
                guard let media else { return nil }
                let imdb = media.ids.imdb
                return TraktWatchlistItem(
                    id: imdb ?? "trakt:\(media.ids.trakt)",
                    title: media.title,
                    mediaType: mediaType,
                    tmdbId: media.ids.tmdb,
                    traktId: media.ids.trakt,
                    imdbId: imdb
                )
            }
        } catch {
            return []
        }
    }

    private func traktRequest(url: URL, accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2", forHTTPHeaderField: "trakt-api-version")
        request.setValue(clientId, forHTTPHeaderField: "trakt-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private static func todayString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private static func parseDateTime(_ string: String?) -> Date? {
        guard let string else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: string)
    }
}
