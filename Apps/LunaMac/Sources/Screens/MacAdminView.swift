import SwiftUI
import LunaCore

struct MacAdminView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var maxUses = 1
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Admin Panel")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, LunaTheme.navBarTopInset)

                // ── Generate invite ──────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Generate Invite Code")

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Max uses")
                                .font(.subheadline)
                                .foregroundColor(LunaTheme.textSecondary)
                            Spacer()
                            Stepper(value: $maxUses, in: 1...100) {
                                Text("\(maxUses)")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 28)
                            }
                            .fixedSize()
                        }

                        Button {
                            Task {
                                isGenerating = true
                                _ = try? await adminService.generateInviteCode(maxUses: maxUses)
                                isGenerating = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isGenerating {
                                    ProgressView().controlSize(.small).tint(.white)
                                }
                                Text(isGenerating ? "Generating…" : "Generate Code")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LunaTheme.accent)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isGenerating)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LunaTheme.surface)
                    .cornerRadius(12)
                }

                // ── Invite codes ─────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Invite Codes (\(adminService.inviteCodes.count))")

                    if adminService.inviteCodes.isEmpty {
                        Text("No invite codes yet. Generate one above.")
                            .font(.caption)
                            .foregroundColor(LunaTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(LunaTheme.surface)
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(adminService.inviteCodes) { code in
                                let active = code.isActive && !code.isUsed
                                HStack(spacing: 12) {
                                    Text(code.code)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(LunaTheme.accent)
                                    Spacer()
                                    Circle()
                                        .fill(active ? Color.green : Color.red)
                                        .frame(width: 7, height: 7)
                                    Text(active ? "Active" : (code.isUsed ? "Used" : "Revoked"))
                                        .font(.caption)
                                        .foregroundColor(LunaTheme.textTertiary)
                                    if active {
                                        Button("Revoke") {
                                            Task { try? await adminService.revokeInviteCode(code.code) }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(LunaTheme.surface)
                                if code.id != adminService.inviteCodes.last?.id {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .cornerRadius(12)
                    }
                }

                Spacer(minLength: 32)
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
        .task { await adminService.loadInviteCodes() }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(LunaTheme.textTertiary)
            .tracking(1)
            .textCase(.uppercase)
            .padding(.bottom, 8)
    }
}
