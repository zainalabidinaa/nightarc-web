import Foundation

@MainActor
public final class StreamWarmupRepository {
    public static let shared = StreamWarmupRepository()

    private var cache: [String: [StreamItem]] = [:]
    private var timestamps: [String: Date] = [:]
    private let cacheTTL: TimeInterval = 300

    private init() {}

    public func warmup(type: String, id: String, addons: [AddonManifest]) async {
        let key = "\(type):\(id)"
        if let ts = timestamps[key], Date().timeIntervalSince(ts) < cacheTTL {
            return
        }
        await StreamRepository.shared.fetchStreams(type: type, id: id, addons: addons)
        cache[key] = StreamRepository.shared.streams
        timestamps[key] = Date()
    }

    public func getCached(type: String, id: String) -> [StreamItem]? {
        let key = "\(type):\(id)"
        guard let ts = timestamps[key], Date().timeIntervalSince(ts) < cacheTTL else {
            return nil
        }
        return cache[key]
    }
}
