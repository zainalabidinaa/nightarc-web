import Foundation

public final class MetaService: @unchecked Sendable {
    public static let shared = MetaService()
    private let client = StremioHTTPClient.shared

    private init() {}

    public func fetchMeta(type: String, id: String, baseURL: String) async throws -> MetaDetail {
        let url = "\(baseURL)/meta/\(type)/\(id).json"
        let text = try await getTextWithNetworkRetry(url: url)
        return try Self.decodeMetaResponse(json: text, type: type, id: id, baseURL: baseURL)
    }

    private func getTextWithNetworkRetry(url: String) async throws -> String {
        do {
            return try await client.getText(url: url)
        } catch StremioError.networkError(_) {
            try await Task.sleep(for: .seconds(1))
            return try await client.getText(url: url)
        }
    }

    public static func decodeMetaResponse(json: String, type: String, id: String, baseURL: String = "") throws -> MetaDetail {
        guard let data = json.data(using: .utf8) else {
            throw StremioError.invalidResponse
        }

        struct RawMetaDetail: Codable {
            let meta: RawMeta?
        }
        struct RawMeta: Codable {
            let id: String?
            let type: String?
            let name: String?
            let poster: String?
            let _rawPosterUrl: String?  // AIOMetadata raw source URL fallback
            let img: String?
            let image: String?
            let background: String?
            let logo: String?
            let description: String?
            let releaseInfo: String?
            let status: String?
            let imdbRating: String?
            let ageRating: String?
            let runtime: String?
            let genres: [String]?
            let director: FlexiblePersonArray?
            let writer: FlexiblePersonArray?
            let cast: [RawPerson]?
            let trailers: [RawTrailer]?
            let trailerStreams: [RawStream]?
            let videos: [RawVideo]?
            let seasons: [RawSeason]?
            let links: [RawLink]?
            let app_extras: RawAppExtras?
        }
        struct FlexiblePersonArray: Codable {
            let values: [Person]

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) {
                    values = str
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .map { Person(id: $0, name: $0, photo: nil) }
                } else if let arr = try? container.decode([String].self) {
                    values = arr.map { Person(id: $0, name: $0, photo: nil) }
                } else {
                    let people = try container.decode([RawPerson].self)
                    values = people.map { Person(id: $0.id ?? $0.name ?? "", name: $0.name ?? "", photo: $0.photo) }
                }
            }
        }
        struct RawPerson: Codable {
            let id: String?
            let name: String?
            let photo: String?
            let character: String?
        }
        struct RawAppExtras: Codable {
            let cast: [RawAppPerson]?
        }
        struct RawAppPerson: Codable {
            let name: String?
            let character: String?
            let photo: String?
        }
        struct RawTrailer: Codable {
            let id: String?
            let source: String?
            let title: String?
            let name: String?
            let thumbnail: String?
            let youtubeId: String?
            let ytId: String?
        }
        struct RawVideo: Codable {
            let id: String?
            let name: String?
            let title: String?
            let released: String?
            let firstAired: String?
            let thumbnail: String?   // standard Stremio field
            let still: String?       // TVDB/AIOMetadata use "still" for episode stills
            let img: String?
            let image: String?
            let season: Int?
            let episode: Int?
            let number: Int?
            let overview: String?
            let description: String?
            let runtime: String?
            let stream: RawStream?
            let streams: [RawStream]?
            let trailerStreams: [RawStream]?
        }
        struct RawSeason: Codable {
            let id: String?
            let number: Int
            let name: String?
            let episodes: [RawVideo]?
        }
        struct RawStream: Codable {
            let name: String?
            let title: String?
            let description: String?
            let url: String?
            let infoHash: String?
            let fileIdx: Int?
            let externalUrl: String?
            let ytId: String?
            let sources: [String]?
            let behaviorHints: RawBehaviorHints?
        }
        struct RawBehaviorHints: Codable {
            let notWebReady: Bool?
            let bingeGroup: String?
            let countryWhitelist: [String]?
            let proxyHeaders: RawProxyHeaders?
            let filename: String?
            let videoHash: String?
            let videoSize: Int64?
        }
        struct RawProxyHeaders: Codable {
            let request: [String: String]?
            let response: [String: String]?
        }
        struct RawLink: Codable {
            let name: String?
            let category: String?
            let url: String?
        }

        let response = try JSONDecoder().decode(RawMetaDetail.self, from: data)
        guard let meta = response.meta,
              let metaName = firstNonBlank(meta.name) else {
            throw StremioError.invalidResponse
        }

        func mapStream(_ raw: RawStream, addonName: String?, addonId: String?) -> StreamItem {
            StreamItem(
                name: raw.name,
                title: raw.title,
                description: raw.description,
                url: raw.url,
                infoHash: raw.infoHash,
                fileIdx: raw.fileIdx,
                externalUrl: raw.externalUrl,
                ytId: raw.ytId,
                sources: raw.sources,
                addonName: addonName,
                addonId: addonId,
                behaviorHints: raw.behaviorHints.map {
                    StreamBehaviorHints(
                        notWebReady: $0.notWebReady,
                        bingeGroup: $0.bingeGroup,
                        countryWhitelist: $0.countryWhitelist,
                        proxyHeaders: $0.proxyHeaders.map {
                            StreamProxyHeaders(request: $0.request, response: $0.response)
                        },
                        filename: $0.filename,
                        videoHash: $0.videoHash,
                        videoSize: $0.videoSize
                    )
                }
            )
        }

        func mapVideo(_ raw: RawVideo) -> MetaVideo {
            MetaVideo(
                id: raw.id ?? "",
                title: raw.title ?? raw.name ?? "",
                released: raw.released ?? raw.firstAired,
                thumbnail: resolve(firstNonBlank(raw.thumbnail, raw.still, raw.img, raw.image), base: baseURL),
                season: raw.season,
                episode: raw.episode ?? raw.number,
                overview: raw.overview ?? raw.description,
                runtime: raw.runtime,
                streams: (raw.streams ?? (raw.stream.map { [$0] } ?? [])).map { mapStream($0, addonName: nil, addonId: nil) },
                trailerStreams: raw.trailerStreams?.map { mapStream($0, addonName: nil, addonId: nil) }
            )
        }

        let videos = meta.videos?.map(mapVideo)

        let mappedSeasons = meta.seasons?.map { rawSeason in
            Season(
                id: rawSeason.id ?? String(rawSeason.number),
                number: rawSeason.number,
                name: rawSeason.name,
                episodes: rawSeason.episodes?.map(mapVideo)
            )
        }

        // Some addons (e.g. AIOMetadata) return a `seasons` skeleton (season numbers,
        // no episodes) alongside a flat `videos` array that has the actual episodes.
        // When seasons exist but none of them carry episodes, backfill from flat videos.
        let seasonsWithEpisodes: [Season]?
        if let raw = (mappedSeasons?.isEmpty == true ? nil : mappedSeasons) {
            let anyHasEpisodes = raw.contains { ($0.episodes?.isEmpty == false) }
            if anyHasEpisodes {
                seasonsWithEpisodes = raw
            } else if let fromVideos = Self.seasons(from: videos) {
                // Preserve season names/ids from the skeleton, fill in episodes from videos
                let byNumber = Dictionary(uniqueKeysWithValues: fromVideos.map { ($0.number, $0) })
                seasonsWithEpisodes = raw.map { s in
                    guard let filled = byNumber[s.number] else { return s }
                    return Season(id: s.id, number: s.number, name: s.name, poster: s.poster, episodes: filled.episodes)
                }
            } else {
                seasonsWithEpisodes = raw
            }
        } else {
            seasonsWithEpisodes = nil
        }
        let seasons = seasonsWithEpisodes

        let trailerStreams = meta.trailerStreams?.map { mapStream($0, addonName: nil, addonId: nil) }
            ?? meta.trailers?.compactMap { trailer -> StreamItem? in
                let ytId = trailer.youtubeId ?? trailer.ytId ?? trailer.source
                guard let ytId = ytId else { return nil }
                return StreamItem(
                    name: trailer.title ?? trailer.name,
                    title: trailer.title ?? trailer.name,
                    ytId: ytId,
                    addonName: nil,
                    addonId: nil
                )
            }

        return MetaDetail(
            id: meta.id ?? id,
            type: MediaType(rawValue: meta.type ?? type) ?? .movie,
            name: metaName,
            poster: resolve(meta.poster, base: baseURL)
                ?? resolve(meta._rawPosterUrl, base: baseURL)
                ?? resolve(meta.img, base: baseURL)
                ?? resolve(meta.image, base: baseURL),
            background: resolve(meta.background, base: baseURL),
            logo: resolve(meta.logo, base: baseURL),
            description: meta.description,
            releaseInfo: meta.releaseInfo,
            status: meta.status,
            imdbRating: meta.imdbRating,
            ageRating: meta.ageRating,
            runtime: meta.runtime,
            genres: meta.genres,
            director: meta.director?.values,
            writer: meta.writer?.values,
            cast: meta.app_extras?.cast?.map {
                Person(id: $0.name ?? "", name: $0.name ?? "", photo: $0.photo, character: $0.character)
            } ?? meta.cast?.map {
                Person(id: $0.id ?? $0.name ?? "", name: $0.name ?? "", photo: $0.photo, character: $0.character)
            },
            trailers: meta.trailers?.map {
                Trailer(
                    id: $0.id ?? $0.source ?? $0.ytId ?? $0.youtubeId ?? "",
                    title: $0.title ?? $0.name,
                    thumbnail: $0.thumbnail,
                    youtubeId: $0.youtubeId ?? $0.ytId ?? $0.source
                )
            },
            trailerStreams: trailerStreams,
            videos: videos,
            seasons: seasons ?? Self.seasons(from: videos),
            links: meta.links?.map {
                MetaLink(name: $0.name ?? "", category: $0.category, url: $0.url ?? "")
            }
        )
    }

    private static func seasons(from videos: [MetaVideo]?) -> [Season]? {
        guard let videos else { return nil }
        let grouped = Dictionary(grouping: videos.filter { $0.season != nil }) { $0.season ?? 0 }
        let seasons = grouped.keys.sorted().map { number in
            Season(
                id: String(number),
                number: number,
                name: "Season \(number)",
                episodes: grouped[number]?.sorted { ($0.episode ?? 0) < ($1.episode ?? 0) }
            )
        }
        return seasons.isEmpty ? nil : seasons
    }

    private static func firstNonBlank(_ values: String?...) -> String? {
        values.first { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? nil
    }

    private static func resolve(_ path: String?, base: String) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return removeUnsupportedImageProxy(path)
        }
        guard !base.isEmpty else { return path }
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return "\(trimmedBase)/\(trimmedPath)"
    }

    private static func removeUnsupportedImageProxy(_ urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased(),
              host.hasSuffix("top-posters.com") else {
            return urlString
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?
            .first { $0.name == "fallback_url" || $0.name == "fallback" }?
            .value
            .flatMap { decodeNestedURL($0) }
    }

    private static func decodeNestedURL(_ value: String) -> String? {
        var decoded = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !decoded.isEmpty else { return nil }

        for _ in 0..<3 {
            guard let next = decoded.removingPercentEncoding,
                  next != decoded else {
                break
            }
            decoded = next
        }
        return decoded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : decoded
    }
}
