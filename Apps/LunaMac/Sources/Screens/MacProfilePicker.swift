import SwiftUI
import LunaCore

struct MacProfilePicker: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showCreate = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(LunaTheme.accent)

            Text("Who's watching?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120))],
                spacing: 20
            ) {
                ForEach(profileManager.profiles) { profile in
                    Button {
                        profileManager.selectProfile(profile)
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(
                                    profile.avatarColor
                                        .map { Color(hex: $0) } ?? LunaTheme.accent
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(profile.name.prefix(1).uppercased()))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            Text(profile.name)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            if profile.isAdmin {
                                Text("Admin")
                                    .font(.caption2)
                                    .foregroundColor(LunaTheme.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button { showCreate = true } label: {
                    VStack(spacing: 8) {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(LunaTheme.textTertiary)
                            )
                        Text("Add Profile")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 500)

            Button("Sign Out") {
                Task { await profileManager.signOut() }
            }
            .foregroundColor(LunaTheme.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
        .sheet(isPresented: $showCreate) {
            MacCreateProfile()
        }
    }
}

struct MacCreateProfile: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 56))
                .foregroundColor(LunaTheme.accent)

            Text("Create Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            TextField("Profile Name", text: $name)
                .textFieldStyle(.plain)
                .padding(10)
                .background(LunaTheme.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(width: 300)
                .foregroundColor(.white)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                createProfile()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Text("Create Profile")
                        .fontWeight(.semibold)
                }
                .frame(width: 300, height: 40)
                .background((name.isEmpty || isLoading) ? LunaTheme.surface : LunaTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty || isLoading)

            Spacer()
        }
        .frame(width: 400, height: 350)
        .background(LunaTheme.background)
    }

    private func createProfile() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await profileManager.createProfile(name: name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
