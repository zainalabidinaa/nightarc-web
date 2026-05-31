import SwiftUI
import LunaCore

struct MacContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared

    var body: some View {
        Group {
            if profileManager.isAuthenticated {
                if profileManager.currentProfile != nil {
                    MacMainView()
                } else if !profileManager.profiles.isEmpty {
                    MacProfilePicker()
                } else {
                    MacCreateProfile()
                }
            } else {
                MacAuthView()
            }
        }
        .onChange(of: profileManager.currentProfile) { _, newProfile in
            roleManager.evaluateRole(profile: newProfile)
        }
    }
}

struct MacMainView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var selectedTab: MacTab? = .home

    enum MacTab: String, CaseIterable {
        case home, search, library, settings, admin
        var icon: String {
            switch self {
            case .home: "house.fill"
            case .search: "magnifyingglass"
            case .library: "bookmark.fill"
            case .settings: "gearshape.fill"
            case .admin: "shield.fill"
            }
        }
        var label: String {
            switch self {
            case .home: "Home"
            case .search: "Search"
            case .library: "Library"
            case .settings: "Settings"
            case .admin: "Admin"
            }
        }
    }

    var visibleTabs: [MacTab] {
        var tabs: [MacTab] = [.home, .search, .library, .settings]
        if roleManager.isAdmin { tabs.append(.admin) }
        return tabs
    }

    var body: some View {
        NavigationSplitView {
            List(visibleTabs, id: \.self, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .foregroundColor(selectedTab == tab ? .purple : .primary)
            }
            .listStyle(.sidebar)
            .navigationTitle("Luna")
            .frame(minWidth: 200)
        } detail: {
            switch selectedTab {
            case .home: MacHomeView()
            case .search: MacSearchView()
            case .library: MacLibraryView()
            case .settings: MacSettingsView()
            case .admin: MacAdminView()
            case .none: Text("Select a tab").foregroundColor(.secondary)
            }
        }
        .task {
            if let profile = profileManager.currentProfile {
                await addonRepo.loadAddons(profileId: profile.id)
            }
        }
    }
}

struct MacHomeView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var homeRepo = HomeRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared

    var body: some View {
        ScrollView {
            if catalogRepo.isLoading {
                ProgressView().scaleEffect(1.2).padding(.top, 100)
            } else {
                if !homeRepo.continueWatchingItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Continue Watching").font(.title3).fontWeight(.semibold).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(homeRepo.continueWatchingItems) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.3))
                                            .frame(width: 160, height: 90)
                                            .overlay(ProgressView(value: item.progressFraction).tint(.purple).padding(.horizontal, 4).padding(.bottom, 4), alignment: .bottom)
                                        Text(item.name).font(.caption).lineLimit(1).frame(width: 160)
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }.padding(.top)
                }
                ForEach(catalogRepo.catalogRows) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(row.title).font(.title3).fontWeight(.semibold).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(row.items) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.2))
                                            .frame(width: 120, height: 180)
                                            .overlay(
                                                Text(item.type == .movie ? "🎬" : "📺").font(.title)
                                            )
                                        Text(item.name).font(.caption).lineLimit(2).frame(width: 120)
                                        if let rating = item.imdbRating {
                                            Text("⭐ " + rating).font(.caption2).foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }.padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 600)
        .task {
            guard let profile = profileManager.currentProfile else { return }
            await addonRepo.loadAddons(profileId: profile.id)
            await catalogRepo.loadAllCatalogs(addons: addonRepo.enabledAddons)
            await homeRepo.loadContinueWatching(profileId: profile.id)
        }
    }
}

struct MacSearchView: View {
    @StateObject private var searchRepo = SearchRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var query = ""

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search movies & shows...", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await searchRepo.search(query: query, addons: addonRepo.enabledAddons) } }
            }.padding()
            if searchRepo.isLoading {
                Spacer(); ProgressView(); Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(searchRepo.results) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.2))
                                    .frame(height: 180)
                                    .overlay(
                                        Text(item.type == .movie ? "🎬" : "📺").font(.title)
                                    )
                                Text(item.name).font(.caption).lineLimit(2)
                            }
                        }
                    }.padding()
                }
            }
        }
    }
}

struct MacLibraryView: View {
    @StateObject private var libraryRepo = LibraryRepository.shared
    @EnvironmentObject var profileManager: ProfileManager

    var body: some View {
        VStack {
            if libraryRepo.isLoading {
                Spacer(); ProgressView(); Spacer()
            } else if libraryRepo.libraryItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bookmark").font(.system(size: 40)).foregroundColor(.secondary)
                    Text("Your library is empty").font(.title2)
                    Text("Save movies and shows to watch later").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(libraryRepo.libraryItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.2))
                                    .frame(height: 180)
                                    .overlay(
                                        Text(item.mediaType == "series" ? "📺" : "🎬").font(.title)
                                    )
                                Text(item.name ?? item.mediaId).font(.caption).lineLimit(2)
                            }
                            .contextMenu {
                                Button("Remove") {
                                    Task {
                                        guard let profile = profileManager.currentProfile else { return }
                                        await libraryRepo.removeFromLibrary(profileId: profile.id, mediaId: item.mediaId)
                                    }
                                }
                            }
                        }
                    }.padding()
                }
            }
        }
        .task {
            guard let profile = profileManager.currentProfile else { return }
            await libraryRepo.loadLibrary(profileId: profile.id)
        }
    }
}

struct MacSettingsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var newUrl = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let profile = profileManager.currentProfile {
                HStack(spacing: 12) {
                    Circle().fill(Color.purple).frame(width: 40, height: 40)
                        .overlay(Text(String(profile.name.prefix(1).uppercased())).foregroundColor(.white))
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.headline)
                        Text(profile.isAdmin ? "Admin" : "User").font(.caption).foregroundColor(.secondary)
                    }
                }.padding()
                Button("Switch Profile") { profileManager.currentProfile = nil }.padding(.horizontal).padding(.bottom)
            }
            Divider()
            List {
                Section("Addons (\(addonRepo.managedAddons.count))") {
                    ForEach(addonRepo.managedAddons) { addon in
                        HStack {
                            Text(addon.displayName)
                            Spacer()
                            Text(addon.enabled ? "Enabled" : "Disabled").foregroundColor(addon.enabled ? .green : .secondary)
                        }
                    }
                    HStack {
                        TextField("Add addon URL...", text: $newUrl).textFieldStyle(.roundedBorder)
                        Button("Install") {
                            Task { await addonRepo.installAddon(url: newUrl); newUrl = "" }
                        }.disabled(newUrl.isEmpty)
                    }
                }
                Section {
                    Button("Sign Out") { Task { await profileManager.signOut() } }.foregroundColor(.red)
                }
            }.listStyle(.inset)
        }
    }
}

struct MacAdminView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var maxUses = 1

    var body: some View {
        VStack(alignment: .leading) {
            Text("Admin Panel").font(.title).fontWeight(.bold).padding()
            HStack { Text("Max uses:"); Stepper("\(maxUses)", value: $maxUses, in: 1...100) }.padding(.horizontal)
            Button("Generate Invite Code") {
                Task { try await adminService.generateInviteCode(maxUses: maxUses) }
            }.padding(.horizontal)
            List {
                Section("Invite Codes (\(adminService.inviteCodes.count))") {
                    ForEach(adminService.inviteCodes) { code in
                        HStack {
                            Text(code.code).font(.system(.body, design: .monospaced)).fontWeight(.bold)
                            Spacer()
                            Circle().fill(code.isActive && !code.isUsed ? Color.green : Color.red).frame(width: 8, height: 8)
                            if code.isActive && !code.isUsed {
                                Button("Revoke") { Task { try await adminService.revokeInviteCode(code.code) } }.foregroundColor(.red)
                            }
                        }
                    }
                }
            }.listStyle(.inset)
        }
        .task { await adminService.loadInviteCodes() }
    }
}

struct MacAuthView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill").font(.system(size: 48)).foregroundColor(.purple)
            Text("Luna").font(.system(size: 36, weight: .bold, design: .rounded))
            VStack(spacing: 12) {
                TextField("Email", text: $email).textFieldStyle(.roundedBorder).frame(width: 300)
                SecureField("Password", text: $password).textFieldStyle(.roundedBorder).frame(width: 300)
                if isSignUp { TextField("Invite Code", text: $inviteCode).textFieldStyle(.roundedBorder).frame(width: 300) }
            }
            if let error = errorMessage { Text(error).foregroundColor(.red).font(.caption) }
            Button(action: performAuth) {
                HStack { if isLoading { ProgressView().scaleEffect(0.8) }; Text(isSignUp ? "Create Account" : "Sign In") }
            }.buttonStyle(.borderedProminent).disabled(isLoading || email.isEmpty || password.isEmpty).frame(width: 300)
            Button(isSignUp ? "Have an account? Sign In" : "New? Sign Up") { isSignUp.toggle(); errorMessage = nil }.buttonStyle(.link)
            Spacer()
        }.frame(width: 400, height: 500)
    }

    private func performAuth() {
        isLoading = true; errorMessage = nil
        Task {
            do {
                if isSignUp { try await profileManager.signUp(email: email, password: password, inviteCode: inviteCode) }
                else { try await profileManager.signIn(email: email, password: password) }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}

struct MacProfilePicker: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showCreate = false; @State private var newName = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "moon.stars.fill").font(.system(size: 48)).foregroundColor(.purple)
            Text("Who's watching?").font(.title2).fontWeight(.semibold)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(profileManager.profiles) { profile in
                        Button { profileManager.selectProfile(profile) } label: {
                            VStack(spacing: 8) {
                                Circle().fill(Color.purple).frame(width: 80, height: 80)
                                    .overlay(Text(String(profile.name.prefix(1).uppercased())).font(.title).fontWeight(.bold).foregroundColor(.white))
                                Text(profile.name).font(.subheadline)
                                if profile.isAdmin { Text("Admin").font(.caption2).foregroundColor(.purple) }
                            }
                        }.buttonStyle(.plain)
                    }
                    Button { showCreate = true } label: {
                        VStack(spacing: 8) {
                            Circle().stroke(Color.secondary, lineWidth: 2).frame(width: 80, height: 80)
                                .overlay(Image(systemName: "plus").font(.title2).foregroundColor(.secondary))
                            Text("Add Profile").font(.subheadline).foregroundColor(.secondary)
                        }
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 32)
            }
            Button("Sign Out") { Task { await profileManager.signOut() } }.foregroundColor(.secondary)
            Spacer()
        }
        .sheet(isPresented: $showCreate) {
            VStack(spacing: 20) {
                TextField("Profile name", text: $newName).textFieldStyle(.roundedBorder).padding(.horizontal).padding(.top)
                Button("Create") {
                    Task { try await profileManager.createProfile(name: newName); newName = ""; showCreate = false }
                }.disabled(newName.isEmpty)
                Spacer()
            }.frame(width: 300, height: 150)
        }
    }
}

struct MacCreateProfile: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var name = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "moon.stars.fill").font(.system(size: 64)).foregroundColor(.purple)
            Text("Create Your First Profile").font(.title2).fontWeight(.semibold)
            TextField("Profile Name", text: $name).textFieldStyle(.roundedBorder).frame(width: 300)
            Button("Create Profile") { Task { try await profileManager.createProfile(name: name) } }
                .buttonStyle(.borderedProminent).disabled(name.isEmpty)
            Spacer()
        }.frame(width: 400, height: 400)
    }
}
