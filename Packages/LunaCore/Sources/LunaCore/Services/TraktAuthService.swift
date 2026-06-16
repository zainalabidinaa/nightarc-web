import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Supabase token row

private struct TraktTokenRow: Codable {
    let profileId: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }
}

// MARK: - Token exchange response

private struct TraktTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - TraktAuthService

@MainActor
public final class TraktAuthService: ObservableObject {
    public static let shared = TraktAuthService()

    @Published public var isConnected: Bool = false
    @Published public var isConnecting: Bool = false

    private(set) var accessToken: String? = nil
    private var profileId: String? = nil

    private let redirectUri = "nightarc://trakt-callback"

    private var clientId: String {
        MetadataIntegrationStore.shared.traktClientId
    }

    private init() {}

    // MARK: - Public API

    /// Launches Trakt OAuth2 flow in Safari for the given profile.
    public func connect(profileId: String) {
        self.profileId = profileId
        let state = UUID().uuidString
        let urlString = "https://trakt.tv/oauth/authorize?response_type=code&client_id=\(clientId)&redirect_uri=\(redirectUri)&state=\(state)"
        guard let url = URL(string: urlString) else { return }
        isConnecting = true
#if canImport(UIKit)
        UIApplication.shared.open(url)
#endif
    }

    /// Called from the app's onOpenURL handler with the redirect URL.
    public func handleCallback(url: URL) {
        guard url.scheme == "nightarc",
              url.host == "trakt-callback" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value,
              let profileId = self.profileId else {
            isConnecting = false
            return
        }

        Task {
            await exchangeCodeForToken(code: code, profileId: profileId)
        }
    }

    /// Loads a stored token for the given profile from Supabase.
    public func loadToken(profileId: String) async {
        self.profileId = profileId
        do {
            let rows: [TraktTokenRow] = try await SupabaseClient.shared.select(
                from: "trakt_oauth_tokens",
                where: ["profile_id": profileId]
            )
            guard let row = rows.first else {
                isConnected = false
                return
            }
            if row.expiresAt > Date() {
                accessToken = row.accessToken
                isConnected = true
            } else {
                // Token expired — attempt refresh
                await refreshToken(profileId: profileId, refreshToken: row.refreshToken)
            }
        } catch {
            isConnected = false
        }
    }

    /// Disconnects Trakt for the given profile, deleting the stored token.
    public func disconnect(profileId: String) async {
        do {
            try await SupabaseClient.shared.delete(
                from: "trakt_oauth_tokens",
                where: ["profile_id": profileId]
            )
        } catch {}
        accessToken = nil
        isConnected = false
    }

    // MARK: - Private helpers

    private func exchangeCodeForToken(code: String, profileId: String) async {
        guard !clientId.isEmpty else {
            isConnecting = false
            return
        }

        let body: [String: String] = [
            "code": code,
            "client_id": clientId,
            "client_secret": "",   // public client; server requires the field
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        guard let url = URL(string: "https://api.trakt.tv/oauth/token"),
              let bodyData = try? JSONEncoder().encode(body) else {
            isConnecting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                isConnecting = false
                return
            }
            let tokenResponse = try JSONDecoder().decode(TraktTokenResponse.self, from: data)
            accessToken = tokenResponse.accessToken
            isConnected = true
            isConnecting = false
            await saveToken(
                profileId: profileId,
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresIn: tokenResponse.expiresIn
            )
        } catch {
            isConnecting = false
        }
    }

    private func refreshToken(profileId: String, refreshToken: String) async {
        guard !clientId.isEmpty else { return }

        let body: [String: String] = [
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": "",
            "redirect_uri": redirectUri,
            "grant_type": "refresh_token"
        ]

        guard let url = URL(string: "https://api.trakt.tv/oauth/token"),
              let bodyData = try? JSONEncoder().encode(body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
            let tokenResponse = try JSONDecoder().decode(TraktTokenResponse.self, from: data)
            accessToken = tokenResponse.accessToken
            isConnected = true
            await saveToken(
                profileId: profileId,
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresIn: tokenResponse.expiresIn
            )
        } catch {}
    }

    private func saveToken(profileId: String, accessToken: String, refreshToken: String, expiresIn: Int) async {
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        let row = TraktTokenRow(
            profileId: profileId,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
        do {
            try await SupabaseClient.shared.upsert(
                into: "trakt_oauth_tokens",
                onConflict: "profile_id",
                value: row
            )
        } catch {}
    }
}
