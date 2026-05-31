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
                    ProgressView().tint(LunaTheme.accent)
                } else if libraryRepo.libraryItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40))
                            .foregroundColor(LunaTheme.textTertiary)
                        Text("Your library is empty")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Save movies and shows to watch later")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                            spacing: 16
                        ) {
                            ForEach(libraryRepo.libraryItems) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LunaTheme.surfaceElevated)
                                            .frame(width: 120, height: 180)

                                        if let poster = item.poster, let url = URL(string: poster) {
                                            AsyncImage(url: url) { phase in
                                                if case .success(let image) = phase {
                                                    image.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 180)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                }
                                            }
                                        } else {
                                            Image(systemName: item.mediaType == "movie" ? "film" : "tv")
                                                .font(.title)
                                                .foregroundColor(LunaTheme.textTertiary)
                                        }
                                    }

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
                                .contextMenu {
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
}
