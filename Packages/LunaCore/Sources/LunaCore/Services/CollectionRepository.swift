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
            .filter { $0.collection_id == collection.id }
            .sorted { $0.sort_order < $1.sort_order }
    }

    public func catalogs(for folder: DBFolder) -> [DBFolderCatalog] {
        folderCatalogs.filter { $0.folder_id == folder.id }
    }

    public func sources(for folder: DBFolder) -> [DBFolderSource] {
        folderSources
            .filter { $0.folder_id == folder.id }
            .sorted { ($0.sort_order ?? 0) < ($1.sort_order ?? 0) }
    }
}
