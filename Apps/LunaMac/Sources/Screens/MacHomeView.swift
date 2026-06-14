import SwiftUI
import NightarcCore

struct MacHomeView: View {
    let onSelectMedia: (MetaPreview) -> Void
    var onSelectFolder: ((CatalogRow) -> Void)?

    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.openWindow) private var openWindow
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var collectionRepo = CollectionRepository.shared
    @StateObject private var homeRepo = HomeRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var preferenceStore = CollectionDisplayPreferenceStore.shared
    @StateObject private var rowStyleStore = CollectionRowDisplayStyleStore.shared
    @StateObject private var heroStore = HeroPreferenceStore.shared
    @StateObject private var libraryRepo = LibraryRepository.shared

    @State private var heroIndex = 0
    @State private var isResumingItemId: String?
    @AppStorage("luna.cinematicModeEnabled") private var cinematicModeEnabled = true

    private let mainRowNames: Set<String> = [
        "Popular Movies", "Popular TV Shows",
        "Trending Movies", "Trending TV Shows"
    ]

    private var featuredItems: [MetaPreview] {
        let allRows = catalogRepo.catalogRows
        let heroRows: [CatalogRow]
        if heroStore.rowOrder.isEmpty {
            let defaults = allRows.filter { mainRowNames.contains($0.title) }
            heroRows = defaults.isEmpty ? allRows : defaults
        } else {
            let enabledOrdered = heroStore.rowOrder
                .filter { heroStore.isEnabled(rowTitle: $0) }
                .compactMap { title in allRows.first { $0.title == title } }
            let missing = allRows.filter {
                mainRowNames.contains($0.title) &&
                !heroStore.rowOrder.contains($0.title) &&
                heroStore.isEnabled(rowTitle: $0.title)
            }
            let computed = enabledOrdered + missing
            let defaults = allRows.filter { mainRowNames.contains($0.title) }
            heroRows = computed.isEmpty ? (defaults.isEmpty ? allRows : defaults) : computed
        }

        var seen = Set<String>()
        var candidates: [MetaPreview] = []
        for row in heroRows {
            var taken = 0
            for item in row.items.sorted(by: { ($0.popularity ?? 0) > ($1.popularity ?? 0) }) where !seen.contains(item.id) {
                guard taken < 8, candidates.count < 20 else { break }
                seen.insert(item.id)
                candidates.append(item)
                taken += 1
            }
        }
        return candidates
    }

    var body: some View {
        ZStack(alignment: .top) {
            ambientBackground

            ScrollView {
                VStack(spacing: 0) {
                    if !featuredItems.isEmpty {
                        HomeHero(
                            items: featuredItems,
                            currentIndex: $heroIndex,
                            onWatchNow: { item in
                                route(item: item)
                            },
                            onToggleLibrary: { item in
                                Task {
                                    guard let profile = profileManager.currentProfile else { return }
                                    await libraryRepo.toggleLibrary(
                                        profileId: profile.id,
                                        mediaId: item.id,
                                        mediaType: item.type.rawValue,
                                        name: item.name,
                                        poster: item.poster
                                    )
                                }
                            }
                        )
                    }

                    if !homeRepo.continueWatchingItems.isEmpty {
                        continueWatchingRow
                            .padding(.top, featuredItems.isEmpty ? 96 : 18)
                            .padding(.bottom, 28)
                    }

                    if !catalogRepo.catalogRows.isEmpty {
                        LazyVStack(spacing: 30) {
                            ForEach(catalogRepo.catalogRows) { row in
                                MacCollectionRowContainer(
                                    row: row,
                                    style: rowStyleStore.style(forRowTitle: row.title),
                                    onTap: route(item:),
                                    onHeaderTap: { onSelectFolder?(row) }
                                )
                                .onAppear {
                                    if row.id == catalogRepo.catalogRows.last?.id {
                                        Task {
                                            await catalogRepo.loadMore(rowId: row.id, addons: addonRepo.enabledAddons)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, featuredItems.isEmpty ? 96 : 24)
                    } else if catalogRepo.isLoading || addonRepo.isLoading {
                        loadingState
                            .padding(.top, 180)
                    }

                    Spacer().frame(height: 48)
                }
            }
        }
        .background(NightarcTheme.background)
        .task {
            guard let profile = profileManager.currentProfile else { return }
            catalogRepo.isLoading = true
            await addonRepo.loadAddons(profileId: profile.id)
            async let continueWatching: Void = homeRepo.loadContinueWatching(profileId: profile.id)
            await libraryRepo.loadLibrary(profileId: profile.id)
            await reloadCatalogRows(mode: .replaceCache)
            await continueWatching
            warmupContinueWatching()
        }
        .onChange(of: preferenceStore.revision) { _, _ in
            Task { await reloadCatalogRows(mode: .replaceCache) }
        }
        .onChange(of: rowStyleStore.revision) { _, _ in
            Task { await reloadCatalogRows(mode: .replaceCache) }
        }
        .onChange(of: heroStore.revision) { _, _ in
            heroIndex = 0
        }
    }

    private var ambientBackground: some View {
        ZStack(alignment: .top) {
            NightarcTheme.background
            if cinematicModeEnabled,
               featuredItems.indices.contains(heroIndex),
               let url = MacHeroArtworkProvider.shared.heroArtURL(for: featuredItems[heroIndex]) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .frame(maxWidth: .infinity)
                .frame(height: 520)
                .scaleEffect(1.08)
                .blur(radius: 32)
                .saturation(0.18)
                .brightness(0.10)
                .opacity(0.70)
                .mask(
                    LinearGradient(
                        colors: [.black, .black.opacity(0.62), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            }
        }
    }

    private var continueWatchingRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Watching")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(homeRepo.continueWatchingItems) { item in
                        ContinueWatchingCard(
                            item: item,
                            isLoading: isResumingItemId == item.mediaId,
                            width: 250,
                            height: 142
                        )
                        .onTapGesture { resumeItem(item) }
                    }
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 18) {
            MacLottieLoadingView(size: 70)
            Text("Loading your collections")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }

    private func route(item: MetaPreview) {
        if item.id.hasPrefix("folder_") {
            let fallback = CatalogRow(
                id: item.id,
                title: item.name,
                items: [],
                tileShape: item.posterShape?.rawValue ?? "poster",
                coverImage: item.poster ?? item.banner
            )
            onSelectFolder?(catalogRepo.allFolderRows[item.id] ?? fallback)
        } else {
            onSelectMedia(item)
        }
    }

    private func resumeItem(_ item: ContinueWatchingItem) {
        guard isResumingItemId == nil else { return }
        isResumingItemId = item.mediaId
        Task {
            defer { isResumingItemId = nil }
            guard let profile = profileManager.currentProfile else { return }
            let decodedId = item.mediaId.removingPercentEncoding ?? item.mediaId
            let cachedSource = [decodedId, item.parentMediaId]
                .compactMap { $0 }
                .lazy
                .compactMap { LastPlaybackSourceStore.shared.source(profileId: profile.id, mediaId: $0) }
                .first

            if let cachedSource {
                openWindow(id: "player", value: PlayerLaunch(
                    title: item.name,
                    sourceUrl: cachedSource.sourceUrl,
                    sourceHeaders: cachedSource.sourceHeaders,
                    logo: item.logo,
                    poster: item.poster,
                    episodeThumbnail: item.thumbnail,
                    seasonNumber: item.seasonNumber,
                    episodeNumber: item.episodeNumber,
                    streamTitle: cachedSource.streamTitle ?? item.episodeTitle,
                    providerName: cachedSource.providerName,
                    contentType: item.mediaType == "movie" ? .movie : .series,
                    videoId: decodedId,
                    parentMetaId: item.parentMediaId,
                    parentMetaType: item.parentMediaId == nil ? nil : item.mediaType,
                    initialPositionMs: item.resumePositionMs,
                    subtitles: nil
                ))
                return
            }

            guard let stream = await StreamRepository.shared.bestStream(
                for: item.mediaType,
                id: item.mediaId,
                from: addonRepo.enabledAddons
            ), let url = stream.url else { return }

            openWindow(id: "player", value: PlayerLaunch(
                title: item.name,
                sourceUrl: url,
                sourceHeaders: stream.behaviorHints?.proxyHeaders?.request,
                logo: item.logo,
                poster: item.poster,
                episodeThumbnail: item.thumbnail,
                seasonNumber: item.seasonNumber,
                episodeNumber: item.episodeNumber,
                streamTitle: stream.displayName,
                providerName: stream.addonName,
                contentType: item.mediaType == "movie" ? .movie : .series,
                videoId: decodedId,
                parentMetaId: item.parentMediaId,
                parentMetaType: item.parentMediaId == nil ? nil : item.mediaType,
                initialPositionMs: item.resumePositionMs,
                subtitles: stream.subtitles
            ))
        }
    }

    private func warmupContinueWatching() {
        let addons = addonRepo.enabledAddons
        guard !homeRepo.continueWatchingItems.isEmpty, !addons.isEmpty else { return }
        for item in homeRepo.continueWatchingItems.prefix(5) {
            Task {
                await StreamWarmupRepository.shared.warmup(type: item.mediaType, id: item.mediaId, addons: addons)
            }
        }
    }

    private func reloadCatalogRows(mode: CatalogReloadMode = .preserveCacheOnEmpty) async {
        await loadGlobalOrganizer()
        if collectionRepo.collections.isEmpty {
            await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
        } else {
            await catalogRepo.loadFromCollections(
                collectionRepo: collectionRepo,
                addons: addonRepo.enabledAddons,
                mode: mode
            )
        }
    }

    private func loadGlobalOrganizer() async {
        guard let url = Bundle.main.url(forResource: "home-organizer", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            await collectionRepo.load()
            return
        }
        await collectionRepo.loadOrganizer(
            bundledData: data,
            remoteURL: NightarcConfig.homeOrganizerRemoteURL.flatMap(URL.init(string:))
        )
    }
}
