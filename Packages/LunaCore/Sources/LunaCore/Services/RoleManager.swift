import Foundation

@MainActor
public class RoleManager: ObservableObject {
    public static let shared = RoleManager()

    @Published public var isAdmin = false
    @Published public var profileRole: ProfileRole = .user

    private init() {}

    public func evaluateRole(profile: NightarcProfile?) {
        let role = profile?.profileRole ?? .user
        profileRole = role
        isAdmin = role == .admin
    }

    public func setUserAsAdmin(profile: NightarcProfile) async throws {
        let updated = NightarcProfile(
            id: profile.id,
            userId: profile.userId,
            name: profile.name,
            avatarColor: profile.avatarColor,
            avatarId: profile.avatarId,
            profileIndex: profile.profileIndex,
            usesPrimaryAddons: profile.usesPrimaryAddons,
            pinEnabled: profile.pinEnabled,
            role: "admin",
            createdAt: profile.createdAt
        )
        try await ProfileManager.shared.updateProfile(updated)
        evaluateRole(profile: updated)
    }
}
