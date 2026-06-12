import Foundation

public enum StreamQuality: Int, Sendable, Comparable {
    case unknown = 0
    case hd1080 = 1080
    case ultraHD4K = 2160

    public static func < (lhs: StreamQuality, rhs: StreamQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum StreamSourceSelector {
    public static func playbackCandidates(from streams: [StreamItem]) -> [StreamItem] {
        streams.filter(isPlaybackCandidate)
    }

    public static func hasMultiplePlaybackCandidates(in streams: [StreamItem]) -> Bool {
        var count = 0
        for stream in streams where isPlaybackCandidate(stream) {
            count += 1
            if count > 1 { return true }
        }
        return false
    }

    public static func has4KPlaybackCandidate(in streams: [StreamItem], excludingSourceUrl: String?) -> Bool {
        streams.contains { stream in
            isPlaybackCandidate(stream) &&
            stream.url != excludingSourceUrl &&
            quality(of: stream) == .ultraHD4K
        }
    }

    public static func initialStream(from streams: [StreamItem], prefer4K: Bool) -> StreamItem? {
        rankedStreams(playbackCandidates(from: streams), prefer4K: prefer4K).first
    }

    public static func best4KStream(from streams: [StreamItem], excluding current: StreamItem?) -> StreamItem? {
        rankedStreams(streams.filter(isPlaybackCandidate), prefer4K: true)
            .first { quality(of: $0) == .ultraHD4K && !sameStream($0, current) }
    }

    public static func nextStream(
        after current: StreamItem?,
        currentSourceUrl: String? = nil,
        from streams: [StreamItem],
        prefer4K: Bool
    ) -> StreamItem? {
        let ranked = rankedStreams(playbackCandidates(from: streams), prefer4K: prefer4K)
            .filter { !sameStream($0, current) && !sameSourceUrl($0, currentSourceUrl) }
        let currentQuality = current.map(quality)

        if let currentQuality,
           let sameQuality = ranked.first(where: { quality(of: $0) == currentQuality }) {
            return sameQuality
        }
        if prefer4K, let fourK = ranked.first(where: { quality(of: $0) == .ultraHD4K }) {
            return fourK
        }
        return ranked.first(where: { quality(of: $0) == .hd1080 }) ?? ranked.first
    }

    public static func quality(of stream: StreamItem) -> StreamQuality {
        let text = searchableText(for: stream)
        if text.contains("2160") || text.contains("4k") || text.contains("uhd") {
            return .ultraHD4K
        }
        if text.contains("1080") || text.contains("fhd") || text.contains("fullhd") {
            return .hd1080
        }
        return .unknown
    }

    public static func isPlaybackCandidate(_ stream: StreamItem) -> Bool {
        let text = searchableText(for: stream)
        if stream.sourceType == .youtube || stream.sourceType == .external || stream.sourceType == .playerFrame {
            return false
        }
        if stream.behaviorHints?.bingeGroup?.lowercased() == "trailer" {
            return false
        }
        if text.contains("trailer") || text.contains("teaser") {
            return false
        }
        return true
    }

    private static func rankedStreams(_ streams: [StreamItem], prefer4K: Bool) -> [StreamItem] {
        streams.sorted {
            let lhs = rankingScore(for: $0, prefer4K: prefer4K)
            let rhs = rankingScore(for: $1, prefer4K: prefer4K)
            if lhs != rhs { return lhs > rhs }
            return $0.displayName < $1.displayName
        }
    }

    private static func rankingScore(for stream: StreamItem, prefer4K: Bool) -> Double {
        let text = searchableText(for: stream)
        var score = Double(stream.qualityScore)

        // Penalise cam / telesync rips
        if text.contains("cam") || text.contains("hdcam") || text.contains("telesync") || text.contains(" ts ") {
            score -= 80
        }

        // ── Tier 1: debrid-cached / instant ─────────────────────────────
        // behaviorHints.cached is the canonical signal (Torrentio, Comet, etc.)
        // bolt ⚡ in stream text is a display-only fallback for older addons
        if stream.behaviorHints?.cached == true || hasBoltMarker(in: text) {
            score += 10_000
        }
        // ── Tier 2: explicitly labelled as cached ───────────────────────
        else if text.contains("cached") || text.contains("[cache]") {
            score += 5_000
        }
        // ── Tier 3: rank by speed/size signals ──────────────────────────
        // Real-world streams rarely include explicit "Mbps" labels; they
        // show file size in GB (e.g. "💾 8.9 GB").  We combine all three
        // signals and cap at 900 pts so this tier stays below "cached".
        else {
            var bonus: Double = 0
            // 3a. Explicit Mbps label
            if let mbps = extractMbps(from: text) { bonus = max(bonus, min(mbps * 10, 900)) }
            // 3b. behaviorHints.videoSize (bytes) — populated by Torrentio & many addons
            if let bytes = stream.behaviorHints?.videoSize, bytes > 0 {
                let gb = Double(bytes) / 1_073_741_824
                bonus = max(bonus, min(gb * 25, 900))
            }
            // 3c. File-size text in stream name/title ("8.9 GB", "💾 4.2 GB", etc.)
            if let gb = extractGB(from: text) { bonus = max(bonus, min(gb * 25, 900)) }
            score += bonus
        }

        // Resolution bonus is always applied on top of the tier score
        switch quality(of: stream) {
        case .ultraHD4K: score += prefer4K ? 30 : 0
        case .hd1080:    score += prefer4K ? 20 : 25
        case .unknown:   break
        }
        return score
    }

    private static func hasBoltMarker(in text: String) -> Bool {
        text.contains("\u{26A1}") || text.contains(":zap:") || text.contains("⚡")
    }

    /// Parses explicit bitrate labels: "50 Mbps", "12 Mb/s", "5 MiB/s".
    private static func extractMbps(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*(?:mbps|mb/s|mib/s)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match -> Double? in
            Range(match.range(at: 1), in: text).flatMap { Double(text[$0]) }
        }.max()
    }

    /// Parses file-size labels: "8.9 GB", "💾 4.2 GB", "1.4 gb", "1400 MB" → returns GB.
    private static func extractGB(from text: String) -> Double? {
        // Match patterns like "8.9 gb", "1400 mb", optionally preceded by 💾 or whitespace
        let pattern = #"(?:💾\s*)?(\d+(?:\.\d+)?)\s*(gb|mb)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let values: [Double] = regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges >= 3,
                  let numRange  = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text),
                  let value = Double(text[numRange]) else { return nil }
            let unit = text[unitRange].lowercased()
            return unit == "mb" ? value / 1024 : value   // normalise to GB
        }
        return values.max()
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

    private static func sameStream(_ lhs: StreamItem, _ rhs: StreamItem?) -> Bool {
        guard let rhs else { return false }
        return lhs.id == rhs.id
    }

    private static func sameSourceUrl(_ stream: StreamItem, _ sourceUrl: String?) -> Bool {
        guard let sourceUrl else { return false }
        return stream.url == sourceUrl
    }
}
