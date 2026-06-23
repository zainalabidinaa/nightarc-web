import Foundation

public final class CatalogResponseCache: @unchecked Sendable {
    public static let shared = CatalogResponseCache()

    private let ttl: TimeInterval = 30 * 60
    private let lock = NSLock()
    private var memory: [String: Entry] = [:]
    private let diskURL: URL = {
        let dir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MoonlitCatalogCache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("catalogs.json")
    }()

    private struct Entry: Codable {
        var data: Data
        var timestamp: Date
    }

    private init() {
        loadFromDisk()
    }

    private func loadFromDisk() {
        lock.lock()
        defer { lock.unlock() }
        guard let fileData = try? Data(contentsOf: diskURL),
              let dict = try? JSONDecoder().decode([String: Entry].self, from: fileData) else { return }
        memory = dict
    }

    private func saveToDisk() {
        let snapshot = memory
        DispatchQueue.global(qos: .utility).async { [lock, diskURL] in
            lock.lock()
            guard let data = try? JSONEncoder().encode(snapshot) else { lock.unlock(); return }
            lock.unlock()
            try? data.write(to: diskURL, options: .atomic)
        }
    }

    public func get(key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = memory[key] else { return nil }
        guard Date().timeIntervalSince(entry.timestamp) < ttl else {
            memory[key] = nil
            return nil
        }
        return entry.data
    }

    public func set(key: String, data: Data) {
        lock.lock()
        memory[key] = Entry(data: data, timestamp: Date())
        let now = Date()
        memory = memory.filter { now.timeIntervalSince($0.value.timestamp) < ttl }
        lock.unlock()
        saveToDisk()
    }

    public func clear() {
        lock.lock()
        memory = [:]
        lock.unlock()
        try? FileManager.default.removeItem(at: diskURL)
    }
}
