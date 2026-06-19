import SwiftUI
import MoonlitCore

struct SearchScreen: View {
    @StateObject private var searchRepo = SearchRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var query = ""
    @State private var selectedMedia: MetaPreview?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MoonlitTheme.textTertiary)
                    TextField("Search movies & shows...", text: $query)
                        .foregroundColor(.white)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(MoonlitTheme.textTertiary)
                        }
                    }
                }
                .padding()
                .glassCard(cornerRadius: 14)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .onChange(of: query) { _, newValue in
                    searchTask?.cancel()
                    guard !newValue.isEmpty else {
                        searchRepo.results = []
                        return
                    }
                    searchTask = Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        guard !Task.isCancelled else { return }
                        await searchRepo.search(query: newValue, addons: addonRepo.enabledAddons)
                    }
                }

                if searchRepo.isLoading {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { _ in
                                SearchResultRowShimmer()
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if searchRepo.results.isEmpty && !searchRepo.searchQuery.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results found",
                        message: "Try a different search term or check your spelling"
                    )
                    Spacer()
                } else if !searchRepo.results.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: []) {
                            ForEach(searchRepo.results) { item in
                                SearchResultRow(item: item)
                                    .onTapGesture { selectedMedia = item }
                                if item.id != searchRepo.results.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.leading, 72)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .glassCard(cornerRadius: 14)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await searchRepo.search(query: query, addons: addonRepo.enabledAddons)
                    }
                } else {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Discover content",
                        message: "Search for movies and TV shows across all your connected addons"
                    )
                    Spacer()
                }
            }
            .background(MoonlitTheme.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedMedia) { media in
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
        }
    }
}

// MARK: - List row

private struct SearchResultRow: View {
    let item: MetaPreview

    private var isMovie: Bool { item.type == .movie }
    private var typeColor: Color { isMovie ? MoonlitTheme.accent : Color(red: 0.4, green: 0.7, blue: 1.0) }

    var body: some View {
        HStack(spacing: 14) {
            // Poster thumbnail
            Group {
                let posterURL = PosterService.posterURL(forImdbId: item.id) ?? item.poster
                if let urlStr = posterURL, let url = URL(string: urlStr) {
                    CachedAsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            posterPlaceholder
                        }
                    }
                } else {
                    posterPlaceholder
                }
            }
            .frame(width: 52, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Type badge
                    HStack(spacing: 4) {
                        Image(systemName: isMovie ? "film.fill" : "tv.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text(isMovie ? "Movie" : "Series")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.15), in: Capsule())

                    // IMDb rating
                    if let rating = item.imdbRating, !rating.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                            Text(rating)
                                .font(.caption.weight(.medium))
                                .foregroundColor(MoonlitTheme.textSecondary)
                        }
                    }

                    // Year
                    if let year = item.releaseInfo, !year.isEmpty {
                        Text(year)
                            .font(.caption)
                            .foregroundColor(MoonlitTheme.textTertiary)
                    }
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoonlitTheme.textTertiary.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var posterPlaceholder: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
            startPoint: .top, endPoint: .bottom
        )
        .overlay(
            Image(systemName: isMovie ? "film" : "tv")
                .font(.body)
                .foregroundColor(MoonlitTheme.textTertiary)
        )
    }
}

// MARK: - Shimmer row

private struct SearchResultRowShimmer: View {
    var body: some View {
        HStack(spacing: 12) {
            ShimmerCard(width: 44, height: 62, cornerRadius: 6)
            VStack(alignment: .leading, spacing: 6) {
                ShimmerCard(width: 180, height: 14, cornerRadius: 4)
                ShimmerCard(width: 90, height: 11, cornerRadius: 4)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
