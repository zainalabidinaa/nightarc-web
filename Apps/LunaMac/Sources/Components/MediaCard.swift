import SwiftUI
import NightarcCore

struct MediaCard: View {
    let item: MetaPreview
    var row: CatalogRow?
    var width: CGFloat?
    var height: CGFloat?

    @State private var primaryFailed = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topTrailing) {
                artwork
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(isHovering ? 0.18 : 0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isHovering ? 0.38 : 0.24), radius: isHovering ? 16 : 8, y: 6)

                if let rating = item.imdbRating, resolvedShape != .landscape {
                    ratingBadge(rating)
                        .padding(7)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(isHovering ? 1.025 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isHovering)
            .onHover { isHovering = $0 }

            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(NightarcTheme.textPrimary)
                .lineLimit(2)
                .frame(width: cardWidth, alignment: .leading)
        }
        .onChange(of: item.id) { _, _ in
            primaryFailed = false
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = primaryFailed ? fallbackImageURL : primaryImageURL {
            CachedAsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: usesFittedArtwork ? .fit : .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(groupArtworkScale)
                    .clipped()
                    .background(NightarcTheme.surfaceElevated)
            } placeholder: {
                placeholder
                    .onAppear {
                        if !primaryFailed, fallbackImageURL != nil {
                            primaryFailed = true
                        }
                    }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            NightarcTheme.surfaceElevated
            VStack(spacing: 8) {
                Image(systemName: item.id.hasPrefix("folder_") ? "folder.fill" : item.type == .series ? "tv.fill" : "film.fill")
                    .font(.system(size: resolvedShape == .landscape ? 28 : 24))
                    .foregroundColor(.white.opacity(0.18))
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private var resolvedShape: PosterShape? {
        if let rowShape = row?.tileShape {
            return PosterShape(rawValue: rowShape.lowercased())
        }
        return item.posterShape
    }

    private var usesFittedArtwork: Bool {
        item.id.hasPrefix("folder_")
    }

    private var groupArtworkScale: CGFloat {
        guard usesFittedArtwork else { return 1 }
        let title = "\(row?.title ?? "") \(item.name)".lowercased()
        return title.contains("award") ? 1.08 : 1
    }

    private var primaryImageURL: URL? {
        if resolvedShape == .landscape {
            return (item.banner ?? item.poster).flatMap(URL.init)
        }
        return (item.poster ?? item.banner).flatMap(URL.init)
    }

    private var fallbackImageURL: URL? {
        let primary = primaryImageURL
        let candidates: [String?]
        if resolvedShape == .landscape {
            candidates = [item.poster, row?.heroBackdrop, row?.coverImage, item.banner]
        } else {
            candidates = [item.banner, row?.heroBackdrop, row?.coverImage, item.poster]
        }
        return candidates
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .compactMap(URL.init)
            .first { $0 != primary }
    }

    private var cardWidth: CGFloat {
        if let width { return width }
        switch resolvedShape {
        case .landscape: return 240
        case .square: return 150
        case .poster, nil: return 154
        }
    }

    private var cardHeight: CGFloat {
        if let height { return height }
        switch resolvedShape {
        case .landscape: return 135
        case .square: return 150
        case .poster, nil: return 231
        }
    }

    private func ratingBadge(_ rating: String) -> some View {
        HStack(spacing: 4) {
            Text("IMDb")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Color(red: 0.961, green: 0.773, blue: 0.094))
            Rectangle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 1, height: 10)
            Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.yellow)
            Text(rating.replacingOccurrences(of: "/10", with: ""))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.black.opacity(0.45), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.75))
    }
}
