import ImageIO
import NightarcCore
import SwiftUI
import UIKit

struct AnimatedRemoteImage: UIViewRepresentable {
    let url: URL
    let contentMode: UIView.ContentMode

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = contentMode
        // Prevent UIImageView's intrinsic size from overriding SwiftUI's .frame() constraint.
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = contentMode
        Task {
            let image = await Self.loadImage(from: url)
            await MainActor.run {
                imageView.image = image
                imageView.startAnimating()
            }
        }
    }

    private static func loadImage(from url: URL) async -> UIImage? {
        if let data = NightarcImageCache.cachedData(for: url) {
            return animatedImage(data: data) ?? UIImage(data: data)
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        NightarcImageCache.store(data: data, for: url)
        return animatedImage(data: data) ?? UIImage(data: data)
    }

    private static func animatedImage(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 1 else {
            return nil
        }

        var images: [UIImage] = []
        var duration: TimeInterval = 0
        for index in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            duration += frameDuration(source: source, index: index)
        }
        return UIImage.animatedImage(with: images, duration: duration)
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
