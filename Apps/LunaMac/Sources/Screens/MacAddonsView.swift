import SwiftUI
import LunaCore

struct MacAddonsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newUrl = ""
    @State private var installError: String?
    @State private var isInstalling = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 0) {
                        if addonRepo.userAddons.isEmpty {
                            HStack {
                                Text("No custom addons installed. Core addons are included automatically and sync across your devices.")
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

                        if let error = installError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                        }

                        HStack(spacing: 8) {
                            TextField("Add addon URL...", text: $newUrl)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(LunaTheme.background)
                                .cornerRadius(6)
                                .foregroundColor(.white)
                            Button(isInstalling ? "..." : "Install") {
                                installError = nil
                                isInstalling = true
                                Task {
                                    let prevCount = addonRepo.managedAddons.count
                                    await addonRepo.installAddon(url: newUrl)
                                    isInstalling = false
                                    if addonRepo.managedAddons.count > prevCount {
                                        newUrl = ""
                                        installError = nil
                                    } else if let err = addonRepo.errorMessage {
                                        installError = err
                                    } else {
                                        installError = "Addon is already installed."
                                    }
                                }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(newUrl.isEmpty || isInstalling ? LunaTheme.surfaceElevated : LunaTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .disabled(newUrl.isEmpty || isInstalling)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LunaTheme.surface)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer().frame(height: 32)
                }
            }
            .background(LunaTheme.background)
            .navigationTitle("Addons")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 400)
        .preferredColorScheme(.dark)
    }
}
