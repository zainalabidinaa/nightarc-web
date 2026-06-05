import SwiftUI
import LunaCore

struct DetailScreen: View {
    let mediaId: String
    let type: String
    let name: String

    @StateObject private var metaRepo = MetaRepository.shared
    @StateObject private var libraryRepo = LibraryRepository.shared
    @StateObject private var watchedRepo = WatchProgressRepository.shared
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared

    @State private var showStreamSelection = false
    @State private var selectedSeasonId: String? = nil

    var body: some View {
        ScrollView {
            if let detail = metaRepo.detail {
                VStack(alignment: .leading, spacing: 0) {

                    // ── BACKDROP ──────────────────────────────────────────
                    // Use GeometryReader to extend the image under the status bar
                    // WITHOUT putting ignoresSafeArea on an inner view (which breaks
                    // sibling layout frames and strips horizontal padding below).
                    GeometryReader { geo in
                        let topInset = geo.safeAreaInsets.top
                        let backdropURL = detail.background.flatMap(URL.init)
                            ?? detail.poster.flatMap(URL.init)

                        ZStack(alignment: .bottom) {
                            if let url = backdropURL {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 320 + topInset)
                                            .clipped()
                                    } else {
                                        Color(LunaTheme.surfaceElevated)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 320 + topInset)
                                    }
                                }
                            } else {
                                Color(LunaTheme.surfaceElevated)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 320 + topInset)
                            }

                            LinearGradient(
                                stops: [
                                    .init(color: .clear,                            location: 0.0),
                                    .init(color: .clear,                            location: 0.35),
                                    .init(color: LunaTheme.background.opacity(0.6), location: 0.65),
                                    .init(color: LunaTheme.background,              location: 1.0),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 320 + topInset)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 320 + topInset)
                    }
                    // Fixed layout height the VStack sees — GeometryReader
                    // renders taller internally to cover the safe area
                    .frame(height: 320)

                    // ── POSTER + TITLE ────────────────────────────────────
                    // .offset(y:) moves the view visually without disturbing
                    // sibling layout frames — safe alternative to negative padding
                    HStack(alignment: .bottom, spacing: 14) {
                        if let poster = detail.poster, let url = URL(string: poster) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable()
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(width: 110, height: 165)
                                        .cornerRadius(10)
                                        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LunaTheme.surfaceElevated)
                                        .frame(width: 110, height: 165)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(detail.name)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)

                            // Meta row
                            HStack(spacing: 6) {
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
                                if let release = detail.releaseInfo {
                                    Text(release)
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textSecondary)
                                }
                                if let runtime = detail.runtime {
                                    Text(runtime)
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textSecondary)
                                }
                            }

                            if let genres = detail.genres?.prefix(3), !genres.isEmpty {
                                HStack(spacing: 5) {
                                    ForEach(Array(genres), id: \.self) { genre in
                                        Text(genre)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(LunaTheme.textSecondary)
                                            .padding(.horizontal, 7).padding(.vertical, 3)
                                            .overlay(
                                                Capsule()
                                                    .stroke(LunaTheme.textTertiary.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .padding(.horizontal, 16)
                    .offset(y: -50)          // visually floats into backdrop bottom
                    .padding(.bottom, -50)   // cancel the extra space .offset leaves

                    // ── ACTION BUTTONS ────────────────────────────────────
                    HStack(spacing: 10) {
                        Button { showStreamSelection = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill").font(.subheadline)
                                Text("Play").font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LunaTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        let inLibrary = libraryRepo.isInLibrary(mediaId: detail.id)
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
                            Image(systemName: inLibrary ? "bookmark.fill" : "bookmark")
                                .font(.title3)
                                .frame(width: 50, height: 50)
                                .background(LunaTheme.surfaceElevated)
                                .foregroundColor(inLibrary ? LunaTheme.accent : .white)
                                .cornerRadius(10)
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: inLibrary)

                        let watched = watchedRepo.isWatched(mediaId: detail.id)
                        Button {
                            Task {
                                guard let profile = profileManager.currentProfile else { return }
                                if watched {
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
                            Image(systemName: watched ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title3)
                                .frame(width: 50, height: 50)
                                .background(LunaTheme.surfaceElevated)
                                .foregroundColor(watched ? .green : .white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // ── OVERVIEW ──────────────────────────────────────────
                    if let description = detail.description, !description.isEmpty {
                        ExpandableText(text: description)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                    }

                    // ── DETAILS CHIPS ─────────────────────────────────────
                    detailChips(detail: detail)

                    // ── CAST ──────────────────────────────────────────────
                    if let cast = detail.cast, !cast.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Cast")
                                .font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(cast.prefix(20)) { person in
                                        VStack(spacing: 5) {
                                            Circle()
                                                .fill(LunaTheme.surfaceElevated)
                                                .frame(width: 54, height: 54)
                                                .overlay(
                                                    Text(String(person.name.prefix(1)).uppercased())
                                                        .font(.headline)
                                                        .foregroundColor(LunaTheme.textSecondary)
                                                )
                                            Text(person.name)
                                                .font(.caption2)
                                                .foregroundColor(LunaTheme.textSecondary)
                                                .lineLimit(1)
                                                .frame(width: 60)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 20)
                    }

                    // ── EPISODES ──────────────────────────────────────────
                    if let seasons = detail.seasons, !seasons.isEmpty {
                        let sorted = seasons.sorted { $0.number < $1.number }
                        let activeId = selectedSeasonId ?? sorted.first?.id

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Episodes")
                                .font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 16)

                            // Season picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(sorted) { season in
                                        Button { selectedSeasonId = season.id } label: {
                                            Text("Season \(season.number)")
                                                .font(.subheadline.weight(.medium))
                                                .padding(.horizontal, 14).padding(.vertical, 7)
                                                .background(
                                                    season.id == activeId
                                                        ? LunaTheme.accent
                                                        : LunaTheme.surfaceElevated
                                                )
                                                .foregroundColor(season.id == activeId ? .white : LunaTheme.textSecondary)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            if let activeSeason = sorted.first(where: { $0.id == activeId }),
                               let episodes = activeSeason.episodes {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(episodes) { ep in
                                            EpisodeCard(episode: ep) {
                                                showStreamSelection = true
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }

                    // ── NETWORK / PRODUCTION ──────────────────────────────
                    if let links = detail.links, !links.isEmpty {
                        let networks = links.filter { $0.category?.lowercased() == "network" }
                        let studios  = links.filter { $0.category?.lowercased() == "production" }
                        if !networks.isEmpty || !studios.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                if !networks.isEmpty {
                                    linkRow(label: "NETWORK", links: networks)
                                }
                                if !studios.isEmpty {
                                    linkRow(label: "PRODUCTION", links: studios)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        }
                    }

                    Spacer().frame(height: 48)
                }
            } else if metaRepo.isLoading {
                VStack {
                    Spacer().frame(height: 280)
                    ProgressView().tint(LunaTheme.accent)
                    Spacer()
                }
            } else if let error = metaRepo.errorMessage {
                VStack {
                    Spacer().frame(height: 200)
                    Text(error).foregroundColor(LunaTheme.textSecondary).padding().multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(LunaTheme.background)
        .refreshable {
            await metaRepo.loadDetail(
                type: type,
                id: mediaId,
                addons: addonRepo.findAddonWithMetaResource(type: type)
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStreamSelection) {
            StreamSelectionScreen(
                mediaType: MediaType(rawValue: type) ?? .movie,
                mediaId: mediaId,
                mediaName: metaRepo.detail?.name ?? name,
                poster: metaRepo.detail?.poster,
                logo: metaRepo.detail?.logo
            )
        }
        .task {
            if addonRepo.enabledAddons.isEmpty, let profile = profileManager.currentProfile {
                await addonRepo.loadAddons(profileId: profile.id)
            }
            await metaRepo.loadDetail(
                type: type,
                id: mediaId,
                addons: addonRepo.findAddonWithMetaResource(type: type)
            )
            if let profile = profileManager.currentProfile {
                await libraryRepo.loadLibrary(profileId: profile.id)
                await watchedRepo.loadAll(profileId: profile.id)
            }
        }
    }

    @ViewBuilder
    private func detailChips(detail: MetaDetail) -> some View {
        let hasGenres  = !(detail.genres ?? []).isEmpty
        let hasDirector = !(detail.director ?? []).isEmpty
        if hasGenres || hasDirector {
            VStack(alignment: .leading, spacing: 14) {
                if hasGenres {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GENRES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(LunaTheme.textTertiary)
                            .tracking(1.5)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(detail.genres!, id: \.self) { genre in
                                    Text(genre)
                                        .font(.caption)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(LunaTheme.surfaceElevated)
                                        .foregroundColor(LunaTheme.textSecondary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                if hasDirector {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DIRECTOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(LunaTheme.textTertiary)
                            .tracking(1.5)
                        Text(detail.director!.map(\.name).joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private func linkRow(label: String, links: [MetaLink]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(LunaTheme.textTertiary)
                .tracking(1.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(links) { link in
                        Text(link.name)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(LunaTheme.textSecondary)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(LunaTheme.surfaceElevated)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

// MARK: - Expandable overview text

private struct ExpandableText: View {
    let text: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(LunaTheme.textSecondary)
                .lineLimit(expanded ? nil : 3)
                .animation(.easeInOut(duration: 0.2), value: expanded)

            Button { expanded.toggle() } label: {
                Text(expanded ? "Less" : "More")
                    .font(.caption.bold())
                    .foregroundColor(LunaTheme.accent)
            }
        }
    }
}

// MARK: - Episode Card

struct EpisodeCard: View {
    let episode: MetaVideo
    let onPlay: () -> Void

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
                                .frame(width: 220, height: 124)
                                .clipped()
                                .cornerRadius(10)
                        } else {
                            episodePlaceholder
                        }
                    }
                    .frame(width: 220, height: 124)
                } else {
                    episodePlaceholder
                }

                // Play button
                Button(action: onPlay) {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .offset(x: 1.5)
                        )
                }
            }
            .frame(width: 220, height: 124)

            if let epNum = episode.episode {
                Text("Episode \(epNum)")
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textTertiary)
            }
            Text(episode.title)
                .font(.caption.weight(.semibold))
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

    private var episodePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LunaTheme.surfaceElevated)
            .frame(width: 220, height: 124)
            .overlay(
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundColor(LunaTheme.textTertiary)
            )
    }
}

struct SeasonDetailScreen: View {
    let season: Season
    let seriesName: String

    var body: some View {
        List {
            if let episodes = season.episodes {
                ForEach(episodes) { episode in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("E\(episode.episode ?? 0): \(episode.title)")
                                .foregroundColor(.white)
                            if let overview = episode.overview {
                                Text(overview)
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        if let runtime = episode.runtime {
                            Text(runtime)
                                .font(.caption2)
                                .foregroundColor(LunaTheme.textTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(LunaTheme.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(LunaTheme.background)
        .navigationTitle(season.name ?? "Season \(season.number)")
    }
}
