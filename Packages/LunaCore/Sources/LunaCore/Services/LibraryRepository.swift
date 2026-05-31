import Foundation

@MainActor
public class LibraryRepository: ObservableObject {
    public static let shared = LibraryRepository()

    @Published public var libraryItems: [LibraryItem] = []
    @Published public var isLoading = false

    private let syncService = SyncService.shared

    private init() {}

    public func loadLibrary(profileId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            libraryItems = try await syncService.pullLibraryItems(profileId: profileId)
        } catch {
            libraryItems = []
        }
    }

    public func addToLibrary(
        profileId: String,
        mediaId: String,
        mediaType: String,
        name: String? = nil,
        poster: String? = nil
    ) async {
        guard !libraryItems.contains(where: { $0.mediaId == mediaId }) else { return }

        let item = LibraryItem(
            id: UUID().uuidString,
            profileId: profileId,
            mediaId: mediaId,
            mediaType: mediaType,
            name: name,
            poster: poster,
            savedAt: Date()
        )

        libraryItems.insert(item, at: 0)
        try? await syncService.pushLibraryItem(item: item)
    }

    public func removeFromLibrary(profileId: String, mediaId: String) async {
        libraryItems.removeAll { $0.mediaId == mediaId }
        try? await syncService.deleteLibraryItem(profileId: profileId, mediaId: mediaId)
    }

    public func isInLibrary(mediaId: String) -> Bool {
        libraryItems.contains(where: { $0.mediaId == mediaId })
    }

    public func toggleLibrary(
        profileId: String,
        mediaId: String,
        mediaType: String,
        name: String? = nil,
        poster: String? = nil
    ) async {
        if isInLibrary(mediaId: mediaId) {
            await removeFromLibrary(profileId: profileId, mediaId: mediaId)
        } else {
            await addToLibrary(profileId: profileId, mediaId: mediaId, mediaType: mediaType, name: name, poster: poster)
        }
    }

    public var libraryMediaIds: Set<String> {
        Set(libraryItems.map { $0.mediaId })
    }
}
