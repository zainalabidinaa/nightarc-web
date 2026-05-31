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

                group.addTask {
                    do {
                        let searchQuery = CatalogService.StremioCatalogQuery(
                            type: "movie",
                            id: "top",
                            baseURL: baseURL,
                            extras: ["search": query]
                        )
                        return try await self.catalogService.fetchCatalog(query: searchQuery)
                    } catch {
                        do {
                            let searchQuery = CatalogService.StremioCatalogQuery(
                                type: "movie",
                                id: "search",
                                baseURL: baseURL,
                                extras: ["search": query]
                            )
                            return try await self.catalogService.fetchCatalog(query: searchQuery)
                        } catch {
                            return nil
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
