import Foundation

@MainActor
public class SearchRepository: ObservableObject {
    public static let shared = SearchRepository()

    @Published public var results: [MetaPreview] = []
    @Published public var isLoading = false
    @Published public var searchQuery = ""

    private let catalogService = CatalogService.shared

    private init() {}

    public func search(query: String, addons: [AddonManifest]) async {
        guard !query.isEmpty else {
            results = []
            return
        }

        isLoading = true
        searchQuery = query
        defer { isLoading = false }

        var allResults: [MetaPreview] = []

        await withTaskGroup(of: [MetaPreview]?.self) { group in
            for addon in addons {
                guard addon.hasResource("catalog"),
                      let baseURL = addon.transportUrl else { continue }

                let searchableCatalogs = (addon.catalogs ?? []).filter { catalog in
                    catalog.extra?.contains { $0.name == "search" } == true
                }

                if searchableCatalogs.isEmpty {
                    // Fallback: try common search catalog patterns for movie and series
                    for type in ["movie", "series"] {
                        let addonRef = addon
                        group.addTask {
                            return try? await self.catalogService.fetchCatalog(
                                query: CatalogService.StremioCatalogQuery(
                                    type: type,
                                    id: "search",
                                    baseURL: baseURL,
                                    extras: ["search": query]
                                )
                            )
                        }
                        _ = addonRef
                    }
                } else {
                    for catalog in searchableCatalogs {
                        group.addTask {
                            return try? await self.catalogService.fetchCatalog(
                                query: CatalogService.StremioCatalogQuery(
                                    type: catalog.type,
                                    id: catalog.id,
                                    baseURL: baseURL,
                                    extras: ["search": query]
                                )
                            )
                        }
                    }
                }
            }

            for await result in group {
                if let items = result {
                    allResults.append(contentsOf: items)
                }
            }
        }

        let unique = Dictionary(grouping: allResults, by: { $0.id })
            .compactMap { $0.value.first }
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }

        self.results = unique
    }
}
