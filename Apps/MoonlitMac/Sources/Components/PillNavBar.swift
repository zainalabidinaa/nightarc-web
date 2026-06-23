import SwiftUI
import MoonlitCore

enum MacMainTab: String, CaseIterable {
    case home, search, library, settings, admin

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .library: return "rectangle.stack.fill"
        case .settings: return "gear"
        case .admin: return "shield.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .library: return "Library"
        case .settings: return "Settings"
        case .admin: return "Admin"
        }
    }

    var keyboardShortcut: KeyEquivalent {
        switch self {
        case .home: return "1"
        case .search: return "2"
        case .library: return "3"
        case .settings: return "4"
        case .admin: return "5"
        }
    }
}

struct PillNavBar: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @Binding var selectedTab: MacMainTab

    @Namespace private var pillNamespace

    private var visibleTabs: [MacMainTab] {
        [.home, .search, .library, .settings]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs, id: \.self) { tab in
                tabButton(tab)
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 20)
                .padding(.horizontal, 8)

            profileMenu
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            ZStack {
                Color.black.opacity(0.65)
                GlassMaterialView()
            }
            .clipShape(Capsule())
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
    }

    private func tabButton(_ tab: MacMainTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                Text(tab.label)
                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
            }
            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .keyboardShortcut(tab.keyboardShortcut, modifiers: .command)
    }

    private var profileMenu: some View {
        Menu {
            if let profile = profileManager.currentProfile {
                Text("Signed in as \(profile.name)")
            }
            Divider()
            Button("Switch Profile") {
                profileManager.currentProfile = nil
            }
            Button("Sign Out") {
                profileManager.currentProfile = nil
                Task { await profileManager.signOut() }
            }
        } label: {
            HStack(spacing: 6) {
                MacProfileAvatarView(
                    avatarId: profileManager.currentProfile?.avatarId,
                    name: profileManager.currentProfile?.name ?? "?",
                    avatarColor: profileManager.currentProfile?.avatarColor,
                    size: 24
                )
                Text(profileManager.currentProfile?.name ?? "Profile")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile menu")
    }
}

struct GlassMaterialView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .withinWindow
        view.state = .active
        view.wantsLayer = true
        view.alphaValue = 0.6
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
