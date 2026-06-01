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

    private let mainRowNames: Set<String> = [
        "Popular Movies", "Popular TV Shows",
        "Trending Movies", "Trending TV Shows"
    ]

    private var featuredItems: [MetaPreview] {
        let mainRows = catalogRepo.catalogRows.filter { mainRowNames.contains($0.title) }
        var seen = Set<String>()
        var candidates: [MetaPreview] = []
        for row in mainRows {
            for item in row.items where !seen.contains(item.id) {
                seen.insert(item.id)
                candidates.append(item)
            }
        }
        return candidates
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !featuredItems.isEmpty {
                    let safeIndex = heroIndex % featuredItems.count
                    let rowTitle = catalogRepo.catalogRows
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
                                    ContinueWatchingCard(item: item)
                                        .onTapGesture {
                                            if let match = catalogRepo.catalogRows
                                                .flatMap({ $0.items })
                                                .first(where: { $0.id == item.mediaId }) {
                                                selectedMedia = match
                                            } else {
                                                selectedMedia = MetaPreview(
                                                    id: item.mediaId,
                                                    type: item.mediaType == "movie" ? .movie : .series,
                                                    name: item.name,
                                                    poster: item.poster
                                                )
                                            }
                                            showDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                }

                if !catalogRepo.catalogRows.isEmpty {
                    let mainRows = catalogRepo.catalogRows.filter { mainRowNames.contains($0.title) }
                    let folderRows = catalogRepo.catalogRows.filter { !mainRowNames.contains($0.title) }

                    VStack(spacing: 28) {
                        ForEach(mainRows) { row in
                            MediaRow(title: row.title, items: row.items) { item in
                                selectedMedia = item
                                showDetail = true
                            }
                        }
                    }

                    if !folderRows.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Browse")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 140), spacing: 10)],
                                spacing: 10
                            ) {
                                ForEach(folderRows) { row in
                                    FolderTile(row: row) {
                                        if let first = row.items.first {
                                            selectedMedia = first
                                            showDetail = true
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }
                } else if catalogRepo.isLoading {
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
        .task {
            guard let profile = profileManager.currentProfile else { return }
            await addonRepo.loadAddons(profileId: profile.id)
            await collectionRepo.load()
            await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
            await homeRepo.loadContinueWatching(profileId: profile.id)
            startHeroTimer()
        }
        .onDisappear {
            heroTimer?.invalidate()
            heroTimer = nil
        }
        .onChange(of: featuredItems.count) { newCount in
            heroIndex = 0
            startHeroTimer()
        }
    }

    private func startHeroTimer() {
        heroTimer?.invalidate()
        guard featuredItems.count > 1 else { return }
        heroTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                heroIndex = (heroIndex + 1) % featuredItems.count
            }
        }
    }
}
