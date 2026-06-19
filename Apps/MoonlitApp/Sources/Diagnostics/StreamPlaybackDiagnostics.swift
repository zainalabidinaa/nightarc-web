import Foundation
import MoonlitCore
import os
import QuartzCore

enum StreamPlaybackDiagnostics {
    static func logSelectedStream(_ stream: StreamItem, reason: String) {
        print(
            "[Moonlit][StreamDebug] selected reason=\(reason) " +
            "addon=\(stream.addonName ?? "nil") " +
            "quality=\(qualityLabel(for: stream)) " +
            "type=\(stream.sourceType.rawValue) " +
            "host=\(host(for: stream.url)) " +
            "hasHeaders=\((stream.behaviorHints?.proxyHeaders?.request?.isEmpty == false)) " +
            "title=\(stream.displayName.prefix(120))"
        )
    }

    static func logLaunch(_ launch: PlayerLaunch) {
        print(
            "[Moonlit][StreamDebug] launch provider=\(launch.providerName ?? "nil") " +
            "content=\(launch.contentType.rawValue) " +
            "videoId=\(launch.videoId) " +
            "parent=\(launch.parentMetaId ?? "nil") " +
            "host=\(host(for: launch.sourceUrl)) " +
            "hasHeaders=\((launch.sourceHeaders?.isEmpty == false)) " +
            "headerKeys=\((launch.sourceHeaders ?? [:]).keys.sorted().joined(separator: ",")) " +
            "responseContentType=\(launch.sourceContentType ?? "nil") " +
            "responseHeaderKeys=\((launch.sourceResponseHeaders ?? [:]).keys.sorted().joined(separator: ",")) " +
            "videoSize=\(launch.sourceVideoSize.map(String.init) ?? "nil")"
        )
    }

    private static func qualityLabel(for stream: StreamItem) -> String {
        switch StreamSourceSelector.quality(of: stream) {
        case .ultraHD4K: return "4K"
        case .hd1080: return "1080p"
        case .unknown: return "unknown"
        }
    }

    private static func host(for urlString: String?) -> String {
        guard let urlString, let host = URL(string: urlString)?.host else { return "nil" }
        return host
    }
}

@MainActor
final class PlayerPerformanceDiagnostics {
    static let shared = PlayerPerformanceDiagnostics()

    #if DEBUG
    private let logger = Logger(subsystem: "com.moonlit.zain", category: "PlayerPerformance")
    private var counts: [String: Int] = [:]
    private var totalDurationsMs: [String: Double] = [:]
    private var lastFlush = CACurrentMediaTime()
    private let logFileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("player-performance.log")
    #endif

    private init() {}

    func mark(_ key: String) {
        #if DEBUG
        record(key, durationMs: nil)
        #endif
    }

    func event(_ message: String) {
        #if DEBUG
        emit("event \(message)")
        #endif
    }

    func measure<T>(_ key: String, _ work: () -> T) -> T {
        #if DEBUG
        let start = CACurrentMediaTime()
        let value = work()
        record(key, durationMs: (CACurrentMediaTime() - start) * 1000)
        return value
        #else
        return work()
        #endif
    }

    func logAVSync(
        backend: String,
        displayFPS: Double,
        syncDiff: Double,
        droppedFrames: UInt32,
        droppedPackets: UInt32,
        droppedFramesDelta: UInt32,
        droppedPacketsDelta: UInt32,
        videoBitrate: Int,
        audioBitrate: Int
    ) {
        #if DEBUG
        let message = String(
            format: "avsync backend=%@ fps=%.1f diff=%.4fs droppedFrames=%u(+%u) droppedPackets=%u(+%u) videoBitrate=%d audioBitrate=%d",
            backend,
            displayFPS,
            syncDiff,
            droppedFrames,
            droppedFramesDelta,
            droppedPackets,
            droppedPacketsDelta,
            videoBitrate,
            audioBitrate
        )
        emit(message)
        #endif
    }

    #if DEBUG
    private func emit(_ message: String) {
        let timestamp = String(format: "%.3f", CACurrentMediaTime())
        let prefixedMessage = "[Moonlit][PlayerPerf] t=\(timestamp) \(message)"
        logger.notice("\(message, privacy: .public)")
        print(prefixedMessage)
        NSLog("%@", prefixedMessage)
        appendToDebugFile(prefixedMessage)
    }

    private func appendToDebugFile(_ line: String) {
        guard let data = "\(line)\n".data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            guard let handle = try? FileHandle(forWritingTo: logFileURL) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logFileURL, options: .atomic)
        }
    }

    private func record(_ key: String, durationMs: Double?) {
        counts[key, default: 0] += 1
        if let durationMs {
            totalDurationsMs[key, default: 0] += durationMs
        }

        let now = CACurrentMediaTime()
        guard now - lastFlush >= 1 else { return }
        lastFlush = now

        let countSummary = counts.keys.sorted().map { "\($0)=\(counts[$0, default: 0])" }.joined(separator: " ")
        let timingSummary = totalDurationsMs.keys.sorted().map { key in
            let total = totalDurationsMs[key, default: 0]
            let count = max(counts[key, default: 1], 1)
            return "\(key).avgMs=\(String(format: "%.3f", total / Double(count)))"
        }.joined(separator: " ")
        let message = [countSummary, timingSummary].filter { !$0.isEmpty }.joined(separator: " ")

        emit(message)
        counts.removeAll(keepingCapacity: true)
        totalDurationsMs.removeAll(keepingCapacity: true)
    }
    #endif
}
