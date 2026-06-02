import Foundation

@MainActor
public class CatalogRepository: ObservableObject {
    public static let shared = CatalogRepository()

    @Published public var catalogRows: [CatalogRow] = []
    @Published public var collectionRows: [CatalogRow] = []
    @Published public var isLoading = false

    private let catalogService = CatalogService.shared

    private init() {}

    public func loadAllCatalogs(addons: [AddonManifest]) async {
        isLoading = true
        catalogRows = []

        // Score catalogs so Popular/Trending load first — hero appears fast,
        // then remaining rows fill in progressively behind it.
        struct ScoredCatalog {
            let addon: AddonManifest
            let catalog: AddonCatalog
            let baseURL: String
            let extras: [String: String]
            let score: Int
        }

        var scored: [ScoredCatalog] = []
        for addon in addons {
            guard let catalogs = addon.catalogs, let baseURL = addon.transportUrl else { continue }
            for catalog in catalogs {
                let needsSearch = (catalog.extra ?? []).contains { $0.name == "search" && ($0.isRequired ?? false) }
                if needsSearch { continue }
                var extras: [String: String] = [:]
                for e in catalog.extra ?? [] { if let first = e.options?.first { extras[e.name] = first } }
                let text = "\(catalog.name ?? "") \(catalog.id) \(catalog.type)".lowercased()
                var s = 0
                if text.contains("popular")  { s += 4 }
                if text.contains("trending") { s += 4 }
                if text.contains("featured") { s += 3 }
                if catalog.type == "movie" || catalog.type == "series" { s += 2 }
                scored.append(ScoredCatalog(addon: addon, catalog: catalog, baseURL: baseURL, extras: extras, score: s))
            }
        }
        scored.sort { $0.score > $1.score }

        // Load high-priority catalogs first (score ≥ 4) so the hero populates fast,
        // then load everything else progressively.
        let priority = scored.filter { $0.score >= 4 }
        let rest     = scored.filter { $0.score < 4 }

        func fetch(_ items: [ScoredCatalog]) async {
            await withTaskGroup(of: CatalogRow?.self) { group in
                for sc in items {
                    group.addTask {
                        do {
                            let query = CatalogService.StremioCatalogQuery(
                                type: sc.catalog.type,
                                id: sc.catalog.id,
                                baseURL: sc.baseURL,
                                extras: sc.extras
                            )
                            let rows = try await self.catalogService.fetchCatalog(query: query)
                            guard !rows.isEmpty else { return nil }
                            return CatalogRow(
                                id: "\(sc.addon.id)_\(sc.catalog.type)_\(sc.catalog.id)",
                                title: sc.catalog.name ?? sc.catalog.id.capitalized,
                                items: rows,
                                addonName: sc.addon.name,
                                page: 0,
                                hasMore: rows.count >= 50
                            )
                        } catch { return nil }
                    }
                }
                for await row in group {
                    if let row, !catalogRows.contains(where: { $0.id == row.id }) {
                        catalogRows.append(row)
                        isLoading = false
                    }
                }
            }
        }

        await fetch(priority)   // hero-worthy rows — appear first
        await fetch(rest)       // remaining rows fill in after
        isLoading = false
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

        self.collectionRows = rows
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
