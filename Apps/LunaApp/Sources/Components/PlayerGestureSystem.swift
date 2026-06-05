import SwiftUI
import AVFoundation
import MediaPlayer
import LunaCore

enum PlayerGestureMode {
    case none
    case brightness
    case volume
    case horizontalSeek
}

struct PlayerGestureState {
    var mode: PlayerGestureMode = .none
    var initialBrightness: CGFloat = 0
    var initialVolume: Float = 0
    var seekBase: Double = 0
    var value: Double = 0
}

struct PlayerGestureViewModifier: ViewModifier {
    @ObservedObject var engine: PlayerEngine
    @Binding var state: PlayerGestureState
    @Binding var showControls: Bool
    @Binding var isLocked: Bool

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !isLocked else { return }
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height

                if state.mode == .none {
                    let absDx = abs(value.translation.width)
                    let absDy = abs(value.translation.height)
                    let startX = value.startLocation.x / screenWidth

                    if absDx > absDy * 1.5 {
                        state.mode = .horizontalSeek
                        state.seekBase = engine.currentPosition
                    } else if startX < 0.4 {
                        state.mode = .brightness
                        state.initialBrightness = UIScreen.main.brightness
                    } else if startX > 0.6 {
                        state.mode = .volume
                        state.initialVolume = AVAudioSession.sharedInstance().outputVolume
                    }
                }

                switch state.mode {
                case .horizontalSeek:
                    let sensitivity: Double
                    if engine.duration >= 3600 {
                        sensitivity = 120
                    } else if engine.duration >= 1800 {
                        sensitivity = 90
                    } else {
                        sensitivity = 60
                    }
                    let delta = (value.translation.width / screenWidth) * sensitivity
                    state.value = min(max(state.seekBase + delta, 0), engine.duration)
                    engine.seek(to: state.value)
                case .brightness:
                    let delta = (-value.translation.height / screenHeight)
                    state.value = Double(min(max(state.initialBrightness + delta, 0), 1))
                    UIScreen.main.brightness = state.value
                case .volume:
                    let delta = Float(-value.translation.height / screenHeight)
                    state.value = Double(min(max(state.initialVolume + delta, 0), 1))
                    setVolume(Float(state.value))
                case .none:
                    break
                }
            }
            .onEnded { _ in
                state.mode = .none
            }
    }

    private func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView(frame: .zero)
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.value = volume
        }
    }
}

extension View {
    func playerGestures(
        engine: PlayerEngine,
        state: Binding<PlayerGestureState>,
        showControls: Binding<Bool>,
        isLocked: Binding<Bool>
    ) -> some View {
        modifier(PlayerGestureViewModifier(
            engine: engine,
            state: state,
            showControls: showControls,
            isLocked: isLocked
        ))
    }
}
