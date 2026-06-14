import SwiftUI
import NightarcCore

@main
struct NightarcApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var roleManager = RoleManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        NightarcTypography.registerFonts()
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().tintColor = .systemBlue
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.55)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
                .environmentObject(roleManager)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
                .tint(.blue)
                .accentColor(.blue)
                .onOpenURL { handleDeepLink($0) }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let scheme = url.scheme else { return }

        if scheme == "stremio" || scheme == "luna",
           url.host == "install-addon",
           let addonURL = URLComponents(url: url, resolvingAgainstBaseURL: true)?
               .queryItems?.first(where: { $0.name == "url" })?.value {
            Task {
                await AddonRepository.shared.installAddon(url: addonURL)
                ToastPresenter.shared.show(message: "Addon installed", style: .success)
            }
        }
    }
}
