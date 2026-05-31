import SwiftUI
import LunaCore
import AVKit

struct PlayerScreen: View {
    let launch: PlayerLaunch
    @StateObject private var engine = PlayerEngine.shared
    @StateObject private var controls = PlayerControlsState()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = engine.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        controls.toggleControls()
                    }
            } else if engine.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Loading...")
                        .foregroundColor(.white)
                }
            }

            if controls.showControls {
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.down")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(launch.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            if let streamTitle = launch.streamTitle {
                                Text(streamTitle)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.trailing)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Slider(value: Binding(
                            get: { engine.currentPosition },
                            set: { engine.seek(to: $0) }
                        ), in: 0...max(engine.duration, 1))
                        .tint(.white)

                        HStack {
                            Text(formatTime(engine.currentPosition))
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                            Text(formatTime(engine.duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)

                        HStack(spacing: 40) {
                            Button { engine.skipBack() } label: {
                                Image(systemName: "gobackward.15")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }

                            Button { engine.togglePlayPause() } label: {
                                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            Button { engine.skipForward() } label: {
                                Image(systemName: "goforward.30")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            engine.launch(launch)
            engine.play()
            controls.showTemporarily()
        }
        .onDisappear {
            engine.pause()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        let sec = s % 60
        if m >= 60 {
            let h = m / 60
            let min = m % 60
            return String(format: "%d:%02d:%02d", h, min, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }
}
