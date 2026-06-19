import SwiftUI
import MoonlitCore
import KSPlayer

#if os(macOS)
import AppKit
#endif

struct MacPlayerView: View {
    let launch: PlayerLaunch

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var coordinator = KSVideoPlayer.Coordinator()
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var visibility = PlayerControlVisibilityState()
    @State private var hideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var pendingSeekTime: Double = 0
    @State private var saveTask: Task<Void, Never>?
    @State private var subtitleChoices: [SubtitleItem] = []
    @State private var selectedExternalSubtitle: SubtitleItem?
    @State private var externalSubtitleCues: [MacSubtitleCue] = []
    @State private var isLoadingSubtitles = false
    @State private var subtitleError: String?
    @State private var showStartupLoading = true

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

                if let selectedExternalSubtitle {
                    ExternalSubtitleOverlay(
                        cues: externalSubtitleCues,
                        time: TimeInterval(coordinator.timemodel.currentTime),
                        isLoading: isLoadingSubtitles,
                        title: selectedExternalSubtitle.displayTitle
                    )
                    .padding(.horizontal, 56)
                    .padding(.bottom, 150)
                    .allowsHitTesting(false)
                } else {
                    PlayerSubtitleOverlay(model: coordinator.subtitleModel, time: TimeInterval(coordinator.timemodel.currentTime))
                        .padding(.horizontal, 56)
                        .padding(.bottom, 150)
                        .allowsHitTesting(false)
                }

                PlayerMouseTrackingView {
                    showControls()
                }
                .ignoresSafeArea()

                if showStartupLoading {
                    PlayerStartupLoadingOverlay(launch: launch)
                        .transition(.opacity)
                }

                VStack {
                    topBar
                    Spacer()
                    NativeLikePlayerControls(
                        title: launch.title,
                        coordinator: coordinator,
                        timeModel: coordinator.timemodel,
                        isSeeking: $isSeeking,
                        pendingSeekTime: $pendingSeekTime,
                        subtitleChoices: subtitleChoices,
                        selectedExternalSubtitle: $selectedExternalSubtitle,
                        isLoadingSubtitles: isLoadingSubtitles,
                        subtitleError: subtitleError,
                        onInteraction: showControls,
                        onSelectExternalSubtitle: { subtitle in
                            Task { await selectExternalSubtitle(subtitle) }
                        },
                        onDisableExternalSubtitles: {
                            selectedExternalSubtitle = nil
                            externalSubtitleCues = []
                            subtitleError = nil
                        },
                        onDismiss: { dismiss() }
                    )
                    .padding(.horizontal, 34)
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
                Task {
                    await loadAvailableSubtitles()
                    try? await Task.sleep(for: .seconds(1.25))
                    showStartupLoading = false
                }
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
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .macDarkGlassCapsule(interactive: true)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel("Close player")

            Spacer()
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
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
                poster: launch.episodeThumbnail ?? launch.poster,
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

    private func loadAvailableSubtitles() async {
        let embedded = launch.subtitles ?? []
        let addonSubtitles: [SubtitleItem]
        do {
            addonSubtitles = try await SubtitleService.shared.fetchSubtitlesFromAddons(
                type: launch.parentMetaType ?? launch.contentType.rawValue,
                id: launch.videoId,
                addons: addonRepo.managedAddons.map(\.manifest)
            )
        } catch {
            addonSubtitles = []
        }

        var seen = Set<String>()
        subtitleChoices = (embedded + addonSubtitles).filter { subtitle in
            seen.insert(subtitle.url).inserted
        }
    }

    private func selectExternalSubtitle(_ subtitle: SubtitleItem) async {
        selectedExternalSubtitle = subtitle
        coordinator.subtitleModel.selectedSubtitleInfo = nil
        isLoadingSubtitles = true
        subtitleError = nil
        externalSubtitleCues = []

        guard let url = URL(string: subtitle.url) else {
            subtitleError = "Invalid subtitle URL"
            isLoadingSubtitles = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                subtitleError = "Unable to decode subtitles"
                isLoadingSubtitles = false
                return
            }
            externalSubtitleCues = MacSubtitleCue.parse(content)
        } catch {
            subtitleError = "Unable to load subtitles"
        }
        isLoadingSubtitles = false
    }
}

private struct NativeLikePlayerControls: View {
    let title: String
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    @ObservedObject var timeModel: ControllerTimeModel
    @Binding var isSeeking: Bool
    @Binding var pendingSeekTime: Double
    let subtitleChoices: [SubtitleItem]
    @Binding var selectedExternalSubtitle: SubtitleItem?
    let isLoadingSubtitles: Bool
    let subtitleError: String?
    let onInteraction: () -> Void
    let onSelectExternalSubtitle: (SubtitleItem) -> Void
    let onDisableExternalSubtitles: () -> Void
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
            .padding(.horizontal, 6)

            // Controls row
            HStack(spacing: 0) {
                // Time
                Text(formatTime(currentTime))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 58, alignment: .leading)

                Spacer().frame(width: 12)

                // Skip back
                PlayerControlButton(systemName: "gobackward.10", size: 21, frameSize: 46) {
                    onInteraction()
                    coordinator.skip(interval: -10)
                }

                Spacer().frame(width: 10)

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
                        .font(.system(size: 25, weight: .semibold))
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                        .macDarkGlassCapsule(interactive: true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Spacer().frame(width: 10)

                // Skip forward
                PlayerControlButton(systemName: "goforward.10", size: 21, frameSize: 46) {
                    onInteraction()
                    coordinator.skip(interval: 10)
                }

                Spacer().frame(width: 12)

                // Time remaining
                Text("-\(formatTime(totalTime - currentTime))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 58, alignment: .trailing)

                Spacer(minLength: 20)

                // Right-side controls
                HStack(spacing: 9) {
                    // Volume
                    HStack(spacing: 7) {
                        Button {
                            onInteraction()
                            coordinator.isMuted.toggle()
                        } label: {
                            Image(systemName: coordinator.isMuted || coordinator.playbackVolume == 0
                                  ? "speaker.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 40, height: 40)
                                .macDarkGlassCapsule(interactive: true)
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
                            .frame(width: 78)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .onHover { volumeHover = $0 }

                    // Subtitles
                    SubtitleMenu(
                        coordinator: coordinator,
                        externalSubtitles: subtitleChoices,
                        selectedExternalSubtitle: $selectedExternalSubtitle,
                        isLoadingExternal: isLoadingSubtitles,
                        error: subtitleError,
                        onInteraction: onInteraction,
                        onSelectExternalSubtitle: onSelectExternalSubtitle,
                        onDisableExternalSubtitles: onDisableExternalSubtitles
                    )

                    // Audio
                    AudioMenu(coordinator: coordinator, onInteraction: onInteraction)

                    // Speed
                    SpeedMenu(coordinator: coordinator, onInteraction: onInteraction)

                    // Fullscreen
                    PlayerControlButton(systemName: "arrow.up.backward.and.arrow.down.forward", size: 16, frameSize: 40) {
                        onInteraction()
                        coordinator.playerLayer?.player.view?.window?.toggleFullScreen(nil)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .macDarkGlassCard(cornerRadius: 22, interactive: true)
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
                    .frame(height: 6)

                // Progress
                if range.upperBound > 0 {
                    Capsule()
                        .fill(.white)
                        .frame(width: max(0, min(width, width * CGFloat(value / range.upperBound))), height: 6)
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
        .frame(height: 18)
        .contentShape(Rectangle())
    }
}

private struct PlayerControlButton: View {
    let systemName: String
    let size: CGFloat
    var frameSize: CGFloat = 46
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .frame(width: frameSize, height: frameSize)
                .contentShape(Circle())
                .macDarkGlassCapsule(interactive: true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
    }
}

private struct SubtitleMenu: View {
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    let externalSubtitles: [SubtitleItem]
    @Binding var selectedExternalSubtitle: SubtitleItem?
    let isLoadingExternal: Bool
    let error: String?
    let onInteraction: () -> Void
    let onSelectExternalSubtitle: (SubtitleItem) -> Void
    let onDisableExternalSubtitles: () -> Void

    private var groupedExternalSubtitles: [(lang: String, items: [SubtitleItem])] {
        let grouped = Dictionary(grouping: externalSubtitles, by: { $0.lang.isEmpty ? "unknown" : $0.lang })
        return grouped.keys.sorted().map { lang in
            (
                lang: lang,
                items: (grouped[lang] ?? []).sorted { $0.displayTitle < $1.displayTitle }
            )
        }
    }

    var body: some View {
        Menu {
            if !coordinator.subtitleModel.subtitleInfos.isEmpty {
                Section("Embedded") {
                    ForEach(coordinator.subtitleModel.subtitleInfos, id: \.subtitleID) { subtitle in
                        Button {
                            onInteraction()
                            onDisableExternalSubtitles()
                            subtitle.isEnabled = true
                            coordinator.subtitleModel.selectedSubtitleInfo = subtitle
                        } label: {
                            Label(subtitle.name.isEmpty ? subtitle.subtitleID : subtitle.name, systemImage: coordinator.subtitleModel.selectedSubtitleInfo?.subtitleID == subtitle.subtitleID && selectedExternalSubtitle == nil ? "checkmark" : "")
                        }
                    }
                }
            }

            if !groupedExternalSubtitles.isEmpty {
                ForEach(groupedExternalSubtitles, id: \.lang) { group in
                    if group.items.count == 1, let subtitle = group.items.first {
                        Button {
                            onInteraction()
                            onSelectExternalSubtitle(subtitle)
                        } label: {
                            Label(subtitleDisplayName(for: group.lang), systemImage: selectedExternalSubtitle?.url == subtitle.url ? "checkmark" : "")
                        }
                    } else {
                        Menu(subtitleDisplayName(for: group.lang)) {
                            ForEach(group.items) { subtitle in
                                Button {
                                    onInteraction()
                                    onSelectExternalSubtitle(subtitle)
                                } label: {
                                    Label(subtitle.displayTitle, systemImage: selectedExternalSubtitle?.url == subtitle.url ? "checkmark" : "")
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                onInteraction()
                coordinator.subtitleModel.selectedSubtitleInfo = nil
                onDisableExternalSubtitles()
            } label: {
                Label("Off", systemImage: coordinator.subtitleModel.selectedSubtitleInfo == nil && selectedExternalSubtitle == nil ? "checkmark" : "")
            }

            if isLoadingExternal {
                Text("Loading subtitles...")
            }
            if let error {
                Text(error)
            }
        } label: {
            Image(systemName: "captions.bubble.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
                .macDarkGlassCapsule(interactive: true)
        }
        .menuStyle(.borderlessButton)
        .foregroundStyle(.white.opacity(0.92))
        .accessibilityLabel("Subtitles")
    }

    private func subtitleDisplayName(for lang: String) -> String {
        let names = Locale.current.localizedString(forLanguageCode: lang)
            ?? Locale(identifier: "en").localizedString(forLanguageCode: lang)
        return names ?? lang.uppercased()
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 40, height: 40)
                    .macDarkGlassCapsule(interactive: true)
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
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .macDarkGlassCapsule(interactive: true)
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
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 50, height: 38)
                .macDarkGlassCapsule(interactive: true)
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

private struct ExternalSubtitleOverlay: View {
    let cues: [MacSubtitleCue]
    let time: TimeInterval
    let isLoading: Bool
    let title: String

    private var activeText: String? {
        cues.first { time >= $0.start && time <= $0.end }?.text
    }

    var body: some View {
        VStack {
            Spacer()
            if isLoading {
                Text("Loading \(title)...")
                    .subtitleBubble(fontSize: 18)
            } else if let activeText {
                Text(activeText)
                    .subtitleBubble(fontSize: 28)
            }
        }
    }
}

private struct PlayerStartupLoadingOverlay: View {
    let launch: PlayerLaunch

    private var backdropURL: URL? {
        [launch.episodeThumbnail, launch.background, launch.poster].compactMap { $0 }.compactMap(URL.init(string:)).first
    }

    var body: some View {
        ZStack {
            Color.black

            if let backdropURL {
                CachedAsyncImage(url: backdropURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 26)
                        .opacity(0.42)
                } placeholder: {
                    Color.clear
                }
                .ignoresSafeArea()
            }

            LinearGradient(
                colors: [.black.opacity(0.72), .black.opacity(0.36), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                MacLottieLoadingView(size: 58)
                Text(launch.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                Text("Preparing playback")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MoonlitTheme.textSecondary)
            }
            .padding(24)
            .macDarkGlassCard(cornerRadius: 22)
        }
    }
}

private struct MacSubtitleCue: Identifiable, Sendable {
    let id = UUID()
    let start: TimeInterval
    let end: TimeInterval
    let text: String

    static func parse(_ content: String) -> [MacSubtitleCue] {
        var cues: [MacSubtitleCue] = []
        let lines = content.components(separatedBy: "\n")
        var index = 0

        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.contains("-->") {
                let parts = line.components(separatedBy: "-->")
                if parts.count >= 2,
                   let start = parseTime(parts[0].trimmingCharacters(in: .whitespaces)),
                   let end = parseTime(parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? "") {
                    index += 1
                    var textLines: [String] = []
                    while index < lines.count {
                        let candidate = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
                        if candidate.isEmpty || candidate.contains("-->") { break }
                        if candidate.allSatisfy(\.isNumber) {
                            index += 1
                            continue
                        }
                        textLines.append(stripTags(candidate))
                        index += 1
                    }
                    let text = textLines.filter { !$0.isEmpty }.joined(separator: "\n")
                    if !text.isEmpty {
                        cues.append(MacSubtitleCue(start: start, end: end, text: text))
                    }
                    continue
                }
            }
            index += 1
        }

        return cues
    }

    private static func parseTime(_ value: String) -> TimeInterval? {
        let normalized = value.replacingOccurrences(of: ",", with: ".")
        let parts = normalized.components(separatedBy: ":")
        switch parts.count {
        case 3:
            guard let hours = Double(parts[0]), let minutes = Double(parts[1]), let seconds = Double(parts[2]) else { return nil }
            return hours * 3600 + minutes * 60 + seconds
        case 2:
            guard let minutes = Double(parts[0]), let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        default:
            return nil
        }
    }

    private static func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

private extension Text {
    func subtitleBubble(fontSize: CGFloat) -> some View {
        self
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.95), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private extension SubtitleItem {
    var displayTitle: String {
        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return lang.isEmpty ? id : lang.uppercased()
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
