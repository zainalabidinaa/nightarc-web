import Foundation

@MainActor
public class AdminService: ObservableObject {
    public static let shared = AdminService()

    @Published public var inviteCodes: [InviteCode] = []
    @Published public var stats: AdminStats = AdminStats()
    @Published public var allUsers: [AdminUserInfo] = []
    @Published public var isLoading = false

    private let client = SupabaseClient.shared

    private init() {}

    public func loadInviteCodes() async {
        do {
            let codes: [InviteCode] = try await client.select(
                from: "invite_codes",
                order: "created_at.desc"
            )
            inviteCodes = codes
        } catch {
            inviteCodes = []
        }
    }

    public func generateInviteCode(maxUses: Int = 1) async throws -> InviteCode {
        guard let session = ProfileManager.shared.currentSession else {
            throw SupabaseError.notAuthenticated
        }

        let code = generateRandomCode()
        let invite = InviteCode(
            code: code,
            createdBy: session.userId,
            maxUses: maxUses,
            isActive: true
        )

        _ = try await client.insert(into: "invite_codes", value: invite) as [InviteCode]
        inviteCodes.insert(invite, at: 0)
        return invite
    }

    public func revokeInviteCode(_ code: String) async throws {
        struct RevokeUpdate: Encodable {
            let is_active: Bool
        }
        try await client.update(
            table: "invite_codes",
            where: ["code": code],
            value: RevokeUpdate(is_active: false)
        )
        if let idx = inviteCodes.firstIndex(where: { $0.code == code }) {
            inviteCodes[idx] = InviteCode(
                code: inviteCodes[idx].code,
                createdBy: inviteCodes[idx].createdBy,
                usedBy: inviteCodes[idx].usedBy,
                usedAt: inviteCodes[idx].usedAt,
                createdAt: inviteCodes[idx].createdAt,
                maxUses: inviteCodes[idx].maxUses,
                isActive: false
            )
        }
    }

    public func loadStats() async {
        do {
            struct UserRow: Codable {
                let id: String
            }
            struct ProfileRow: Codable {
                let id: String
            }
            struct InviteRow: Codable {
                let code: String
                let is_active: Bool
            }

            let users: [UserRow] = try await client.select(from: "auth", where: [:])
            let profiles: [ProfileRow] = try await client.select(from: "profiles", where: [:])
            let codes: [InviteRow] = try await client.select(from: "invite_codes", where: [:])

            stats = AdminStats(
                totalUsers: users.count,
                totalProfiles: profiles.count,
                activeInviteCodes: codes.filter { $0.is_active }.count,
                totalWatchlistItems: 0,
                totalWatchedItems: 0,
                activeUsers: users.count
            )
        } catch {
            stats = AdminStats()
        }
    }

    public func loadAllUsers() async {
        do {
            struct UserRow: Codable {
                let id: String
                let email: String?
                let created_at: String?
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"

            let users: [UserRow] = try await client.select(from: "auth", where: [:])
            allUsers = users.compactMap { user in
                AdminUserInfo(
                    id: user.id,
                    email: user.email ?? "Unknown",
                    createdAt: user.created_at.flatMap { dateFormatter.date(from: $0) } ?? Date()
                )
            }
        } catch {
            allUsers = []
        }
    }

    public func banUser(userId: String) async throws {
        struct BanUpdate: Encodable {
            let banned: Bool
        }
        try await client.update(
            table: "profiles",
            where: ["user_id": userId],
            value: BanUpdate(banned: true)
        )
    }

    private func generateRandomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

public struct AdminUserInfo: Identifiable, Sendable {
    public let id: String
    public let email: String
    public let createdAt: Date

    public init(id: String, email: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}
