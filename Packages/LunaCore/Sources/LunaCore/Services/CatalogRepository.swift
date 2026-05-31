import Foundation

@MainActor
public class CatalogRepository: ObservableObject {
    public static let shared = CatalogRepository()

    @Published public var catalogRows: [CatalogRow] = []
    @Published public var isLoading = false

    private let catalogService = CatalogService.shared

    private init() {}

    public func loadAllCatalogs(addons: [AddonManifest]) async {
        isLoading = true
        defer { isLoading = false }

        var rows: [CatalogRow] = []

        await withTaskGroup(of: CatalogRow?.self) { group in
            for addon in addons {
                guard let catalogs = addon.catalogs,
                      let baseURL = addon.transportUrl else { continue }

                for catalog in catalogs {
                    group.addTask {
                        do {
                            let query = CatalogService.StremioCatalogQuery(
                                type: catalog.type,
                                id: catalog.id,
                                baseURL: baseURL
                            )
                            let items = try await self.catalogService.fetchCatalog(query: query)
                            guard !items.isEmpty else { return nil }
                            return CatalogRow(
                                id: "\(addon.id)_\(catalog.id)",
                                title: catalog.name ?? catalog.id.capitalized,
                                items: items,
                                addonName: addon.name,
                                page: 0,
                                hasMore: items.count >= 50
                            )
                        } catch {
                            return nil
                        }
                    }
                }
            }

            for await row in group {
                if let row = row {
                    rows.append(row)
                }
            }
        }

        self.catalogRows = rows
    }

    public func loadFromCollections(
        collectionRepo: CollectionRepository,
        addons: [AddonManifest]
    ) async {
        isLoading = true
        defer { isLoading = false }

        guard let baseURL = addons.first(where: {
            $0.transportUrl?.contains("aiometadata") == true || $0.id.contains("aio")
        })?.transportUrl ?? addons.first?.transportUrl else { return }

        var rows: [CatalogRow] = []

        for collection in collectionRepo.collections {
            for folder in collectionRepo.folders(for: collection) {
                let sources = collectionRepo.catalogs(for: folder)
                guard !sources.isEmpty else { continue }

                var items: [MetaPreview] = []
                await withTaskGroup(of: [MetaPreview].self) { group in
                    for source in sources {
                        group.addTask {
                            do {
                                let type = source.media_type == "all" ? "movie" : source.media_type
                                var extras: [String: String] = [:]
                                if let genre = source.genre, genre != "None" {
                                    extras["genre"] = genre
                                }
                                let query = CatalogService.StremioCatalogQuery(
                                    type: type,
                                    id: source.catalog_id,
                                    baseURL: baseURL,
                                    extras: extras
                                )
                                return try await self.catalogService.fetchCatalog(query: query)
                            } catch {
                                return []
                            }
                        }
                    }
                    for await result in group {
                        items.append(contentsOf: result)
                    }
                }

                guard !items.isEmpty else { continue }

                rows.append(CatalogRow(
                    id: "folder_\(folder.id)",
                    title: folder.name,
                    items: items,
                    addonName: "AIOMetadata",
                    page: 0,
                    hasMore: false
                ))
            }
        }

        self.catalogRows = rows
    }

    public func loadMore(rowId: String, addons: [AddonManifest]) async {
        guard let index = catalogRows.firstIndex(where: { $0.id == rowId }),
              catalogRows[index].hasMore else { return }

        let row = catalogRows[index]
        let nextPage = row.page + 1

        let components = rowId.split(separator: "_").map(String.init)
        guard components.count >= 2 else { return }
        let addonId = components[0]
        let catalogId = components.dropFirst().joined(separator: "_")

        guard let addon = addons.first(where: { $0.id == addonId }),
              let baseURL = addon.transportUrl,
              let catalog = addon.catalogs?.first(where: { $0.id == catalogId }) else { return }

        do {
            let query = CatalogService.StremioCatalogQuery(
                type: catalog.type,
                id: catalog.id,
                baseURL: baseURL,
                extras: ["skip": String(nextPage * 50)]
            )
            let items = try await catalogService.fetchCatalog(query: query)
            if !items.isEmpty {
                catalogRows[index].items.append(contentsOf: items)
                catalogRows[index].page = nextPage
                catalogRows[index].hasMore = items.count >= 50
            } else {
                catalogRows[index].hasMore = false
            }
        } catch {
            catalogRows[index].hasMore = false
        }
    }
}
