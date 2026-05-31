import Foundation

@MainActor
public class StreamRepository: ObservableObject {
    public static let shared = StreamRepository()

    @Published public var streams: [StreamItem] = []
    @Published public var isLoading = false

    private let streamService = StreamService.shared

    private init() {}

    public func fetchStreams(type: String, id: String, addons: [AddonManifest]) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let found = try await streamService.fetchStreamsFromAddons(type: type, id: id, addons: addons)
            self.streams = found
        } catch {
            self.streams = []
        }
    }

    public func fetchStreamsFromSingleAddon(type: String, id: String, addon: AddonManifest) async throws -> [StreamItem] {
        guard let baseURL = addon.transportUrl else { return [] }
        let raw = try await streamService.fetchStreams(type: type, id: id, baseURL: baseURL)
        return raw.map { stream in
            StreamItem(
                name: stream.name, title: stream.title, description: stream.description,
                url: stream.url, infoHash: stream.infoHash, fileIdx: stream.fileIdx,
                externalUrl: stream.externalUrl, sources: stream.sources,
                sourceName: stream.sourceName, addonName: addon.name, addonId: addon.id,
                behaviorHints: stream.behaviorHints
            )
        }
    }

    public func bestStream(for type: String, id: String, from addons: [AddonManifest]) async -> StreamItem? {
        await fetchStreams(type: type, id: id, addons: addons)
        return streams.first { $0.hasDirectUrl }
            ?? streams.first
    }
}
