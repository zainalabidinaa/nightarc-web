import Foundation

public enum StreamMatchGuard {
    public static func shouldKeep(_ stream: StreamItem, type: String, id: String) -> Bool {
        let text = searchableText(for: stream)
        let expectedImdbId = id.components(separatedBy: ":").first ?? id

        if containsDifferentImdbId(in: text, expected: expectedImdbId) {
            return false
        }

        guard type == "series",
              let expectedEpisode = expectedSeriesEpisode(from: id) else {
            return true
        }

        return !containsDifferentEpisode(in: text, expected: expectedEpisode)
    }

    private static func searchableText(for stream: StreamItem) -> String {
        ([
            stream.name,
            stream.title,
            stream.description,
            stream.sourceName,
            stream.addonName,
            stream.behaviorHints?.filename,
        ] + (stream.sources ?? []))
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
    }

    private static func expectedSeriesEpisode(from id: String) -> (season: Int, episode: Int)? {
        let parts = id.components(separatedBy: ":")
        guard parts.count >= 3,
              let season = Int(parts[1]),
              let episode = Int(parts[2]) else {
            return nil
        }
        return (season, episode)
    }

    private static func containsDifferentImdbId(in text: String, expected: String) -> Bool {
        matches(pattern: #"\btt\d{5,10}\b"#, in: text).contains { $0 != expected.lowercased() }
    }

    private static func containsDifferentEpisode(
        in text: String,
        expected: (season: Int, episode: Int)
    ) -> Bool {
        let patterns = [
            #"s\s*(\d{1,2})\s*[.\-_· ]*\s*e\s*(\d{1,3})"#,
            #"\b(\d{1,2})\s*x\s*(\d{1,3})\b"#,
            #"season\s*(\d{1,2}).{0,12}episode\s*(\d{1,3})"#,
        ]

        for pattern in patterns {
            for groups in captureGroups(pattern: pattern, in: text) {
                guard groups.count == 2,
                      let season = Int(groups[0]),
                      let episode = Int(groups[1]) else {
                    continue
                }
                if season != expected.season || episode != expected.episode {
                    return true
                }
            }
        }

        return false
    }

    private static func matches(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }

    private static func captureGroups(pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).map { match in
            (1..<match.numberOfRanges).compactMap { index in
                Range(match.range(at: index), in: text).map { String(text[$0]) }
            }
        }
    }
}
