import SwiftUI
import MoonlitCore

struct CachedAsyncImage<Content: View>: View {
    let url: URL
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    @MainActor private func load() async {
        if let cachedData = MoonlitImageCache.cachedData(for: url),
           let image = UIImage(data: cachedData) {
            phase = .success(Image(uiImage: image))
            return
        }

        // Retry transient network failures with backoff. A chunk of artwork is hosted on
        // flaky free hosts (e.g. i.postimg.cc) that intermittently drop connections; a
        // single attempt leaves ~20% of tiles blank. Backoffs: ~0.4s, 1.0s, 2.0s.
        let backoffs: [Double] = [0.4, 1.0, 2.0]
        var lastError: Error = URLError(.unknown)
        for attempt in 0...backoffs.count {
            if Task.isCancelled { return }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 200
                guard (200..<400).contains(code) else {
                    // A real HTTP error (404 etc) won't fix itself — fail fast.
                    phase = .failure(URLError(.badServerResponse))
                    return
                }
                guard let image = UIImage(data: data) else {
                    phase = .failure(URLError(.cannotDecodeContentData))
                    return
                }
                MoonlitImageCache.store(data: data, for: url)
                phase = .success(Image(uiImage: image))
                return
            } catch {
                lastError = error
                if attempt < backoffs.count {
                    try? await Task.sleep(for: .seconds(backoffs[attempt]))
                }
            }
        }
        phase = .failure(lastError)
    }
}
