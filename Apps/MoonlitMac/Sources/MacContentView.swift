import SwiftUI
import MoonlitCore

struct MacContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager

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

