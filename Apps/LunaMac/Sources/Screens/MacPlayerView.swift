import SwiftUI
import LunaCore
import AVKit

struct MacPlayerView: View {
    let launch: PlayerLaunch
    @StateObject private var engine = PlayerEngine.shared
    @StateObject private var controlsState = PlayerControlsState()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = engine.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else if engine.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .foregroundColor(.white)
                }
            }

            if controlsState.showControls || !engine.isPlaying {
                PlayerControls(
                    engine: engine,
                    launch: launch,
                    onDismiss: { dismiss() }
                )
            }
        }
        .onTapGesture {
            controlsState.toggleControls()
        }
        .onAppear {
            engine.launch(launch)
            engine.play()
            controlsState.showTemporarily()
            setupKeyboardShortcuts()
        }
        .onDisappear {
            engine.pause()
        }
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space
                engine.togglePlayPause()
                controlsState.showTemporarily()
                return nil
            case 40: // K
                engine.togglePlayPause()
                controlsState.showTemporarily()
                return nil
            case 46: // M
                engine.toggleMute()
                controlsState.showTemporarily()
                return nil
            case 8: // C
                engine.cycleSubtitle()
                controlsState.showTemporarily()
                return nil
            case 3: // F
                NSApp.keyWindow?.toggleFullScreen(nil)
                return nil
            case 123: // Left arrow
                engine.skipBack15()
                controlsState.showTemporarily()
                return nil
            case 124: // Right arrow
                engine.skipForward15()
                controlsState.showTemporarily()
                return nil
            default:
                break
            }
            return event
        }
    }
}
