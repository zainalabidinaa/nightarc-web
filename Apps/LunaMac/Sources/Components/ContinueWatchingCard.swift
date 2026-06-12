import SwiftUI
import LunaCore

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    var isLoading: Bool = false
    @State private var isHovering = false

    private var episodeLabel: String? {
        guard let s = item.seasonNumber, let e = item.episodeNumber else { return nil }
        return "S\(s)E\(e)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                // Poster
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            fallbackView
                        }
                    } else {
                        fallbackView
                    }
                }
                .frame(width: 220, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Progress bar at bottom
                VStack {
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Rectangle()
                                .fill(LunaTheme.accent)
                                .frame(width: geo.size.width * item.progressFraction, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Loading / hover overlay
                if isLoading {
                    Color.black.opacity(0.5)
                    ProgressView().tint(.white)
                } else if isHovering {
                    Color.black.opacity(0.3)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
            }
            .frame(width: 220, height: 124)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { isHovering = $0 }

            Text(item.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)

            if let subtitle = episodeLabel ?? item.episodeTitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(LunaTheme.textTertiary)
                    .lineLimit(1)
                    .frame(width: 220, alignment: .leading)
            }
        }
    }

    private var fallbackView: some View {
        ZStack {
            Rectangle().fill(LunaTheme.surfaceElevated)
            Image(systemName: "play.rectangle")
                .font(.title2)
                .foregroundColor(.white.opacity(0.15))
        }
    }
}
