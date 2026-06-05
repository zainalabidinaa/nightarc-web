import SwiftUI
import LunaCore

struct SourcesPanel: View {
    @ObservedObject var engine: PlayerEngine
    @StateObject private var streamRepo = StreamRepository.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                if streamRepo.isLoading {
                    ProgressView().tint(LunaTheme.accent)
                } else if streamRepo.streams.isEmpty {
                    Text("No streams loaded")
                        .foregroundColor(LunaTheme.textSecondary)
                } else {
                    List {
                        ForEach(groupedByAddon, id: \.key) { addonName, streams in
                            Section(addonName) {
                                ForEach(streams) { stream in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(stream.displayName)
                                                .foregroundColor(.white)
                                            if let desc = stream.description {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundColor(LunaTheme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        if stream.url == engine.currentLaunch?.sourceUrl {
                                            Text("Playing")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(LunaTheme.accent)
                                        }
                                    }
                                    .listRowBackground(LunaTheme.surface)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var groupedByAddon: [(key: String, value: [StreamItem])] {
        Dictionary(grouping: streamRepo.streams) { $0.addonName ?? "Unknown" }
            .sorted { $0.key < $1.key }
    }
}
