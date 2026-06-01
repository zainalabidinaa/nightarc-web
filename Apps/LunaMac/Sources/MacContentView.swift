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
