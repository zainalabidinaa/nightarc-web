import Foundation

public actor MetaService {
    public static let shared = MetaService()
    private let client = StremioHTTPClient.shared

    private init() {}

    public func fetchMeta(type: String, id: String, baseURL: String) async throws -> MetaDetail {
        let url = "\(baseURL)/meta/\(type)/\(id).json"

        struct RawMetaDetail: Codable {
            let meta: RawMeta?
        }
        struct RawMeta: Codable {
            let id: String?
            let type: String?
            let name: String?
            let poster: String?
            let background: String?
            let logo: String?
            let description: String?
            let releaseInfo: String?
            let status: String?
            let imdbRating: String?
            let ageRating: String?
            let runtime: String?
            let genres: [String]?
            let director: [String]?
            let writer: [String]?
            let cast: [RawPerson]?
            let trailers: [RawTrailer]?
            let videos: [RawVideo]?
            let links: [RawLink]?
        }
        struct RawPerson: Codable {
            let id: String?
            let name: String?
            let photo: String?
        }
        struct RawTrailer: Codable {
            let id: String?
            let title: String?
            let thumbnail: String?
            let youtubeId: String?
        }
        struct RawVideo: Codable {
            let id: String?
            let title: String?
            let released: String?
            let thumbnail: String?
            let season: Int?
            let episode: Int?
            let overview: String?
            let runtime: String?
        }
        struct RawLink: Codable {
            let name: String?
            let category: String?
            let url: String?
        }

        let response: RawMetaDetail = try await client.getJSON(url: url, type: RawMetaDetail.self)
        let meta = response.meta

        return MetaDetail(
            id: meta?.id ?? id,
            type: MediaType(rawValue: meta?.type ?? type) ?? .movie,
            name: meta?.name ?? "Unknown",
            poster: meta?.poster,
            background: meta?.background,
            logo: meta?.logo,
            description: meta?.description,
            releaseInfo: meta?.releaseInfo,
            status: meta?.status,
            imdbRating: meta?.imdbRating,
            ageRating: meta?.ageRating,
            runtime: meta?.runtime,
            genres: meta?.genres,
            director: meta?.director,
            writer: meta?.writer,
            cast: meta?.cast?.map {
                Person(id: $0.id ?? "", name: $0.name ?? "", photo: $0.photo)
            },
            trailers: meta?.trailers?.map {
                Trailer(id: $0.id ?? "", title: $0.title, thumbnail: $0.thumbnail, youtubeId: $0.youtubeId)
            },
            videos: meta?.videos?.map {
                MetaVideo(
                    id: $0.id ?? "",
                    title: $0.title ?? "",
                    released: $0.released,
                    thumbnail: $0.thumbnail,
                    season: $0.season,
                    episode: $0.episode,
                    overview: $0.overview,
                    runtime: $0.runtime
                )
            },
            links: meta?.links?.map {
                MetaLink(name: $0.name ?? "", category: $0.category, url: $0.url ?? "")
            }
        )
    }
}
