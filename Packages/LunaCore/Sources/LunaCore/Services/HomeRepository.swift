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
            let incomplete = Array(
                progress
                    .filter { !$0.completed && $0.positionSeconds > 0 }
                    .sorted { $0.updatedAt > $1.updatedAt }
                    .prefix(10)
            )

            let metaService = MetaService.shared
            // Snapshot the enabled addons on the MainActor before entering the task group
            let addonRepo = AddonRepository.shared
            var items: [ContinueWatchingItem] = []

            await withTaskGroup(of: ContinueWatchingItem.self) { group in
                for entry in incomplete {
                    // Find addons that support the meta resource for this media type
                    let addons = addonRepo.findAddonWithMetaResource(type: entry.mediaType)
                    group.addTask {
                        var meta: MetaDetail?
                        for addon in addons {
                            guard let baseURL = addon.transportUrl else { continue }
                            if let fetched = try? await metaService.fetchMeta(
                                type: entry.mediaType,
                                id: entry.mediaId,
                                baseURL: baseURL
                            ) {
                                meta = fetched
                                break
                            }
                        }
                        return ContinueWatchingItem(
                            mediaId: entry.mediaId,
                            mediaType: entry.mediaType,
                            name: meta?.name ?? entry.mediaId,
                            poster: meta?.poster,
                            resumePositionMs: entry.positionSeconds * 1000,
                            durationMs: entry.durationSeconds * 1000,
                            progressFraction: entry.progressFraction
                        )
                    }
                }
                for await item in group {
                    items.append(item)
                }
            }

            // Re-sort to match original updatedAt order (task group doesn't preserve order)
            let sortedIds = incomplete.map(\.mediaId)
            continueWatchingItems = items.sorted {
                let ia = sortedIds.firstIndex(of: $0.mediaId) ?? Int.max
                let ib = sortedIds.firstIndex(of: $1.mediaId) ?? Int.max
                return ia < ib
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
