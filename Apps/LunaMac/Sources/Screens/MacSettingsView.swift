import SwiftUI
import LunaCore

struct MacSettingsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var systemAddonName: String?
    @State private var systemAddonUrl: String?
    @State private var showVideoPlayerSettings = false
    @State private var showSubtitleAppearance = false
    @State private var showAddons = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                profileCard
                    .padding(.top, LunaTheme.navBarTopInset)

                settingsSectionLabel("Playback")
                VStack(spacing: 0) {
                    navRow(icon: "play.rectangle.fill", title: "Video Player") {
                        showVideoPlayerSettings = true
                    }
                    Divider().background(Color.white.opacity(0.06))
                    navRow(icon: "captions.bubble.fill", title: "Subtitle Appearance") {
                        showSubtitleAppearance = true
                    }
                }
                .background(LunaTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                settingsSectionLabel("Content Management")
                VStack(spacing: 0) {
                    navRow(icon: "puzzlepiece.fill", title: "Addons (\(addonRepo.userAddons.count) installed)") {
                        showAddons = true
                    }
                }
                .background(LunaTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                if let sysUrl = systemAddonUrl {
                    settingsSectionLabel("System Addon")
                    systemAddonRow(name: systemAddonName, url: sysUrl)
                        .padding(.horizontal, 16)
                }

                settingsSectionLabel("App")
                VStack(spacing: 0) {
                    HStack {
                        Text("Version")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Luna for macOS · v1.0")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(LunaTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                Button("Sign Out") {
                    Task { await profileManager.signOut() }
                }
                .foregroundColor(.red)
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer().frame(height: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
        .sheet(isPresented: $showVideoPlayerSettings) {
            NavigationStack {
                MacVideoPlayerSettingsView()
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSubtitleAppearance) {
            NavigationStack {
                MacSubtitleAppearanceView()
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showAddons) {
            MacAddonsView()
                .environmentObject(profileManager)
                .preferredColorScheme(.dark)
        }
        .task {
            let info = try? await SyncService.shared.pullSystemAddonInfo()
            systemAddonUrl = info?.url
            systemAddonName = info?.name
            if addonRepo.managedAddons.isEmpty, let profile = profileManager.currentProfile {
                await addonRepo.loadAddons(profileId: profile.id, systemAddonUrl: info?.url)
            }
        }
    }

    // MARK: - Profile Card

    @ViewBuilder
    private var profileCard: some View {
        if let profile = profileManager.currentProfile {
            HStack(spacing: 14) {
                Circle()
                    .fill(profile.avatarColor.map { Color(hex: $0) } ?? LunaTheme.accent)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(profile.name.prefix(1).uppercased()))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        if roleManager.isAdmin {
                            Text("Admin")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(LunaTheme.accent.opacity(0.2))
                                .foregroundColor(LunaTheme.accent)
                                .cornerRadius(4)
                        }
                    }
                    if let email = profileManager.currentSession?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                }
                Spacer()
                Button("Switch") {
                    profileManager.currentProfile = nil
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LunaTheme.surfaceElevated)
                .foregroundColor(LunaTheme.textSecondary)
                .cornerRadius(8)
                .buttonStyle(.plain)
            }
            .padding()
            .background(LunaTheme.surface)
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - System Addon Row

    private func systemAddonRow(name: String?, url: String) -> some View {
        HStack {
            Image(systemName: "star.circle.fill").foregroundColor(LunaTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(name ?? "System Addon")
                    .font(.subheadline).foregroundColor(.white)
                Text(url)
                    .font(.caption2).foregroundColor(LunaTheme.textTertiary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(LunaTheme.surface)
        .cornerRadius(10)
    }

    // MARK: - Nav Row

    private func navRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(LunaTheme.accent)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(LunaTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

@MainActor
private func settingsSectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(LunaTheme.textTertiary)
        .tracking(1)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
}
