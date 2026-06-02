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
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                Group {
                    if let poster = item.poster, let url = URL(string: poster) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle().fill(LunaTheme.surfaceElevated)
                            }
                        }
                    } else {
                        Rectangle().fill(LunaTheme.surfaceElevated)
                    }
                }
                .frame(width: 200, height: 112)
                .clipped()
                .cornerRadius(8)

                VStack(spacing: 0) {
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Rectangle()
                                .fill(LunaTheme.accent)
                                .frame(
                                    width: geo.size.width * item.progressFraction,
                                    height: 3
                                )
                        }
                    }
                    .frame(height: 3)
                }
                .cornerRadius(8)

                if isLoading {
                    Color.black.opacity(0.4).cornerRadius(8)
                    ProgressView().tint(.white)
                } else if isHovering {
                    Color.black.opacity(0.4).cornerRadius(8)
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        )
                }
            }
            .frame(width: 200, height: 112)
            .onHover { isHovering = $0 }

            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)

            if let subtitle = item.episodeTitle ?? episodeLabel {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textTertiary)
                    .lineLimit(1)
                    .frame(width: 200, alignment: .leading)
            }
        }
    }
}
