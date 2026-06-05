import SwiftUI
import LunaCore

struct HomeScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var collectionRepo = CollectionRepository.shared
    @StateObject private var homeRepo = HomeRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var preferenceStore = CollectionDisplayPreferenceStore.shared
    @StateObject private var libraryRepo = LibraryRepository.shared
    @State private var selectedMedia: MetaPreview?
    @State private var showDetail = false
    @State private var selectedFolder: CatalogRow? = nil
    @State private var showFolder = false

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

    @State private var heroIndex = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let metrics = ResponsiveMetrics(for: geo.size.width)
                ZStack {
                    LunaTheme.background.ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 0) {
                            if !featuredItems.isEmpty {
                                ParallaxHero(
                                    items: featuredItems,
                                    currentIndex: $heroIndex,
                                    metrics: metrics,
                                    onWatchNow: { item in
                                        selectedMedia = item
                                        showDetail = true
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

                    // Continue Watching
                    if !homeRepo.continueWatchingItems.isEmpty {
                    ContinueWatchingRow(
                        items: homeRepo.continueWatchingItems,
                        onTap: { item in
                            // ContinueWatchingItem -> navigate via mediaId lookup
                            if let match = catalogRepo.catalogRows
                                .flatMap({ $0.items })
                                .first(where: { $0.id == item.mediaId }) {
                                selectedMedia = match
                                showDetail = true
                            } else {
                                // Fallback: build a minimal MetaPreview from the CW item
                                selectedMedia = MetaPreview(
                                    id: item.mediaId,
                                    type: item.mediaType == "movie" ? .movie : .series,
                                    name: item.name,
                                    poster: item.poster
                                )
                                showDetail = true
                            }
                        },
                        metrics: metrics
                        )
                        .padding(.top, 16)
                    }

                    if !catalogRepo.catalogRows.isEmpty {
                        // Main rows
                        let mainRows = catalogRepo.catalogRows.filter { mainRowNames.contains($0.title) }
                        let browseRows = catalogRepo.catalogRows.filter { !mainRowNames.contains($0.title) }

                        LazyVStack(spacing: 24) {
                            ForEach(mainRows) { row in
                                CatalogRowView(row: row, onTap: { item in
                                    selectedMedia = item
                                    showDetail = true
                                }, metrics: metrics)
                                .onAppear {
                                    if row.id == mainRows.last?.id {
                                        Task {
                                            await catalogRepo.loadMore(
                                                rowId: row.id,
                                                addons: addonRepo.enabledAddons
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 24)

                        if !browseRows.isEmpty {
                            LazyVStack(spacing: 24) {
                                ForEach(browseRows) { row in
                                    CatalogRowView(row: row, onTap: { item in
                                        if item.id.hasPrefix("folder_"),
                                           let folderRow = catalogRepo.allFolderRows[item.id] {
                                            selectedFolder = folderRow
                                            showFolder = true
                                        } else {
                                            selectedMedia = item
                                            showDetail = true
                                        }
                                    }, metrics: metrics)
                                }
                            }
                            .padding(.top, 24)
                        }
                    } else if catalogRepo.isLoading {
                        VStack(spacing: 24) {
                            Spacer().frame(height: 20)
                            ShimmerCard(width: 375, height: 200, cornerRadius: 12)
                                .padding(.horizontal)
                            ShimmerCard(width: 120, height: 16, cornerRadius: 4)
                                .padding(.horizontal)
                            HStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { _ in
                                    ShimmerCard(width: 180, height: 100, cornerRadius: 8)
                                }
                            }
                            .padding(.horizontal)
                            HStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { _ in
                                    ShimmerCard(width: 105, height: 158, cornerRadius: 8)
                                }
                            }
                            .padding(.horizontal)
                            Spacer()
                        }
                    }

                    Spacer().frame(height: 32)
                }
            }
            .refreshable {
                guard let profile = profileManager.currentProfile else { return }
                await reloadCatalogRows()
                await homeRepo.loadContinueWatching(profileId: profile.id)
            }
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let profile = profileManager.currentProfile {
                        Button {
                            profileManager.currentProfile = nil
                        } label: {
                            ProfileAvatarView(profile: profile, size: 32)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let media = selectedMedia {
                    DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
                }
            }
            .navigationDestination(isPresented: $showFolder) {
                if let folder = selectedFolder {
                    FolderScreen(row: folder)
                }
            }
            .task {
                guard let profile = profileManager.currentProfile else { return }
                await addonRepo.loadAddons(profileId: profile.id)
                await collectionRepo.load()
                await libraryRepo.loadLibrary(profileId: profile.id)
                if catalogRepo.catalogRows.isEmpty {
                    if collectionRepo.collections.isEmpty {
                        await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
                    } else {
                        await catalogRepo.loadFromCollections(
                            collectionRepo: collectionRepo,
                            addons: addonRepo.enabledAddons
                        )
                        await catalogRepo.supplementWithAddonCatalogs(
                            addons: addonRepo.enabledAddons
                        )
                    }
                }
                await homeRepo.loadContinueWatching(profileId: profile.id)
            }
            .onChange(of: preferenceStore.revision) { _, _ in
                Task { await reloadCatalogRows() }
            }
        }
    }

    private func reloadCatalogRows() async {
        if collectionRepo.collections.isEmpty {
            await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
        } else {
            await catalogRepo.loadFromCollections(
                collectionRepo: collectionRepo,
                addons: addonRepo.enabledAddons
            )
            await catalogRepo.supplementWithAddonCatalogs(addons: addonRepo.enabledAddons)
        }
    }
}

// MARK: - Folder Grid

struct FolderGridSection: View {
    let rows: [CatalogRow]
    let onTap: (MetaPreview) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse")
                .font(.headline).foregroundColor(.white).padding(.horizontal)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(rows) { row in
                    FolderCell(row: row, onTap: onTap)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FolderCell: View {
    let row: CatalogRow
    let onTap: (MetaPreview) -> Void

    private var isLandscape: Bool {
        row.tileShape == "landscape"
    }

    var body: some View {
        let coverURL: URL? = {
            if let ci = row.coverImage { return URL(string: ci) }
            if let p = row.items.first?.poster { return URL(string: p) }
            return nil
        }()

        Button {
            if let first = row.items.first { onTap(first) }
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LunaTheme.surfaceElevated)
                    .aspectRatio(isLandscape ? 16/9 : 2/3, contentMode: .fit)

                if let url = coverURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .aspectRatio(isLandscape ? 16/9 : 2/3, contentMode: .fit)
                }

                LinearGradient(
                    colors: [.black.opacity(0.75), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .aspectRatio(isLandscape ? 16/9 : 2/3, contentMode: .fit)

                Text(row.title)
                    .font(.system(size: isLandscape ? 11 : 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Catalog Row View

struct CatalogRowView: View {
    let row: CatalogRow
    let onTap: (MetaPreview) -> Void
    var metrics: ResponsiveMetrics? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let titleLogo = row.titleLogo, let url = URL(string: titleLogo) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                        }
                    }
                } else if !(row.hideTitle ?? false) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(row.items.enumerated()), id: \.element.id) { index, item in
                        let isLandscape = row.tileShape == "landscape"
                        let isSquare = row.tileShape == "square"
                        let w = isLandscape ? (metrics?.landscapeWidth ?? 200) : isSquare ? (metrics?.posterWidth ?? 140) : (metrics?.posterWidth ?? 120)
                        let h = isLandscape ? (metrics?.landscapeHeight ?? 112) : isSquare ? (metrics?.posterWidth ?? 140) : (metrics?.posterHeight ?? 180)
                        ContentCard(item: item, row: row, index: index, width: w, height: h)
                            .onTapGesture { onTap(item) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Continue Watching

struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]
    let onTap: (ContinueWatchingItem) -> Void
    var metrics: ResponsiveMetrics? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continue Watching")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item,
                                             width: metrics?.continueWatchingWidth ?? 192,
                                             height: metrics?.continueWatchingHeight ?? 108)
                            .onTapGesture { onTap(item) }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
}

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    var width: CGFloat = 192
    var height: CGFloat = 108

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                RoundedRectangle(cornerRadius: 8).fill(LunaTheme.surfaceElevated)
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(LunaTheme.surfaceElevated)
                    }
                }
                .frame(width: width, height: height).clipped()
                .glassCard(cornerRadius: 8)

                // Play overlay circle
                Circle().fill(Color.black.opacity(0.5)).frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    )
                    .padding(.bottom, 16)

                // Progress bar
                VStack(spacing: 0) {
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 3)
                            Rectangle()
                                .fill(LunaTheme.accent)
                                .frame(width: geo.size.width * item.progressFraction, height: 3)
                        }
                    }.frame(height: 3)
                }.cornerRadius(8)
            }
            .frame(width: width, height: height)

            Text(item.name)
                .font(.caption).foregroundColor(.white).lineLimit(1).frame(width: width, alignment: .leading)
            Text("\(Int(item.progressFraction * 100))% watched")
                .font(.caption2).foregroundColor(LunaTheme.textSecondary)
        }
    }
}
