import SwiftUI
import LunaCore

struct ParallaxHero: View {
    let items: [MetaPreview]
    @Binding var currentIndex: Int
    let metrics: ResponsiveMetrics
    let onWatchNow: (MetaPreview) -> Void
    let onToggleLibrary: (MetaPreview) -> Void

    @State private var autoTimer: Timer?
    private let autoAdvanceSeconds: TimeInterval = 6

    var body: some View {
        GeometryReader { geometry in
            let height = 420 + geometry.safeAreaInsets.top
            ZStack(alignment: .bottomLeading) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        AsyncImage(url: URL(string: item.banner ?? item.poster ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                LunaTheme.surfaceContainer
                            }
                        }
                        .scaleEffect(1.14)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: height)

                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.40),
                            .init(color: LunaTheme.background.opacity(0.5), location: 0.65),
                            .init(color: LunaTheme.background, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height * 0.6)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let category = items[safe: currentIndex]?.genres?.first {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(LunaTheme.accent)
                    }

                    Text(items[safe: currentIndex]?.name ?? "")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    metaRow

                    buttonRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.bottom, 24)

                HStack(spacing: 5) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(
                                width: index == currentIndex ? 20 : 6,
                                height: 3
                            )
                            .animation(.easeInOut(duration: 0.25), value: currentIndex)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: height, alignment: .topTrailing)
                .padding(.trailing, 16)
                .padding(.top, geometry.safeAreaInsets.top + 16)
            }
            .clipped()
        }
        .frame(height: 420)
        .onAppear { startAutoAdvance() }
        .onDisappear { stopAutoAdvance() }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            if let rating = items[safe: currentIndex]?.imdbRating {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(rating)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            if let year = items[safe: currentIndex]?.releaseInfo {
                Text("• \(year)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            if let genres = items[safe: currentIndex]?.genres {
                Text(genres.prefix(2).joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button {
                if let item = items[safe: currentIndex] {
                    onWatchNow(item)
                }
            } label: {
                Text("Watch Now")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(.white))
            }

            Button {
                if let item = items[safe: currentIndex] {
                    onToggleLibrary(item)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark")
                    Text("My List")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .glassCapsule(interactive: true, clear: true)
        }
    }

    private func startAutoAdvance() {
        autoTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceSeconds, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex = (currentIndex + 1) % max(items.count, 1)
            }
        }
    }

    private func stopAutoAdvance() {
        autoTimer?.invalidate()
        autoTimer = nil
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
