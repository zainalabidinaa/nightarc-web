import SwiftUI
import LunaCore

struct FolderScreen: View {
    let row: CatalogRow

    @State private var selectedMedia: MetaPreview?
    @State private var showDetail = false
    @State private var selectedFolder: CatalogRow?
    @State private var showFolder = false
    @State private var isLoadingItems = false
    @State private var isLoadingMoreItems = false

    // Observe CatalogRepository so the grid updates when on-demand items arrive.
    @ObservedObject private var catalogRepo = CatalogRepository.shared

    // The live row — either the originally-passed row (already populated) or the
    // updated version in allFolderRows once on-demand loading completes.
    private var displayRow: CatalogRow {
        catalogRepo.allFolderRows[row.id] ?? row
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    /// A shape-normalised version of displayRow: uses the row's tileShape when
    /// set, otherwise falls back to "poster" so all tiles are uniform.
    private var shapeRow: CatalogRow {
        guard displayRow.tileShape == nil else { return displayRow }
        return CatalogRow(
            id: displayRow.id,
            title: displayRow.title,
            items: displayRow.items,
            addonName: displayRow.addonName,
            addonId: displayRow.addonId,
            page: displayRow.page,
            hasMore: displayRow.hasMore,
            tileShape: "poster",
            coverImage: displayRow.coverImage,
            focusGif: displayRow.focusGif,
            focusGifEnabled: displayRow.focusGifEnabled,
            titleLogo: displayRow.titleLogo,
            heroBackdrop: displayRow.heroBackdrop,
            heroVideoURL: displayRow.heroVideoURL,
            hideTitle: displayRow.hideTitle,
            focusGlowEnabled: displayRow.focusGlowEnabled,
            viewMode: displayRow.viewMode,
            showAllTab: displayRow.showAllTab,
            pinToTop: displayRow.pinToTop,
            backdropImage: displayRow.backdropImage
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero backdrop
                if let backdrop = displayRow.heroBackdrop ?? displayRow.backdropImage ?? displayRow.coverImage,
                   let url = URL(string: backdrop) {
                    GeometryReader { geo in
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 220)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            colors: [.black.opacity(0.15), LunaTheme.background],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                    }
                    .frame(height: 220)
                    .ignoresSafeArea(edges: .top)
                }

                if isLoadingItems {
                    // Shimmer placeholder while loading on-demand
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<12, id: \.self) { _ in
                            ShimmerCard(width: 100, height: 150, cornerRadius: 10)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                } else {
                    // Poster grid — pass shapeRow so all cards use a uniform tile shape
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(displayRow.items.enumerated()), id: \.element.id) { index, item in
                            ContentCard(item: item, row: shapeRow, index: index)
                                .onTapGesture {
                                    if item.id.hasPrefix("folder_"),
                                       let folderRow = catalogRepo.allFolderRows[item.id] {
                                        selectedFolder = folderRow
                                        showFolder = true
                                    } else {
                                        selectedMedia = item
                                        showDetail = true
                                    }
                                }
                                .onAppear {
                                    guard index == displayRow.items.count - 1 else { return }
                                    guard displayRow.hasMore, !isLoadingMoreItems else { return }
                                    Task { await loadMoreItems() }
                                }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    .padding(.bottom, isLoadingMoreItems ? 0 : 24)

                    if isLoadingMoreItems {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
            }
        }
        .background(LunaTheme.background)
        .navigationTitle(displayRow.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showDetail) {
            if let media = selectedMedia {
                DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
            }
        }
        .navigationDestination(isPresented: $showFolder) {
            if let folder = selectedFolder {
                FolderScreen(row: folder)
            }
        }
        .task {
            // Skeleton row (from group collection) — load items on demand.
            guard displayRow.items.isEmpty, !isLoadingItems else { return }
            isLoadingItems = true
            await catalogRepo.loadFolderItems(
                folderId: row.id,
                collectionRepo: CollectionRepository.shared,
                addons: AddonRepository.shared.enabledAddons
            )
            isLoadingItems = false
        }
    }

    private func loadMoreItems() async {
        isLoadingMoreItems = true
        defer { isLoadingMoreItems = false }
        await catalogRepo.loadMoreFolderItems(
            folderId: row.id,
            collectionRepo: CollectionRepository.shared,
            addons: AddonRepository.shared.enabledAddons
        )
    }
}
