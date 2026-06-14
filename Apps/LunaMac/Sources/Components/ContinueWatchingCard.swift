import SwiftUI
import NightarcCore

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    var isLoading: Bool = false
    var width: CGFloat = 240
    var height: CGFloat = 135

    @State private var isHovering = false

    private var imageURL: URL? {
        (item.thumbnail ?? item.poster).flatMap(URL.init)
    }

    private var episodeLabel: String? {
        guard let s = item.seasonNumber, let e = item.episodeNumber else { return nil }
        return "S\(String(format: "%02d", s)) · E\(String(format: "%02d", e))"
    }

    private var minutesRemaining: Int? {
        guard item.durationMs > 0 else { return nil }
        let remainingMs = item.durationMs * (1.0 - item.progressFraction)
        let mins = Int((remainingMs / 60_000).rounded())
        return mins > 0 ? mins : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .bottom) {
                Group {
                    if let imageURL {
                        CachedAsyncImage(url: imageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            fallbackView
                        }
                    } else {
                        fallbackView
                    }
                }
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        if let episodeLabel {
                            Text(episodeLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                        if let minutesRemaining {
                            Text("\(minutesRemaining) min left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.18))
                            Capsule()
                                .fill(NightarcTheme.accent)
                                .frame(width: geo.size.width * item.progressFraction)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(10)

                if isLoading {
                    Color.black.opacity(0.34)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    MacLottieLoadingView(size: 24)
                }
            }
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovering ? 0.18 : 0.06), lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.025 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isHovering)
            .onHover { isHovering = $0 }

            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)

            if let subtitle = cardSubtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(NightarcTheme.textTertiary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
    }

    private var cardSubtitle: String? {
        if let episodeLabel {
            if let title = item.episodeTitle, !title.isEmpty {
                return "\(episodeLabel) · \(title)"
            }
            return episodeLabel
        }
        guard item.resumePositionMs > 0 else { return nil }
        let seconds = Int(item.resumePositionMs / 1000)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    private var fallbackView: some View {
        ZStack {
            NightarcTheme.surfaceElevated
            Image(systemName: "play.rectangle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.15))
        }
    }
}
