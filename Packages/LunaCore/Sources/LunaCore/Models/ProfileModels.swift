import Foundation

public struct LunaProfile: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let userId: String
    public let name: String
    public let avatarColor: String?
    public let avatarId: Int?
    public let profileIndex: Int
    public let usesPrimaryAddons: Bool
    public let pinEnabled: Bool
    public let role: String
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case userId = "user_id"
        case avatarColor = "avatar_color"
        case avatarId = "avatar_id"
        case profileIndex = "profile_index"
        case usesPrimaryAddons = "uses_primary_addons"
        case pinEnabled = "pin_enabled"
        case createdAt = "created_at"
    }

    public init(
        id: String,
        userId: String,
        name: String,
        avatarColor: String? = nil,
        avatarId: Int? = nil,
        profileIndex: Int = 0,
        usesPrimaryAddons: Bool = true,
        pinEnabled: Bool = false,
        role: String = "user",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.avatarColor = avatarColor
        self.avatarId = avatarId
        self.profileIndex = profileIndex
        self.usesPrimaryAddons = usesPrimaryAddons
        self.pinEnabled = pinEnabled
        self.role = role
        self.createdAt = createdAt
    }

    public var isAdmin: Bool { role == "admin" }
}

public struct UserSession: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let userId: String
    public let email: String?

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        userId: String,
        email: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.userId = userId
        self.email = email
    }

    public var isExpired: Bool { Date() >= expiresAt }
}
