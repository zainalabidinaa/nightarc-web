import Foundation

@MainActor
public class ProfileManager: ObservableObject {
    public static let shared = ProfileManager()

    @Published public var profiles: [LunaProfile] = []
    @Published public var currentProfile: LunaProfile?
    @Published public var currentSession: UserSession?
    @Published public var isLoading = false
    @Published public var isAuthenticated = false

    private let auth = SupabaseAuth.shared
    private let syncService = SyncService.shared
    private let client = SupabaseClient.shared

    private init() {}

    public func signIn(email: String, password: String) async throws {
        let session = try await auth.signIn(email: email, password: password)
        self.currentSession = session
        try await loadProfiles(userId: session.userId)
        self.isAuthenticated = true
    }

    public func signUp(email: String, password: String, inviteCode: String) async throws {
        let session = try await auth.signUp(email: email, password: password, inviteCode: inviteCode)
        self.currentSession = session

        let profile = LunaProfile(
            id: UUID().uuidString,
            userId: session.userId,
            name: "Default",
            profileIndex: 0,
            role: "user"
        )
        _ = try await client.insert(into: "profiles", value: profile) as [LunaProfile]
        self.profiles = [profile]
        self.currentProfile = profile
        self.isAuthenticated = true
    }

    public func signOut() async {
        try? await auth.signOut()
        currentSession = nil
        currentProfile = nil
        profiles = []
        isAuthenticated = false
    }

    public func loadProfiles(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let fetched: [LunaProfile] = try await syncService.pullProfiles(userId: userId)
        self.profiles = fetched

        if currentProfile == nil || !fetched.contains(where: { $0.id == currentProfile?.id }) {
            self.currentProfile = fetched.first
        }
    }

    public func selectProfile(_ profile: LunaProfile) {
        currentProfile = profile
    }

    public func createProfile(name: String) async throws {
        guard let session = currentSession else { throw SupabaseError.notAuthenticated }

        let nextIndex = (profiles.map { $0.profileIndex }.max() ?? -1) + 1
        let newProfile = LunaProfile(
            id: UUID().uuidString,
            userId: session.userId,
            name: name,
            avatarColor: randomColor(),
            avatarId: Int.random(in: 0...30),
            profileIndex: nextIndex,
            role: "user"
        )
        _ = try await client.insert(into: "profiles", value: newProfile) as [LunaProfile]
        profiles.append(newProfile)
    }

    public func deleteProfile(_ profile: LunaProfile) async throws {
        try await client.delete(from: "profiles", where: ["id": profile.id])
        profiles.removeAll { $0.id == profile.id }
        if currentProfile?.id == profile.id {
            currentProfile = profiles.first
        }
    }

    public func updateProfile(_ profile: LunaProfile) async throws {
        try await client.update(table: "profiles", where: ["id": profile.id], value: profile)
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            if currentProfile?.id == profile.id {
                currentProfile = profile
            }
        }
    }

    private func randomColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
                      "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"]
        return colors.randomElement() ?? "#4ECDC4"
    }

    public var isAdmin: Bool {
        currentProfile?.isAdmin ?? false
    }

    public func refreshCurrentProfile() async throws {
        guard let session = currentSession, let profile = currentProfile else { return }
        let fetched: [LunaProfile] = try await syncService.pullProfiles(userId: session.userId)
        if let updated = fetched.first(where: { $0.id == profile.id }) {
            currentProfile = updated
            if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[idx] = updated
            }
        }
    }
}
