import Foundation

public actor StremioHTTPClient {
    public static let shared = StremioHTTPClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = 10
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    public func getText(url: String, headers: [String: String]? = nil) async throws -> String {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StremioError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
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

public enum StremioError: Error {
    case httpError(Int)
    case invalidResponse
    case invalidManifest
    case manifestNotFound
    case addonUnreachable(String)
    case networkError(Error)
}
