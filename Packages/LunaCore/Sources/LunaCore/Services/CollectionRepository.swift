import Foundation

@MainActor
public class CollectionRepository: ObservableObject {
    public static let shared = CollectionRepository()

    @Published public var collections: [DBCollection] = []
    @Published public var folders: [DBFolder] = []
    @Published public var folderCatalogs: [DBFolderCatalog] = []
    @Published public var folderSources: [DBFolderSource] = []
    @Published public var isLoading = false

    private let client = SupabaseClient.shared

    private init() {}

    public func loadOrganizer(
        bundledData: Data,
        remoteURL: URL? = nil,
        store: CollectionOrganizerStore = .shared
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            apply(try store.cachedOrBundledLayout(bundledData: bundledData))
        } catch {
            collections = []
            folders = []
            folderCatalogs = []
            folderSources = []
        }

        if let refreshed = await store.refresh(remoteURL: remoteURL) {
            apply(refreshed)
        }
    }

    public func apply(_ organized: OrganizedCollections) {
        collections = organized.collections
        folders = organized.folders
        folderCatalogs = organized.folderCatalogs
        folderSources = organized.folderSources
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let c: [DBCollection] = client.select(from: "collections", order: "sort_order.asc")
            async let f: [DBFolder] = client.select(from: "folders", order: "sort_order.asc")
            async let fc: [DBFolderCatalog] = client.select(from: "folder_catalogs")
            async let fs: [DBFolderSource] = client.select(from: "folder_sources", order: "sort_order.asc")
            collections = try await c
            folders = try await f
            folderCatalogs = try await fc
            folderSources = try await fs
        } catch {
            // keep existing data on error
        }
    }

    public func folders(for collection: DBCollection) -> [DBFolder] {
        folders
            .filter { $0.collectionId == collection.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    public func catalogs(for folder: DBFolder) -> [DBFolderCatalog] {
        folderCatalogs.filter { $0.folderId == folder.id }
    }

    public func sources(for folder: DBFolder) -> [DBFolderSource] {
        folderSources
            .filter { $0.folderId == folder.id }
            .sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
    }
}
