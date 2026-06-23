import SwiftUI
import MoonlitCore

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
    @StateObject private var likedRepo = LikedRepository.shared
    @State private var showSourcePicker = false
    @State private var actorItem: Person?
    @State private var selectedSeasonId: String?
    @State private var selectedVideoId: String?
    @State private var selectedSeasonNum: Int?
    @State private var selectedEpisodeNum: Int?
    @State private var selectedInitialPositionMs: Double?
    @State private var isLiked = false
    @State private var showFullOverview = false
    @State private var trailers: [Trailer] = []
    @State private var moreLikeThisItems: [MetaPreview] = []
    @State private var trailerLink: URL?
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    private let contentMaxWidth: CGFloat = 1120
    private let contentHorizontalPadding: CGFloat = 28

    private var staleDetailLabel: String {
        guard let updatedAt = metaRepo.cachedDetailUpdatedAt else {
            return "Showing saved details"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last updated \(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
    }

    var body: some View {
        ScrollView {
            if let detail = metaRepo.detail {
                VStack(alignment: .leading, spacing: 0) {
                    hero(for: detail)

                    if metaRepo.isShowingStaleDetail {
                        staleIndicator
                    }

                    actions(for: detail)
                        .padding(.top, 16)

                    if let description = detail.description, !description.isEmpty {
                        overview(description)
                            .padding(.top, 20)
                    }

                    if let directors = detail.director, !directors.isEmpty {
                        directorsView(directors)
                            .padding(.top, 12)
                    }

                    if let genres = detail.genres, !genres.isEmpty {
                        genresView(genres)
                            .padding(.top, 16)
                    }

                    if let links = detail.links, !links.isEmpty {
                        linksView(links)
                            .padding(.top, 16)
                    }

                    if !trailers.isEmpty {
                        trailersView
                            .padding(.top, 20)
                    }

                    if let seasons = detail.seasons, !seasons.isEmpty {
                        episodesView(seasons)
                            .padding(.top, 20)
                    }

                    let related = moreLikeThisItems.isEmpty
                        ? (detail.moreLikeThis ?? [])
                        : moreLikeThisItems
                    if !related.isEmpty {
                        moreLikeThisView(related)
                            .padding(.top, 20)
                    }

                    if let cast = detail.cast, !cast.isEmpty {
                        castView(cast)
                            .padding(.top, 20)
                    }

                    Spacer().frame(height: 32)
                }
            } else if metaRepo.isLoading {
                VStack {
                    Spacer().frame(height: 200)
                    MacLottieLoadingView(size: 72)
                    Spacer()
                }
            } else if let error = metaRepo.errorMessage {
                VStack(spacing: 12) {
                    Spacer().frame(height: 200)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(MoonlitTheme.textSecondary)
                    Text(error)
                        .foregroundColor(MoonlitTheme.textSecondary)
                        .padding()
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
        .background(MoonlitTheme.background)
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
            MacActorBioView(name: actor.name, tmdbPersonId: nil)
                .frame(minWidth: 500, minHeight: 500)
        }
        .task {
            await metaRepo.loadDetail(type: type, id: mediaId, addons: addonRepo.findAddonWithMetaResource(type: type))
            if let profile = profileManager.currentProfile {
                await libraryRepo.loadLibrary(profileId: profile.id)
                await watchedRepo.loadAll(profileId: profile.id)
                isLiked = likedRepo.isLiked(mediaId)
            }
            Task.detached { await StreamWarmupRepository.shared.warmup(type: type, id: mediaId, addons: addonRepo.managedAddons.map(\.manifest)) }
        }
        .task(id: metaRepo.detail?.id) {
            guard let detail = metaRepo.detail else { return }
            await fetchTrailers(detail: detail)
            await fetchMoreLikeThis(detail: detail)
        }
    }

    // MARK: - Hero

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
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            if let rating = detail.imdbRating {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Text(rating)
                                        .font(.caption.bold())
                                        .foregroundColor(.yellow)
                                }
                            }
                            if let info = detail.releaseInfo {
                                Text(info)
                                    .font(.caption)
                                    .foregroundColor(MoonlitTheme.textSecondary)
                            }
                            if let runtime = detail.runtime {
                                Text(runtime)
                                    .font(.caption)
                                    .foregroundColor(MoonlitTheme.textSecondary)
                            }
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
                    .frame(height: 340)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, MoonlitTheme.background],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            } placeholder: {
                MoonlitTheme.surfaceElevated.frame(height: 340)
            }
        } else {
            MoonlitTheme.surfaceElevated.frame(height: 200)
        }
    }

    private var staleIndicator: some View {
        contentRail {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .semibold))
                Text(staleDetailLabel)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.72))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08), in: Capsule())
        }
        .padding(.top, 10)
    }

    // MARK: - Actions

    private func actions(for detail: MetaDetail) -> some View {
        contentRail {
            HStack(spacing: 12) {
                let progress = watchedRepo.getProgress(mediaId: detail.id)
                let watched = watchedRepo.isWatched(mediaId: detail.id)

                Button {
                    selectedVideoId = nil
                    selectedSeasonNum = nil
                    selectedEpisodeNum = nil
                    let initMs = progress.map { $0.positionSeconds * 1000 }
                    selectedInitialPositionMs = initMs
                    showSourcePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: progress == nil ? "play.fill" : "play.circle.fill")
                        Text(playButtonTitle(hasProgress: progress != nil, isWatched: watched, progress: progress))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            poster: detail.rawPosterUrl ?? detail.poster
                        )
                    }
                } label: {
                    Image(systemName: libraryRepo.isInLibrary(mediaId: detail.id) ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .padding(12)
                        .background(MoonlitTheme.surface)
                        .foregroundColor(libraryRepo.isInLibrary(mediaId: detail.id) ? .white : MoonlitTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        guard let profile = profileManager.currentProfile else { return }
                        if isLiked {
                            await likedRepo.removeLiked(mediaId: detail.id, profileId: profile.id)
                        } else {
                            await likedRepo.addLiked(LikedItem(
                                mediaId: detail.id,
                                mediaType: type,
                                name: detail.name,
                                poster: detail.rawPosterUrl ?? detail.poster,
                                tmdbId: nil
                            ), profileId: profile.id)
                        }
                        isLiked = likedRepo.isLiked(detail.id)
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title3)
                        .padding(12)
                        .background(MoonlitTheme.surface)
                        .foregroundColor(isLiked ? .red : MoonlitTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .onAppear { isLiked = likedRepo.isLiked(detail.id) }

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
                        .background(MoonlitTheme.surface)
                        .foregroundColor(watchedRepo.isWatched(mediaId: detail.id) ? .green : MoonlitTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    private func playButtonTitle(hasProgress: Bool, isWatched: Bool, progress: WatchProgressEntry?) -> String {
        if isWatched { return "Rewatch" }
        if let progress, progress.progressFraction > 0.01 {
            if let season = progress.season, let episode = progress.episode {
                return "Continue · S\(season)E\(episode)"
            }
            let minutes = Int(progress.positionSeconds / 60)
            let seconds = Int(progress.positionSeconds) % 60
            return "Continue · \(minutes):\(String(format: "%02d", seconds))"
        }
        return "Play"
    }

    // MARK: - Overview

    private func overview(_ description: String) -> some View {
        contentRail {
            Button {
                showFullOverview.toggle()
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.body)
                        .foregroundColor(MoonlitTheme.textSecondary)
                        .lineLimit(showFullOverview ? nil : 3)
                        .multilineTextAlignment(.leading)
                    if !showFullOverview {
                        Text("More")
                            .font(.caption.bold())
                            .foregroundColor(MoonlitTheme.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Directors

    private func directorsView(_ directors: [Person]) -> some View {
        contentRail {
            VStack(alignment: .leading, spacing: 4) {
                Text("Director")
                    .font(.caption)
                    .foregroundColor(MoonlitTheme.textTertiary)
                Text(directors.map(\.name).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Genres

    private func genresView(_ genres: [String]) -> some View {
        contentRail {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(genres, id: \.self) { genre in
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MoonlitTheme.surface)
                            .foregroundColor(MoonlitTheme.textSecondary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Links

    private func linksView(_ links: [MetaLink]) -> some View {
        let networks = links.filter { $0.category?.lowercased() == "network" }
        let studios = links.filter { $0.category?.lowercased() == "production" }
        return Group {
            if !networks.isEmpty || !studios.isEmpty {
                contentRail {
                    VStack(alignment: .leading, spacing: 8) {
                        if !networks.isEmpty {
                            linkRow(label: "NETWORK", links: networks)
                        }
                        if !studios.isEmpty {
                            linkRow(label: "PRODUCTION", links: studios)
                        }
                    }
                }
            }
        }
    }

    private func linkRow(label: String, links: [MetaLink]) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(MoonlitTheme.textTertiary)
                .frame(width: 80, alignment: .leading)
            ForEach(links) { link in
                Button {
                    if let url = URL(string: link.url) {
                        openURL(url)
                    }
                } label: {
                    Text(link.name)
                        .font(.subheadline)
                        .foregroundColor(MoonlitTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Trailers

    private var trailersView: some View {
        VStack(alignment: .leading, spacing: 10) {
            contentRail {
                Text("Trailers")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trailers) { trailer in
                        TrailerCard(trailer: trailer) {
                            if let url = trailer.url.flatMap(URL.init) {
                                openURL(url)
                            }
                        }
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
            }
        }
    }

    // MARK: - More Like This

    private func moreLikeThisView(_ items: [MetaPreview]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            contentRail {
                Text("More Like This")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items.prefix(20)) { item in
                        MediaCard(item: item, width: 154, height: 231)
                            .onTapGesture {
                                onBack()
                            }
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
            }
        }
    }

    // MARK: - Cast

    private func castView(_ cast: [Person]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            contentRail {
                Text("Cast")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(cast.prefix(15)) { person in
                        Button {
                            actorItem = person
                        } label: {
                            VStack(spacing: 4) {
                                let photoURL = person.photo.flatMap(URL.init)
                                if let url = photoURL {
                                    CachedAsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        castPlaceholder(for: person.name)
                                    }
                                    .frame(width: 72, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                } else {
                                    castPlaceholder(for: person.name)
                                        .frame(width: 72, height: 100)
                                }
                                Text(person.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 80)
                                if let character = person.character {
                                    Text(character)
                                        .font(.caption2)
                                        .foregroundColor(MoonlitTheme.textTertiary)
                                        .lineLimit(1)
                                        .frame(width: 80)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
            }
        }
    }

    @ViewBuilder
    private func castPlaceholder(for name: String) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(MoonlitTheme.surfaceElevated)
            .overlay(
                Text(String(name.prefix(1)))
                    .font(.title2)
                    .foregroundColor(MoonlitTheme.textSecondary)
            )
    }

    // MARK: - Episodes

    private func episodesView(_ seasons: [Season]) -> some View {
        let sorted = seasons.filter { $0.number != 0 }.sorted { $0.number < $1.number }
        let activeId = selectedSeasonId ?? sorted.first?.id

        return contentRail {
            VStack(alignment: .leading, spacing: 12) {
                Text("Episodes")
                    .font(.headline)
                    .foregroundColor(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sorted) { season in
                            let isActive = season.id == activeId
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedSeasonId = season.id
                                }
                            } label: {
                                Text("Season \(season.number)")
                                    .font(.subheadline.weight(isActive ? .bold : .medium))
                                    .foregroundColor(isActive ? .black : .white.opacity(0.85))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(
                                            isActive ? AnyShapeStyle(Color.white)
                                                     : AnyShapeStyle(Color.white.opacity(0.06))
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let activeSeason = sorted.first(where: { $0.id == activeId }),
                   let episodes = activeSeason.episodes {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(episodes) { ep in
                                let seasonNumber = ep.season ?? activeSeason.number
                                let progress = watchedRepo.getEpisodeProgress(
                                    parentMediaId: detailId(for: activeSeason),
                                    season: seasonNumber,
                                    episode: ep.episode
                                )
                                let watched = watchedRepo.isEpisodeWatched(
                                    parentMediaId: detailId(for: activeSeason),
                                    season: seasonNumber,
                                    episode: ep.episode
                                )
                                EpisodeCard(
                                    episode: ep,
                                    progressFraction: progress?.progressFraction,
                                    isWatched: watched
                                )
                                .onTapGesture {
                                    selectedVideoId = ep.id
                                    selectedSeasonNum = seasonNumber
                                    selectedEpisodeNum = ep.episode
                                    let initMs = progress.map { $0.positionSeconds * 1000 }
                                    selectedInitialPositionMs = initMs
                                    showSourcePicker = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func detailId(for season: Season) -> String {
        metaRepo.detail?.id ?? mediaId
    }

    // MARK: - Data Fetching

    private func fetchTrailers(detail: MetaDetail) async {
        var allTrailers: [Trailer] = []
        let streailerBase = "https://streailer.elfhosted.com"

        if let streams = try? await StreamService.shared.fetchStreams(
            type: type,
            id: mediaId,
            baseURL: streailerBase
        ) {
            let trailers = streams.compactMap { stream -> Trailer? in
                guard let name = stream.name, !name.isEmpty else { return nil }
                return Trailer(name: name, url: stream.url)
            }
            allTrailers.append(contentsOf: trailers)
        }

        await MainActor.run { self.trailers = allTrailers }
    }

    private func fetchMoreLikeThis(detail: MetaDetail) async {
        await MainActor.run { self.moreLikeThisItems = detail.moreLikeThis ?? [] }
    }

    // MARK: - Helpers

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
                MoonlitTheme.surfaceElevated
            }
            .frame(width: 118, height: 177)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        }
    }
}

// MARK: - Trailer Model

private struct Trailer: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let url: String?
}

// MARK: - Trailer Card

private struct TrailerCard: View {
    let trailer: Trailer
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MoonlitTheme.surfaceElevated)
                        .frame(width: 280, height: 158)

                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(trailer.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 280, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Episode Card

struct EpisodeCard: View {
    let episode: MetaVideo
    var progressFraction: Double?
    var isWatched: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(MoonlitTheme.surfaceElevated)
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

                if isWatched {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                } else {
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

                if let fraction = progressFraction, fraction > 0, !isWatched {
                    VStack {
                        Spacer()
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: geo.size.width * CGFloat(fraction), height: 3)
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }
            }
            .frame(width: 220, height: 124)

            HStack {
                if let epNum = episode.episode {
                    Text("E\(epNum)")
                        .font(.caption2.bold())
                        .foregroundColor(MoonlitTheme.accent)
                }
                Text(episode.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 220, alignment: .leading)

            if let overview = episode.overview {
                Text(overview)
                    .font(.caption2)
                    .foregroundColor(MoonlitTheme.textSecondary)
                    .lineLimit(2)
                    .frame(width: 220, alignment: .leading)
            }
        }
    }
}

// MARK: - DetailItem (for window-based navigation)

struct DetailItem: Codable, Hashable {
    let mediaId: String
    let type: String
    let name: String
}
