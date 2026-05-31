import Foundation

public struct DBCollection: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let sort_order: Int
    public let backdrop_image: String?
    public let view_mode: String?
    public let show_all_tab: Bool?
    public let focus_glow_enabled: Bool?
    public let pin_to_top: Bool?
    public let created_at: Date?
}

public struct DBFolder: Codable, Identifiable, Sendable {
    public let id: String
    public let collection_id: String
    public let name: String
    public let sort_order: Int
    public let cover_image: String?
    public let focus_gif: String?
    public let title_logo: String?
    public let hero_backdrop: String?
    public let hero_video_url: String?
    public let hide_title: Bool?
    public let tile_shape: String?
    public let focus_gif_enabled: Bool?
    public let created_at: Date?
}

public struct DBFolderCatalog: Codable, Identifiable, Sendable {
    public let id: String
    public let folder_id: String
    public let catalog_id: String
    public let media_type: String
    public let genre: String?
}
