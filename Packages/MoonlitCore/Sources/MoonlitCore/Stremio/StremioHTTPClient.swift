import Foundation

public final class StremioHTTPClient: @unchecked Sendable {
    public static let shared = StremioHTTPClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 25
        config.httpMaximumConnectionsPerHost = 3
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024,
            diskPath: "moonlit.httpcache"
        )
        config.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    public func getText(url: String, headers: [String: String]? = nil) async throws -> String {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Force HTTP/2 — prevents the iOS QUIC crypto-queue overflow (max 5
        // simultaneous QUIC handshakes) that blocks startup when many addons load at once
        request.assumesHTTP3Capable = false
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw StremioError.networkError(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StremioError.networkError(URLError(.badServerResponse))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw StremioError.httpError(httpResponse.statusCode)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw StremioError.invalidResponse
        }
        return text
    }

    public func getJSON<T: Decodable>(url: String, type: T.Type) async throws -> T {
        let text = try await getText(url: url)
        guard let data = text.data(using: .utf8) else {
            throw StremioError.invalidResponse
        }
        return try decoder.decode(T.self, from: data)
    }
}

public enum StremioError: Error, LocalizedError {
    case httpError(Int)
    case invalidResponse
    case invalidManifest
    case manifestNotFound
    case addonUnreachable(String)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .httpError(404):
            return "Content not found on this addon"
        case .httpError(429):
            return "Too many requests — try again in a moment"
        case .httpError(let code) where (500..<600).contains(code):
            return "Addon server error — try another addon"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .invalidResponse:
            return "Invalid response from addon"
        case .invalidManifest:
            return "Invalid addon manifest"
        case .manifestNotFound:
            return "Addon manifest not found"
        case .addonUnreachable(let url):
            return "Addon unreachable: \(url)"
        }
    }
}
