import Foundation

public struct WatchProgressEntry: Codable, Sendable, Identifiable {
    public let id: String
    public let profileId: String
    public let mediaId: String
    public let mediaType: String
    public let positionSeconds: Double
    public let durationSeconds: Double
    public let completed: Bool
    public let updatedAt: Date

    public var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(positionSeconds / durationSeconds, 1.0)
    }

    public init(
        id: String,
        profileId: String,
        mediaId: String,
        mediaType: String,
        positionSeconds: Double = 0,
        durationSeconds: Double = 0,
        completed: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.positionSeconds = positionSeconds
        self.durationSeconds = durationSeconds
        self.completed = completed
        self.updatedAt = updatedAt
    }
}

public struct ContinueWatchingItem: Codable, Sendable, Identifiable {
    public let mediaId: String
    public let mediaType: String
    public let name: String
    public let poster: String?
    public let resumePositionMs: Double
    public let durationMs: Double
    public let progressFraction: Double
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    public let episodeTitle: String?

    public var id: String { mediaId }

    public init(
        mediaId: String,
        mediaType: String,
        name: String,
        poster: String? = nil,
        resumePositionMs: Double = 0,
        durationMs: Double = 0,
        progressFraction: Double = 0,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        episodeTitle: String? = nil
    ) {
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.resumePositionMs = resumePositionMs
        self.durationMs = durationMs
        self.progressFraction = progressFraction
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
    }
}

public struct WatchedItem: Codable, Sendable, Identifiable {
    public let id: String
    public let profileId: String
    public let mediaId: String
    public let mediaType: String
    public let name: String?
    public let poster: String?
    public let season: Int?
    public let episode: Int?
    public let markedAt: Date

    public init(
        id: String,
        profileId: String,
        mediaId: String,
        mediaType: String,
        name: String? = nil,
        poster: String? = nil,
        season: Int? = nil,
        episode: Int? = nil,
        markedAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.season = season
        self.episode = episode
        self.markedAt = markedAt
    }
}

public struct LibraryItem: Codable, Sendable, Identifiable {
    public let id: String
    public let profileId: String
    public let mediaId: String
    public let mediaType: String
    public let name: String?
    public let poster: String?
    public let banner: String?
    public let savedAt: Date

    public init(
        id: String,
        profileId: String,
        mediaId: String,
        mediaType: String,
        name: String? = nil,
        poster: String? = nil,
        banner: String? = nil,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.name = name
        self.poster = poster
        self.banner = banner
        self.savedAt = savedAt
    }
}

public struct InviteCode: Codable, Sendable, Identifiable {
    public let code: String
    public let createdBy: String
    public let usedBy: String?
    public let usedAt: Date?
    public let createdAt: Date
    public let maxUses: Int
    public let isActive: Bool

    public var id: String { code }

    public init(
        code: String,
        createdBy: String,
        usedBy: String? = nil,
        usedAt: Date? = nil,
        createdAt: Date = Date(),
        maxUses: Int = 1,
        isActive: Bool = true
    ) {
        self.code = code
        self.createdBy = createdBy
        self.usedBy = usedBy
        self.usedAt = usedAt
        self.createdAt = createdAt
        self.maxUses = maxUses
        self.isActive = isActive
    }

    public var isUsed: Bool { usedBy != nil }
}

public struct AdminStats: Codable, Sendable {
    public let totalUsers: Int
    public let totalProfiles: Int
    public let activeInviteCodes: Int
    public let totalWatchlistItems: Int
    public let totalWatchedItems: Int
    public let activeUsers: Int

    public init(
        totalUsers: Int = 0,
        totalProfiles: Int = 0,
        activeInviteCodes: Int = 0,
        totalWatchlistItems: Int = 0,
        totalWatchedItems: Int = 0,
        activeUsers: Int = 0
    ) {
        self.totalUsers = totalUsers
        self.totalProfiles = totalProfiles
        self.activeInviteCodes = activeInviteCodes
        self.totalWatchlistItems = totalWatchlistItems
        self.totalWatchedItems = totalWatchedItems
        self.activeUsers = activeUsers
    }
}
