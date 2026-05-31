import SwiftUI
import LunaCore

struct AuthScreen: View {
    @EnvironmentObject var profileManager: ProfileManager

    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LunaTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundColor(LunaTheme.accent)

                Text("Luna")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(isSignUp ? "Create your account" : "Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(LunaTheme.textSecondary)

                Spacer().frame(height: 16)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(LunaTheme.surface)
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .background(LunaTheme.surface)
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    if isSignUp {
                        TextField("Invite Code", text: $inviteCode)
                            .autocapitalization(.allCharacters)
                            .padding()
                            .background(LunaTheme.surface)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                Button(action: performAuth) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LunaTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 32)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    withAnimation { isSignUp.toggle() }
                    errorMessage = nil
                }
                .font(.subheadline)
                .foregroundColor(LunaTheme.accent)

                Spacer()
            }
        }
    }

    private func performAuth() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    guard !inviteCode.isEmpty else {
                        errorMessage = "Invite code is required"
                        isLoading = false
                        return
                    }
                    try await profileManager.signUp(email: email, password: password, inviteCode: inviteCode)
                } else {
                    try await profileManager.signIn(email: email, password: password)
                }
            } catch SupabaseError.signUpRequiresInvite {
                errorMessage = "Invalid or used invite code"
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
