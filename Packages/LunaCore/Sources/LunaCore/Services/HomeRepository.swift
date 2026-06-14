import Foundation

@MainActor
public class HomeRepository: ObservableObject {
    public static let shared = HomeRepository()

    @Published public var continueWatchingItems: [ContinueWatchingItem] = []
    @Published public var isLoadingContinueWatching = false

    private let syncService = SyncService.shared

    private init() {}

    public nonisolated static func latestEntriesForContinueWatching(
        _ progress: [WatchProgressEntry],
        limit: Int = 10
    ) -> [WatchProgressEntry] {
        let sorted = progress
            .filter { !$0.completed && $0.positionSeconds > 0 }
            .sorted { a, b in
                // Prefer entries whose mediaId explicitly encodes a specific episode
                // (e.g. "tt9813792:4:9") over bare series IDs (e.g. "tt9813792").
                // A ghost entry (series-only mediaId) can end up with a newer timestamp
                // when the app re-saves with no episode suffix, pushing a real episode
                // entry out of Continue Watching.
                let aIsEpisodeSpecific = a.decodedMediaId.components(separatedBy: ":").count >= 3
                let bIsEpisodeSpecific = b.decodedMediaId.components(separatedBy: ":").count >= 3
                if aIsEpisodeSpecific != bIsEpisodeSpecific { return aIsEpisodeSpecific }
                return a.updatedAt > b.updatedAt
            }

        var seenKeys = Set<String>()
        var entries: [WatchProgressEntry] = []
        for entry in sorted {
            let type = entry.mediaType.lowercased()
            let key: String
            switch type {
            case "series", "tv", "show", "shows", "anime":
                key = "series:\(entry.parentOrSelfMediaId)"
            default:
                key = "\(type):\(entry.decodedMediaId)"
            }

            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            entries.append(entry)
            if entries.count == limit { break }
        }
        return entries
    }

    public func loadContinueWatching(profileId: String) async {
        isLoadingContinueWatching = true
        defer { isLoadingContinueWatching = false }

        do {
            let progress = try await syncService.pullWatchProgress(profileId: profileId)

            // Clean up ghost entries: bare series IDs (e.g. "tt9813792") that were
            // stored without episode suffix. These can overwrite real episode-specific
            // entries (e.g. "tt9813792:4:9") if the mediaId wasn't resolved correctly.
            // We only delete them when a proper episode-specific entry exists for the
            // same series, so we're not losing data — just removing the stale ghost.
            let seriesProgress = progress.filter { entry in
                let type = entry.mediaType.lowercased()
                return ["series", "tv", "show", "shows", "anime"].contains(type)
            }
            let episodeSpecificIds = Set(seriesProgress.compactMap { entry -> String? in
                guard entry.decodedMediaId.components(separatedBy: ":").count >= 3 else { return nil }
                return entry.parentOrSelfMediaId
            })
            let ghostEntries = seriesProgress.filter { entry in
                guard entry.decodedMediaId.components(separatedBy: ":").count == 1 else { return false }
                return episodeSpecificIds.contains(entry.parentOrSelfMediaId)
            }
            for ghost in ghostEntries {
                try? await syncService.deleteWatchProgress(id: ghost.id)
            }
            let cleanedProgress = ghostEntries.isEmpty ? progress : progress.filter { p in
                !ghostEntries.contains(where: { $0.id == p.id })
            }
            let incomplete = Self.latestEntriesForContinueWatching(cleanedProgress, limit: 10)

            // Snapshot the enabled addons on the MainActor before entering the task group
            let addonRepo = AddonRepository.shared
            var items: [ContinueWatchingItem] = []
            // Snapshot catalog items on the main actor so task-group closures don't cross-actor
            let catalogItems = CatalogRepository.shared.allCatalogItems

            await withTaskGroup(of: ContinueWatchingItem.self) { group in
                for entry in incomplete {
                    // Find addons that support the meta resource for this media type
                    let addons = addonRepo.findAddonWithMetaResource(type: entry.mediaType)
                    group.addTask {
                        // Supabase stores mediaId URL-encoded (e.g. "tt9813792%3A1%3A2").
                        // Decode first so split on ":" correctly yields the base series ID.
                        let decodedMediaId = entry.decodedMediaId
                        let metaLookupId = entry.parentOrSelfMediaId

                        // Normalize media type: "tv"/"show" → "series" so the meta URL is valid
                        let normalizedType: String = {
                            switch entry.mediaType.lowercased() {
                            case "tv", "show", "shows", "anime": return "series"
                            default: return entry.mediaType.lowercased()
                            }
                        }()
                        let altType = normalizedType == "series" ? "movie" : "series"

                        // Use the same enriched metadata path as DetailScreen so episode
                        // stills include TVDB/TMDB fallbacks when configured.
                        var meta = await MetaRepository.shared.fetchDetail(
                            type: normalizedType,
                            id: metaLookupId,
                            addons: addons
                        )
                        if meta?.name == "Unknown" || meta == nil {
                            meta = await MetaRepository.shared.fetchDetail(
                                type: altType,
                                id: metaLookupId,
                                addons: addons
                            )
                        }

                        // Treat raw IMDb/Stremio IDs (e.g. "tt9813792" or "tt9813792:1:2") as
                        // absent names — they're IDs, not display titles.
                        func isRawId(_ str: String?) -> Bool {
                            guard let str else { return false }
                            return str.range(of: #"^tt\d{4,}"#, options: .regularExpression) != nil
                        }

                        // AIOMetadata may echo back the decoded compound ID as the meta name
                        // (e.g. "tt9813792:1:2"). Reject those as non-titles.
                        if let metaName = meta?.name, isRawId(metaName) {
                            meta = nil
                        }

                        // Fallback: try the already-loaded catalog rows for name + poster,
                        // then URL-decode the stored ID as last resort.
                        // Treat "Unknown" and raw IMDb IDs as absent.
                        let rawName = meta?.name ?? (isRawId(entry.name) ? nil : entry.name)
                        var cwName: String? = (rawName == nil || rawName == "Unknown" || rawName?.isEmpty == true) ? nil : rawName
                        var cwPoster = meta?.poster ?? entry.poster
                        var cwLogo = meta?.logo

                        if cwName == nil || cwPoster == nil || cwLogo == nil, let catalogItem = catalogItems.first(where: {
                            $0.id == metaLookupId || $0.id == decodedMediaId || $0.id == entry.mediaId
                        }) {
                            if cwName == nil { cwName = catalogItem.name }
                            if cwPoster == nil { cwPoster = catalogItem.poster }
                            if cwLogo == nil { cwLogo = catalogItem.logo }
                        }

                        // Resolve effective season/episode:
                        // 1. Use the stored entry values if present (new entries post-fix).
                        // 2. Fall back to parsing from mediaId "parentId:season:episode"
                        //    format (entries saved after the episode-specific ID fix).
                        let effectiveSeason = entry.inferredSeason
                        let effectiveEpisode = entry.inferredEpisode

                        // Find the matching episode for thumbnail + title.
                        // Try flat videos array first (standard Stremio), then
                        // fall back to structured seasons (AIOMetadata / TVDB style
                        // where episodes live inside seasons and season is nil on each video).
                        let matchingVideo: MetaVideo? = {
                            if let video = meta?.videos?.first(where: { $0.id == decodedMediaId }) {
                                return video
                            }
                            if let seasons = meta?.seasons {
                                for season in seasons {
                                    if let ep = season.episodes?.first(where: { $0.id == decodedMediaId }) {
                                        return ep
                                    }
                                }
                            }
                            if let s = effectiveSeason, let e = effectiveEpisode {
                                if let video = meta?.videos?.first(where: {
                                    $0.season == s && $0.episode == e
                                }) { return video }
                                if let seasons = meta?.seasons {
                                    for season in seasons where season.number == s {
                                        if let ep = season.episodes?.first(where: { $0.episode == e }) {
                                            return ep
                                        }
                                    }
                                }
                            }
                            return nil
                        }()
                        let fallbackThumbnail: String? = {
                            matchingVideo?.thumbnail ?? entry.thumbnailFallbackForContinueWatching
                        }()
                        let directAIOMetadataThumbnail: String? = {
                            guard fallbackThumbnail == nil,
                                  effectiveSeason != nil || effectiveEpisode != nil,
                                  let manifestURL = NightarcConfig.defaultAddons.first(where: { $0.contains("aiometadata") }) else {
                                return nil
                            }
                            return manifestURL.replacingOccurrences(of: "/manifest.json", with: "")
                        }()
                        let resolvedThumbnail: String?
                        if let directAIOMetadataThumbnail,
                           let directMeta = try? await MetaService.shared.fetchMeta(
                                type: normalizedType,
                                id: metaLookupId,
                                baseURL: directAIOMetadataThumbnail
                           ) {
                            resolvedThumbnail = Self.matchEpisode(
                                in: directMeta,
                                decodedMediaId: decodedMediaId,
                                season: effectiveSeason,
                                episode: effectiveEpisode
                            )?.thumbnail
                        } else {
                            resolvedThumbnail = fallbackThumbnail
                        }

                        let decodedFallback = (entry.mediaId.removingPercentEncoding ?? entry.mediaId)
                            .split(separator: ":").first.map(String.init) ?? entry.mediaId
                        return ContinueWatchingItem(
                            mediaId: entry.mediaId,
                            parentMediaId: metaLookupId,
                            mediaType: entry.mediaType,
                            name: cwName ?? decodedFallback,
                            poster: cwPoster,
                            logo: cwLogo,
                            resumePositionMs: entry.positionSeconds * 1000,
                            durationMs: entry.durationSeconds * 1000,
                            progressFraction: entry.progressFraction,
                            seasonNumber: effectiveSeason,
                            episodeNumber: effectiveEpisode,
                            episodeTitle: matchingVideo?.title,
                            thumbnail: resolvedThumbnail
                        )
                    }
                }
                for await item in group {
                    items.append(item)
                }
            }

            // Re-sort to match original updatedAt order (task group doesn't preserve order)
            let sortedIds = incomplete.map(\.mediaId)
            continueWatchingItems = items.sorted {
                let ia = sortedIds.firstIndex(of: $0.mediaId) ?? Int.max
                let ib = sortedIds.firstIndex(of: $1.mediaId) ?? Int.max
                return ia < ib
            }
        } catch {
            continueWatchingItems = []
        }
    }

    public func loadCatalogRows(addons: [AddonManifest]) async -> [CatalogRow] {
        await CatalogRepository.shared.loadAllCatalogs(addons: addons)
        return CatalogRepository.shared.catalogRows
    }

    private nonisolated static func matchEpisode(
        in meta: MetaDetail,
        decodedMediaId: String,
        season: Int?,
        episode: Int?
    ) -> MetaVideo? {
        if let video = meta.videos?.first(where: { $0.id == decodedMediaId }) {
            return video
        }
        if let seasons = meta.seasons {
            for seasonGroup in seasons {
                if let video = seasonGroup.episodes?.first(where: { $0.id == decodedMediaId }) {
                    return video
                }
            }
        }
        guard let season, let episode else { return nil }
        if let video = meta.videos?.first(where: { $0.season == season && $0.episode == episode }) {
            return video
        }
        if let seasons = meta.seasons {
            for seasonGroup in seasons where seasonGroup.number == season {
                if let video = seasonGroup.episodes?.first(where: { $0.episode == episode }) {
                    return video
                }
            }
        }
        return nil
    }
}
