import SwiftUI
import LunaCore

struct HomeHero: View {
    let item: MetaPreview
    let rowTitle: String
    let onTap: () -> Void
    let dotCount: Int
    let activeIndex: Int
    let onDotTap: (Int) -> Void

    private let heroHeight: CGFloat = 400

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop
            Group {
                if let banner = item.banner ?? item.poster, let url = URL(string: banner) {
                    CachedAsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        LunaTheme.surface
                    }
                } else {
                    LunaTheme.surface
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
            .clipped()
            .overlay {
                // Single unified gradient for readability
                LinearGradient(
                    stops: [
                        .init(color: LunaTheme.background, location: 0),
                        .init(color: .clear, location: 0.15),
                        .init(color: .clear, location: 0.55),
                        .init(color: .black.opacity(0.7), location: 0.8),
                        .init(color: .black.opacity(0.95), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Content
            VStack(alignment: .leading, spacing: 0) {
                Text(rowTitle.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(LunaTheme.accent)
                    .tracking(2)
                    .padding(.bottom, 10)

                if let logoUrl = item.logo.flatMap({ URL(string: $0) }) {
                    CachedAsyncImage(url: logoUrl) { img in
                        img.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 56)
                            .frame(maxWidth: 300, alignment: .leading)
                    } placeholder: {
                        titleText.padding(.bottom, 4)
                    }
                    .padding(.bottom, 10)
                } else {
                    titleText.padding(.bottom, 10)
                }

                HStack(spacing: 12) {
                    if let rating = item.imdbRating {
                        Label(rating, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    if let release = item.releaseInfo {
                        Text("·").foregroundColor(.white.opacity(0.3))
                        Text(release)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    if let genres = item.genres?.prefix(2) {
                        Text("·").foregroundColor(.white.opacity(0.3))
                        Text(genres.joined(separator: " · "))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.bottom, 12)

                if let desc = item.description {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .frame(maxWidth: 480, alignment: .leading)
                        .padding(.bottom, 18)
                } else {
                    Spacer().frame(height: 18)
                }

                HStack(spacing: 10) {
                    Button(action: onTap) {
                        Label("Watch Now", systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onTap) {
                        Image(systemName: "info.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)

            // Dots
            if dotCount > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<dotCount, id: \.self) { i in
                        Button { onDotTap(i) } label: {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(i == activeIndex ? .white : .white.opacity(0.3))
                                .frame(width: i == activeIndex ? 18 : 6, height: 3)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.3), value: activeIndex)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: heroHeight)
        .clipped()
    }

    private var titleText: some View {
        Text(item.name)
            .font(.system(size: 40, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
    }
}
