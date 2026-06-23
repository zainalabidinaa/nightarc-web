import Foundation

public final class SubtitleService: @unchecked Sendable {
    public static let shared = SubtitleService()
    private let client = StremioHTTPClient.shared

    private static let openSubtitlesProURL = "https://opensubtitlesv3-pro.dexter21767.com/eyJsYW5ncyI6WyJlbmdsaXNoIl0sInNvdXJjZSI6ImFsbCIsImFpVHJhbnNsYXRlZCI6ZmFsc2UsImF1dG9BZGp1c3RtZW50IjpmYWxzZX0="
    private static let openSubtitlesV3URL = "https://opensubtitles-v3.strem.io"

    private init() {}

    public func fetchSubtitles(type: String, id: String, baseURL: String) async throws -> [SubtitleItem] {
        let url = "\(baseURL)/subtitles/\(type)/\(id).json"

        struct RawSubtitle: Codable {
            let id: String?
            let url: String?
            let lang: String?
            let name: String?
        }
        struct SubtitleResponse: Codable {
            let subtitles: [RawSubtitle]?
        }

        do {
            let response: SubtitleResponse = try await client.getJSON(url: url, type: SubtitleResponse.self)
            return (response.subtitles ?? []).compactMap { raw in
                guard let url = raw.url, !url.isEmpty else { return nil }
                return SubtitleItem(
                    id: raw.id ?? UUID().uuidString,
                    url: url,
                    lang: raw.lang ?? "unknown",
                    name: raw.name
                )
            }
        } catch {
            throw error
        }
    }

    public func fetchSubtitlesFromAddons(
        type: String,
        id: String,
        addons: [AddonManifest]
    ) async throws -> [SubtitleItem] {
        var allSubtitles: [SubtitleItem] = []

        var baseURLs = addons.compactMap { addon -> String? in
            guard addon.hasResource("subtitles"), let url = addon.transportUrl else { return nil }
            return url
        }
        baseURLs.append(Self.openSubtitlesProURL)
        baseURLs.append(Self.openSubtitlesV3URL)

        let uniqueURLs = Array(Set(baseURLs))

        await withTaskGroup(of: [SubtitleItem]?.self) { group in
            for baseURL in uniqueURLs {
                group.addTask {
                    do {
                        return try await self.fetchSubtitles(type: type, id: id, baseURL: baseURL)
                    } catch {
                        return nil
                    }
                }
            }

            for await result in group {
                if let subtitles = result {
                    allSubtitles.append(contentsOf: subtitles)
                }
            }
        }

        var seen = Set<String>()
        return allSubtitles.filter { seen.insert($0.url).inserted }
    }
}
