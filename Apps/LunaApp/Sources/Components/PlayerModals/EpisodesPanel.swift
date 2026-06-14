import SwiftUI
import NightarcCore

struct EpisodesPanel: View {
    @ObservedObject var engine: PlayerEngine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NightarcTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let launch = engine.currentLaunch {
                        Text(launch.title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)

                        if let season = launch.seasonNumber, let episode = launch.episodeNumber {
                            Text("Season \(season) • Episode \(episode)")
                                .font(.subheadline)
                                .foregroundColor(NightarcTheme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Episodes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
