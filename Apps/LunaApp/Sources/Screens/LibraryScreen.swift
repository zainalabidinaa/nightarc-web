import SwiftUI
import NightarcCore

#Preview("Library") {
    LibraryScreen()
        .environmentObject(ProfileManager.shared)
        .preferredColorScheme(.dark)
}

struct LibraryScreen: View {
    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var likedRepo = LikedRepository.shared
    @StateObject private var upcomingService = UpcomingItemsService.shared
    @StateObject private var traktAuth = TraktAuthService.shared
    @StateObject private var watchProgressRepo = WatchProgressRepository.shared
    @EnvironmentObject var profileManager: ProfileManager

    @State private var watchlistFilter: MediaFilter = .all
    @State private var likedFilter: MediaFilter = .all
    @State private var resolvedArtwork: [String: String] = [:]

    enum MediaFilter: String, CaseIterable {
        case all = "All"
        case movies = "Movies"
        case series = "Series"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    upcomingSection
                    watchlistSection
                    likedSection
                    Spacer().frame(height: 40)
                }
            }
            .background(NightarcTheme.background)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            guard let profile = profileManager.currentProfile else { return }
            if addonRepo.enabledAddons.isEmpty {
                await addonRepo.loadAddons(profileId: profile.id)
            }
            await libraryRepo.loadLibrary(profileId: profile.id)
            await watchProgressRepo.loadAll(profileId: profile.id)
            await likedRepo.loadLibrary()
            await TraktAuthService.shared.loadToken(profileId: profile.id)
            await upcomingService.refresh(likedItems: likedRepo.likedItems)
            await resolveLibraryArtwork()
        }
    }

    // MARK: - Computed

    private var filteredWatchlist: [NightarcCore.LibraryItem] {
        switch watchlistFilter {
        case .all:    return libraryRepo.libraryItems
        case .movies: return libraryRepo.libraryItems.filter { $0.mediaType == "movie" }
        case .series: return libraryRepo.libraryItems.filter { $0.mediaType != "movie" }
        }
    }

    private var availableLikedItems: [LikedItem] {
        switch likedFilter {
        case .all:    return likedRepo.likedItems
        case .movies: return likedRepo.likedItems.filter { $0.mediaType == "movie" }
        case .series: return likedRepo.likedItems.filter { $0.mediaType != "movie" }
        }
    }

    private var upcomingItems: [LikedItem] {
        let liked = likedRepo.likedItems.filter { upcomingService.isUpcoming($0.mediaId) }
        let traktOnly = upcomingService.traktUpcomingItems.filter { upcomingService.isUpcoming($0.mediaId) }
        // Deduplicate: liked items take priority; Trakt items sharing a tmdbId are dropped
        let likedTmdbIds = Set(liked.compactMap(\.tmdbId))
        let uniqueTrakt = traktOnly.filter { item in
            guard let tmdbId = item.tmdbId else { return true }
            return !likedTmdbIds.contains(tmdbId)
        }
        return liked + uniqueTrakt
    }

    // MARK: - Watchlist Section

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(title: "Watchlist", count: libraryRepo.libraryItems.count)
            filterChips(selection: $watchlistFilter)

            if filteredWatchlist.isEmpty {
                emptyState(icon: "bookmark", message: "Nothing bookmarked yet.\nTap 🔖 on any title to add it.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 10)], spacing: 10) {
                    ForEach(filteredWatchlist, id: \.id) { item in
                        watchlistPosterCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func watchlistPosterCard(_ item: NightarcCore.LibraryItem) -> some View {
        NavigationLink(destination: DetailScreen(
            mediaId: item.mediaId,
            type: item.mediaType,
            name: item.name ?? item.mediaId
        )) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let url = artworkURL(for: item) {
                        CachedAsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                watchlistPlaceholder(item)
                            }
                        }
                    } else {
                        watchlistPlaceholder(item)
                    }
                }
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Watch progress bar
                if let entry = watchProgressRepo.getProgress(mediaId: item.mediaId),
                   entry.progressFraction > 0.02 {
                    VStack(spacing: 0) {
                        Spacer()
                        GeometryReader { geo in
                            Capsule()
                                .fill(NightarcTheme.accent.opacity(0.9))
                                .frame(width: geo.size.width * entry.progressFraction, height: 3)
                        }
                        .frame(height: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: 100, height: 150)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    guard let profile = profileManager.currentProfile else { return }
                    await libraryRepo.removeFromLibrary(profileId: profile.id, mediaId: item.mediaId)
                }
            } label: {
                Label("Remove from Watchlist", systemImage: "bookmark.slash")
            }
        }
    }

    @ViewBuilder
    private func watchlistPlaceholder(_ item: NightarcCore.LibraryItem) -> some View {
        Color.white.opacity(0.05)
            .overlay(
                Image(systemName: item.mediaType == "movie" ? "film" : "tv")
                    .foregroundColor(NightarcTheme.textTertiary)
            )
    }

    // MARK: - Liked Section

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(systemImage: "heart.fill", imageTint: Color(red: 1, green: 0.25, blue: 0.35), title: "Liked", count: availableLikedItems.count)
            filterChips(selection: $likedFilter)

            if availableLikedItems.isEmpty {
                emptyState(icon: "heart", message: "Nothing liked yet.\nTap the heart button on any title to add it.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 10)], spacing: 10) {
                    ForEach(availableLikedItems, id: \.id) { item in
                        likedPosterCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func likedPosterCard(_ item: LikedItem) -> some View {
        NavigationLink(destination: DetailScreen(
            mediaId: item.mediaId,
            type: item.mediaType,
            name: item.name
        )) {
            Group {
                let posterURLStr = PosterService.posterURL(forImdbId: item.mediaId) ?? item.poster
                if let urlStr = posterURLStr, let url = URL(string: urlStr) {
                    CachedAsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Color.white.opacity(0.05)
                        }
                    }
                } else {
                    Color.white.opacity(0.05)
                }
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task { await likedRepo.removeLiked(mediaId: item.mediaId) }
            } label: {
                Label("Remove from Liked", systemImage: "heart.slash")
            }
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            librarySectionHeader(systemImage: "calendar", imageTint: NightarcTheme.accent, title: "Upcoming", count: upcomingItems.count)

            if upcomingItems.isEmpty {
                emptyState(icon: "calendar", message: "No upcoming releases.\nLike a movie or series to track it.")
            } else { upcomingList }
        }
    }

    private var upcomingList: some View {
        VStack(spacing: 0) {
            ForEach(upcomingItems, id: \.id) { item in
                NavigationLink(destination: DetailScreen(
                    mediaId: item.mediaId,
                    type: item.mediaType,
                    name: item.name
                )) {
                    upcomingRow(item)
                }
                .buttonStyle(.plain)
                if item.id != upcomingItems.last?.id {
                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 72)
                }
            }
        }
        .glassCard(cornerRadius: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func upcomingRow(_ item: LikedItem) -> some View {
        HStack(spacing: 12) {
            Group {
                if let poster = item.poster, let url = URL(string: poster) {
                    CachedAsyncImage(url: url) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFill() }
                        else { Color.white.opacity(0.05) }
                    }
                } else { Color.white.opacity(0.05) }
            }
            .frame(width: 44, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if item.mediaId.hasPrefix("trakt:") {
                        Text("Trakt")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.92, green: 0.27, blue: 0.0))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.92, green: 0.27, blue: 0.0).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                Text(item.mediaType == "movie" ? "Movie" : "Series")
                    .font(.caption)
                    .foregroundColor(NightarcTheme.textTertiary)
            }

            Spacer()

            if let badge = upcomingService.badge(for: item.mediaId) {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(NightarcTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NightarcTheme.accent.opacity(0.12))
                    .cornerRadius(6)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(NightarcTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Shared helpers

    private func librarySectionHeader(
        systemImage: String? = nil,
        imageTint: Color = .white,
        title: String,
        count: Int
    ) -> some View {
        HStack(spacing: 6) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(imageTint)
            }
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(NightarcTheme.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func filterChips(selection: Binding<MediaFilter>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MediaFilter.allCases, id: \.self) { filter in
                    Button { selection.wrappedValue = filter } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selection.wrappedValue == filter ? .white : NightarcTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(selection.wrappedValue == filter ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(Color.white.opacity(0.2))
            Text(message)
                .font(.subheadline)
                .foregroundColor(NightarcTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }

    // MARK: - Artwork resolution (preserved from original)

    private func artworkURL(for item: NightarcCore.LibraryItem) -> URL? {
        // Prefer btttr poster for any IMDb-id item — always up to date.
        if let bttr = PosterService.posterURL(forImdbId: item.mediaId) { return URL(string: bttr) }
        if let resolved = resolvedArtwork[item.mediaId] { return URL(string: resolved) }
        guard let poster = item.poster, !isStaleSavedArtwork(poster) else { return nil }
        return URL(string: poster)
    }

    private func isStaleSavedArtwork(_ url: String) -> Bool {
        let l = url.lowercased()
        // btttr.cc is now our primary poster source — never stale.
        return l.contains("betterposters")
            || l.contains("ratingposterdb") || l.contains("api.top-posters.com")
    }

    private func resolveLibraryArtwork() async {
        let items = libraryRepo.libraryItems
        let movieAddons = addonRepo.findAddonWithMetaResource(type: "movie")
        let seriesAddons = addonRepo.findAddonWithMetaResource(type: "series")
        await withTaskGroup(of: (String, String?).self) { group in
            for item in items {
                let addons = item.mediaType == "movie" ? movieAddons : seriesAddons
                group.addTask {
                    let detail = await MetaRepository.shared.fetchDetail(
                        type: item.mediaType,
                        id: item.mediaId,
                        addons: addons
                    )
                    return (item.mediaId, detail?.rawPosterUrl ?? detail?.poster)
                }
            }
            var artwork = resolvedArtwork
            for await (mediaId, poster) in group {
                if let poster, !poster.isEmpty { artwork[mediaId] = poster }
            }
            resolvedArtwork = artwork
        }
    }
}
