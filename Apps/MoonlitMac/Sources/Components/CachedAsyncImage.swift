import SwiftUI
import MoonlitCore

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var nsImage: MoonlitImage?

    var body: some View {
        if let img = nsImage {
            content(Image(moonlitImage: img))
        } else {
            placeholder()
                .task { await load() }
        }
    }

    private func load() async {
        guard let url, nsImage == nil else { return }

        if let data = MoonlitImageCache.cachedData(for: url),
           let img = MoonlitImage(data: data) {
            nsImage = img
            return
        }

        // Retry transient network failures with backoff — a chunk of artwork is hosted on
        // flaky free hosts (e.g. i.postimg.cc) that intermittently drop connections.
        let backoffs: [Double] = [0.4, 1.0, 2.0]
        for attempt in 0...backoffs.count {
            if Task.isCancelled { return }
            if let (data, response) = try? await URLSession.shared.data(from: url) {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 200
                if (200..<400).contains(code), let img = MoonlitImage(data: data) {
                    MoonlitImageCache.store(data: data, for: url)
                    nsImage = img
                    return
                }
                if !(200..<400).contains(code) { return } // real HTTP error — don't retry
            }
            if attempt < backoffs.count {
                try? await Task.sleep(for: .seconds(backoffs[attempt]))
            }
        }
    }
}

extension Image {
    init(moonlitImage: MoonlitImage) {
        #if os(macOS)
        self.init(nsImage: moonlitImage)
        #elseif os(iOS)
        self.init(uiImage: moonlitImage)
        #endif
    }
}
