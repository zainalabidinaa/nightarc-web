import Foundation

public actor SubtitleService {
    public static let shared = SubtitleService()
    private let client = StremioHTTPClient.shared

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
            return (response.subtitles ?? []).map { raw in
                SubtitleItem(
                    id: raw.id ?? UUID().uuidString,
                    url: raw.url ?? "",
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

        await withTaskGroup(of: [SubtitleItem]?.self) { group in
            for addon in addons {
                guard addon.hasResource("subtitles"),
                      let baseURL = addon.transportUrl else { continue }

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

        return allSubtitles
    }
}
