import Foundation

/// Pre-fetches streams for a given media item so that when the user taps play
/// the streams are already available and playback can start without a network round-trip.
///
/// Cache is persisted to disk so it survives app restarts and background evictions.
/// TTL is 60 minutes — Stremio-style stream URLs are stable for hours.
public actor StreamWarmupRepository {
    public static let shared = StreamWarmupRepository()

    // In-memory mirror of the disk cache for fast reads.
    private var cache: [String: [StreamItem]] = [:]
    private var timestamps: [String: Date] = [:]
    private var inFlight: Set<String> = []
    private let cacheTTL: TimeInterval = 3600  // 60 min

    private let streamService = StreamService.shared

    private static let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LunaStreamWarmup", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("streams.json")
    }()

    private init() {
        // Load the persisted cache synchronously at init time.
        // Using a nonisolated helper avoids the actor-isolation requirement in init.
        let loaded = Self.loadDiskEntries()
        let now = Date()
        for entry in loaded where now.timeIntervalSince(entry.timestamp) < 3600 {
            cache[entry.key] = entry.streams
            timestamps[entry.key] = entry.timestamp
        }
    }

    // MARK: - Public API

    /// Fire-and-forget: fetch streams for `id` in the background.
    /// Safe to call from any context; duplicate calls within TTL are no-ops.
    public func warmup(type: String, id: String, addons: [AddonManifest]) async {
        let key = cacheKey(type: type, id: id)
        if let ts = timestamps[key], Date().timeIntervalSince(ts) < cacheTTL { return }
        guard !inFlight.contains(key) else { return }
        inFlight.insert(key)
        defer { inFlight.remove(key) }

        let eligible = addons.filter {
            $0.hasResource("stream") &&
            ($0.types?.contains(type) ?? false) &&
            $0.transportUrl != nil
        }
        guard !eligible.isEmpty else { return }

        var collected: [StreamItem] = []
        await withTaskGroup(of: [StreamItem].self) { group in
            for addon in eligible {
                guard let baseURL = addon.transportUrl else { continue }
                group.addTask {
                    guard let raw = try? await self.streamService.fetchStreams(
                        type: type, id: id, baseURL: baseURL
                    ) else { return [] }
                    return raw.compactMap { stream -> StreamItem? in
                        let item = StreamItem(
                            name: stream.name, title: stream.title,
                            description: stream.description, url: stream.url,
                            infoHash: stream.infoHash, fileIdx: stream.fileIdx,
                            externalUrl: stream.externalUrl, ytId: stream.ytId,
                            playerFrameUrl: stream.playerFrameUrl, sources: stream.sources,
                            sourceName: stream.sourceName,
                            addonName: addon.name, addonId: addon.id,
                            behaviorHints: stream.behaviorHints, subtitles: stream.subtitles
                        )
                        return StreamMatchGuard.shouldKeep(item, type: type, id: id) ? item : nil
                    }
                }
            }
            for await batch in group { collected.append(contentsOf: batch) }
        }

        if !collected.isEmpty {
            cache[key] = collected
            timestamps[key] = Date()
            saveToDisk()
        }
    }

    /// Returns cached streams if still fresh. Survives app restarts via disk persistence.
    public func getCached(type: String, id: String) -> [StreamItem]? {
        let key = cacheKey(type: type, id: id)
        guard let ts = timestamps[key], Date().timeIntervalSince(ts) < cacheTTL else { return nil }
        return cache[key]
    }

    /// Evict a specific entry (e.g. after profile switch or forced refresh).
    public func evict(type: String, id: String) {
        let key = cacheKey(type: type, id: id)
        cache.removeValue(forKey: key)
        timestamps.removeValue(forKey: key)
        saveToDisk()
    }

    /// Remove all entries older than TTL (called opportunistically on warmup).
    public func pruneExpired() {
        let now = Date()
        let staleKeys = timestamps.filter { now.timeIntervalSince($0.value) >= cacheTTL }.map(\.key)
        staleKeys.forEach { cache.removeValue(forKey: $0); timestamps.removeValue(forKey: $0) }
        if !staleKeys.isEmpty { saveToDisk() }
    }

    // MARK: - Disk persistence

    private struct DiskEntry: Codable {
        let key: String
        let streams: [StreamItem]
        let timestamp: Date
    }

    private func saveToDisk() {
        let entries = cache.compactMap { key, streams -> DiskEntry? in
            guard let ts = timestamps[key] else { return nil }
            return DiskEntry(key: key, streams: streams, timestamp: ts)
        }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: Self.cacheURL, options: .atomic)
    }

    private static func loadDiskEntries() -> [DiskEntry] {
        guard let data = try? Data(contentsOf: cacheURL),
              let entries = try? JSONDecoder().decode([DiskEntry].self, from: data) else { return [] }
        return entries
    }

    private func cacheKey(type: String, id: String) -> String { "\(type):\(id)" }
}
