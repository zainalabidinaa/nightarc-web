import SwiftUI
import LunaCore

@main
struct LunaApp: App {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var roleManager = RoleManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        LunaTypography.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
                .environmentObject(roleManager)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        }
    }
}
