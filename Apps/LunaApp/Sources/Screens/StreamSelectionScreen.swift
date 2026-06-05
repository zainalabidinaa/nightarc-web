import SwiftUI
import LunaCore

struct StreamSelectionScreen: View {
    let mediaType: MediaType
    let mediaId: String
    let mediaName: String
    let poster: String?
    let logo: String?

    @StateObject private var streamRepo = StreamRepository.shared
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var selectedStream: StreamItem?
    @State private var showPlayer = false
    @State private var playerLaunch: PlayerLaunch?
    @State private var noUrlAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                if streamRepo.isLoading {
                    ProgressView()
                        .tint(LunaTheme.accent)
                } else if streamRepo.streams.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "play.slash")
                            .font(.title)
                            .foregroundColor(LunaTheme.textTertiary)
                        Text("No streams available")
                            .foregroundColor(LunaTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(groupedByAddon, id: \.key) { addonName, streams in
                            Section(addonName) {
                                ForEach(streams) { stream in
                                    Button {
                                        Task {
                                            await StreamWarmupRepository.shared.warmup(
                                                type: mediaType.rawValue,
                                                id: mediaId,
                                                addons: addonRepo.enabledAddons
                                            )
                                        }
                                        launchStream(stream)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(stream.displayName)
                                                    .foregroundColor(.white)
                                                if let desc = stream.description, !desc.isEmpty {
                                                    Text(desc)
                                                        .font(.caption)
                                                        .foregroundColor(LunaTheme.textSecondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "play.circle.fill")
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
            .sensoryFeedback(.impact(weight: .light), trigger: selectedStream?.id)
            .navigationTitle("Select Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let launch = playerLaunch {
                    PlayerScreen(
                        launch: launch,
                        onDismiss: { showPlayer = false }
                    )
                }
            }
            .alert("No direct URL", isPresented: $noUrlAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This stream doesn't have a direct playback URL (it may be a torrent or external link not supported by the built-in player).")
            }
            .task {
                // Clear stale results from any previous media item
                streamRepo.clearStreams()
                // Ensure addons are loaded (may not be if coming from a deep link)
                if addonRepo.enabledAddons.isEmpty,
                   let profile = ProfileManager.shared.currentProfile {
                    await addonRepo.loadAddons(profileId: profile.id)
                }
                await streamRepo.fetchStreams(
                    type: mediaType.rawValue,
                    id: mediaId,
                    addons: addonRepo.enabledAddons
                )
            }
        }
    }

    private var groupedByAddon: [(key: String, value: [StreamItem])] {
        let grouped = Dictionary(grouping: streamRepo.streams) { $0.addonName ?? "Unknown" }
        return grouped.sorted { $0.key < $1.key }
    }

    private func launchStream(_ stream: StreamItem) {
        selectedStream = stream
        // Prefer direct URL, fall back to externalUrl (e.g. YouTube/streaming service links)
        guard let url = stream.url ?? stream.externalUrl else {
            noUrlAlert = true
            return
        }
        let launch = PlayerLaunch(
            title: mediaName,
            sourceUrl: url,
            sourceHeaders: stream.behaviorHints?.proxyHeaders?.request,
            logo: logo,
            poster: poster,
            streamTitle: stream.displayName,
            providerName: stream.addonName,
            contentType: mediaType,
            videoId: mediaId,
            initialPositionMs: nil
        )
        playerLaunch = launch
        showPlayer = true
    }
}
