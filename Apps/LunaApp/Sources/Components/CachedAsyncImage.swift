import SwiftUI
import NightarcCore

struct CachedAsyncImage<Content: View>: View {
    let url: URL
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    @MainActor private func load() async {
        if let cachedData = NightarcImageCache.cachedData(for: url),
           let image = UIImage(data: cachedData) {
            phase = .success(Image(uiImage: image))
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            NightarcImageCache.store(data: data, for: url)
            if let image = UIImage(data: data) {
                phase = .success(Image(uiImage: image))
            } else {
                phase = .failure(URLError(.cannotDecodeContentData))
            }
        } catch {
            phase = .failure(error)
        }
    }
}
