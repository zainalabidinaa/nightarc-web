import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
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

    // PKCE state — stored for the duration of the auth flow
    private var codeVerifier: String? = nil

    private let redirectUri = "moonlit://trakt-callback"

    private var clientId: String {
        MetadataIntegrationStore.shared.traktClientId
    }

    private var clientSecret: String {
        MetadataIntegrationStore.shared.traktClientSecret
    }

    private init() {}

    // MARK: - Public API

    public func connect(profileId: String) {
        self.profileId = profileId
        isConnecting = true

        // Generate PKCE pair
        let verifier = Self.generateCodeVerifier()
        codeVerifier = verifier
        let challenge = Self.codeChallenge(for: verifier)

        let state = UUID().uuidString
        var components = URLComponents(string: "https://trakt.tv/oauth/authorize")!
        components.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: clientId),
            .init(name: "redirect_uri", value: redirectUri),
            .init(name: "state", value: state),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]
        guard let url = components.url else { isConnecting = false; return }
#if canImport(UIKit)
        UIApplication.shared.open(url)
#elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
#endif
    }

    public func handleCallback(url: URL) {
        guard url.scheme == "moonlit", url.host == "trakt-callback" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value,
              let profileId = self.profileId else {
            isConnecting = false
            return
        }
        Task { await exchangeCodeForToken(code: code, profileId: profileId) }
    }

    public func loadToken(profileId: String) async {
        self.profileId = profileId
        do {
            let rows: [TraktTokenRow] = try await SupabaseClient.shared.select(
                from: "trakt_oauth_tokens",
                where: ["profile_id": profileId]
            )
            guard let row = rows.first else { isConnected = false; return }
            // Proactively refresh if token expires within 1 hour
            if row.expiresAt > Date().addingTimeInterval(3600) {
                accessToken = row.accessToken
                isConnected = true
            } else {
                await refreshToken(profileId: profileId, refreshToken: row.refreshToken)
            }
        } catch {
            isConnected = false
        }
    }

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

    // MARK: - Private

    private func exchangeCodeForToken(code: String, profileId: String) async {
        guard !clientId.isEmpty else { isConnecting = false; return }

        var body: [String: String] = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code",
        ]
        // Include PKCE verifier if we used it; include secret if available
        if let verifier = codeVerifier { body["code_verifier"] = verifier }
        if !clientSecret.isEmpty { body["client_secret"] = clientSecret }

        await performTokenRequest(body: body, profileId: profileId, isRefresh: false)
        codeVerifier = nil
    }

    private func refreshToken(profileId: String, refreshToken: String) async {
        guard !clientId.isEmpty else {
            isConnected = false
            return
        }
        var body: [String: String] = [
            "refresh_token": refreshToken,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "refresh_token",
        ]
        if !clientSecret.isEmpty { body["client_secret"] = clientSecret }
        await performTokenRequest(body: body, profileId: profileId, isRefresh: true)
    }

    private func performTokenRequest(body: [String: String], profileId: String, isRefresh: Bool) async {
        guard let url = URL(string: "https://api.trakt.tv/oauth/token"),
              let bodyData = try? JSONEncoder().encode(body) else {
            if !isRefresh { isConnecting = false }
            else { isConnected = false; accessToken = nil }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                if isRefresh { isConnected = false; accessToken = nil }
                else { isConnecting = false }
                return
            }
            let token = try JSONDecoder().decode(TraktTokenResponse.self, from: data)
            accessToken = token.accessToken
            isConnected = true
            isConnecting = false
            await saveToken(profileId: profileId, accessToken: token.accessToken,
                            refreshToken: token.refreshToken, expiresIn: token.expiresIn)
        } catch {
            if isRefresh { isConnected = false; accessToken = nil }
            else { isConnecting = false }
        }
    }

    private func saveToken(profileId: String, accessToken: String, refreshToken: String, expiresIn: Int) async {
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        let row = TraktTokenRow(profileId: profileId, accessToken: accessToken,
                                refreshToken: refreshToken, expiresAt: expiresAt)
        try? await SupabaseClient.shared.upsert(into: "trakt_oauth_tokens", onConflict: "profile_id", value: row)
    }

    // MARK: - PKCE helpers

    private static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128).description
    }

    private static func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
