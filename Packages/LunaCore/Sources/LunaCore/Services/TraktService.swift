import Foundation

// MARK: - Model

public struct TraktWatchlistItem: Sendable {
    public let id: String
    public let title: String
    public let mediaType: String   // "movie" or "series"
    public let tmdbId: Int?
    public let traktId: Int
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
}

// MARK: - TraktService

@MainActor
public final class TraktService {
    public static let shared = TraktService()

    private var clientId: String {
        MetadataIntegrationStore.shared.traktClientId
    }

    private init() {}

    /// Fetches the user's Trakt watchlist (shows + movies) using the given Bearer token.
    /// Returns an empty array on any error.
    public func fetchWatchlist(accessToken: String) async -> [TraktWatchlistItem] {
        async let shows = fetchList(path: "/users/me/watchlist/shows", mediaType: "series", accessToken: accessToken)
        async let movies = fetchList(path: "/users/me/watchlist/movies", mediaType: "movie", accessToken: accessToken)
        let (s, m) = await (shows, movies)
        return s + m
    }

    // MARK: - Private

    private func fetchList(path: String, mediaType: String, accessToken: String) async -> [TraktWatchlistItem] {
        guard let url = URL(string: "https://api.trakt.tv\(path)") else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2", forHTTPHeaderField: "trakt-api-version")
        request.setValue(clientId, forHTTPHeaderField: "trakt-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
            let entries = try JSONDecoder().decode([TraktListEntry].self, from: data)
            return entries.compactMap { entry -> TraktWatchlistItem? in
                let media = mediaType == "movie" ? entry.movie : entry.show
                guard let media else { return nil }
                return TraktWatchlistItem(
                    id: "trakt:\(media.ids.trakt)",
                    title: media.title,
                    mediaType: mediaType,
                    tmdbId: media.ids.tmdb,
                    traktId: media.ids.trakt
                )
            }
        } catch {
            return []
        }
    }
}
