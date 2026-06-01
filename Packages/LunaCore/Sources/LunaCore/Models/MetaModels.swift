import Foundation

public enum MediaType: String, Codable, Sendable, CaseIterable {
    case movie = "movie"
    case series = "series"
    case channel = "channel"
    case tv = "tv"
}

public struct MetaPreview: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let type: MediaType
    public let name: String
    public let poster: String?
    public let banner: String?
    public let logo: String?
    public let posterShape: PosterShape?
    public let description: String?
    public let releaseInfo: String?
    public let rawReleaseDate: String?
    public let popularity: Double?
    public let voteCount: Int?
    public let imdbRating: String?
    public let genres: [String]?
    public let released: String?
    public let status: String?
    public let behaviorHints: BehaviorHints?
    public let rankHint: Int?

    public init(
        id: String,
        type: MediaType,
        name: String,
        poster: String? = nil,
        banner: String? = nil,
        logo: String? = nil,
        posterShape: PosterShape? = nil,
        description: String? = nil,
        releaseInfo: String? = nil,
        rawReleaseDate: String? = nil,
        popularity: Double? = nil,
        voteCount: Int? = nil,
        imdbRating: String? = nil,
        genres: [String]? = nil,
        released: String? = nil,
        status: String? = nil,
        behaviorHints: BehaviorHints? = nil,
        rankHint: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.poster = poster
        self.banner = banner
        self.logo = logo
        self.posterShape = posterShape
        self.description = description
        self.releaseInfo = releaseInfo
        self.rawReleaseDate = rawReleaseDate
        self.popularity = popularity
        self.voteCount = voteCount
        self.imdbRating = imdbRating
        self.genres = genres
        self.released = released
        self.status = status
        self.behaviorHints = behaviorHints
        self.rankHint = rankHint
    }
}

public struct BehaviorHints: Codable, Sendable, Hashable {
    public let defaultVideoId: String?
    public let hasScheduledVideos: Bool?
}

public struct ContentBadge: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let text: String
    public let style: BadgeStyle

    public init(text: String, style: BadgeStyle) {
        self.id = text
        self.text = text
        self.style = style
    }
}

public enum BadgeStyle: String, Codable, Sendable {
    case accent
    case warning
    case info
}

public extension MetaPreview {
    func derivedBadges(index: Int? = nil) -> [ContentBadge] {
        var badges: [ContentBadge] = []

        if let released = released {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: released) {
                let now = Date()
                if date > now {
                    let display = DateFormatter()
                    display.dateFormat = "d MMM"
                    badges.append(ContentBadge(
                        text: "Coming \(display.string(from: date))",
                        style: .accent
                    ))
                }
            }
        }

        if let status = status?.lowercased() {
            if status == "pilot" {
                badges.append(ContentBadge(text: "Pilot", style: .accent))
            } else if status == "continuing" || status == "returning series" {
                if let released = released {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = formatter.date(from: released) {
                        let weekAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
                        if date > weekAgo {
                            badges.append(ContentBadge(text: "New Series", style: .accent))
                        }
                    }
                }
            } else if status == "ended" {
                badges.append(ContentBadge(text: "Complete", style: .info))
            }
        }

        if let idx = index, idx < 5 {
            badges.append(ContentBadge(text: "#\(idx + 1) Today", style: .warning))
        }

        return badges
    }
}

public enum PosterShape: String, Codable, Sendable {
    case poster
    case square
    case landscape
}

public struct MetaDetail: Codable, Sendable, Identifiable {
    public let id: String
    public let type: MediaType
    public let name: String
    public let poster: String?
    public let background: String?
    public let logo: String?
    public let description: String?
    public let releaseInfo: String?
    public let status: String?
    public let imdbRating: String?
    public let ageRating: String?
    public let runtime: String?
    public let genres: [String]?
    public let director: [String]?
    public let writer: [String]?
    public let cast: [Person]?
    public let trailers: [Trailer]?
    public let videos: [MetaVideo]?
    public let seasons: [Season]?
    public let links: [MetaLink]?
    public let moreLikeThis: [MetaPreview]?
    public let collectionItems: [MetaPreview]?

    public init(
        id: String,
        type: MediaType,
        name: String,
        poster: String? = nil,
        background: String? = nil,
        logo: String? = nil,
        description: String? = nil,
        releaseInfo: String? = nil,
        status: String? = nil,
        imdbRating: String? = nil,
        ageRating: String? = nil,
        runtime: String? = nil,
        genres: [String]? = nil,
        director: [String]? = nil,
        writer: [String]? = nil,
        cast: [Person]? = nil,
        trailers: [Trailer]? = nil,
        videos: [MetaVideo]? = nil,
        seasons: [Season]? = nil,
        links: [MetaLink]? = nil,
        moreLikeThis: [MetaPreview]? = nil,
        collectionItems: [MetaPreview]? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.poster = poster
        self.background = background
        self.logo = logo
        self.description = description
        self.releaseInfo = releaseInfo
        self.status = status
        self.imdbRating = imdbRating
        self.ageRating = ageRating
        self.runtime = runtime
        self.genres = genres
        self.director = director
        self.writer = writer
        self.cast = cast
        self.trailers = trailers
        self.videos = videos
        self.seasons = seasons
        self.links = links
        self.moreLikeThis = moreLikeThis
        self.collectionItems = collectionItems
    }
}

public struct Season: Codable, Sendable, Identifiable {
    public let id: String
    public let number: Int
    public let name: String?
    public let poster: String?
    public let episodes: [MetaVideo]?

    public init(
        id: String,
        number: Int,
        name: String? = nil,
        poster: String? = nil,
        episodes: [MetaVideo]? = nil
    ) {
        self.id = id
        self.number = number
        self.name = name
        self.poster = poster
        self.episodes = episodes
    }
}

public struct MetaVideo: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let released: String?
    public let thumbnail: String?
    public let season: Int?
    public let episode: Int?
    public let overview: String?
    public let runtime: String?

    public init(
        id: String,
        title: String,
        released: String? = nil,
        thumbnail: String? = nil,
        season: Int? = nil,
        episode: Int? = nil,
        overview: String? = nil,
        runtime: String? = nil
    ) {
        self.id = id
        self.title = title
        self.released = released
        self.thumbnail = thumbnail
        self.season = season
        self.episode = episode
        self.overview = overview
        self.runtime = runtime
    }
}

public struct Person: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let photo: String?

    public init(id: String, name: String, photo: String? = nil) {
        self.id = id
        self.name = name
        self.photo = photo
    }
}

public struct Trailer: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String?
    public let thumbnail: String?
    public let youtubeId: String?

    public init(id: String, title: String? = nil, thumbnail: String? = nil, youtubeId: String? = nil) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.youtubeId = youtubeId
    }
}

public struct MetaLink: Codable, Sendable, Identifiable {
    public let name: String
    public let category: String?
    public let url: String

    public var id: String { url }

    public init(name: String, category: String? = nil, url: String) {
        self.name = name
        self.category = category
        self.url = url
    }
}

public struct CatalogRow: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public var items: [MetaPreview]
    public let addonName: String?
    public var page: Int
    public var hasMore: Bool

    public let tileShape: String?
    public let coverImage: String?
    public let focusGif: String?
    public let focusGifEnabled: Bool?
    public let titleLogo: String?
    public let heroBackdrop: String?
    public let heroVideoURL: String?
    public let hideTitle: Bool?
    public let focusGlowEnabled: Bool?
    public let viewMode: String?
    public let showAllTab: Bool?
    public let pinToTop: Bool?
    public let backdropImage: String?

    public init(
        id: String,
        title: String,
        items: [MetaPreview],
        addonName: String? = nil,
        page: Int = 0,
        hasMore: Bool = false,
        tileShape: String? = nil,
        coverImage: String? = nil,
        focusGif: String? = nil,
        focusGifEnabled: Bool? = nil,
        titleLogo: String? = nil,
        heroBackdrop: String? = nil,
        heroVideoURL: String? = nil,
        hideTitle: Bool? = nil,
        focusGlowEnabled: Bool? = nil,
        viewMode: String? = nil,
        showAllTab: Bool? = nil,
        pinToTop: Bool? = nil,
        backdropImage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.addonName = addonName
        self.page = page
        self.hasMore = hasMore
        self.tileShape = tileShape
        self.coverImage = coverImage
        self.focusGif = focusGif
        self.focusGifEnabled = focusGifEnabled
        self.titleLogo = titleLogo
        self.heroBackdrop = heroBackdrop
        self.heroVideoURL = heroVideoURL
        self.hideTitle = hideTitle
        self.focusGlowEnabled = focusGlowEnabled
        self.viewMode = viewMode
        self.showAllTab = showAllTab
        self.pinToTop = pinToTop
        self.backdropImage = backdropImage
    }
}
