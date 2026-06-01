import SwiftUI
import LunaCore

struct MacDetailView: View {
    let mediaId: String
    let type: String
    let name: String

    @StateObject private var metaRepo = MetaRepository.shared
    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var watchedRepo = WatchProgressRepository.shared
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var showSourcePicker = false
    @State private var showPlayer = false
    @State private var playerLaunch: PlayerLaunch?
    @State private var selectedSeasonId: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            if let detail = metaRepo.detail {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        if let bg = detail.background, let url = URL(string: bg) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 320)
                                        .clipped()
                                        .overlay(
                                            LinearGradient(
                                                colors: [.clear, LunaTheme.background],
                                                startPoint: .center,
                                                endPoint: .bottom
                                            )
                                        )
                                default:
                                    LunaTheme.surfaceElevated.frame(height: 320)
                                }
                            }
                        } else {
                            LunaTheme.surfaceElevated.frame(height: 200)
                        }

                        HStack(alignment: .bottom, spacing: 16) {
                            if let poster = detail.poster, let url = URL(string: poster) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 110, height: 165)
                                            .cornerRadius(8)
                                    } else {
                                        LunaTheme.surfaceElevated
                                            .frame(width: 110, height: 165)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(detail.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                if let info = detail.releaseInfo {
                                    Text(info)
                                        .font(.subheadline)
                                        .foregroundColor(LunaTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }

                    HStack(spacing: 12) {
                        Button {
                            showSourcePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(LunaTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                guard let profile = profileManager.currentProfile else { return }
                                await libraryRepo.toggleLibrary(
                                    profileId: profile.id,
                                    mediaId: detail.id,
                                    mediaType: type,
                                    name: detail.name,
                                    poster: detail.poster
                                )
                            }
                        } label: {
                            Image(systemName: libraryRepo.isInLibrary(mediaId: detail.id) ? "bookmark.fill" : "bookmark")
                                .font(.title3)
                                .padding(12)
                                .background(LunaTheme.surface)
                                .foregroundColor(libraryRepo.isInLibrary(mediaId: detail.id) ? LunaTheme.accent : .white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                guard let profile = profileManager.currentProfile else { return }
                                if watchedRepo.isWatched(mediaId: detail.id) {
                                    await watchedRepo.markUnwatched(mediaId: detail.id)
                                } else {
                                    await watchedRepo.markWatched(
                                        profileId: profile.id,
                                        mediaId: detail.id,
                                        mediaType: type,
                                        name: detail.name,
                                        poster: detail.poster
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: watchedRepo.isWatched(mediaId: detail.id) ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title3)
                                .padding(12)
                                .background(LunaTheme.surface)
                                .foregroundColor(watchedRepo.isWatched(mediaId: detail.id) ? .green : .white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    if let description = detail.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overview")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(description)
                                .font(.body)
                                .foregroundColor(LunaTheme.textSecondary)
                                .lineLimit(6)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }

                    if let genres = detail.genres, !genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(genres, id: \.self) { genre in
                                    Text(genre)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(LunaTheme.surface)
                                        .foregroundColor(LunaTheme.textSecondary)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 16)
                    }

                    if let cast = detail.cast, !cast.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cast")
                                .font(.headline)
                                .foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(cast.prefix(15)) { person in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(LunaTheme.surfaceElevated)
                                                .frame(width: 56, height: 56)
                                                .overlay(
                                                    Text(String(person.name.prefix(1)))
                                                        .font(.headline)
                                                        .foregroundColor(LunaTheme.textSecondary)
                                                )
                                            Text(person.name)
                                                .font(.caption2)
                                                .foregroundColor(LunaTheme.textSecondary)
                                                .lineLimit(1)
                                                .frame(width: 64)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 20)
                    }

                    if let seasons = detail.seasons, !seasons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Episodes")
                                .font(.headline)
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(seasons.sorted(by: { $0.number < $1.number })) { season in
                                        Button {
                                            selectedSeasonId = season.id
                                        } label: {
                                            Text("Season \(season.number)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    (selectedSeasonId == season.id || (selectedSeasonId == nil && seasons.first?.id == season.id))
                                                        ? Color.white : LunaTheme.surface
                                                )
                                                .foregroundColor(
                                                    (selectedSeasonId == season.id || (selectedSeasonId == nil && seasons.first?.id == season.id))
                                                        ? .black : LunaTheme.textSecondary
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            if let activeSeason = seasons.first(where: { $0.id == (selectedSeasonId ?? seasons.first?.id) }),
                               let episodes = activeSeason.episodes {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(episodes) { ep in
                                            EpisodeCard(episode: ep)
                                                .onTapGesture {
                                                    showSourcePicker = true
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }

                    Spacer().frame(height: 32)
                }
            } else if metaRepo.isLoading {
                VStack {
                    Spacer().frame(height: 200)
                    ProgressView().tint(LunaTheme.accent)
                    Spacer()
                }
            } else if let error = metaRepo.errorMessage {
                Text(error).foregroundColor(.red).padding()
            }
        }
        .background(LunaTheme.background)
        .sheet(isPresented: $showSourcePicker) {
            MacSourcePickerView(
                mediaType: MediaType(rawValue: type) ?? .movie,
                mediaId: mediaId,
                mediaName: metaRepo.detail?.name ?? name,
                poster: metaRepo.detail?.poster,
                logo: metaRepo.detail?.logo,
                onLaunch: { launch in
                    playerLaunch = launch
                    showSourcePicker = false
                    showPlayer = true
                }
            )
            .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(isPresented: $showPlayer) {
            if let launch = playerLaunch {
                MacPlayerView(launch: launch)
                    .frame(minWidth: 900, minHeight: 550)
            }
        }
        .task {
            await metaRepo.loadDetail(type: type, id: mediaId, addons: addonRepo.findAddonWithMetaResource(type: type))
            if let profile = profileManager.currentProfile {
                await libraryRepo.loadLibrary(profileId: profile.id)
                await watchedRepo.loadAll(profileId: profile.id)
            }
        }
    }
}

struct EpisodeCard: View {
    let episode: MetaVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LunaTheme.surfaceElevated)
                    .frame(width: 220, height: 124)

                if let thumb = episode.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 220, height: 124)
                    .clipped()
                    .cornerRadius(10)
                }

                Color.black.opacity(0.3).cornerRadius(10)

                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .offset(x: 1.5)
                    )
            }
            .frame(width: 220, height: 124)

            Text(episode.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)

            if let overview = episode.overview {
                Text(overview)
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textSecondary)
                    .lineLimit(2)
                    .frame(width: 220, alignment: .leading)
            }
        }
    }
}
