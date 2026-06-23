import Foundation

public enum StreamCompatibility {
    case direct
    case enhanced
    case unsupported
}

public func classifyStream(url: String?, sourceType: StreamSourceType) -> StreamCompatibility {
    if sourceType == .torrent { return .enhanced }
    if sourceType == .youtube { return .enhanced }
    if sourceType == .external { return .unsupported }
    if sourceType == .playerFrame { return .unsupported }

    guard let url = url?.lowercased() else {
        return .unsupported
    }

    if url.hasSuffix(".m3u8") || url.hasSuffix(".m3u") { return .direct }
    if url.hasSuffix(".mp4") { return .direct }
    if url.hasSuffix(".mov") { return .direct }

    return .enhanced
}
