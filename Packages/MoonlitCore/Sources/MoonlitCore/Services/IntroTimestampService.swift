import Foundation

public struct IntroTimestamp: Sendable {
    public let introStart: Double
    public let introEnd: Double
    public let highlights: [Double]
}

@MainActor
public final class IntroTimestampService {
    public static let shared = IntroTimestampService()

    private var cache: [String: IntroTimestamp?] = [:]

    private init() {}

    public func timestamps(imdbId: String, season: Int, episode: Int) async -> IntroTimestamp? {
        let key = "\(imdbId):s\(String(format: "%02d", season))e\(String(format: "%02d", episode))"
        if let cached = cache[key] { return cached }
        let result = await fetchFromPublicMetaDB(imdbId: imdbId, season: season, episode: episode)
        cache[key] = result
        return result
    }

    public func clearCache() { cache.removeAll() }

    private func fetchFromPublicMetaDB(imdbId: String, season: Int, episode: Int) async -> IntroTimestamp? {
        let urlString = "https://publicmeta.info/api/v1/intro?imdbId=\(imdbId)&season=\(season)&episode=\(episode)"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let json = try JSONDecoder().decode(PublicMetaDBResponse.self, from: data)
            guard let intro = json.intro else { return nil }
            return IntroTimestamp(introStart: intro.start, introEnd: intro.end, highlights: json.highlights ?? [])
        } catch {
            return nil
        }
    }
}

private struct PublicMetaDBResponse: Decodable {
    let intro: IntroWindow?
    let highlights: [Double]?
}

private struct IntroWindow: Decodable {
    let start: Double
    let end: Double
}
