import Foundation

// MARK: - SubtitleCue

public struct SubtitleCue: Sendable {
    public let start: TimeInterval
    public let end: TimeInterval
    public let text: String

    public static func parse(_ content: String) -> [SubtitleCue] {
        var cues: [SubtitleCue] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.contains("-->") {
                let arrowParts = line.components(separatedBy: "-->")
                if arrowParts.count >= 2,
                   let start = parseVTTTime(arrowParts[0].trimmingCharacters(in: .whitespaces)),
                   let end = parseVTTTime(arrowParts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? "") {
                    i += 1
                    var textLines: [String] = []
                    while i < lines.count {
                        let t = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        if t.isEmpty || t.contains("-->") { break }
                        if t.allSatisfy({ $0.isNumber }) { i += 1; continue }
                        textLines.append(stripTags(t))
                        i += 1
                    }
                    let text = textLines.filter { !$0.isEmpty }.joined(separator: "\n")
                    if !text.isEmpty { cues.append(SubtitleCue(start: start, end: end, text: text)) }
                    continue
                }
            }
            i += 1
        }
        return cues
    }

    private static func parseVTTTime(_ s: String) -> TimeInterval? {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        let parts = normalized.components(separatedBy: ":")
        switch parts.count {
        case 3:
            guard let h = Double(parts[0]), let m = Double(parts[1]), let sec = Double(parts[2]) else { return nil }
            return h * 3600 + m * 60 + sec
        case 2:
            guard let m = Double(parts[0]), let sec = Double(parts[1]) else { return nil }
            return m * 60 + sec
        default: return nil
        }
    }

    private static func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

// MARK: - SubtitleCueIndex

public struct SubtitleCueIndex: Sendable {
    private struct IndexedCue: Sendable {
        let cue: SubtitleCue
        let originalIndex: Int
    }

    private let cuesByStart: [IndexedCue]
    private let maxEndThroughIndex: [TimeInterval]

    public init(cues: [SubtitleCue]) {
        let sorted = cues.enumerated()
            .map { IndexedCue(cue: $0.element, originalIndex: $0.offset) }
            .sorted {
                if $0.cue.start == $1.cue.start {
                    return $0.originalIndex < $1.originalIndex
                }
                return $0.cue.start < $1.cue.start
            }
        self.cuesByStart = sorted

        var runningMax: TimeInterval = 0
        self.maxEndThroughIndex = sorted.map { item in
            runningMax = max(runningMax, item.cue.end)
            return runningMax
        }
    }

    public func activeCues(at position: TimeInterval) -> [SubtitleCue] {
        guard !cuesByStart.isEmpty else { return [] }

        var low = 0
        var high = cuesByStart.count
        while low < high {
            let mid = (low + high) / 2
            if cuesByStart[mid].cue.start <= position {
                low = mid + 1
            } else {
                high = mid
            }
        }

        var active: [IndexedCue] = []
        var index = low - 1
        while index >= 0 {
            guard maxEndThroughIndex[index] > position else { break }
            let item = cuesByStart[index]
            if position < item.cue.end {
                active.append(item)
            }
            index -= 1
        }

        return active
            .sorted {
                if $0.cue.start == $1.cue.start {
                    return $0.originalIndex < $1.originalIndex
                }
                return $0.cue.start < $1.cue.start
            }
            .map(\.cue)
    }
}
