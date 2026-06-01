import Foundation

public actor CatalogService {
    public static let shared = CatalogService()
    private let client = StremioHTTPClient.shared

    private init() {}

    public struct StremioCatalogQuery {
        public let type: String
        public let id: String
        public let baseURL: String
        public let extras: [String: String]

        public init(type: String, id: String, baseURL: String, extras: [String: String] = [:]) {
            self.type = type
            self.id = id
            self.baseURL = baseURL
            self.extras = extras
        }

        public func buildURL() -> String {
            var url = "\(baseURL)/catalog/\(type)/\(id).json"
            if !extras.isEmpty {
                let params = extras.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                url += "?\(params)"
            }
            return url
        }
    }

    public func fetchCatalog(query: StremioCatalogQuery) async throws -> [MetaPreview] {
        let url = query.buildURL()

        struct RawMeta: Codable {
            let id: String?
            let type: String?
            let name: String?
            let poster: String?
            let banner: String?
            let logo: String?
            let posterShape: String?
            let description: String?
            let releaseInfo: String?
            let releaseDate: String?
            let popularity: Double?
            let voteCount: Int?
            let imdbRating: String?
            let genres: [String]?
            let released: String?
            let status: String?
            let behaviorHints: BehaviorHints?
        }
        struct CatalogResponse: Codable {
            let metas: [RawMeta]?
        }

        do {
            let response: CatalogResponse = try await client.getJSON(url: url, type: CatalogResponse.self)
            return (response.metas ?? []).map { raw in
                MetaPreview(
                    id: raw.id ?? "",
                    type: MediaType(rawValue: raw.type ?? "movie") ?? .movie,
                    name: raw.name ?? "Unknown",
                    poster: raw.poster,
                    banner: raw.banner,
                    logo: raw.logo,
                    posterShape: raw.posterShape.flatMap { PosterShape(rawValue: $0) },
                    description: raw.description,
                    releaseInfo: raw.releaseInfo,
                    rawReleaseDate: raw.releaseDate,
                    popularity: raw.popularity,
                    voteCount: raw.voteCount,
                    imdbRating: raw.imdbRating,
                    genres: raw.genres,
                    released: raw.released,
                    status: raw.status,
                    behaviorHints: raw.behaviorHints
                )
            }
        } catch {
            throw error
        }
    }

    public func fetchCatalogPaginated(
        query: StremioCatalogQuery,
        skip: Int = 0
    ) async throws -> CatalogResponse {
        var extras = query.extras
        extras["skip"] = String(skip)

        let paginatedQuery = StremioCatalogQuery(
            type: query.type,
            id: query.id,
            baseURL: query.baseURL,
            extras: extras
        )

        let items = try await fetchCatalog(query: paginatedQuery)
        return CatalogResponse(items: items, hasMore: items.count >= 50, page: skip / 50)
    }

    public struct CatalogResponse {
        public let items: [MetaPreview]
        public let hasMore: Bool
        public let page: Int

        public init(items: [MetaPreview], hasMore: Bool, page: Int) {
            self.items = items
            self.hasMore = hasMore
            self.page = page
        }
    }
}
