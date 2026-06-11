import SwiftUI
import LunaCore

struct MacDetailView: View {
    let mediaId: String
    let type: String
    let name: String
    let onBack: () -> Void

    @StateObject private var metaRepo = MetaRepository.shared
    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var watchedRepo = WatchProgressRepository.shared
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var showSourcePicker = false
    @State private var actorItem: Person?
    @State private var selectedSeasonId: String?
    @State private var selectedVideoId: String?
    @State private var selectedSeasonNum: Int?
    @State private var selectedEpisodeNum: Int?
    @Environment(\.openWindow) private var openWindow

    private let contentMaxWidth: CGFloat = 1120
    private let contentHorizontalPadding: CGFloat = 28

    var body: some View {
        ScrollView {
            if let detail = metaRepo.detail {
                VStack(alignment: .leading, spacing: 0) {
                    hero(for: detail)
                    actions(for: detail)
                        .padding(.top, 16)

                    if let description = detail.description, !description.isEmpty {
                        overview(description)
                            .padding(.top, 20)
                    }

                    if let genres = detail.genres, !genres.isEmpty {
                        genresView(genres)
                            .padding(.top, 16)
                    }

                    if let cast = detail.cast, !cast.isEmpty {
                        castView(cast)
                            .padding(.top, 20)
                    }

                    if let seasons = detail.seasons, !seasons.isEmpty {
                        episodesView(seasons)
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
                videoId: selectedVideoId,
                seasonNumber: selectedSeasonNum,
                episodeNumber: selectedEpisodeNum,
                onLaunch: { launch in
                    showSourcePicker = false
                    openWindow(id: "player", value: launch)
                }
            )
            .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(item: $actorItem) { actor in
            NavigationStack {
                MacActorBioView(name: actor.name, tmdbPersonId: nil)
            }
            .preferredColorScheme(.dark)
        }
        .task {
            await metaRepo.loadDetail(type: type, id: mediaId, addons: addonRepo.findAddonWithMetaResource(type: type))
            if let profile = profileManager.currentProfile {
                await libraryRepo.loadLibrary(profileId: profile.id)
                await watchedRepo.loadAll(profileId: profile.id)
            }
        }
    }

    private func hero(for detail: MetaDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            backdrop(for: detail.background)

            VStack {
                contentRail {
                    HStack {
                        Button { onBack() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .padding(.top, 16)
                Spacer()
            }

            contentRail {
                HStack(alignment: .bottom, spacing: 18) {
                    posterView(for: detail.poster)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(detail.name)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        if let info = detail.releaseInfo {
                            Text(info)
                                .font(.subheadline)
                                .foregroundColor(LunaTheme.textSecondary)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func backdrop(for background: String?) -> some View {
        if let background, let url = URL(string: background) {
            CachedAsyncImage(url: url) { image in
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
            } placeholder: {
                LunaTheme.surfaceElevated.frame(height: 320)
            }
        } else {
            LunaTheme.surfaceElevated.frame(height: 200)
        }
    }

    private func actions(for detail: MetaDetail) -> some View {
        contentRail {
            HStack(spacing: 12) {
                Button {
                    selectedVideoId = nil
                    selectedSeasonNum = nil
                    selectedEpisodeNum = nil
                    showSourcePicker = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        .foregroundColor(libraryRepo.isInLibrary(mediaId: detail.id) ? .white : LunaTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        .foregroundColor(watchedRepo.isWatched(mediaId: detail.id) ? .green : LunaTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    private func overview(_ description: String) -> some View {
        contentRail {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.body)
                    .foregroundColor(LunaTheme.textSecondary)
                    .lineLimit(6)
            }
        }
    }

    private func genresView(_ genres: [String]) -> some View {
        contentRail {
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
            }
        }
    }

    private func castView(_ cast: [Person]) -> some View {
        contentRail {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cast")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(cast.prefix(15)) { person in
                            Button {
                                actorItem = person
                            } label: {
                                VStack(spacing: 4) {
                                    Group {
                                        if let photo = person.photo, let url = URL(string: photo) {
                                            CachedAsyncImage(url: url) { img in
                                                img.resizable().scaledToFill()
                                            } placeholder: {
                                                Circle().fill(LunaTheme.surfaceElevated)
                                                    .overlay(
                                                        Text(String(person.name.prefix(1)))
                                                            .font(.headline)
                                                            .foregroundColor(LunaTheme.textSecondary)
                                                    )
                                            }
                                            .clipShape(Circle())
                                        } else {
                                            Circle()
                                                .fill(LunaTheme.surfaceElevated)
                                                .overlay(
                                                    Text(String(person.name.prefix(1)))
                                                        .font(.headline)
                                                        .foregroundColor(LunaTheme.textSecondary)
                                                )
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    Text(person.name)
                                        .font(.caption2)
                                        .foregroundColor(LunaTheme.textSecondary)
                                        .lineLimit(1)
                                        .frame(width: 64)
                                    if let character = person.character {
                                        Text(character)
                                            .font(.caption2)
                                            .foregroundColor(LunaTheme.textTertiary)
                                            .lineLimit(1)
                                            .frame(width: 64)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func episodesView(_ seasons: [Season]) -> some View {
        contentRail {
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
                                    .background(isSelectedSeason(season, in: seasons) ? Color.white : LunaTheme.surface)
                                    .foregroundColor(isSelectedSeason(season, in: seasons) ? .black : LunaTheme.textSecondary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let activeSeason = seasons.first(where: { $0.id == (selectedSeasonId ?? seasons.first?.id) }),
                   let episodes = activeSeason.episodes {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(episodes) { ep in
                                EpisodeCard(episode: ep)
                                    .onTapGesture {
                                        selectedVideoId = ep.id
                                        selectedSeasonNum = ep.season
                                        selectedEpisodeNum = ep.episode
                                        showSourcePicker = true
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func isSelectedSeason(_ season: Season, in seasons: [Season]) -> Bool {
        selectedSeasonId == season.id || (selectedSeasonId == nil && seasons.first?.id == season.id)
    }

    @ViewBuilder
    private func contentRail<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, contentHorizontalPadding)
    }

    @ViewBuilder
    private func posterView(for poster: String?) -> some View {
        if let poster, let url = URL(string: poster) {
            CachedAsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                LunaTheme.surfaceElevated
            }
            .frame(width: 118, height: 177)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
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
                    CachedAsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        EmptyView()
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
