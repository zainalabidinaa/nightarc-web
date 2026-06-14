import SwiftUI
import NightarcCore

struct MacMainView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var catalogRepo = CatalogRepository.shared
    @State private var selectedTab: MacMainTab = .home
    @State private var detailItem: DetailItem?
    @State private var folderItem: FolderItem?

    struct DetailItem: Identifiable {
        let id: String
        let type: String
        let name: String
    }

    struct FolderItem: Identifiable {
        let id: String
        let row: CatalogRow
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                if let folder = folderItem {
                    MacFolderView(row: folder.row, onBack: { folderItem = nil }) { item in
                        if item.id.hasPrefix("folder_"),
                           let row = catalogRepo.allFolderRows[item.id] {
                            folderItem = FolderItem(id: item.id, row: row)
                        } else {
                            detailItem = DetailItem(id: item.id, type: item.type.rawValue, name: item.name)
                        }
                    } onSelectFolder: { row in
                        folderItem = FolderItem(id: row.id, row: row)
                    }
                } else if let detail = detailItem {
                    MacDetailView(
                        mediaId: detail.id,
                        type: detail.type,
                        name: detail.name,
                        onBack: { detailItem = nil }
                    )
                } else {
                    switch selectedTab {
                    case .home:
                        MacHomeView(onSelectMedia: { item in
                            if item.id.hasPrefix("folder_"),
                               let row = catalogRepo.allFolderRows[item.id] {
                                folderItem = FolderItem(id: item.id, row: row)
                            } else {
                                detailItem = DetailItem(id: item.id, type: item.type.rawValue, name: item.name)
                            }
                        }, onSelectFolder: { row in
                            folderItem = FolderItem(id: row.id, row: row)
                        })
                    case .search:
                        MacSearchView(onSelectMedia: { item in
                            detailItem = DetailItem(id: item.id, type: item.type.rawValue, name: item.name)
                        })
                    case .library:
                        MacLibraryView(onSelectMedia: { item in
                            detailItem = DetailItem(id: item.id, type: item.type.rawValue, name: item.name)
                        })
                    case .settings: MacSettingsView()
                    case .admin: MacAdminView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NightarcTheme.background)

            if detailItem == nil && folderItem == nil {
                VStack {
                    PillNavBar(selectedTab: $selectedTab)
                        .padding(.top, 12)
                    Spacer()
                }
            }
        }
    }
}
