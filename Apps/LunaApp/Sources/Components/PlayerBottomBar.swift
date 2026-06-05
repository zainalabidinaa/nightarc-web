import SwiftUI
import LunaCore

struct PlayerBottomBar: View {
    @ObservedObject var engine: PlayerEngine

    @State private var showSubtitles = false
    @State private var showAudio = false
    @State private var showSources = false
    @State private var showEpisodes = false

    let hasMultipleSources: Bool
    let hasEpisodes: Bool
    let hasExternalUrl: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button { /* cycle aspect ratio */ } label: {
                Image(systemName: "rectangle.arrowtriangle.2.inward")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                let speeds: [Float] = [1.0, 1.25, 1.5, 2.0]
                let current = engine.playbackSpeed
                if let idx = speeds.firstIndex(of: current) {
                    engine.setPlaybackSpeed(speeds[(idx + 1) % speeds.count])
                }
            } label: {
                Image(systemName: "speedometer")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Spacer()

            Button { showSubtitles = true } label: {
                Image(systemName: "captions.bubble")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Spacer()

            Button { showAudio = true } label: {
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            if hasMultipleSources {
                Spacer()
                Button { showSources = true } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }

            if hasEpisodes {
                Spacer()
                Button { showEpisodes = true } label: {
                    Image(systemName: "rectangle.stack")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }

            if hasExternalUrl {
                Spacer()
                Button {
                    if let urlString = engine.currentLaunch?.sourceUrl,
                       let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showSubtitles) { SubtitleModal(engine: engine) }
        .sheet(isPresented: $showAudio) { AudioTrackModal(engine: engine) }
        .sheet(isPresented: $showSources) { SourcesPanel(engine: engine) }
        .sheet(isPresented: $showEpisodes) { EpisodesPanel(engine: engine) }
    }
}
