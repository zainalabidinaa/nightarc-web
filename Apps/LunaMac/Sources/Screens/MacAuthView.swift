import SwiftUI
import LunaCore

struct MacAuthView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(LunaTheme.accent)

            Text("Luna")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("Sign in to your media hub")
                .font(.subheadline)
                .foregroundColor(LunaTheme.textTertiary)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(LunaTheme.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(width: 320)
                    .foregroundColor(.white)

                SecureField("Password", text: $password)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(LunaTheme.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(width: 320)
                    .foregroundColor(.white)

                if isSignUp {
                    TextField("Invite Code", text: $inviteCode)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(LunaTheme.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 320)
                        .foregroundColor(.white)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: performAuth) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .fontWeight(.semibold)
                }
                .frame(width: 320, height: 40)
                .background(LunaTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1)

            Button(isSignUp ? "Have an account? Sign In" : "New to Luna? Create Account") {
                isSignUp.toggle()
                errorMessage = nil
            }
            .buttonStyle(.plain)
            .foregroundColor(LunaTheme.textTertiary)
            .font(.subheadline)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
    }

    private func performAuth() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if isSignUp {
                    try await profileManager.signUp(
                        email: email, password: password, inviteCode: inviteCode
                    )
                } else {
                    try await profileManager.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
