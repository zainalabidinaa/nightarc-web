import SwiftUI
import MoonlitCore

struct MacSearchView: View {
    let onSelectMedia: (MetaPreview) -> Void
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
                    .foregroundColor(MoonlitTheme.textTertiary)
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
                            .foregroundColor(MoonlitTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(MoonlitTheme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal)
            .padding(.top, MoonlitTheme.navBarTopInset)

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
                ProgressView().tint(MoonlitTheme.accent)
                Spacer()
            } else if !searchRepo.results.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        ForEach(filteredResults) { item in
                            Button {
                                onSelectMedia(item)
                            } label: {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            } else if !query.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(MoonlitTheme.textTertiary)
                    Text("No results for \"\(query)\"")
                        .foregroundColor(MoonlitTheme.textSecondary)
                }
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(MoonlitTheme.textTertiary)
                    Text("Search movies & shows")
                        .font(.title3)
                        .foregroundColor(MoonlitTheme.textSecondary)
                    Text("Find your next watch across all addons")
                        .font(.caption)
                        .foregroundColor(MoonlitTheme.textTertiary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoonlitTheme.background)
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
                .background(isSelected ? MoonlitTheme.accent : MoonlitTheme.surface)
                .foregroundColor(isSelected ? .white : MoonlitTheme.textSecondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
