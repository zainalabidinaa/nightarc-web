import SwiftUI
import LunaCore

struct LibraryScreen: View {
    @StateObject private var libraryRepo = LibraryRepository.shared
    @EnvironmentObject var profileManager: ProfileManager
    @State private var selectedMedia: MetaPreview?

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                if libraryRepo.isLoading {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                        spacing: 16
                    ) {
                        ForEach(0..<9, id: \.self) { _ in
                            ShimmerCard(width: 120, height: 180, cornerRadius: 8)
                        }
                    }
                    .padding()
                } else if libraryRepo.libraryItems.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "Your library is empty",
                        message: "Save movies and shows to watch later. Tap the bookmark icon on any title to add it here."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                            spacing: 16
                        ) {
                            ForEach(libraryRepo.libraryItems) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack {
                                        if let poster = item.poster, let url = URL(string: poster) {
                                            AsyncImage(url: url) { phase in
                                                if case .success(let image) = phase {
                                                    image.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 180)
                                                        .clipped()
                                                } else {
                                                    placeholderView(item: item)
                                                }
                                            }
                                        } else {
                                            placeholderView(item: item)
                                        }
                                    }
                                    .frame(width: 120, height: 180)
                                    .glassCard(cornerRadius: 8)

                                    Text(item.name ?? item.mediaId)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .frame(width: 120)
                                }
                                .onTapGesture {
                                    selectedMedia = MetaPreview(
                                        id: item.mediaId,
                                        type: item.mediaType == "series" ? .series : .movie,
                                        name: item.name ?? item.mediaId,
                                        poster: item.poster
                                    )
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            guard let profile = profileManager.currentProfile else { return }
                                            await libraryRepo.removeFromLibrary(
                                                profileId: profile.id,
                                                mediaId: item.mediaId
                                            )
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        guard let profile = profileManager.currentProfile else { return }
                        await libraryRepo.loadLibrary(profileId: profile.id)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedMedia) { media in
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
            .task {
                guard let profile = profileManager.currentProfile else { return }
                await libraryRepo.loadLibrary(profileId: profile.id)
            }
        }
    }

    @ViewBuilder
    private func placeholderView(item: LunaCore.LibraryItem) -> some View {
        Image(systemName: item.mediaType == "movie" ? "film" : "tv")
            .font(.title)
            .foregroundColor(LunaTheme.textTertiary)
            .frame(width: 120, height: 180)
    }
}
