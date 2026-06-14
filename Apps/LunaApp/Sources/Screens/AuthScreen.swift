import SwiftUI
import NightarcCore

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
            NightarcTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("luna-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88, height: 88)
                    .cornerRadius(20)
                    .shadow(color: NightarcTheme.accent.opacity(0.5), radius: 24)

                Text("Nightarc")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(isSignUp ? "Create your account" : "Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(NightarcTheme.textSecondary)

                Spacer().frame(height: 16)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .glassCard(cornerRadius: 12)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .glassCard(cornerRadius: 12)
                        .foregroundColor(.white)

                    if isSignUp {
                        TextField("Invite Code", text: $inviteCode)
                            .autocapitalization(.allCharacters)
                            .padding()
                            .glassCard(cornerRadius: 12)
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
                            LottieLoadingView(size: 22)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .glassProminentButtonStyle(tint: NightarcTheme.accent, cornerRadius: 12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 32)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    withAnimation { isSignUp.toggle() }
                    errorMessage = nil
                }
                .font(.subheadline)
                .foregroundColor(NightarcTheme.accent)

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
