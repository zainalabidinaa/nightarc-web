import Foundation

public struct LastPlaybackSource: Codable, Sendable, Equatable {
    public let sourceUrl: String
    public let sourceHeaders: [String: String]?
    public let providerName: String?
    public let streamTitle: String?
    public let savedAt: Date

    public init(
        sourceUrl: String,
        sourceHeaders: [String: String]? = nil,
        providerName: String? = nil,
        streamTitle: String? = nil,
        savedAt: Date = Date()
    ) {
        self.sourceUrl = sourceUrl
        self.sourceHeaders = sourceHeaders
        self.providerName = providerName
        self.streamTitle = streamTitle
        self.savedAt = savedAt
    }
}

public extension LastPlaybackSource {
    static let maxAge: TimeInterval = 30 * 60

    var isExpired: Bool {
        Date().timeIntervalSince(savedAt) > Self.maxAge
    }
}

@MainActor
public final class LastPlaybackSourceStore {
    public static let shared = LastPlaybackSourceStore()

    private let defaults: UserDefaults
    private let prefix = "moonlit.lastPlaybackSource"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func save(_ source: LastPlaybackSource, profileId: String, mediaId: String) {
        guard let data = try? JSONEncoder().encode(source) else { return }
        defaults.set(data, forKey: key(profileId: profileId, mediaId: mediaId))
    }

    public func source(profileId: String, mediaId: String) -> LastPlaybackSource? {
        guard let data = defaults.data(forKey: key(profileId: profileId, mediaId: mediaId)) else {
            return nil
        }
        return try? JSONDecoder().decode(LastPlaybackSource.self, from: data)
    }

    /// Remove a cached source so the watchdog doesn't retry the same stale URL.
    public func evict(profileId: String, mediaId: String) {
        defaults.removeObject(forKey: key(profileId: profileId, mediaId: mediaId))
    }

    public func clearAll() {
        for k in defaults.dictionaryRepresentation().keys where k.hasPrefix(prefix) {
            defaults.removeObject(forKey: k)
        }
    }

    private func key(profileId: String, mediaId: String) -> String {
        let normalizedMediaId = mediaId.removingPercentEncoding ?? mediaId
        return "\(prefix).\(profileId).\(normalizedMediaId)"
    }
}
