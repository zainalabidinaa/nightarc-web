import SwiftUI
import LunaCore

struct MacSearchView: View {
    @StateObject private var searchRepo = SearchRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var query = ""
    @State private var selectedFilter: String? = nil

    var filteredResults: [MetaPreview] {
        guard let filter = selectedFilter else { return searchRepo.results }
        return searchRepo.results.filter { $0.type.rawValue == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(LunaTheme.textTertiary)
                TextField("Search movies & shows...", text: $query)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .onSubmit {
                        Task { await searchRepo.search(query: query, addons: addonRepo.enabledAddons) }
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        selectedFilter = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(LunaTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(LunaTheme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal)
            .padding(.top, 56)

            if !searchRepo.results.isEmpty {
                HStack(spacing: 8) {
                    FilterPill(label: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    FilterPill(label: "Movies", isSelected: selectedFilter == "movie") {
                        selectedFilter = "movie"
                    }
                    FilterPill(label: "TV Shows", isSelected: selectedFilter == "series") {
                        selectedFilter = "series"
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }

            if searchRepo.isLoading {
                Spacer()
                ProgressView().tint(LunaTheme.accent)
                Spacer()
            } else if !searchRepo.results.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        ForEach(filteredResults) { item in
                            MediaCard(item: item)
                        }
                    }
                    .padding()
                }
            } else if !query.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(LunaTheme.textTertiary)
                    Text("No results for \"\(query)\"")
                        .foregroundColor(LunaTheme.textSecondary)
                }
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(LunaTheme.textTertiary)
                    Text("Search movies & shows")
                        .font(.title3)
                        .foregroundColor(LunaTheme.textSecondary)
                    Text("Find your next watch across all addons")
                        .font(.caption)
                        .foregroundColor(LunaTheme.textTertiary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LunaTheme.background)
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? LunaTheme.accent : LunaTheme.surface)
                .foregroundColor(isSelected ? .white : LunaTheme.textSecondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
