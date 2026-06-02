import SwiftUI
import LunaCore

struct MacHomeView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var collectionRepo = CollectionRepository.shared
    @StateObject private var homeRepo = HomeRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var heroIndex = 0
    @State private var heroTimer: Timer?
    @State private var selectedMedia: MetaPreview?
    @State private var showDetail = false
    @State private var autoPlayLaunch: PlayerLaunch?
    @State private var isResumingItemId: String?

    private var allRows: [CatalogRow] {
        catalogRepo.catalogRows + catalogRepo.collectionRows
    }

    /// Rows good enough to feature in the hero (Popular / Trending), matched loosely
    /// since addon catalog names vary (e.g. "TMDB Popular", "Trending Movies").
    private func isFeaturedRow(_ row: CatalogRow) -> Bool {
        let t = row.title.lowercased()
        return t.contains("popular") || t.contains("trending")
    }

    /// Featured rows first, then the rest — keeps the best content at the top.
    private var orderedRows: [CatalogRow] {
        allRows.filter { isFeaturedRow($0) } + allRows.filter { !isFeaturedRow($0) }
    }

    // Mirror LunaWebV2's pickFeaturedItems: interleave up to 3 movies + 3 series
    // from Popular/Trending rows, sorted by popularity, capped at 5 total.
    private var featuredItems: [MetaPreview] {
        let featured = allRows.filter { isFeaturedRow($0) }
        let source = featured.isEmpty ? Array(allRows.prefix(2)) : featured

        func topItems(type: MediaType, limit: Int) -> [MetaPreview] {
            var seen = Set<String>()
            var result: [MetaPreview] = []
            for row in source where row.items.first?.type == type {
                for item in row.items where (item.banner != nil || item.poster != nil) && !seen.contains(item.id) {
                    seen.insert(item.id)
                    result.append(item)
                }
            }
            return result.sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }.prefix(limit).map { $0 }
        }

        let movies = topItems(type: .movie, limit: 3)
        let series = topItems(type: .series, limit: 3)
        var result: [MetaPreview] = []
        let maxLen = max(movies.count, series.count)
        for i in 0..<maxLen {
            if result.count >= 5 { break }
            if i < movies.count { result.append(movies[i]) }
            if result.count < 5, i < series.count { result.append(series[i]) }
        }
        return result.isEmpty ? Array(source.flatMap { $0.items }.filter { $0.poster != nil }.prefix(5)) : result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !featuredItems.isEmpty {
                    let safeIndex = heroIndex % featuredItems.count
                    let rowTitle = allRows
                        .first(where: { $0.items.contains(where: { $0.id == featuredItems[safeIndex].id }) })?
                        .title ?? "Featured"

                    HomeHero(
                        item: featuredItems[safeIndex],
                        rowTitle: rowTitle,
                        onTap: {
                            selectedMedia = featuredItems[safeIndex]
                            showDetail = true
                        },
                        dotCount: featuredItems.count,
                        activeIndex: safeIndex,
                        onDotTap: { i in
                            withAnimation(.easeInOut(duration: 0.4)) {
                                heroIndex = i
                            }
                            startHeroTimer()
                        }
                    )

                    Spacer().frame(height: 24)
                }

                if !homeRepo.continueWatchingItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Continue Watching")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(homeRepo.continueWatchingItems) { item in
                                    ContinueWatchingCard(
                                        item: item,
                                        isLoading: isResumingItemId == item.mediaId
                                    )
                                    .onTapGesture { resumeItem(item) }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                }

                if !allRows.isEmpty {
                    VStack(spacing: 28) {
                        ForEach(orderedRows) { row in
                            MediaRow(title: row.title, items: row.items) { item in
                                selectedMedia = item
                                showDetail = true
                            }
                        }
                    }
                } else if catalogRepo.isLoading || addonRepo.isLoading {
                    ProgressView()
                        .tint(LunaTheme.accent)
                        .padding(.top, 100)
                }

                Spacer().frame(height: 32)
            }
        }
        .background(LunaTheme.background)
        .sheet(isPresented: $showDetail) {
            if let media = selectedMedia {
                MacDetailView(
                    mediaId: media.id,
                    type: media.type.rawValue,
                    name: media.name
                )
                .frame(minWidth: 800, minHeight: 600)
            }
        }
        .sheet(item: $autoPlayLaunch) { launch in
            MacPlayerView(launch: launch)
        }
        .task {
            guard let profile = profileManager.currentProfile else { return }

            // Fire collections + CW immediately — they don't need the system addon URL.
            // They run in parallel with the Supabase addon fetch + manifest downloads.
            async let collectionsLoad: () = collectionRepo.load()
            async let cwLoad: () = homeRepo.loadContinueWatching(profileId: profile.id)

            let systemAddonUrl = try? await SyncService.shared.pullSystemAddon()
            await addonRepo.loadAddons(profileId: profile.id, systemAddonUrl: systemAddonUrl)
            await collectionsLoad
            await cwLoad

            let enabled = addonRepo.enabledAddons
            // Mirror LunaWebV2: home catalog rows come from the SYSTEM ADDON only.
            let catalogAddon: AddonManifest?
            if let sysUrl = systemAddonUrl {
                catalogAddon = addonRepo.managedAddons
                    .first(where: { $0.manifestUrl == sysUrl })?.manifest
            } else {
                catalogAddon = enabled.first(where: { !($0.catalogs?.isEmpty ?? true) })
            }
            let catalogAddons = catalogAddon.map { [$0] } ?? []
            await catalogRepo.loadAllCatalogs(addons: catalogAddons)
            await catalogRepo.loadFromCollections(collectionRepo: collectionRepo, addons: enabled)
            startHeroTimer()
        }
        .onDisappear {
            heroTimer?.invalidate()
            heroTimer = nil
        }
        .onChange(of: featuredItems.count) {
            heroIndex = 0
            startHeroTimer()
        }
    }

    private func resumeItem(_ item: ContinueWatchingItem) {
        guard isResumingItemId == nil else { return }
        isResumingItemId = item.mediaId
        Task {
            defer { isResumingItemId = nil }
            let addons = addonRepo.enabledAddons
            guard let stream = await StreamRepository.shared.bestStream(
                for: item.mediaType,
                id: item.mediaId,
                from: addons
            ), let url = stream.url else { return }

            autoPlayLaunch = PlayerLaunch(
                title: item.name,
                sourceUrl: url,
                sourceHeaders: stream.behaviorHints?.proxyHeaders?.request,
                poster: item.poster,
                seasonNumber: item.seasonNumber,
                episodeNumber: item.episodeNumber,
                streamTitle: stream.displayName,
                providerName: stream.addonName,
                contentType: item.mediaType == "movie" ? .movie : .series,
                videoId: item.mediaId,
                initialPositionMs: item.resumePositionMs
            )
        }
    }

    private func startHeroTimer() {
        heroTimer?.invalidate()
        guard featuredItems.count > 1 else { return }
        heroTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            Task { @MainActor in
                let count = featuredItems.count
                guard count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    heroIndex = (heroIndex + 1) % count
                }
            }
        }
    }
}
