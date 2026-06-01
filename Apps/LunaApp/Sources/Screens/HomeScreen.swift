import SwiftUI
import LunaCore

struct HomeScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var collectionRepo = CollectionRepository.shared
    @StateObject private var homeRepo = HomeRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var selectedMedia: MetaPreview?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !homeRepo.continueWatchingItems.isEmpty {
                        ContinueWatchingRow(items: homeRepo.continueWatchingItems)
                    }

                    if !catalogRepo.catalogRows.isEmpty {
                        LazyVStack(spacing: 24) {
                            ForEach(catalogRepo.catalogRows) { row in
                                CatalogRowView(row: row) { item in
                                    selectedMedia = item
                                    showDetail = true
                                }
                                .onAppear {
                                    if row.id == catalogRepo.catalogRows.last?.id {
                                        Task {
                                            await catalogRepo.loadMore(
                                                rowId: row.id,
                                                addons: addonRepo.enabledAddons
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    } else if catalogRepo.isLoading {
                        VStack {
                            Spacer().frame(height: 100)
                            ProgressView()
                                .tint(LunaTheme.accent)
                            Spacer()
                        }
                    }
                }
            }
            .background(LunaTheme.background)
            .navigationTitle("Luna")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let profile = profileManager.currentProfile {
                        Button {
                            profileManager.currentProfile = nil
                        } label: {
                            Circle()
                                .fill(profile.avatarColor.map { Color(hex: $0) } ?? LunaTheme.accent)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(profile.name.prefix(1)))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let media = selectedMedia {
                    DetailScreen(mediaId: media.id, type: media.type.rawValue, name: media.name)
                }
            }
            .task {
                guard let profile = profileManager.currentProfile else { return }
                await addonRepo.loadAddons(profileId: profile.id)
                await collectionRepo.load()
                if collectionRepo.collections.isEmpty {
                    await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
                } else {
                    await catalogRepo.loadFromCollections(
                        collectionRepo: collectionRepo,
                        addons: addonRepo.enabledAddons
                    )
                }
                await homeRepo.loadContinueWatching(profileId: profile.id)
            }
        }
    }
}

struct CatalogRowView: View {
    let row: CatalogRow
    let onTap: (MetaPreview) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let titleLogo = row.titleLogo, let url = URL(string: titleLogo) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                        }
                    }
                } else if !(row.hideTitle ?? false) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(row.items.enumerated()), id: \.element.id) { index, item in
                        ContentCard(item: item, row: row, index: index)
                            .onTapGesture { onTap(item) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continue Watching")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
}

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LunaTheme.surfaceElevated)
                    .frame(width: 160, height: 90)

                ProgressView(value: item.progressFraction)
                    .tint(LunaTheme.accent)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }

            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 160)
        }
    }
}
