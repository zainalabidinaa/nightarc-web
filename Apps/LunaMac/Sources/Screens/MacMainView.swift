import SwiftUI
import LunaCore

struct MacMainView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var selectedTab: MacMainTab = .home

    var body: some View {
        ZStack(alignment: .top) {
            // Content area
            VStack(spacing: 0) {
                switch selectedTab {
                case .home: MacHomeView()
                case .search: MacSearchView()
                case .library: MacLibraryView()
                case .settings: MacSettingsView()
                case .admin: MacAdminView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LunaTheme.background)

            // Floating pill navbar
            VStack {
                PillNavBar(selectedTab: $selectedTab)
                    .padding(.top, 12)
                Spacer()
            }
        }
    }
}
