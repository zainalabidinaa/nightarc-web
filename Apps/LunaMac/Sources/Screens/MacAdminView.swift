import SwiftUI
import LunaCore

struct MacAdminView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var maxUses = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Admin Panel")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 56)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Max uses:")
                            .font(.subheadline)
                            .foregroundColor(LunaTheme.textSecondary)
                        Stepper("\(maxUses)", value: $maxUses, in: 1...100)
                            .labelsHidden()
                    }

                    Button("Generate Invite Code") {
                        Task { try await adminService.generateInviteCode(maxUses: maxUses) }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LunaTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(LunaTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Invite Codes (\(adminService.inviteCodes.count))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(LunaTheme.textTertiary)
                        .tracking(1)
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 6)

                    VStack(spacing: 0) {
                        ForEach(adminService.inviteCodes) { code in
                            HStack {
                                Text(code.code)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(LunaTheme.accent)
                                Spacer()
                                Circle()
                                    .fill(code.isActive && !code.isUsed ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(code.isActive && !code.isUsed ? "Active" : "Revoked")
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textTertiary)
                                if code.isActive && !code.isUsed {
                                    Button("Revoke") {
                                        Task { try await adminService.revokeInviteCode(code.code) }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(LunaTheme.surface)
                            if code.id != adminService.inviteCodes.last?.id {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer().frame(height: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
        .task { await adminService.loadInviteCodes() }
    }
}
