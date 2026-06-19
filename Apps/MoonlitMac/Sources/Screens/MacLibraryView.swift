import SwiftUI
import MoonlitCore

struct MacLibraryView: View {
    let onSelectMedia: (MetaPreview) -> Void

    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var likedRepo = LikedRepository.shared
    @StateObject private var upcomingService = UpcomingItemsService.shared
    @StateObject private var watchProgressRepo = WatchProgressRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @EnvironmentObject var profileManager: ProfileManager

    @State private var watchlistFilter: MediaFilter = .all
    @State private var likedFilter: MediaFilter = .all

    enum MediaFilter: String, CaseIterable {
        case all = "All"
        case movies = "Movies"
        case series = "Series"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                watchlistSection
                likedSection
                upcomingSection
                Spacer().frame(height: 40)
            }
            .padding(.top, MoonlitTheme.navBarTopInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoonlitTheme.background)
        .task {
            guard let profile = profileManager.currentProfile else { return }
            if addonRepo.enabledAddons.isEmpty {
                await addonRepo.loadAddons(profileId: profile.id)
            }
            await libraryRepo.loadLibrary(profileId: profile.id)
            await watchProgressRepo.loadAll(profileId: profile.id)
            await likedRepo.loadLiked(profileId: profile.id)
            await upcomingService.refresh(likedItems: likedRepo.likedItems)
        }
    }

    // MARK: - Computed

    private var filteredWatchlist: [MoonlitCore.LibraryItem] {
        switch watchlistFilter {
        case .all:    return libraryRepo.libraryItems
        case .movies: return libraryRepo.libraryItems.filter { $0.mediaType == "movie" }
        case .series: return libraryRepo.libraryItems.filter { $0.mediaType != "movie" }
        }
    }

    private var availableLikedItems: [LikedItem] {
        let notUpcoming = likedRepo.likedItems.filter { !upcomingService.isUpcoming($0.mediaId) }
        switch likedFilter {
        case .all:    return notUpcoming
        case .movies: return notUpcoming.filter { $0.mediaType == "movie" }
        case .series: return notUpcoming.filter { $0.mediaType != "movie" }
        }
    }

    private var upcomingItems: [LikedItem] {
        likedRepo.likedItems.filter { upcomingService.isUpcoming($0.mediaId) }
    }

    // MARK: - Watchlist Section

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Watchlist", icon: "bookmark.fill", count: libraryRepo.libraryItems.count)
            filterChips(selection: $watchlistFilter)

            if filteredWatchlist.isEmpty {
                emptyState(icon: "bookmark", message: "Nothing bookmarked yet")
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(filteredWatchlist, id: \.id) { item in
                        watchlistCard(item)
                            .onTapGesture {
                                let mediaType = MediaType(rawValue: item.mediaType ?? "movie") ?? .movie
                                onSelectMedia(MetaPreview(
                                    id: item.mediaId,
                                    type: mediaType,
                                    name: item.name ?? item.mediaId,
                                    poster: item.poster
                                ))
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func watchlistCard(_ item: MoonlitCore.LibraryItem) -> some View {
        let progress = watchProgressRepo.getProgress(mediaId: item.mediaId)?.progressFraction ?? 0
        return VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                CachedAsyncImage(url: item.poster.flatMap { URL(string: $0) }) { img in
                    img.resizable().aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(MoonlitTheme.surfaceElevated)
                        .overlay(
                            Image(systemName: item.mediaType == "series" ? "tv" : "film")
                                .foregroundColor(MoonlitTheme.textTertiary)
                        )
                }
                .frame(height: 195)
                .clipped()
                .cornerRadius(8)

                if progress > 0.02 {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(MoonlitTheme.accent)
                            .frame(width: geo.size.width * progress, height: 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 3)
                }
            }
            .frame(height: 195)

            Text(item.name ?? item.mediaId)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .contextMenu {
            Button("Remove from Watchlist", role: .destructive) {
                Task {
                    guard let profile = profileManager.currentProfile else { return }
                    await libraryRepo.removeFromLibrary(profileId: profile.id, mediaId: item.mediaId)
                }
            }
        }
    }

    // MARK: - Liked Section

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Liked", icon: "heart.fill", count: availableLikedItems.count)
            filterChips(selection: $likedFilter)

            if availableLikedItems.isEmpty {
                emptyState(icon: "heart", message: "Nothing liked yet")
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(availableLikedItems, id: \.id) { item in
                        likedCard(item)
                            .onTapGesture {
                                let mediaType = MediaType(rawValue: item.mediaType) ?? .movie
                                onSelectMedia(MetaPreview(
                                    id: item.mediaId,
                                    type: mediaType,
                                    name: item.name,
                                    poster: item.poster
                                ))
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func likedCard(_ item: LikedItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CachedAsyncImage(url: item.poster.flatMap { URL(string: $0) }) { img in
                img.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(MoonlitTheme.surfaceElevated)
                    .overlay(
                        Image(systemName: item.mediaType == "series" ? "tv" : "film")
                            .foregroundColor(MoonlitTheme.textTertiary)
                    )
            }
            .frame(height: 195)
            .clipped()
            .cornerRadius(8)

            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .contextMenu {
            Button("Remove from Liked", role: .destructive) {
                Task { await likedRepo.removeLiked(mediaId: item.mediaId, profileId: profileManager.currentProfile?.id ?? "") }
            }
        }
    }

    // MARK: - Upcoming Section

    @ViewBuilder
    private var upcomingSection: some View {
        if !upcomingItems.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(title: "Upcoming", icon: "calendar", count: upcomingItems.count)
                VStack(spacing: 0) {
                    ForEach(upcomingItems, id: \.id) { item in
                        upcomingRow(item)
                        if item.id != upcomingItems.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
                .background(MoonlitTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func upcomingRow(_ item: LikedItem) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: item.poster.flatMap { URL(string: $0) }) { img in
                img.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle().fill(MoonlitTheme.surfaceElevated)
            }
            .frame(width: 44, height: 66)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                if let badge = upcomingService.badge(for: item.mediaId) {
                    Text(badge)
                        .font(.caption)
                        .foregroundColor(MoonlitTheme.textTertiary)
                }
            }
            Spacer()
            Text("Upcoming")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MoonlitTheme.accent.opacity(0.2))
                .foregroundColor(MoonlitTheme.accent)
                .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            let mediaType = MediaType(rawValue: item.mediaType) ?? .movie
            onSelectMedia(MetaPreview(
                id: item.mediaId,
                type: mediaType,
                name: item.name,
                poster: item.poster
            ))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(MoonlitTheme.accent)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(MoonlitTheme.textTertiary)
                .tracking(1)
            Text("(\(count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(MoonlitTheme.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func filterChips(selection: Binding<MediaFilter>) -> some View {
        HStack(spacing: 8) {
            ForEach(MediaFilter.allCases, id: \.self) { filter in
                Button(filter.rawValue) {
                    selection.wrappedValue = filter
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(selection.wrappedValue == filter ? MoonlitTheme.accent : MoonlitTheme.surface)
                .foregroundColor(selection.wrappedValue == filter ? .white : MoonlitTheme.textSecondary)
                .cornerRadius(20)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func emptyState(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(MoonlitTheme.textTertiary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(MoonlitTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 32)
    }
}
