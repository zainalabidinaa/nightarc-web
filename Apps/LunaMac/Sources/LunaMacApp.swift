import SwiftUI
import LunaCore

@main
struct LunaMacApp: App {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var roleManager = RoleManager.shared

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environmentObject(profileManager)
                .environmentObject(roleManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
