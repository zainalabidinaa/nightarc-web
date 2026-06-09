import Foundation

public struct LikedItem: Codable, Identifiable, Sendable {
    public let id: String
    public let mediaId: String
    public let mediaType: String
    public let name: String
    public let poster: String?
    public let tmdbId: Int?
    public let likedAt: Date

    public init(mediaId: String, mediaType: String, name: String, poster: String?, tmdbId: Int?) {
        self.id = mediaId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.tmdbId = tmdbId
        self.likedAt = Date()
    }
}

@MainActor
public final class LikedRepository: ObservableObject {
    public static let shared = LikedRepository()

    @Published public private(set) var likedItems: [LikedItem] = []

    private let storageKey = "luna.liked.items"

    private init() { loadFromLocal() }

    public func isLiked(_ mediaId: String) -> Bool {
        likedItems.contains { $0.mediaId == mediaId }
    }

    public func addLiked(_ item: LikedItem) async {
        guard !isLiked(item.mediaId) else { return }
        likedItems.insert(item, at: 0)
        saveToLocal()
    }

    public func removeLiked(mediaId: String) async {
        likedItems.removeAll { $0.mediaId == mediaId }
        saveToLocal()
    }

    public func loadLibrary() async {
        loadFromLocal()
    }

    private func loadFromLocal() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([LikedItem].self, from: data) else { return }
        likedItems = items
    }

    private func saveToLocal() {
        let data = try? JSONEncoder().encode(likedItems)
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
