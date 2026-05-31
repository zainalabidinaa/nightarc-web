import SwiftUI
import LunaCore

@main
struct LunaApp: App {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var roleManager = RoleManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
                .environmentObject(roleManager)
                .preferredColorScheme(.dark)
        }
    }
}
