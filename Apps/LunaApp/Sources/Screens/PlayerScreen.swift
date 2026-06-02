import SwiftUI
import AVKit
import LunaCore

struct PlayerScreen: View {
    let streamURL: URL
    let title: String
    let onDismiss: () -> Void

    @State private var player = AVPlayer()
    @State private var showControls = true
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var isPlaying = false
    @State private var playbackSpeed: Float = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CustomPlayerView(player: player)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                }

            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button { onDismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                        }
                        .glassCircle(clear: true)

                        Spacer()

                        VStack(spacing: 2) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(timeRemaining)
                                .font(.caption)
                                .foregroundColor(LunaTheme.textSecondary)
                        }

                        Spacer()

                        Button { /* ellipsis menu */ } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                        }
                        .glassCircle(clear: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 56)

                    Spacer()

                    // Center play/pause
                    Button {
                        togglePlayPause()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                    }
                    .glassCircle(clear: true)
                    .contentTransition(.symbolEffect(.replace))

                    Spacer()

                    // Bottom transport
                    VStack(spacing: 12) {
                        // Progress
                        VStack(spacing: 6) {
                            if #available(iOS 26, *) {
                                Slider(
                                    value: Binding(
                                        get: { currentTime },
                                        set: { seek(to: $0) }
                                    ),
                                    in: 0...max(duration, 1)
                                )
                                .labelsHidden()
                                .tint(.white)
                                .controlSize(.large)
                            } else {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.20))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(
                                                width: duration > 0
                                                    ? geo.size.width * (currentTime / duration)
                                                    : 0,
                                                height: 4
                                            )
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 14, height: 14)
                                            .offset(x: duration > 0
                                                ? geo.size.width * (currentTime / duration) - 7
                                                : -7)
                                    }
                                }
                                .frame(height: 32)
                            }

                            HStack {
                                Text(formatTime(currentTime))
                                Spacer()
                                Text("-\(formatTime(max(duration - currentTime, 0)))")
                            }
                            .font(.caption)
                            .foregroundColor(LunaTheme.textSecondary)
                        }

                        // Transport pill
                        HStack(spacing: 0) {
                            Button {
                                playbackSpeed = max(0.5, playbackSpeed - 0.25)
                                player.rate = playbackSpeed
                            } label: {
                                Text("\(playbackSpeed, specifier: "%.2f")x")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 36)
                            }
                            .glassCapsule(interactive: true, clear: true)

                            Spacer()

                            HStack(spacing: 24) {
                                Button {
                                    seek(by: -15)
                                } label: {
                                    Image(systemName: "gobackward.15")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }

                                Button {
                                    togglePlayPause()
                                } label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                }
                                .glassCircle(clear: true)
                                .contentTransition(.symbolEffect(.replace))

                                Button {
                                    seek(by: 30)
                                } label: {
                                    Image(systemName: "goforward.30")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                            }

                            Spacer()

                            Button {
                                player.isMuted.toggle()
                            } label: {
                                Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 36)
                            }
                            .glassCapsule(interactive: true, clear: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 18)
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
            player.play()
            isPlaying = true
            setupTimeObserver()
        }
        .onDisappear {
            player.pause()
        }
    }

    private var timeRemaining: String {
        let remaining = max(duration - currentTime, 0)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds)) remaining"
        }
        return "\(minutes):\(String(format: "%02d", seconds)) remaining"
    }

    private func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func seek(to time: TimeInterval) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    private func seek(by seconds: Double) {
        let newTime = max(0, min(currentTime + seconds, duration))
        seek(to: newTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
            if let item = player.currentItem {
                duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
            }
            isPlaying = player.rate > 0
        }
    }
}

// MARK: - AVPlayer UIKit Wrapper

struct CustomPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
