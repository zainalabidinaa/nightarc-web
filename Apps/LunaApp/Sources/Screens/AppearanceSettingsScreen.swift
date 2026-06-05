import SwiftUI
import LunaCore

struct AppearanceSettingsScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: AppTheme

    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.selectedTheme)
    }

    var body: some View {
        ZStack {
            LunaTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Choose an accent color that suits your style.")
                        .font(.subheadline)
                        .foregroundColor(LunaTheme.textSecondary)
                        .padding(.horizontal, 16)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                        spacing: 16
                    ) {
                        ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                            ThemeChip(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                action: { selectedTheme = theme }
                            )
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)

                    amoledToggleSection
                }
                .padding(.top, 16)
            }
            .sensoryFeedback(.selection, trigger: selectedTheme)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedTheme) { _, newTheme in
            themeManager.setTheme(newTheme)
        }
    }

    private var amoledToggleSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMOLED Black")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Use pure black background on AMOLED displays")
                        .font(.caption)
                        .foregroundColor(LunaTheme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { themeManager.isAmoledEnabled },
                    set: { themeManager.setAmoled($0) }
                ))
                .labelsHidden()
                .tint(LunaTheme.accent)
            }
            .padding(16)
        }
        .glassCard(cornerRadius: 14)
        .padding(.horizontal, 16)
    }
}
