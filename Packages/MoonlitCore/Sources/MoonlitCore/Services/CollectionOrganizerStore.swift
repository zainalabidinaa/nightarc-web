import Foundation

public final class CollectionOrganizerStore: @unchecked Sendable {
    public static let shared = CollectionOrganizerStore()

    private let cacheURL: URL
    private let session: URLSession

    public convenience init() {
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MoonlitHomeLayout", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        self.init(
            cacheURL: cacheDir.appendingPathComponent("home-organizer.json"),
            session: .shared
        )
    }

    init(cacheURL: URL, session: URLSession) {
        self.cacheURL = cacheURL
        self.session = session
    }

    public func cachedOrBundledLayout(bundledData: Data) throws -> OrganizedCollections {
        // The bundle is the authoritative full set. A cached layout (a previous, possibly
        // partial, Supabase response) is merged ON TOP as an overlay — it must never
        // replace the bundle outright, or bundle-only collections silently disappear.
        let bundled = try CollectionOrganizerParser.parse(jsonData: bundledData)
        if let cachedData = try? Data(contentsOf: cacheURL),
           let cached = try? CollectionOrganizerParser.parse(jsonData: cachedData) {
            return OrganizedCollections.merged(base: bundled, overlay: cached)
        }
        return bundled
    }

    public func refresh(remoteURL: URL?) async -> OrganizedCollections? {
        guard let remoteURL else { return nil }
        do {
            let (data, response) = try await session.data(from: remoteURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let parsed = try CollectionOrganizerParser.parse(jsonData: data)
            try? data.write(to: cacheURL, options: .atomic)
            return parsed
        } catch {
            return nil
        }
    }
}
