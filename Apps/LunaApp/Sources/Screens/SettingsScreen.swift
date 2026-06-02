import SwiftUI
import LunaCore

struct SettingsScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var showAddons = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Section
                    VStack(spacing: 0) {
                        if let profile = profileManager.currentProfile {
                            HStack {
                                Circle()
                                    .fill(profile.avatarColor.map { Color(hex: $0) } ?? LunaTheme.accent)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(profile.name.prefix(1).uppercased()))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(profile.isAdmin ? "Admin" : "User")
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textTertiary)
                            }
                            .padding()

                            Divider().background(Color.white.opacity(0.08))

                            Button {
                                profileManager.currentProfile = nil
                            } label: {
                                HStack {
                                    Text("Switch Profile")
                                        .foregroundColor(LunaTheme.accent)
                                    Spacer()
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.accent)
                                }
                                .padding()
                            }
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    // Addons Section
                    VStack(spacing: 0) {
                        Button {
                            showAddons = true
                        } label: {
                            HStack {
                                Text("Manage Addons")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(addonRepo.managedAddons.count)")
                                    .foregroundColor(LunaTheme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textTertiary)
                            }
                            .padding()
                        }

                        Divider().background(Color.white.opacity(0.08))

                        Text("Addons provide content catalogs, metadata, and streaming sources")
                            .font(.caption)
                            .foregroundColor(LunaTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    // Account Section
                    VStack(spacing: 0) {
                        Button(role: .destructive) {
                            Task { await profileManager.signOut() }
                        } label: {
                            HStack {
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    // Footer
                    VStack(spacing: 4) {
                        Text("Luna v1.0.0")
                            .font(.caption)
                            .foregroundColor(LunaTheme.textTertiary)
                        Text("Built with the Stremio addon ecosystem")
                            .font(.caption2)
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                    .padding(.top)

                    Spacer().frame(height: 32)
                }
                .padding(.top)
            }
            .background(LunaTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddons) {
                AddonsScreen()
            }
        }
    }
}

struct AddonsScreen: View {
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var newAddonURL = ""
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                List {
                    Section("Default Addons") {
                        ForEach(Array(LunaConfig.defaultAddons.enumerated()), id: \.offset) { _, url in
                            Text(url)
                                .font(.caption)
                                .foregroundColor(LunaTheme.textSecondary)
                        }
                    }

                    Section("Installed (\(addonRepo.managedAddons.count))") {
                        ForEach(addonRepo.managedAddons) { addon in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(addon.displayName)
                                        .foregroundColor(.white)
                                    Text(addon.manifestUrl)
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textTertiary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { addon.enabled },
                                    set: { _ in addonRepo.toggleAddon(url: addon.manifestUrl) }
                                ))
                                .labelsHidden()
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                addonRepo.removeAddon(url: addonRepo.managedAddons[idx].manifestUrl)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Addons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Enter a Stremio addon URL")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("https://.../manifest.json", text: $newAddonURL)
                            .padding()
                            .background(LunaTheme.surface)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .autocapitalization(.none)
                            .keyboardType(.URL)

                        Button {
                            Task {
                                await addonRepo.installAddon(url: newAddonURL)
                                newAddonURL = ""
                                showAddSheet = false
                            }
                        } label: {
                            Text("Install")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LunaTheme.accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(newAddonURL.isEmpty)
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top)
                    .background(LunaTheme.background)
                    .navigationTitle("Add Addon")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddSheet = false }
                        }
                    }
                }
            }
        }
    }
}
