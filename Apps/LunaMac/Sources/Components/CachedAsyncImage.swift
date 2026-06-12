import SwiftUI
import LunaCore

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var nsImage: LunaImage?

    var body: some View {
        if let img = nsImage {
            content(Image(lunaImage: img))
        } else {
            placeholder()
                .task { await load() }
        }
    }

    private func load() async {
        guard let url, nsImage == nil else { return }

        if let data = LunaImageCache.cachedData(for: url),
           let img = LunaImage(data: data) {
            nsImage = img
            return
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = LunaImage(data: data) else { return }

        LunaImageCache.store(data: data, for: url)
        nsImage = img
    }
}

extension Image {
    init(lunaImage: LunaImage) {
        #if os(macOS)
        self.init(nsImage: lunaImage)
        #elseif os(iOS)
        self.init(uiImage: lunaImage)
        #endif
    }
}
