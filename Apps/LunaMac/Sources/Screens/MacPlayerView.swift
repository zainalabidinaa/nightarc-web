import SwiftUI
import LunaCore
import KSPlayer

#if os(macOS)
import AppKit
#endif

struct MacPlayerView: View {
    let launch: PlayerLaunch

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var coordinator = KSVideoPlayer.Coordinator()
    @State private var visibility = PlayerControlVisibilityState()
    @State private var hideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var pendingSeekTime: Double = 0
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        if let url = URL(string: launch.sourceUrl) {
            ZStack {
                KSVideoPlayer(
                    coordinator: coordinator,
                    url: url,
                    options: Self.playerOptions(headers: launch.sourceHeaders)
                )
                .onStateChanged { _, state in
                    visibility.setPlayback(isPlaying: state.isPlaying)
                    scheduleAutoHideIfNeeded()
                }
                .ignoresSafeArea()

                PlayerSubtitleOverlay(model: coordinator.subtitleModel, time: TimeInterval(coordinator.timemodel.currentTime))
                    .padding(.horizontal, 48)
                    .padding(.bottom, 112)
                    .allowsHitTesting(false)

                PlayerMouseTrackingView {
                    showControls()
                }
                .ignoresSafeArea()

                VStack {
                    topBar
                    Spacer()
                    NativeLikePlayerControls(
                        title: launch.title,
                        coordinator: coordinator,
                        timeModel: coordinator.timemodel,
                        isSeeking: $isSeeking,
                        pendingSeekTime: $pendingSeekTime,
                        onInteraction: showControls,
                        onDismiss: { dismiss() }
                    )
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                }
                .opacity(visibility.controlsVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.18), value: visibility.controlsVisible)
            }
            .background(Color.black)
            .preferredColorScheme(.dark)
            .toolbar(.hidden, for: .automatic)
            .onAppear {
                showControls()
                startSavingProgress()
            }
            .onDisappear {
                hideTask?.cancel()
                saveTask?.cancel()
                saveProgress(final: true)
                coordinator.resetPlayer()
            }
            .onTapGesture {
                if visibility.controlsVisible {
                    hideControlsIfAllowed()
                } else {
                    showControls()
                }
            }
            .onKeyPress(.space) {
                togglePlayback()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                seekBy(-5)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                seekBy(5)
                return .handled
            }
            .onKeyPress(.upArrow) {
                adjustVolume(by: 0.05)
                return .handled
            }
            .onKeyPress(.downArrow) {
                adjustVolume(by: -0.05)
                return .handled
            }
            .onKeyPress(KeyEquivalent("f")) {
                coordinator.playerLayer?.player.view?.window?.toggleFullScreen(nil)
                return .handled
            }
            .onKeyPress(KeyEquivalent("m")) {
                coordinator.isMuted.toggle()
                return .handled
            }
            .onKeyPress(KeyEquivalent("s")) {
                let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]
                if let idx = rates.firstIndex(of: coordinator.playbackRate), idx + 1 < rates.count {
                    coordinator.playbackRate = rates[idx + 1]
                } else {
                    coordinator.playbackRate = rates[0]
                }
                return .handled
            }
        } else {
            Color.black.ignoresSafeArea()
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "play.slash")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                        Text("Invalid stream URL")
                            .foregroundColor(.white)
                        Button("Dismiss") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.2))
                    }
                }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close player")

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    private func showControls() {
        visibility.registerInteraction()
        scheduleAutoHideIfNeeded()
    }

    private func scheduleAutoHideIfNeeded() {
        hideTask?.cancel()
        guard visibility.shouldScheduleAutoHide else { return }

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            hideControlsIfAllowed()
        }
    }

    private func hideControlsIfAllowed() {
        guard !isSeeking else { return }
        visibility.hideAfterInactivityIfAllowed()
    }

    private func togglePlayback() {
        showControls()
        if coordinator.state.isPlaying {
            coordinator.playerLayer?.pause()
        } else {
            coordinator.playerLayer?.play()
        }
    }

    private func seekBy(_ interval: Int) {
        showControls()
        coordinator.skip(interval: interval)
    }

    private func adjustVolume(by delta: Float) {
        showControls()
        var vol = coordinator.playbackVolume + delta
        vol = min(max(vol, 0), 1)
        coordinator.playbackVolume = vol
        coordinator.isMuted = vol == 0
    }

    private func startSavingProgress() {
        // Seek to resume position if available
        if let seekMs = launch.initialPositionMs, seekMs > 0 {
            coordinator.seek(time: TimeInterval(seekMs / 1000))
        }

        saveTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                saveProgress(final: false)
            }
        }
    }

    private func saveProgress(final: Bool) {
        guard let profile = profileManager.currentProfile else { return }
        let pos = Double(coordinator.timemodel.currentTime)
        let dur = Double(coordinator.timemodel.totalTime)
        guard dur > 0 else { return }

        Task {
            await WatchProgressRepository.shared.updateProgress(
                profileId: profile.id,
                mediaId: launch.videoId,
                mediaType: launch.contentType.rawValue,
                positionSeconds: pos,
                durationSeconds: dur,
                completed: final && pos > 0 && dur > 0 && pos / dur > 0.9,
                name: launch.title,
                poster: launch.poster,
                parentMetaId: launch.parentMetaId,
                season: launch.seasonNumber,
                episode: launch.episodeNumber
            )
        }
    }

    private static func playerOptions(headers: [String: String]?) -> KSOptions {
        let options = KSOptions()

        for (key, value) in headers ?? [:] {
            options.appendHeader([key: value])
        }

        return options
    }
}

private struct NativeLikePlayerControls: View {
    let title: String
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    @ObservedObject var timeModel: ControllerTimeModel
    @Binding var isSeeking: Bool
    @Binding var pendingSeekTime: Double
    let onInteraction: () -> Void
    let onDismiss: () -> Void

    @State private var volumeHover = false

    private var currentTime: Double {
        isSeeking ? pendingSeekTime : Double(timeModel.currentTime)
    }

    private var totalTime: Double {
        max(Double(timeModel.totalTime), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Timeline
            PlayerScrubber(
                value: Binding(get: { currentTime }, set: { pendingSeekTime = $0 }),
                range: 0 ... totalTime,
                isEditing: $isSeeking,
                onInteraction: onInteraction,
                onCommit: { coordinator.seek(time: pendingSeekTime) }
            )
            .padding(.horizontal, 4)

            // Controls row
            HStack(spacing: 0) {
                // Time
                Text(formatTime(currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, alignment: .leading)

                Spacer().frame(width: 8)

                // Skip back
                PlayerControlButton(systemName: "gobackward.10", size: 20) {
                    onInteraction()
                    coordinator.skip(interval: -10)
                }

                Spacer().frame(width: 6)

                // Play/Pause - larger
                Button {
                    onInteraction()
                    if coordinator.state.isPlaying {
                        coordinator.playerLayer?.pause()
                    } else {
                        coordinator.playerLayer?.play()
                    }
                } label: {
                    Image(systemName: coordinator.state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .medium))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Spacer().frame(width: 6)

                // Skip forward
                PlayerControlButton(systemName: "goforward.10", size: 20) {
                    onInteraction()
                    coordinator.skip(interval: 10)
                }

                Spacer().frame(width: 8)

                // Time remaining
                Text("-\(formatTime(totalTime - currentTime))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 44, alignment: .trailing)

                Spacer(minLength: 20)

                // Right-side controls
                HStack(spacing: 10) {
                    // Volume
                    HStack(spacing: 4) {
                        Button {
                            onInteraction()
                            coordinator.isMuted.toggle()
                        } label: {
                            Image(systemName: coordinator.isMuted || coordinator.playbackVolume == 0
                                  ? "speaker.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.85))

                        if volumeHover {
                            Slider(value: Binding(
                                get: { Double(coordinator.playbackVolume) },
                                set: {
                                    coordinator.playbackVolume = Float($0)
                                    coordinator.isMuted = $0 == 0
                                    onInteraction()
                                }
                            ), in: 0 ... 1)
                            .tint(.white.opacity(0.85))
                            .frame(width: 60)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .onHover { volumeHover = $0 }

                    // Subtitles
                    SubtitleMenu(coordinator: coordinator, onInteraction: onInteraction)

                    // Audio
                    AudioMenu(coordinator: coordinator, onInteraction: onInteraction)

                    // Speed
                    SpeedMenu(coordinator: coordinator, onInteraction: onInteraction)

                    // Fullscreen
                    PlayerControlButton(systemName: "arrow.up.backward.and.arrow.down.forward", size: 15) {
                        onInteraction()
                        coordinator.playerLayer?.player.view?.window?.toggleFullScreen(nil)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 16, interactive: true)
        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 12)
        .onHover { hovering in
            if hovering { onInteraction() }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let clamped = max(Int(seconds), 0)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

private struct PlayerScrubber: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    @Binding var isEditing: Bool
    let onInteraction: () -> Void
    let onCommit: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)

                // Progress
                if range.upperBound > 0 {
                    Capsule()
                        .fill(.white)
                        .frame(width: max(0, min(width, width * CGFloat(value / range.upperBound))), height: 4)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        isEditing = true
                        onInteraction()
                        let ratio = g.location.x / max(width, 1)
                        value = max(range.lowerBound, min(range.upperBound, Double(ratio) * range.upperBound))
                    }
                    .onEnded { _ in
                        isEditing = false
                        onCommit()
                    }
            )
        }
        .frame(height: 12)
        .contentShape(Rectangle())
    }
}

private struct PlayerControlButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
    }
}

private struct SubtitleMenu: View {
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    let onInteraction: () -> Void

    var body: some View {
        Menu {
            Button {
                onInteraction()
                coordinator.subtitleModel.selectedSubtitleInfo = nil
            } label: {
                Label("Off", systemImage: coordinator.subtitleModel.selectedSubtitleInfo == nil ? "checkmark" : "")
            }

            ForEach(coordinator.subtitleModel.subtitleInfos, id: \.subtitleID) { subtitle in
                Button {
                    onInteraction()
                    subtitle.isEnabled = true
                    coordinator.subtitleModel.selectedSubtitleInfo = subtitle
                } label: {
                    Label(subtitle.name.isEmpty ? subtitle.subtitleID : subtitle.name, systemImage: coordinator.subtitleModel.selectedSubtitleInfo?.subtitleID == subtitle.subtitleID ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "captions.bubble.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 30, height: 30)
        }
        .menuStyle(.borderlessButton)
        .foregroundStyle(.white.opacity(0.92))
        .accessibilityLabel("Subtitles")
    }
}

private struct AudioMenu: View {
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    let onInteraction: () -> Void

    private var audioTracks: [MediaPlayerTrack] {
        coordinator.playerLayer?.player.tracks(mediaType: .audio) ?? []
    }

    var body: some View {
        Group {
            if audioTracks.isEmpty {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 30, height: 30)
            } else {
                Menu {
                    ForEach(audioTracks, id: \.trackID) { track in
                        Button {
                            onInteraction()
                            coordinator.playerLayer?.player.select(track: track)
                        } label: {
                            Label(track.name, systemImage: track.isEnabled ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 30, height: 30)
                }
                .menuStyle(.borderlessButton)
                .foregroundStyle(.white.opacity(0.92))
                .accessibilityLabel("Audio track")
            }
        }
    }
}

private struct SpeedMenu: View {
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    let onInteraction: () -> Void
    private let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button {
                    onInteraction()
                    coordinator.playbackRate = rate
                } label: {
                    Label(String(format: "%.2g×", rate), systemImage: abs(coordinator.playbackRate - rate) < 0.01 ? "checkmark" : "")
                }
            }
        } label: {
            Text(String(format: "%.1f×", coordinator.playbackRate))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .frame(width: 36, height: 24)
        }
        .menuStyle(.borderlessButton)
        .foregroundStyle(.white.opacity(0.85))
    }
}

private struct PlayerSubtitleOverlay: View {
    @ObservedObject var model: SubtitleModel
    let time: TimeInterval

    var body: some View {
        VStack {
            Spacer()
            ForEach(model.parts) { part in
                if let text = part.text {
                    Text(AttributedString(text))
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.95), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}

#if os(macOS)
private struct PlayerMouseTrackingView: NSViewRepresentable {
    let onMouseMoved: () -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onMouseMoved = onMouseMoved
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onMouseMoved = onMouseMoved
    }

    final class TrackingView: NSView {
        var onMouseMoved: (() -> Void)?
        private var trackingAreaRef: NSTrackingArea?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingAreaRef {
                removeTrackingArea(trackingAreaRef)
            }

            let area = NSTrackingArea(
                rect: bounds,
                options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            trackingAreaRef = area
            addTrackingArea(area)
        }

        override func mouseMoved(with event: NSEvent) {
            onMouseMoved?()
            super.mouseMoved(with: event)
        }

        override func mouseEntered(with event: NSEvent) {
            onMouseMoved?()
            super.mouseEntered(with: event)
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }
    }
}
#else
private struct PlayerMouseTrackingView: View {
    let onMouseMoved: () -> Void

    var body: some View {
        Color.clear.onHover { hovering in
            if hovering { onMouseMoved() }
        }
    }
}
#endif
