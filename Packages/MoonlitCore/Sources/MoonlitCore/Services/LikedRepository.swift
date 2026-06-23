import Foundation

public struct LikedItem: Codable, Identifiable, Sendable {
    public let id: String
    public let profileId: String
    public let mediaId: String
    public let mediaType: String
    public let name: String
    public let poster: String?
    public let tmdbId: Int?
    public let likedAt: Date

    public init(
        mediaId: String,
        mediaType: String,
        name: String,
        poster: String?,
        tmdbId: Int?,
        profileId: String = "",
        id: String? = nil,
        likedAt: Date = Date()
    ) {
        self.id = id ?? mediaId
        self.profileId = profileId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.tmdbId = tmdbId
        self.likedAt = likedAt
    }
}

@MainActor
public final class LikedRepository: ObservableObject {
    public static let shared = LikedRepository()

    @Published public private(set) var likedItems: [LikedItem] = []

    private let syncService = SyncService.shared
    private var currentProfileId: String = ""

    private init() {}

    public func isLiked(_ mediaId: String) -> Bool {
        likedItems.contains { $0.mediaId == mediaId }
    }

    /// Loads likes for a profile: shows the local cache instantly, then pulls the
    /// account copy from Supabase so likes stay in sync across devices and platforms.
    public func loadLiked(profileId: String) async {
        currentProfileId = profileId
        likedItems = loadFromLocal(profileId: profileId)
        do {
            let remote = try await syncService.pullLikedItems(profileId: profileId)
            likedItems = remote
            saveToLocal(remote, profileId: profileId)
        } catch {
            // Keep the local cache on a transient failure.
        }
    }

    public func addLiked(_ item: LikedItem, profileId: String) async {
        guard !isLiked(item.mediaId) else { return }
        currentProfileId = profileId
        let stamped = LikedItem(
            mediaId: item.mediaId,
            mediaType: item.mediaType,
            name: item.name,
            poster: item.poster,
            tmdbId: item.tmdbId,
            profileId: profileId
        )
        likedItems.insert(stamped, at: 0)
        saveToLocal(likedItems, profileId: profileId)
        try? await syncService.pushLikedItem(item: stamped)
    }

    public func removeLiked(mediaId: String, profileId: String) async {
        currentProfileId = profileId
        likedItems.removeAll { $0.mediaId == mediaId }
        saveToLocal(likedItems, profileId: profileId)
        try? await syncService.deleteLikedItem(profileId: profileId, mediaId: mediaId)
    }

    // MARK: - Local cache (per-profile, offline fallback)

    private func storageKey(_ profileId: String) -> String { "moonlit.liked.items.\(profileId)" }

    private func loadFromLocal(profileId: String) -> [LikedItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey(profileId)),
              let items = try? JSONDecoder().decode([LikedItem].self, from: data) else { return [] }
        return items
    }

    private func saveToLocal(_ items: [LikedItem], profileId: String) {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: storageKey(profileId))
    }
}
