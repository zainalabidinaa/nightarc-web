import Foundation

@MainActor
public class MetaRepository: ObservableObject {
    public static let shared = MetaRepository()

    @Published public var detail: MetaDetail?
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let metaService = MetaService.shared
    private let tmdbApiKey = LunaConfig.tmdbApiKey

    private init() {}

    public func loadDetail(type: String, id: String, addons: [AddonManifest]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        for addon in addons {
            guard addon.hasResource("meta"),
                  let baseURL = addon.transportUrl,
                  let types = addon.types,
                  types.contains(type) else { continue }

            do {
                var detail = try await metaService.fetchMeta(type: type, id: id, baseURL: baseURL)
                detail = await enrichWithTMDB(detail: detail)
                self.detail = detail
                return
            } catch {
                continue
            }
        }

        errorMessage = "Could not load details from any addon"
    }

    private func enrichWithTMDB(detail: MetaDetail) async -> MetaDetail {
        var enriched = detail
        let tmdbId: String?

        let idParts = detail.id.split(separator: ":").map(String.init)
        if idParts.count >= 2, idParts[0] == "tmdb" {
            tmdbId = idParts[1]
        } else if detail.id.hasPrefix("tt") || detail.id.hasPrefix("tt") {
            tmdbId = nil
        } else {
            tmdbId = nil
        }

        guard let tmdbId = tmdbId else {
            if enriched.poster == nil, enriched.background == nil {
                enriched = await enrichFromTMDB(name: detail.name, type: detail.type.rawValue, id: detail.id)
            }
            return enriched
        }

        if enriched.poster == nil || enriched.background == nil || enriched.cast == nil {
            enriched = await fetchTMDBDetails(tmdbId: tmdbId, type: detail.type.rawValue, detail: enriched)
        }

        return enriched
    }

    private func fetchTMDBDetails(tmdbId: String, type: String, detail: MetaDetail) async -> MetaDetail {
        var enriched = detail
        let mediaType = type == "series" ? "tv" : "movie"
        let url = "https://api.themoviedb.org/3/\(mediaType)/\(tmdbId)?api_key=\(tmdbApiKey)&append_to_response=credits,videos,similar"
        guard let apiURL = URL(string: url) else { return enriched }

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decoder = JSONDecoder()

            struct TMDBResponse: Codable {
                let poster_path: String?
                let backdrop_path: String?
                let vote_average: Double?
                let overview: String?
                let genres: [TMDBGenre]?
                let credits: TMDBCredits?
            }
            struct TMDBGenre: Codable { let name: String }
            struct TMDBCredits: Codable {
                let cast: [TMDBCast]?
            }
            struct TMDBCast: Codable {
                let id: Int
                let name: String
                let profile_path: String?
            }

            let tmdb = try decoder.decode(TMDBResponse.self, from: data)

            if enriched.poster == nil, let poster = tmdb.poster_path {
                enriched = MetaDetail(
                    id: enriched.id, type: enriched.type, name: enriched.name,
                    poster: "https://image.tmdb.org/t/p/w342\(poster)",
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
        } catch {}

        return enriched
    }

    private func enrichFromTMDB(name: String, type: String, id: String) async -> MetaDetail {
        return MetaDetail(id: id, type: MediaType(rawValue: type) ?? .movie, name: name)
    }
}
