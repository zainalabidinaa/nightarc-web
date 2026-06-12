import Foundation

#if os(macOS)
import AppKit
public typealias LunaImage = NSImage
#elseif os(iOS)
import UIKit
public typealias LunaImage = UIImage
#endif

public enum LunaImageCache {
    private static let queue = DispatchQueue(label: "luna.imgcache", qos: .utility)
    private static let root: URL = {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LunaImages")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private static func fileURL(for url: URL) -> URL {
        let key = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? url.lastPathComponent
        return root.appendingPathComponent(key)
    }

    public static func cachedData(for url: URL) -> Data? {
        let file = fileURL(for: url)
        return try? Data(contentsOf: file)
    }

    public static func store(data: Data, for url: URL) {
        let file = fileURL(for: url)
        queue.async {
            try? data.write(to: file, options: .atomic)
        }
    }
}
