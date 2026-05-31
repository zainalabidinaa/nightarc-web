import SwiftUI
import LunaCore

struct ContentCard: View {
    let item: MetaPreview
    @State private var imageFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LunaTheme.surfaceElevated)
                    .frame(width: cardWidth, height: cardHeight)

                if let posterURL = item.poster, let url = URL(string: posterURL), !imageFailed {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            placeholderView
                        case .empty:
                            ProgressView().tint(LunaTheme.accent)
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }

            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: cardWidth)

            if let rating = item.imdbRating {
                Text(rating)
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textSecondary)
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 4) {
            Image(systemName: item.type == .movie ? "film" : "tv")
                .font(.title2)
                .foregroundColor(LunaTheme.textTertiary)
            Text(item.name)
                .font(.caption2)
                .foregroundColor(LunaTheme.textSecondary)
                .lineLimit(2)
                .padding(.horizontal, 4)
                .multilineTextAlignment(.center)
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private var cardWidth: CGFloat {
        item.posterShape == .landscape ? 200 : 120
    }

    private var cardHeight: CGFloat {
        item.posterShape == .landscape ? 112 : 180
    }
}
