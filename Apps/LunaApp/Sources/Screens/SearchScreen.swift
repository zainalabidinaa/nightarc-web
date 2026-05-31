import SwiftUI
import LunaCore

struct SearchScreen: View {
    @StateObject private var searchRepo = SearchRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var query = ""
    @State private var selectedMedia: MetaPreview?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search movies & shows...", text: $query)
                    .padding()
                    .background(LunaTheme.surface)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding()
                    .onSubmit {
                        Task { await searchRepo.search(query: query, addons: addonRepo.enabledAddons) }
                    }

                if searchRepo.isLoading {
                    Spacer()
                    ProgressView().tint(LunaTheme.accent)
                    Spacer()
                } else if searchRepo.results.isEmpty && !searchRepo.searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundColor(LunaTheme.textTertiary)
                        Text("No results found")
                            .foregroundColor(LunaTheme.textSecondary)
                    }
                    Spacer()
                } else {
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
