import SwiftUI
import LunaCore

struct MediaCard: View {
    let item: MetaPreview
    @State private var isHovering = false

    private let cardWidth: CGFloat = 160
    private var cardHeight: CGFloat { cardWidth * 1.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                // Poster
                posterView
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                // Rating badge
                if let rating = item.imdbRating {
                    ratingBadge(rating)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }

                // Hover overlay
                if isHovering {
                    hoverOverlay
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(isHovering ? 1.04 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { isHovering = $0 }

            // Title
            Text(item.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(LunaTheme.textPrimary)
                .lineLimit(2)
                .frame(width: cardWidth, alignment: .leading)
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let poster = item.poster, let url = URL(string: poster) {
            CachedAsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                fallbackPoster
            }
        } else {
            fallbackPoster
        }
    }

    private var fallbackPoster: some View {
        ZStack {
            Rectangle().fill(LunaTheme.surfaceElevated)
            Image(systemName: item.type == .series ? "tv" : "film")
                .font(.title2)
                .foregroundColor(.white.opacity(0.15))
        }
    }

    private var hoverOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            playButton
        }
    }

    private var playButton: some View {
        VStack(spacing: 4) {
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .shadow(radius: 4)
            Text(item.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: 120)
        }
        .padding(.bottom, 20)
    }

    private func ratingBadge(_ rating: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.yellow)
            Text(rating)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
