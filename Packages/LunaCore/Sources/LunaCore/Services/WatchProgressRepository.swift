import Foundation

@MainActor
public class WatchProgressRepository: ObservableObject {
    public static let shared = WatchProgressRepository()

    @Published public var progressEntries: [WatchProgressEntry] = []
    @Published public var watchedItems: [WatchedItem] = []

    private let syncService = SyncService.shared

    private init() {}

    public func loadAll(profileId: String) async {
        do {
            progressEntries = try await syncService.pullWatchProgress(profileId: profileId)
            watchedItems = try await syncService.pullWatchedItems(profileId: profileId)
        } catch {
            progressEntries = []
            watchedItems = []
        }
    }

    public func updateProgress(
        profileId: String,
        mediaId: String,
        mediaType: String,
        positionSeconds: Double,
        durationSeconds: Double,
        completed: Bool = false,
        name: String? = nil,
        poster: String? = nil,
        parentMetaId: String? = nil,
        season: Int? = nil,
        episode: Int? = nil
    ) async {
        let existing = progressEntries.first(where: { $0.mediaId == mediaId })
        let existingId = existing?.id ?? UUID().uuidString

        let entry = WatchProgressEntry(
            id: existingId,
            profileId: profileId,
            mediaId: mediaId,
            mediaType: mediaType,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            completed: completed,
            updatedAt: Date(),
            name: name ?? existing?.name,
            poster: poster ?? existing?.poster,
            parentMetaId: parentMetaId ?? existing?.parentMetaId,
            season: season ?? existing?.season,
            episode: episode ?? existing?.episode
        )

        if let idx = progressEntries.firstIndex(where: { $0.mediaId == mediaId }) {
            progressEntries[idx] = entry
        } else {
            progressEntries.append(entry)
        }

        try? await syncService.pushWatchProgress(entry: entry)
    }

    public func getProgress(mediaId: String) -> WatchProgressEntry? {
        progressEntries.first(where: { $0.mediaId == mediaId })
    }

    public func markWatched(
        profileId: String,
        mediaId: String,
        mediaType: String,
        name: String? = nil,
        poster: String? = nil,
        season: Int? = nil,
        episode: Int? = nil
    ) async {
        let item = WatchedItem(
            id: UUID().uuidString,
            profileId: profileId,
            mediaId: mediaId,
            mediaType: mediaType,
            name: name,
            poster: poster,
            season: season,
            episode: episode,
            markedAt: Date()
        )
        watchedItems.append(item)
        try? await syncService.pushWatchedItem(item: item)
    }

    public func markUnwatched(mediaId: String) async {
        guard let item = watchedItems.first(where: { $0.mediaId == mediaId }) else { return }
        try? await SupabaseClient.shared.delete(
            from: "watched_items",
            where: ["id": item.id]
        )
        watchedItems.removeAll { $0.mediaId == mediaId }
    }

    public func isWatched(mediaId: String) -> Bool {
        watchedItems.contains(where: { $0.mediaId == mediaId })
    }

    public var watchedMediaIds: Set<String> {
        Set(watchedItems.map { $0.mediaId })
    }
}
