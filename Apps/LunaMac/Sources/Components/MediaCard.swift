import SwiftUI
import LunaCore

struct MediaCard: View {
    let item: MetaPreview
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // ── Poster image ──────────────────────────────────────────────
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                ZStack {
                                    Rectangle().fill(LunaTheme.surfaceElevated)
                                    Text(item.name)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                        .padding(6)
                                }
                            }
                        }
                    } else {
                        ZStack {
                            Rectangle().fill(LunaTheme.surfaceElevated)
                            Text(item.name)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(6)
                        }
                    }
                }
                .frame(width: 160, height: 240)
                .clipped()
                .cornerRadius(12)
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .overlay(
                    // Hover gradient + play button
                    ZStack(alignment: .bottom) {
                        if isHovering {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.8)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 80)
                            .cornerRadius(12)

                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .offset(x: 1)
                                )
                                .padding(.bottom, 16)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 160, height: 240)
                )

                // ── Rating badge (top-right overlay, mirrors web) ─────────────
                if let rating = item.imdbRating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(rating)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(6)
                }
            }
            .frame(width: 180, height: 240)
            .animation(.easeInOut(duration: 0.3), value: isHovering)
            .onHover { hovering in isHovering = hovering }

            Text(item.name)
                .font(.caption)
                .foregroundColor(LunaTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 180, alignment: .leading)
        }
    }
}
