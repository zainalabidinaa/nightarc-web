import SwiftUI
import LunaCore

struct SearchScreen: View {
    @StateObject private var searchRepo = SearchRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var query = ""
    @State private var selectedMedia: MetaPreview?
    @State private var searchTask: Task<Void, Never>?

    private let filters = ["Trending", "Movies", "Shows"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(LunaTheme.textTertiary)
                    TextField("Search movies & shows...", text: $query)
                        .foregroundColor(.white)
                }
                .padding()
                .glassCard(cornerRadius: 14)
                .padding()
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                // filter toggle
                            } label: {
                                Text(filter)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                            }
                            .glassCapsule(interactive: true)
                            .foregroundColor(LunaTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)

                if searchRepo.isLoading {
                    Spacer()
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                        spacing: 16
                    ) {
                        ForEach(0..<9, id: \.self) { _ in
                            ShimmerCard(width: 120, height: 180, cornerRadius: 8)
                        }
                    }
                    .padding()
                    Spacer()
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
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                            spacing: 16
                        ) {
                            ForEach(searchRepo.results) { item in
                                ContentCard(item: item)
                                    .onTapGesture {
                                        selectedMedia = item
                                    }
                            }
                        }
                        .padding()
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
            .background(LunaTheme.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedMedia) { media in
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
        }
    }
}
