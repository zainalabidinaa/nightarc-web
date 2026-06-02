import SwiftUI
import LunaCore

struct MacSettingsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var newUrl = ""
    @State private var systemAddonName: String?
    @State private var systemAddonUrl: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
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
                            Text(profile.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(profile.isAdmin ? "Admin" : "User")
                                .font(.caption)
                                .foregroundColor(LunaTheme.textTertiary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LunaTheme.surface)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, LunaTheme.navBarTopInset)

                    Button("Switch Profile") {
                        profileManager.currentProfile = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(LunaTheme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                if let sysUrl = systemAddonUrl {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("System Addon")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(LunaTheme.textTertiary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 6)

                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(LunaTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(systemAddonName ?? "System Addon")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(sysUrl)
                                    .font(.caption2)
                                    .foregroundColor(LunaTheme.textTertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LunaTheme.surface)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Addons (\(addonRepo.userAddons.count) installed)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(LunaTheme.textTertiary)
                        .tracking(1)
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 6)

                    VStack(spacing: 0) {
                        if addonRepo.userAddons.isEmpty {
                            HStack {
                                Text("No custom addons. Core addons are included automatically and sync across your devices.")
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textTertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(LunaTheme.surface)
                        }

                        ForEach(addonRepo.userAddons) { addon in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(addon.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Text(addon.manifestUrl)
                                        .font(.caption2)
                                        .foregroundColor(LunaTheme.textTertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button("Remove") {
                                    addonRepo.removeAddon(url: addon.manifestUrl)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(LunaTheme.surface)
                            if addon.id != addonRepo.userAddons.last?.id {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }

                        Divider().background(Color.white.opacity(0.06))

                        HStack(spacing: 8) {
                            TextField("Add addon URL...", text: $newUrl)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(LunaTheme.background)
                                .cornerRadius(6)
                                .foregroundColor(.white)
                            Button("Install") {
                                Task {
                                    await addonRepo.installAddon(url: newUrl)
                                    newUrl = ""
                                }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(newUrl.isEmpty ? LunaTheme.surfaceElevated : LunaTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .disabled(newUrl.isEmpty)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LunaTheme.surface)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Button("Sign Out") {
                    Task { await profileManager.signOut() }
                }
                .foregroundColor(.red)
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Text("Luna for macOS · v1.0")
                    .font(.caption2)
                    .foregroundColor(LunaTheme.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer().frame(height: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
        .task {
            let info = try? await SyncService.shared.pullSystemAddonInfo()
            systemAddonUrl = info?.url
            systemAddonName = info?.name
            if addonRepo.managedAddons.isEmpty, let profile = profileManager.currentProfile {
                await addonRepo.loadAddons(profileId: profile.id, systemAddonUrl: info?.url)
            }
        }
    }
}
