import SwiftUI
import LunaCore

struct FolderScreen: View {
    let row: CatalogRow

    @State private var selectedMedia: MetaPreview?
    @State private var showDetail = false

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let backdrop = row.heroBackdrop ?? row.backdropImage ?? row.coverImage,
                   let url = URL(string: backdrop) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
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
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(row.items.enumerated()), id: \.element.id) { index, item in
                        ContentCard(item: item, row: row, index: index)
                            .onTapGesture {
                                selectedMedia = item
                                showDetail = true
                            }
                    }
                }
                .padding()
            }
        }
        .background(LunaTheme.background)
        .navigationTitle(row.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showDetail) {
            if let media = selectedMedia {
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
        }
    }
}
