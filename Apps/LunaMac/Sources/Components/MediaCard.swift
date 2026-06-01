import SwiftUI
import LunaCore

struct MediaCard: View {
    let item: MetaPreview
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(LunaTheme.surfaceElevated)
                                    .overlay(
                                        Text(item.type == .movie ? "🎬" : "📺")
                                            .font(.title)
                                    )
                            }
                        }
                    } else {
                        Rectangle().fill(LunaTheme.surfaceElevated)
                            .overlay(
                                Text(item.type == .movie ? "🎬" : "📺")
                                    .font(.title)
                            )
                    }
                }
                .frame(width: 180, height: 240)
                .clipped()
                .cornerRadius(10)
                .scaleEffect(isHovering ? 1.05 : 1.0)

                if isHovering {
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }
                    .cornerRadius(10)

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        )
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
            }
            .frame(width: 180, height: 240)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }

            Text(item.name)
                .font(.caption)
                .foregroundColor(LunaTheme.textPrimary)
                .lineLimit(2)
                .frame(width: 180, alignment: .leading)

            if let rating = item.imdbRating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text(rating)
                        .font(.system(size: 11))
                        .foregroundColor(LunaTheme.textTertiary)
                }
            }
        }
    }
}
