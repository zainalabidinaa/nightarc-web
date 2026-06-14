import Foundation

public struct EpisodeStillKey: Hashable, Sendable {
    public let season: Int
    public let episode: Int

    public init(season: Int, episode: Int) {
        self.season = season
        self.episode = episode
    }
}

@MainActor
public class MetaRepository: ObservableObject {
    public static let shared = MetaRepository()

    @Published public var detail: MetaDetail?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isShowingStaleDetail = false
    @Published public var cachedDetailUpdatedAt: Date?

    private let metaService = MetaService.shared
    private let integrationStore = MetadataIntegrationStore.shared
    private var cachedTVDBToken: String?
    private var cachedTVDBKey: String?
    private let cacheDefaults = UserDefaults.standard

    private init() {}

    public func fetchDetail(type: String, id: String, addons: [AddonManifest]) async -> MetaDetail? {
        for addon in addons {
            guard addon.canHandleMeta(type: type, id: id),
                  let baseURL = addon.transportUrl,
                  let detail = try? await metaService.fetchMeta(type: type, id: id, baseURL: baseURL) else {
                continue
            }
            return await enrichWithMetadataProviders(detail: detail)
        }
        return nil
    }

    public func loadDetail(type: String, id: String, addons: [AddonManifest]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard NetworkMonitor.shared.isConnected else {
            if restoreCachedDetail(type: type, id: id) {
                errorMessage = nil
            } else {
                errorMessage = "No internet connection"
            }
            return
        }

        detail = nil
        isShowingStaleDetail = false
        cachedDetailUpdatedAt = nil
        var lastError: Error?

        for addon in addons {
            guard addon.canHandleMeta(type: type, id: id),
                  let baseURL = addon.transportUrl else { continue }

            do {
                let detail = try await metaService.fetchMeta(type: type, id: id, baseURL: baseURL)
                let enriched = await enrichWithMetadataProviders(detail: detail)
                self.detail = enriched
                self.isShowingStaleDetail = false
                self.cachedDetailUpdatedAt = nil
                cacheDetail(enriched, type: type, id: id)
                return
            } catch {
                lastError = error
                print("[Nightarc] Meta fetch failed: addon=\(addon.name) type=\(type) id=\(id) baseURL=\(baseURL) error=\(error)")
                continue
            }
        }

        if addons.isEmpty {
            errorMessage = "No metadata addons are enabled"
        } else if restoreCachedDetail(type: type, id: id) {
            errorMessage = nil
        } else if let lastError {
            let friendlyMessage: String
            if let stremioError = lastError as? StremioError {
                friendlyMessage = stremioError.localizedDescription
            } else if lastError is URLError {
                friendlyMessage = "Check your internet connection and try again"
            } else {
                friendlyMessage = "Addon unavailable (\(lastError.localizedDescription))"
            }
            errorMessage = "Could not load details from any addon (\(friendlyMessage))"
        } else {
            errorMessage = "Could not load details from any addon"
        }
    }

    private struct CachedMetaDetail: Codable {
        let detail: MetaDetail
        let updatedAt: Date
    }

    private func cacheKey(type: String, id: String) -> String {
        "luna.cachedMetaDetail.\(type).\(id)"
    }

    private func cacheDetail(_ detail: MetaDetail, type: String, id: String) {
        let cached = CachedMetaDetail(detail: detail, updatedAt: Date())
        if let data = try? JSONEncoder().encode(cached) {
            cacheDefaults.set(data, forKey: cacheKey(type: type, id: id))
        }
    }

    @discardableResult
    private func restoreCachedDetail(type: String, id: String) -> Bool {
        guard let data = cacheDefaults.data(forKey: cacheKey(type: type, id: id)),
              let cached = try? JSONDecoder().decode(CachedMetaDetail.self, from: data) else {
            return false
        }
        detail = cached.detail
        isShowingStaleDetail = true
        cachedDetailUpdatedAt = cached.updatedAt
        return true
    }

    private func enrichWithMetadataProviders(detail: MetaDetail) async -> MetaDetail {
        var enriched = detail

        let idParts = detail.id.split(separator: ":").map(String.init)
        var tmdbId: String?
        if idParts.count >= 2, idParts[0] == "tmdb" {
            tmdbId = idParts[1]
        } else if detail.id.hasPrefix("tt") {
            tmdbId = await findTMDBId(forIMDBId: detail.id)
        }

        if let tmdbId, (enriched.poster == nil || enriched.background == nil || enriched.cast == nil) {
            enriched = await fetchTMDBDetails(tmdbId: tmdbId, type: detail.type.rawValue, detail: enriched)
        }

        if detail.type == .series {
            let seasons = enriched.seasons ?? []
            let hasEpisodes = seasons.contains { $0.episodes?.isEmpty == false }
            if hasEpisodes {
                let tvdbStills = await fetchTVDBEpisodeStills(imdbId: detail.id, detail: enriched)
                var tmdbStills: [EpisodeStillKey: String] = [:]
                if let tmdbId {
                    tmdbStills = await fetchTMDBEpisodeStills(tmdbId: tmdbId, detail: enriched)
                }
                enriched = Self.mergeEpisodeStills(
                    into: enriched,
                    tvdbStills: tvdbStills,
                    tmdbStills: tmdbStills
                )
            }
        }

        return enriched
    }

    private func findTMDBId(forIMDBId imdbId: String) async -> String? {
        guard let tmdbApiKey = integrationStore.effectiveTMDBAPIKey else { return nil }
        let url = "https://api.themoviedb.org/3/find/\(imdbId)?api_key=\(tmdbApiKey)&external_source=imdb_id"
        guard let apiURL = URL(string: url) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            struct FindResponse: Codable {
                let tv_results: [TMDBTVResult]?
            }
            struct TMDBTVResult: Codable { let id: Int }
            let response = try JSONDecoder().decode(FindResponse.self, from: data)
            if let id = response.tv_results?.first?.id { return String(id) }
        } catch {}
        return nil
    }

    private func fetchTMDBSeasonEpisodeStills(tmdbId: String, seasonNumber: Int) async -> [Int: String] {
        guard let tmdbApiKey = integrationStore.effectiveTMDBAPIKey else { return [:] }
        let url = "https://api.themoviedb.org/3/tv/\(tmdbId)/season/\(seasonNumber)?api_key=\(tmdbApiKey)"
        guard let apiURL = URL(string: url) else { return [:] }
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            struct SeasonResponse: Codable { let episodes: [TMDBEpisode]? }
            struct TMDBEpisode: Codable { let episode_number: Int; let still_path: String? }
            let response = try JSONDecoder().decode(SeasonResponse.self, from: data)
            var stills: [Int: String] = [:]
            for ep in response.episodes ?? [] {
                if let still = ep.still_path {
                    stills[ep.episode_number] = "https://image.tmdb.org/t/p/w400\(still)"
                }
            }
            return stills
        } catch {}
        return [:]
    }

    private func fetchTMDBEpisodeStills(tmdbId: String, detail: MetaDetail) async -> [EpisodeStillKey: String] {
        guard let seasons = detail.seasons, !seasons.isEmpty else { return [:] }

        var allStills: [EpisodeStillKey: String] = [:]
        for season in seasons {
            let stills = await fetchTMDBSeasonEpisodeStills(tmdbId: tmdbId, seasonNumber: season.number)
            for (episode, still) in stills {
                allStills[EpisodeStillKey(season: season.number, episode: episode)] = still
            }
        }
        return allStills
    }

    private func fetchTVDBEpisodeStills(imdbId: String, detail: MetaDetail) async -> [EpisodeStillKey: String] {
        guard detail.type == .series,
              imdbId.hasPrefix("tt"),
              let apiKey = integrationStore.effectiveTVDBAPIKey,
              let token = await tvdbToken(apiKey: apiKey),
              let seriesId = await findTVDBSeriesId(forIMDBId: imdbId, token: token),
              let seasons = detail.seasons else {
            return [:]
        }

        var allStills: [EpisodeStillKey: String] = [:]
        for season in seasons {
            let stills = await fetchTVDBSeasonEpisodeStills(seriesId: seriesId, seasonNumber: season.number, token: token)
            allStills.merge(stills) { current, _ in current }
        }
        return allStills
    }

    private func tvdbToken(apiKey: String) async -> String? {
        if cachedTVDBKey == apiKey, let cachedTVDBToken {
            return cachedTVDBToken
        }

        guard let url = URL(string: "https://api4.thetvdb.com/v4/login") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(TVDBLoginRequest(apikey: apiKey))

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TVDBLoginResponse.self, from: data)
            cachedTVDBKey = apiKey
            cachedTVDBToken = response.data.token
            return response.data.token
        } catch {
            return nil
        }
    }

    private func findTVDBSeriesId(forIMDBId imdbId: String, token: String) async -> Int? {
        guard let url = URL(string: "https://api4.thetvdb.com/v4/search/remoteid/\(imdbId)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TVDBRemoteIDResponse.self, from: data)
            return response.data.compactMap(\.series?.id).first
        } catch {
            return nil
        }
    }

    private func fetchTVDBSeasonEpisodeStills(seriesId: Int, seasonNumber: Int, token: String) async -> [EpisodeStillKey: String] {
        var components = URLComponents(string: "https://api4.thetvdb.com/v4/series/\(seriesId)/episodes/default")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "season", value: String(seasonNumber))
        ]
        guard let url = components?.url else { return [:] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TVDBEpisodesResponse.self, from: data)
            var stills: [EpisodeStillKey: String] = [:]
            for episode in response.data.episodes {
                guard let image = episode.image?.nilIfBlank else { continue }
                stills[EpisodeStillKey(
                    season: episode.seasonNumber ?? seasonNumber,
                    episode: episode.number
                )] = image
            }
            return stills
        } catch {
            return [:]
        }
    }

    nonisolated public static func mergeEpisodeStills(
        into detail: MetaDetail,
        tvdbStills: [EpisodeStillKey: String],
        tmdbStills: [EpisodeStillKey: String]
    ) -> MetaDetail {
        guard let seasons = detail.seasons, !seasons.isEmpty else { return detail }

        let updatedSeasons = seasons.map { season -> Season in
            guard let episodes = season.episodes else { return season }
            let updatedEpisodes = episodes.map { episode -> MetaVideo in
                guard let episodeNumber = episode.episode else {
                    return episode
                }
                let key = EpisodeStillKey(season: season.number, episode: episodeNumber)
                let still = tvdbStills[key] ?? tmdbStills[key] ?? episode.thumbnail
                return MetaVideo(
                    id: episode.id, title: episode.title, released: episode.released, thumbnail: still,
                    season: episode.season, episode: episode.episode, overview: episode.overview,
                    runtime: episode.runtime, streams: episode.streams, trailerStreams: episode.trailerStreams
                )
            }
            return Season(
                id: season.id, number: season.number, name: season.name,
                poster: season.poster, episodes: updatedEpisodes
            )
        }

        return MetaDetail(
            id: detail.id, type: detail.type, name: detail.name,
            poster: detail.poster, background: detail.background,
            logo: detail.logo, description: detail.description,
            releaseInfo: detail.releaseInfo, status: detail.status,
            imdbRating: detail.imdbRating, ageRating: detail.ageRating,
            runtime: detail.runtime, genres: detail.genres,
            director: detail.director, writer: detail.writer, cast: detail.cast,
            trailers: detail.trailers, trailerStreams: detail.trailerStreams,
            videos: detail.videos, seasons: updatedSeasons,
            links: detail.links, moreLikeThis: detail.moreLikeThis,
            collectionItems: detail.collectionItems
        )
    }

    private func fetchTMDBDetails(tmdbId: String, type: String, detail: MetaDetail) async -> MetaDetail {
        guard let tmdbApiKey = integrationStore.effectiveTMDBAPIKey else { return detail }
        var enriched = detail
        let mediaType = type == "series" ? "tv" : "movie"
        let url = "https://api.themoviedb.org/3/\(mediaType)/\(tmdbId)?api_key=\(tmdbApiKey)&append_to_response=credits,videos,similar"
        guard let apiURL = URL(string: url) else { return enriched }

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decoder = JSONDecoder()

            struct TMDBSimilarItem: Codable {
                let id: Int
                let title: String?       // movies
                let name: String?        // TV shows
                let poster_path: String?
                let vote_average: Double?
            }
            struct TMDBSimilarPage: Codable { let results: [TMDBSimilarItem]? }
            struct TMDBResponse: Codable {
                let poster_path: String?
                let backdrop_path: String?
                let vote_average: Double?
                let overview: String?
                let genres: [TMDBGenre]?
                let credits: TMDBCredits?
                let similar: TMDBSimilarPage?
            }
            struct TMDBGenre: Codable { let name: String }
            struct TMDBCredits: Codable { let cast: [TMDBCast]? }
            struct TMDBCast: Codable {
                let id: Int
                let name: String
                let profile_path: String?
            }

            let tmdb = try decoder.decode(TMDBResponse.self, from: data)

            if enriched.poster == nil, let poster = tmdb.poster_path {
                enriched = MetaDetail(
                    id: enriched.id, type: enriched.type, name: enriched.name,
                    poster: "https://image.tmdb.org/t/p/w780\(poster)",
                    background: enriched.background,
                    logo: enriched.logo, description: enriched.description ?? tmdb.overview,
                    releaseInfo: enriched.releaseInfo, status: enriched.status,
                    imdbRating: enriched.imdbRating ?? tmdb.vote_average.map { String(format: "%.1f", $0) },
                    ageRating: enriched.ageRating, runtime: enriched.runtime,
                    genres: enriched.genres ?? tmdb.genres?.map { $0.name },
                    director: enriched.director, writer: enriched.writer,
                    cast: enriched.cast ?? tmdb.credits?.cast?.map {
                        Person(id: String($0.id), name: $0.name, photo: $0.profile_path.map { "https://image.tmdb.org/t/p/w185\($0)" })
                    },
                    trailers: enriched.trailers, videos: enriched.videos, seasons: enriched.seasons,
                    links: enriched.links, moreLikeThis: enriched.moreLikeThis,
                    collectionItems: enriched.collectionItems
                )
            }
            if enriched.background == nil, let backdrop = tmdb.backdrop_path {
                enriched = MetaDetail(
                    id: enriched.id, type: enriched.type, name: enriched.name,
                    poster: enriched.poster,
                    background: "https://image.tmdb.org/t/p/w1280\(backdrop)",
                    logo: enriched.logo, description: enriched.description,
                    releaseInfo: enriched.releaseInfo, status: enriched.status,
                    imdbRating: enriched.imdbRating,
                    ageRating: enriched.ageRating, runtime: enriched.runtime,
                    genres: enriched.genres, director: enriched.director, writer: enriched.writer,
                    cast: enriched.cast, trailers: enriched.trailers, videos: enriched.videos,
                    seasons: enriched.seasons, links: enriched.links, moreLikeThis: enriched.moreLikeThis,
                    collectionItems: enriched.collectionItems
                )
            }

            // Resolve TMDB similar items → real IMDb IDs so stream lookups work
            if enriched.moreLikeThis == nil,
               let similarItems = tmdb.similar?.results, !similarItems.isEmpty {
                let resolvedType: MediaType = mediaType == "tv" ? .series : .movie
                let key = tmdbApiKey
                let mt = mediaType
                let resolved: [MetaPreview] = await withTaskGroup(of: MetaPreview?.self) { group in
                    for item in similarItems.prefix(20) {
                        group.addTask {
                            let extURL = "https://api.themoviedb.org/3/\(mt)/\(item.id)/external_ids?api_key=\(key)"
                            guard let url = URL(string: extURL),
                                  let (extData, _) = try? await URLSession.shared.data(from: url),
                                  let json = try? JSONSerialization.jsonObject(with: extData) as? [String: Any],
                                  let imdbId = json["imdb_id"] as? String,
                                  imdbId.hasPrefix("tt") else { return nil }
                            return MetaPreview(
                                id: imdbId,
                                type: resolvedType,
                                name: item.title ?? item.name ?? "",
                                poster: item.poster_path.map { "https://image.tmdb.org/t/p/w500\($0)" },
                                imdbRating: item.vote_average.map { String(format: "%.1f", $0) }
                            )
                        }
                    }
                    var out: [MetaPreview] = []
                    for await item in group { if let item { out.append(item) } }
                    return out
                }
                if !resolved.isEmpty {
                    enriched = MetaDetail(
                        id: enriched.id, type: enriched.type, name: enriched.name,
                        poster: enriched.poster, background: enriched.background,
                        logo: enriched.logo, description: enriched.description,
                        releaseInfo: enriched.releaseInfo, status: enriched.status,
                        imdbRating: enriched.imdbRating, ageRating: enriched.ageRating,
                        runtime: enriched.runtime, genres: enriched.genres,
                        director: enriched.director, writer: enriched.writer,
                        cast: enriched.cast, trailers: enriched.trailers, videos: enriched.videos,
                        seasons: enriched.seasons, links: enriched.links,
                        moreLikeThis: resolved,
                        collectionItems: enriched.collectionItems
                    )
                }
            }
        } catch {}

        return enriched
    }
}

private struct TVDBLoginRequest: Encodable {
    let apikey: String
}

private struct TVDBLoginResponse: Decodable {
    struct DataPayload: Decodable {
        let token: String
    }

    let data: DataPayload
}

private struct TVDBRemoteIDResponse: Decodable {
    struct Result: Decodable {
        struct Series: Decodable {
            let id: Int
        }

        let series: Series?
    }

    let data: [Result]
}

private struct TVDBEpisodesResponse: Decodable {
    struct DataPayload: Decodable {
        let episodes: [Episode]
    }

    struct Episode: Decodable {
        let image: String?
        let number: Int
        let seasonNumber: Int?
    }

    let data: DataPayload
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
