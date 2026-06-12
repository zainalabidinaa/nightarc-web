import Foundation

public struct StreamPlaybackHints: Sendable, Hashable {
    public let requestHeaders: [String: String]?
    public let responseHeaders: [String: String]?
    public let contentType: String?
    public let videoSize: Int64?

    public init(stream: StreamItem) {
        let responseHeaders = stream.behaviorHints?.proxyHeaders?.response
        self.requestHeaders = stream.behaviorHints?.proxyHeaders?.request
        self.responseHeaders = responseHeaders
        self.contentType = responseHeaders?.first {
            $0.key.caseInsensitiveCompare("content-type") == .orderedSame
        }?.value
        self.videoSize = stream.behaviorHints?.videoSize
    }
}
