import Foundation
import LunaCore

enum StreamPlaybackDiagnostics {
    static func logSelectedStream(_ stream: StreamItem, reason: String) {
        print(
            "[Luna][StreamDebug] selected reason=\(reason) " +
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
            "[Luna][StreamDebug] launch provider=\(launch.providerName ?? "nil") " +
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
