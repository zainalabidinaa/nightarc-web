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
                let normalizedSources = collectionRepo.catalogs(for: folder)
                let rawSources = collectionRepo.sources(for: folder)
                guard !normalizedSources.isEmpty || !rawSources.isEmpty else { continue }

                var items: [MetaPreview] = []
                await withTaskGroup(of: [MetaPreview].self) { group in
                    for source in normalizedSources {
                        group.addTask {
                            await self.fetchNormalizedSource(source, baseURL: baseURL)
                        }
                    }
                    for source in rawSources {
                        group.addTask {
                            await self.fetchRawSource(source, baseURL: baseURL)
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
                    hasMore: false,
                    tileShape: folder.tileShape,
                    coverImage: folder.coverImage,
                    focusGif: folder.focusGif,
                    focusGifEnabled: folder.focusGifEnabled,
                    titleLogo: folder.titleLogo,
                    heroBackdrop: folder.heroBackdrop,
                    heroVideoURL: folder.heroVideoUrl,
                    hideTitle: folder.hideTitle,
                    focusGlowEnabled: collection.focusGlowEnabled,
                    viewMode: collection.viewMode,
                    showAllTab: collection.showAllTab,
                    pinToTop: collection.pinToTop,
                    backdropImage: collection.backdropImage
                ))
            }
        }

        self.catalogRows = rows
    }

    private func genreExtras(_ genre: String?) -> [String: String] {
        guard let genre, genre != "None" else { return [:] }
        return ["genre": genre]
    }

    private func fetchNormalizedSource(
        _ source: DBFolderCatalog,
        baseURL: String
    ) async -> [MetaPreview] {
        do {
            let extras = genreExtras(source.genre)
            if source.mediaType == "all" {
                var results: [MetaPreview] = []
                let movieQuery = CatalogService.StremioCatalogQuery(
                    type: "movie", id: source.catalogId, baseURL: baseURL, extras: extras
                )
                let seriesQuery = CatalogService.StremioCatalogQuery(
                    type: "series", id: source.catalogId, baseURL: baseURL, extras: extras
                )
                if let movieResult = try? await catalogService.fetchCatalog(query: movieQuery) {
                    results.append(contentsOf: movieResult)
                }
                if let seriesResult = try? await catalogService.fetchCatalog(query: seriesQuery) {
                    results.append(contentsOf: seriesResult)
                }
                return results
            }
            let query = CatalogService.StremioCatalogQuery(
                type: source.mediaType,
                id: source.catalogId,
                baseURL: baseURL,
                extras: extras
            )
            return try await catalogService.fetchCatalog(query: query)
        } catch {
            return []
        }
    }

    private func fetchRawSource(
        _ source: DBFolderSource,
        baseURL: String
    ) async -> [MetaPreview] {
        do {
            guard let query = resolveRawQuery(from: source, baseURL: baseURL) else {
                return []
            }
            return try await catalogService.fetchCatalog(query: query)
        } catch {
            return []
        }
    }

    private func resolveRawQuery(
        from source: DBFolderSource,
        baseURL: String
    ) -> CatalogService.StremioCatalogQuery? {
        let mediaType = source.mediaType ?? "movie"
        let extras: [String: String] = [:]

        switch source.provider.lowercased() {
        case "trakt":
            guard let tmdbId = source.tmdbId else { return nil }
            return CatalogService.StremioCatalogQuery(
                type: mediaType,
                id: "trakt.list.\(tmdbId)",
                baseURL: baseURL,
                extras: extras
            )
        case "tmdb":
            if source.tmdbSourceType?.uppercased() == "COLLECTION" {
                return nil
            }
            guard let tmdbId = source.tmdbId else { return nil }
            let catalogId = source.tmdbSourceType?.lowercased() == "discover"
                ? "tmdb.discover.\(mediaType).\(tmdbId)"
                : "tmdb.\(tmdbId)"
            return CatalogService.StremioCatalogQuery(
                type: mediaType,
                id: catalogId,
                baseURL: baseURL,
                extras: extras
            )
        case "mdblist":
            guard let tmdbId = source.tmdbId else { return nil }
            return CatalogService.StremioCatalogQuery(
                type: mediaType,
                id: "mdblist.\(tmdbId)",
                baseURL: baseURL,
                extras: extras
            )
        case "tvdb":
            guard let tmdbId = source.tmdbId else { return nil }
            return CatalogService.StremioCatalogQuery(
                type: mediaType,
                id: "tvdb.discover.\(mediaType).\(tmdbId)",
                baseURL: baseURL,
                extras: extras
            )
        case "streaming":
            guard let tmdbId = source.tmdbId else { return nil }
            return CatalogService.StremioCatalogQuery(
                type: mediaType,
                id: "streaming.\(tmdbId)",
                baseURL: baseURL,
                extras: extras
            )
        default:
            return nil
        }
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
