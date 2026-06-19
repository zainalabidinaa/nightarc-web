import SwiftUI
import MoonlitCore

@main
struct MoonlitMacApp: App {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var roleManager = RoleManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environmentObject(profileManager)
                .environmentObject(roleManager)
                .frame(minWidth: 900, minHeight: 600)
                .background(MoonlitTheme.background)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)

        WindowGroup(id: "player", for: PlayerLaunch.self) { $launch in
            if let launch = launch {
                MacPlayerView(launch: launch)
                    .environmentObject(profileManager)
                    .frame(minWidth: 900, minHeight: 550)
                    .background(Color.black)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 700)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            window.identifier = NSUserInterfaceItemIdentifier("moonlit-main")
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(
                red: 0.031, green: 0.031, blue: 0.031, alpha: 1.0
            )
        }
    }
}
