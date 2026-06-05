import SwiftUI
import LunaCore

struct SettingsScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var addonRepo = AddonRepository.shared
    @StateObject private var collectionRepo = CollectionRepository.shared
    @State private var showAddons = false
    @State private var showCatalogManagement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Section
                    VStack(spacing: 0) {
                        if let profile = profileManager.currentProfile {
                            HStack {
                                ProfileAvatarView(profile: profile, size: 48)
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

                        Button {
                            showCatalogManagement = true
                        } label: {
                            HStack {
                                Text("Catalog Management")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(collectionRepo.collections.count)")
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

                    // Appearance Section
                    NavigationLink(destination: AppearanceSettingsScreen()) {
                        HStack {
                            Label("Appearance", systemImage: "paintpalette")
                                .foregroundColor(.white)
                            Spacer()
                            Circle()
                                .fill(themeManager.accent)
                                .frame(width: 20, height: 20)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(LunaTheme.textTertiary)
                        }
                        .padding(16)
                    }
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

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
            .sheet(isPresented: $showCatalogManagement) {
                CatalogManagementScreen()
            }
            .task {
                if collectionRepo.collections.isEmpty {
                    await collectionRepo.load()
                }
            }
        }
    }
}

struct CatalogManagementScreen: View {
    @StateObject private var collectionRepo = CollectionRepository.shared
    @StateObject private var preferenceStore = CollectionDisplayPreferenceStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                if collectionRepo.isLoading && collectionRepo.collections.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView().tint(LunaTheme.accent)
                        Text("Loading catalogs...")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                    }
                } else if collectionRepo.collections.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.badge.questionmark")
                            .font(.system(size: 42))
                            .foregroundColor(LunaTheme.textTertiary)
                        Text("No folder catalogs found")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Collections from your configured folders will appear here.")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List {
                        Section {
                            Text("Choose which folder catalogs appear on Home. Turning folders into rows changes a collection like Decades into separate 1980s, 1990s, and other rows.")
                                .font(.caption)
                                .foregroundColor(LunaTheme.textSecondary)
                        }

                        ForEach(collectionRepo.collections) { collection in
                            Section(collection.name) {
                                Toggle("Show catalog", isOn: Binding(
                                    get: { preferenceStore.isCollectionEnabled(collection) },
                                    set: { preferenceStore.setCollection(collection, enabled: $0) }
                                ))
                                Toggle("Turn folders into rows", isOn: Binding(
                                    get: { preferenceStore.isCollectionExpanded(collection) },
                                    set: { preferenceStore.setCollection(collection, expanded: $0) }
                                ))

                                let folders = collectionRepo.folders(for: collection)
                                if folders.isEmpty {
                                    Text("No folders in this catalog.")
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textTertiary)
                                } else {
                                    ForEach(folders.filter { !preferenceStore.isFolderHidden($0) }) { folder in
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(folder.name)
                                                    .foregroundColor(.white)
                                                Text("Folder")
                                                    .font(.caption2)
                                                    .foregroundColor(LunaTheme.textTertiary)
                                            }
                                            Spacer()
                                            Button("Remove") {
                                                preferenceStore.setFolder(folder, hidden: true)
                                            }
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.red)
                                        }
                                        .contentShape(Rectangle())
                                        .padding(.vertical, 4)
                                    }

                                    ForEach(folders.filter { preferenceStore.isFolderHidden($0) }) { folder in
                                        HStack(spacing: 12) {
                                            Text(folder.name)
                                                .foregroundColor(LunaTheme.textTertiary)
                                            Spacer()
                                            Button("Restore") {
                                                preferenceStore.setFolder(folder, hidden: false)
                                            }
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(LunaTheme.accent)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Catalog Management")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if collectionRepo.collections.isEmpty {
                    await collectionRepo.load()
                }
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

                if addonRepo.isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(LunaTheme.accent)
                        Text("Loading addons...")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                    }
                } else if let error = addonRepo.errorMessage, addonRepo.managedAddons.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)
                        Text("Failed to load addons")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            Task {
                                guard let profile = ProfileManager.shared.currentProfile else { return }
                                await addonRepo.loadAddons(profileId: profile.id)
                            }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                        }
                        .glassCard(cornerRadius: 12, interactive: true)
                        .foregroundColor(.white)
                    }
                } else {
                    List {
                        Section("Default Addons") {
                            ForEach(Array(LunaConfig.defaultAddons.enumerated()), id: \.offset) { _, url in
                                Text(url)
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textSecondary)
                            }
                        }

                        Section("Installed (\(addonRepo.managedAddons.count))") {
                            if addonRepo.managedAddons.isEmpty {
                                Text("No addons loaded. Pull to refresh or check your connection.")
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textTertiary)
                            }
                            ForEach(addonRepo.managedAddons) { addon in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(addon.displayName)
                                            .foregroundColor(.white)
                                        Text(addon.manifestUrl)
                                            .font(.caption)
                                            .foregroundColor(LunaTheme.textTertiary)
                                        if let err = addon.errorMessage {
                                            Text("Error: \(err)")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
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

                        if let error = addonRepo.errorMessage, !addonRepo.managedAddons.isEmpty {
                            Section("Warning") {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        guard let profile = ProfileManager.shared.currentProfile else { return }
                        await addonRepo.loadAddons(profileId: profile.id)
                    }
                }
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
                                .glassProminentButtonStyle(tint: LunaTheme.accent, cornerRadius: 12)
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
            .task {
                guard let profile = ProfileManager.shared.currentProfile else { return }
                if addonRepo.managedAddons.isEmpty {
                    await addonRepo.loadAddons(profileId: profile.id)
                }
            }
        }
    }
}
