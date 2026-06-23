import ImageIO
import MoonlitCore
import SwiftUI
import AppKit

struct AnimatedGIFFrame {
    let image: CGImage
    let duration: TimeInterval
}

struct AnimatedRemoteImage: NSViewRepresentable {
    let url: URL
    let contentMode: CALayerContentsGravity

    func makeNSView(context: Context) -> AnimatedGIFView {
        let view = AnimatedGIFView()
        view.contentsGravity = contentMode
        return view
    }

    func updateNSView(_ view: AnimatedGIFView, context: Context) {
        view.contentsGravity = contentMode
        Task {
            let frames = await Self.loadFrames(from: url)
            await MainActor.run { view.setFrames(frames) }
        }
    }

    static func loadFrames(from url: URL) async -> [AnimatedGIFFrame] {
        if let data = MoonlitImageCache.cachedData(for: url) {
            return decodeFrames(from: data)
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return [] }
        MoonlitImageCache.store(data: data, for: url)
        return decodeFrames(from: data)
    }

    private static func decodeFrames(from data: Data) -> [AnimatedGIFFrame] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 1 else { return [] }

        var frames: [AnimatedGIFFrame] = []
        for index in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let duration = frameDuration(source: source, index: index)
            frames.append(AnimatedGIFFrame(image: cgImage, duration: duration))
        }
        return frames
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.08
        }
        return gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
            ?? gif[kCGImagePropertyGIFDelayTime] as? TimeInterval
            ?? 0.08
    }
}

final class AnimatedGIFView: NSView {
    private var displayLayer: CALayer?

    var contentsGravity: CALayerContentsGravity = .resizeAspectFill {
        didSet { displayLayer?.contentsGravity = contentsGravity }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        let layer = CALayer()
        layer.contentsGravity = contentsGravity
        self.layer?.addSublayer(layer)
        self.displayLayer = layer
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        let layer = CALayer()
        layer.contentsGravity = contentsGravity
        self.layer?.addSublayer(layer)
        self.displayLayer = layer
    }

    override func layout() {
        super.layout()
        displayLayer?.frame = bounds
    }

    func setFrames(_ frames: [AnimatedGIFFrame]) {
        guard let displayLayer, !frames.isEmpty else { return }

        var totalDuration: TimeInterval = 0
        var cgImages: [CGImage] = []
        var keyTimes: [NSNumber] = []

        for frame in frames {
            cgImages.append(frame.image)
            keyTimes.append(NSNumber(value: totalDuration))
            totalDuration += max(frame.duration, 0.02)
        }

        guard totalDuration > 0 else { return }
        let normalizedKeyTimes = keyTimes.map { NSNumber(value: $0.doubleValue / totalDuration) }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = cgImages
        animation.keyTimes = normalizedKeyTimes
        animation.duration = totalDuration
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        displayLayer.add(animation, forKey: "gifAnimation")
    }
}
