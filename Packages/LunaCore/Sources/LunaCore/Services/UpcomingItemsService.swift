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
        if let last = lastRefresh, now.timeIntervalSince(last) < 86_400 { return }
        await refresh(likedItems: likedItems)
    }

    public func refresh(likedItems: [LikedItem]) async {
        guard let key = apiKey, !key.isEmpty else { return }
        var result: [String: UpcomingInfo] = [:]
        await withTaskGroup(of: (String, UpcomingInfo?).self) { group in
            for item in likedItems {
                guard let tmdbId = item.tmdbId else { continue }
                group.addTask {
                    let info = await self.fetchUpcomingInfo(mediaId: item.mediaId, tmdbId: tmdbId, mediaType: item.mediaType, apiKey: key)
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
