import SwiftUI
import NightarcCore

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var nsImage: NightarcImage?

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

        if let data = NightarcImageCache.cachedData(for: url),
           let img = NightarcImage(data: data) {
            nsImage = img
            return
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = NightarcImage(data: data) else { return }

        NightarcImageCache.store(data: data, for: url)
        nsImage = img
    }
}

extension Image {
    init(lunaImage: NightarcImage) {
        #if os(macOS)
        self.init(nsImage: lunaImage)
        #elseif os(iOS)
        self.init(uiImage: lunaImage)
        #endif
    }
}
