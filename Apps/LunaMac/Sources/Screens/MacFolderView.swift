import SwiftUI
import LunaCore

struct MacFolderView: View {
    let row: CatalogRow
    let onBack: () -> Void
    let onSelectMedia: (MetaPreview) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let backdrop = row.heroBackdrop ?? row.backdropImage ?? row.coverImage,
                   let url = URL(string: backdrop) {
                    CachedAsyncImage(url: url) { img in
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, LunaTheme.background],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            )
                    } placeholder: {
                        EmptyView()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Button { onBack() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)

                    Text(row.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(row.items) { item in
                        MediaCard(item: item)
                            .onTapGesture { onSelectMedia(item) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer().frame(height: 32)
            }
        }
        .background(LunaTheme.background)
    }
}
