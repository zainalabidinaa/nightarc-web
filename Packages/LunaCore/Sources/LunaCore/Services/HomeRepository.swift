import Foundation

@MainActor
public class HomeRepository: ObservableObject {
    public static let shared = HomeRepository()

    @Published public var continueWatchingItems: [ContinueWatchingItem] = []
    @Published public var isLoadingContinueWatching = false

    private let syncService = SyncService()

    private init() {}

    public func loadContinueWatching(profileId: String) async {
        isLoadingContinueWatching = true
        defer { isLoadingContinueWatching = false }

        do {
            let progress = try await syncService.pullWatchProgress(profileId: profileId)
            let incomplete = progress.filter { !$0.completed && $0.positionSeconds > 0 }
            let sorted = incomplete.sorted { $0.updatedAt > $1.updatedAt }

            continueWatchingItems = sorted.map { entry in
                ContinueWatchingItem(
                    mediaId: entry.mediaId,
                    mediaType: entry.mediaType,
                    name: entry.mediaId,
                    resumePositionMs: entry.positionSeconds * 1000,
                    durationMs: entry.durationSeconds * 1000,
                    progressFraction: entry.progressFraction
                )
            }
        } catch {
            continueWatchingItems = []
        }
    }

    public func loadCatalogRows(addons: [AddonManifest]) async -> [CatalogRow] {
        await CatalogRepository.shared.loadAllCatalogs(addons: addons)
        return CatalogRepository.shared.catalogRows
    }
}
