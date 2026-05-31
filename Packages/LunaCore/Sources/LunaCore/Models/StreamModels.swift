import Foundation

public struct StreamItem: Codable, Sendable, Identifiable, Hashable {
    public let name: String?
    public let title: String?
    public let description: String?
    public let url: String?
    public let infoHash: String?
    public let fileIdx: Int?
    public let externalUrl: String?
    public let sources: [String]?
    public let sourceName: String?
    public let addonName: String?
    public let addonId: String?
    public let behaviorHints: StreamBehaviorHints?

    public var id: String { url ?? infoHash ?? externalUrl ?? UUID().uuidString }

    public init(
        name: String? = nil,
        title: String? = nil,
        description: String? = nil,
        url: String? = nil,
        infoHash: String? = nil,
        fileIdx: Int? = nil,
        externalUrl: String? = nil,
        sources: [String]? = nil,
        sourceName: String? = nil,
        addonName: String? = nil,
        addonId: String? = nil,
        behaviorHints: StreamBehaviorHints? = nil
    ) {
        self.name = name
        self.title = title
        self.description = description
        self.url = url
        self.infoHash = infoHash
        self.fileIdx = fileIdx
        self.externalUrl = externalUrl
        self.sources = sources
        self.sourceName = sourceName
        self.addonName = addonName
        self.addonId = addonId
        self.behaviorHints = behaviorHints
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: StreamItem, rhs: StreamItem) -> Bool {
        lhs.id == rhs.id
    }

    public var displayName: String {
        if let title = title, !title.isEmpty { return title }
        if let name = name, !name.isEmpty { return name }
        if let description = description, !description.isEmpty { return description }
        return sourceName ?? addonName ?? "Unknown"
    }

    public var hasDirectUrl: Bool {
        url != nil && !url!.isEmpty
    }
}

public struct StreamBehaviorHints: Codable, Sendable {
    public let notWebReady: Bool?
    public let bingeGroup: String?
    public let proxyHeaders: StreamProxyHeaders?

    public init(
        notWebReady: Bool? = nil,
        bingeGroup: String? = nil,
        proxyHeaders: StreamProxyHeaders? = nil
    ) {
        self.notWebReady = notWebReady
        self.bingeGroup = bingeGroup
        self.proxyHeaders = proxyHeaders
    }
}

public struct StreamProxyHeaders: Codable, Sendable {
    public let request: [String: String]?
    public let response: [String: String]?

    public init(request: [String: String]? = nil, response: [String: String]? = nil) {
        self.request = request
        self.response = response
    }
}

public struct SubtitleItem: Codable, Sendable, Identifiable {
    public let id: String
    public let url: String
    public let lang: String
    public let name: String?

    public init(id: String, url: String, lang: String, name: String? = nil) {
        self.id = id
        self.url = url
        self.lang = lang
        self.name = name
    }
}

public struct PlayerLaunch: Codable, Sendable {
    public let title: String
    public let sourceUrl: String
    public let sourceHeaders: [String: String]?
    public let logo: String?
    public let poster: String?
    public let background: String?
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    public let streamTitle: String?
    public let providerName: String?
    public let contentType: MediaType
    public let videoId: String
    public let parentMetaId: String?
    public let parentMetaType: String?
    public let initialPositionMs: Double?
    public let subtitles: [SubtitleItem]?

    public init(
        title: String,
        sourceUrl: String,
        sourceHeaders: [String: String]? = nil,
        logo: String? = nil,
        poster: String? = nil,
        background: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        streamTitle: String? = nil,
        providerName: String? = nil,
        contentType: MediaType,
        videoId: String,
        parentMetaId: String? = nil,
        parentMetaType: String? = nil,
        initialPositionMs: Double? = nil,
        subtitles: [SubtitleItem]? = nil
    ) {
        self.title = title
        self.sourceUrl = sourceUrl
        self.sourceHeaders = sourceHeaders
        self.logo = logo
        self.poster = poster
        self.background = background
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.streamTitle = streamTitle
        self.providerName = providerName
        self.contentType = contentType
        self.videoId = videoId
        self.parentMetaId = parentMetaId
        self.parentMetaType = parentMetaType
        self.initialPositionMs = initialPositionMs
        self.subtitles = subtitles
    }
}
