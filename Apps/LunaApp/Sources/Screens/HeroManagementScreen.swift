import SwiftUI
import NightarcCore

struct HeroManagementScreen: View {
    @StateObject private var catalogRepo = CatalogRepository.shared
    @StateObject private var heroStore = HeroPreferenceStore.shared

    private let defaultHeroTitles: Set<String> = [
        "Popular Movies", "Popular TV Shows",
        "Trending Movies", "Trending TV Shows"
    ]

    // Rows that are candidates for the hero (have items)
    private var allRows: [CatalogRow] {
        catalogRepo.catalogRows.filter { !$0.items.isEmpty }
    }

    // The display order for the "Catalog Order" section:
    // stored order first, then any default titles not yet in order
    private var orderedEnabledRows: [CatalogRow] {
        let enabledTitles: [String]
        if heroStore.rowOrder.isEmpty {
            // No saved order — use default set in natural row order
            enabledTitles = allRows
                .filter { defaultHeroTitles.contains($0.title) }
                .map(\.title)
        } else {
            enabledTitles = heroStore.rowOrder.filter { heroStore.isEnabled(rowTitle: $0) }
        }
        return enabledTitles.compactMap { title in
            allRows.first { $0.title == title }
        }
    }

    private func isEnabled(_ row: CatalogRow) -> Bool {
        if heroStore.rowOrder.isEmpty {
            return defaultHeroTitles.contains(row.title)
        }
        return heroStore.isEnabled(rowTitle: row.title)
    }

    var body: some View {
        List {
            Section {
                Text("Choose which catalog rows feed into the hero carousel and drag to set priority order.")
                    .font(.caption)
                    .foregroundColor(NightarcTheme.textSecondary)
                    .listRowBackground(Color.clear)
            }

            // ── CATALOG ORDER (enabled rows, draggable) ──────────────
            if !orderedEnabledRows.isEmpty {
                Section("Catalog Order") {
                    ForEach(orderedEnabledRows) { row in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .foregroundColor(.white)
                                    .font(.body)
                                if let addonName = row.addonName {
                                    Text(addonName)
                                        .font(.caption2)
                                        .foregroundColor(NightarcTheme.textTertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.body)
                                .foregroundColor(NightarcTheme.textTertiary)
                        }
                        .listRowBackground(NightarcTheme.surfaceElevated.opacity(0.5))
                    }
                    .onMove { source, destination in
                        // Build current order, apply move, save
                        var current = orderedEnabledRows.map(\.title)
                        current.move(fromOffsets: source, toOffset: destination)
                        // Merge: put moved enabled rows first, preserve disabled at end
                        let disabled = heroStore.rowOrder.filter { !heroStore.isEnabled(rowTitle: $0) }
                        heroStore.setOrder(current + disabled)
                    }
                }
            }

            // ── ENABLED FOR HERO (all available rows, with toggle) ───
            Section("Available Catalogs") {
                if allRows.isEmpty {
                    Text("No catalogs loaded yet. Return to Home to load content first.")
                        .font(.caption)
                        .foregroundColor(NightarcTheme.textTertiary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(allRows) { row in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .foregroundColor(.white)
                                if let addonName = row.addonName {
                                    Text(addonName)
                                        .font(.caption2)
                                        .foregroundColor(NightarcTheme.textTertiary)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { isEnabled(row) },
                                set: { enabled in
                                    if heroStore.rowOrder.isEmpty {
                                        // First interaction — initialize order from defaults
                                        let defaultOrder = allRows
                                            .filter { defaultHeroTitles.contains($0.title) }
                                            .map(\.title)
                                        heroStore.setOrder(defaultOrder)
                                    }
                                    heroStore.setEnabled(enabled, for: row.title)
                                }
                            ))
                            .labelsHidden()
                            .tint(NightarcTheme.accent)
                        }
                        .listRowBackground(NightarcTheme.surfaceElevated.opacity(0.5))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(NightarcTheme.background)
        .navigationTitle("Hero Management")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.editMode, .constant(.active))
    }
}
