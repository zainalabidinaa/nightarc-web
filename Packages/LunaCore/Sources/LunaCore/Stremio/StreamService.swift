import Foundation

public actor StreamService {
    public static let shared = StreamService()
    private let client = StremioHTTPClient.shared

    private init() {}

    public func fetchStreams(type: String, id: String, baseURL: String) async throws -> [StreamItem] {
        let url = "\(baseURL)/stream/\(type)/\(id).json"

        struct RawStream: Codable {
            let name: String?
            let title: String?
            let description: String?
            let url: String?
            let infoHash: String?
            let fileIdx: Int?
            let externalUrl: String?
            let sources: [String]?
            let behaviorHints: RawBehaviorHints?
        }
        struct RawBehaviorHints: Codable {
            let notWebReady: Bool?
            let bingeGroup: String?
            let proxyHeaders: RawProxyHeaders?
        }
        struct RawProxyHeaders: Codable {
            let request: [String: String]?
            let response: [String: String]?
        }
        struct StreamResponse: Codable {
            let streams: [RawStream]?
        }

        do {
            let response: StreamResponse = try await client.getJSON(url: url, type: StreamResponse.self)
            return (response.streams ?? []).map { raw in
                StreamItem(
                    name: raw.name,
                    title: raw.title,
                    description: raw.description,
                    url: raw.url,
                    infoHash: raw.infoHash,
                    fileIdx: raw.fileIdx,
                    externalUrl: raw.externalUrl,
                    sources: raw.sources,
                    sourceName: nil,
                    addonName: nil,
                    addonId: nil,
                    behaviorHints: raw.behaviorHints.map {
                        StreamBehaviorHints(
                            notWebReady: $0.notWebReady,
                            bingeGroup: $0.bingeGroup,
                            proxyHeaders: $0.proxyHeaders.map {
                                StreamProxyHeaders(
                                    request: $0.request,
                                    response: $0.response
                                )
                            }
                        )
                    }
                )
            }
        } catch {
            throw error
        }
    }

    public func fetchStreamsFromAddons(
        type: String,
        id: String,
        addons: [AddonManifest]
    ) async throws -> [StreamItem] {
        var allStreams: [StreamItem] = []

        await withTaskGroup(of: (String, [StreamItem])?.self) { group in
            for addon in addons {
                guard addon.hasResource("stream"),
                      let types = addon.types,
                      types.contains(type),
                      let baseURL = addon.transportUrl else { continue }

                group.addTask {
                    do {
                        let streams = try await self.fetchStreams(type: type, id: id, baseURL: baseURL)
                        let enriched = streams.map { stream in
                            StreamItem(
                                name: stream.name,
                                title: stream.title,
                                description: stream.description,
                                url: stream.url,
                                infoHash: stream.infoHash,
                                fileIdx: stream.fileIdx,
                                externalUrl: stream.externalUrl,
                                sources: stream.sources,
                                sourceName: stream.sourceName,
                                addonName: addon.name,
                                addonId: addon.id,
                                behaviorHints: stream.behaviorHints
                            )
                        }
                        return (addon.name, enriched)
                    } catch {
                        return nil
                    }
                }
            }

            for await result in group {
                if let (_, streams) = result {
                    allStreams.append(contentsOf: streams)
                }
            }
        }

        return allStreams
    }
}
