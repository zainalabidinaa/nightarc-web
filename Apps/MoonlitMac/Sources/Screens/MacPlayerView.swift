import SwiftUI
import MoonlitCore

#if os(macOS)
import AppKit
#endif

struct MacPlayerView: View {
    let launch: PlayerLaunch

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var engine = MPVPlayerEngine()
    @StateObject private var addonRepo = AddonRepository.shared
    @State private var visibility = PlayerControlVisibilityState()
    @State private var hideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var pendingSeekTime: Double = 0
    @State private var subtitleChoices: [SubtitleItem] = []
    @State private var selectedExternalSubtitle: SubtitleItem?
    @State private var externalSubtitleCues: [SubtitleCue] = []
    @State private var isLoadingSubtitles = false
    @State private var subtitleError: String?
    @State private var showStartupLoading = true
    @State private var backupSources: [StreamItem] = []
    @State private var currentSourceIndex = 0
    @State private var isTryingNextSource = false
    @State private var introStart: Double?
    @State private var introEnd: Double?
    @State private var hasAutoSkippedIntro = false

    var body: some View {
        ZStack {
            Color.black

            if let displayView = engine.displayView {
                MPVPlayerViewRepresentable(playerView: displayView)
                    .ignoresSafeArea()
            } else if engine.didEncounterError || (!engine.isLoading && !engine.hasRenderedFrame) {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "play.slash")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))
                    Text(isTryingNextSource ? "Trying next source..." : "Unable to play this source")
                        .foregroundColor(.white)
                    HStack(spacing: 16) {
                        Button("Try Next Source") {
                            tryNextSource()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white.opacity(0.2))
                        Button("Retry") {
                            isTryingNextSource = false
                            currentSourceIndex = 0
                            showStartupLoading = true
                            engine.launch(launch)
                            Task {
                                try? await Task.sleep(for: .seconds(1.25))
                                showStartupLoading = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white.opacity(0.2))
                        Button("Dismiss") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.2))
                    }
                }
            }

            if let selectedExternalSubtitle {
                ExternalSubtitleOverlay(
                    cues: externalSubtitleCues,
                    time: engine.currentPosition,
                    isLoading: isLoadingSubtitles,
                    title: selectedExternalSubtitle.displayTitle
                )
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
                    engine: engine,
                    isSeeking: $isSeeking,
                    pendingSeekTime: $pendingSeekTime,
                    subtitleChoices: subtitleChoices,
                    selectedExternalSubtitle: $selectedExternalSubtitle,
                    isLoadingSubtitles: isLoadingSubtitles,
                    subtitleError: subtitleError,
                    introStart: introStart,
                    onSkipIntro: skipIntro,
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
            Task {
                await loadAvailableSubtitles()
                await fetchBackupSources()
                await fetchIntroTimestamps()
                engine.launch(launch)
                try? await Task.sleep(for: .seconds(1.25))
                showStartupLoading = false
            }
        }
        .onChange(of: engine.didEncounterError) { _, didError in
            if didError && !isTryingNextSource && currentSourceIndex < backupSources.count {
                tryNextSource()
            }
        }
        .onChange(of: engine.currentPosition) { _, pos in
            checkAutoSkipIntro(at: pos)
        }
        .onDisappear {
            hideTask?.cancel()
            engine.stop()
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
            NSApp.keyWindow?.toggleFullScreen(nil)
            return .handled
        }
        .onKeyPress(KeyEquivalent("m")) {
            engine.toggleMute()
            return .handled
        }
        .onKeyPress(KeyEquivalent("s")) {
            let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]
            if let idx = rates.firstIndex(of: engine.playbackSpeed), idx + 1 < rates.count {
                engine.setPlaybackSpeed(rates[idx + 1])
            } else {
                engine.setPlaybackSpeed(rates[0])
            }
            return .handled
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
        engine.togglePlayPause()
    }

    private func seekBy(_ interval: Int) {
        showControls()
        engine.seekBy(Double(interval))
    }

    private func adjustVolume(by delta: Float) {
        showControls()
        if engine.isMuted {
            engine.toggleMute()
        }
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

    private func fetchBackupSources() async {
        await StreamRepository.shared.fetchStreams(
            type: launch.parentMetaType ?? launch.contentType.rawValue,
            id: launch.videoId,
            addons: addonRepo.managedAddons.map(\.manifest),
            title: launch.title
        )
        let allStreams = StreamRepository.shared.streams
        guard !allStreams.isEmpty else { return }
        let currentUrl = launch.sourceUrl
        backupSources = allStreams.filter { $0.url != currentUrl && $0.url != nil && $0.url != "" }
    }

    private func tryNextSource() {
        guard currentSourceIndex < backupSources.count else { return }
        let nextSource = backupSources[currentSourceIndex]
        currentSourceIndex += 1
        isTryingNextSource = true

        guard let url = nextSource.url, !url.isEmpty else {
            tryNextSource()
            return
        }
        let headers = nextSource.behaviorHints?.proxyHeaders?.request ?? [:]
        engine.loadURL(url, headers: headers)
        showStartupLoading = true

        Task {
            try? await Task.sleep(for: .seconds(1.25))
            isTryingNextSource = false
            showStartupLoading = false
        }
    }

    private func fetchIntroTimestamps() async {
        guard let imdbId = launch.videoId.components(separatedBy: ":").first,
              let season = launch.seasonNumber,
              let episode = launch.episodeNumber else { return }

        guard let timestamp = await IntroTimestampService.shared.timestamps(imdbId: imdbId, season: season, episode: episode) else { return }
        introStart = timestamp.introStart
        introEnd = timestamp.introEnd
    }

    private func skipIntro() {
        guard let end = introEnd else { return }
        engine.seek(to: end)
        introStart = nil
        introEnd = nil
    }

    private func checkAutoSkipIntro(at position: Double) {
        guard !hasAutoSkippedIntro,
              let start = introStart,
              let end = introEnd,
              position > 0 else { return }

        if position >= start && position <= end {
            hasAutoSkippedIntro = true
            skipIntro()
        }
    }

    private func selectExternalSubtitle(_ subtitle: SubtitleItem) async {
        selectedExternalSubtitle = subtitle
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
            externalSubtitleCues = SubtitleCue.parse(content)
        } catch {
            subtitleError = "Unable to load subtitles"
        }
        isLoadingSubtitles = false
    }
}

private struct NativeLikePlayerControls: View {
    let title: String
    @ObservedObject var engine: MPVPlayerEngine
    @Binding var isSeeking: Bool
    @Binding var pendingSeekTime: Double
    let subtitleChoices: [SubtitleItem]
    @Binding var selectedExternalSubtitle: SubtitleItem?
    let isLoadingSubtitles: Bool
    let subtitleError: String?
    let introStart: Double?
    let onSkipIntro: () -> Void
    let onInteraction: () -> Void
    let onSelectExternalSubtitle: (SubtitleItem) -> Void
    let onDisableExternalSubtitles: () -> Void
    let onDismiss: () -> Void

    @State private var volumeHover = false

    private var currentTime: Double {
        isSeeking ? pendingSeekTime : engine.currentPosition
    }

    private var totalTime: Double {
        max(engine.duration, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            PlayerScrubber(
                value: Binding(get: { currentTime }, set: { pendingSeekTime = $0 }),
                range: 0 ... totalTime,
                isEditing: $isSeeking,
                onInteraction: onInteraction,
                onCommit: { engine.seek(to: pendingSeekTime) }
            )
            .padding(.horizontal, 6)

            HStack(spacing: 0) {
                Text(formatTime(currentTime))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 58, alignment: .leading)

                Spacer().frame(width: 12)

                PlayerControlButton(systemName: "gobackward.10", size: 21, frameSize: 46) {
                    onInteraction()
                    engine.seekBy(-10)
                }

                Spacer().frame(width: 10)

                Button {
                    onInteraction()
                    engine.togglePlayPause()
                } label: {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                        .macDarkGlassCapsule(interactive: true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Spacer().frame(width: 10)

                PlayerControlButton(systemName: "goforward.10", size: 21, frameSize: 46) {
                    onInteraction()
                    engine.seekBy(10)
                }

                Spacer().frame(width: 12)

                Text("-\(formatTime(totalTime - currentTime))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 58, alignment: .trailing)

                if let introStart, introStart > 0, currentTime < introStart {
                    Spacer().frame(width: 12)
                    Button {
                        onInteraction()
                        onSkipIntro()
                    } label: {
                        Text("Skip Intro")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)

                HStack(spacing: 9) {
                    HStack(spacing: 7) {
                        Button {
                            onInteraction()
                            engine.toggleMute()
                        } label: {
                            Image(systemName: engine.isMuted
                                  ? "speaker.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 40, height: 40)
                                .macDarkGlassCapsule(interactive: true)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.85))

                        if volumeHover {
                            Slider(value: Binding(
                                get: { engine.isMuted ? 0 : 1 },
                                set: {
                                    if $0 == 0 {
                                        if !engine.isMuted { engine.toggleMute() }
                                    } else {
                                        if engine.isMuted { engine.toggleMute() }
                                    }
                                    onInteraction()
                                }
                            ), in: 0 ... 1)
                            .tint(.white.opacity(0.85))
                            .frame(width: 78)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .onHover { volumeHover = $0 }

                    SubtitleMenu(
                        engine: engine,
                        externalSubtitles: subtitleChoices,
                        selectedExternalSubtitle: $selectedExternalSubtitle,
                        isLoadingExternal: isLoadingSubtitles,
                        error: subtitleError,
                        onInteraction: onInteraction,
                        onSelectExternalSubtitle: onSelectExternalSubtitle,
                        onDisableExternalSubtitles: onDisableExternalSubtitles
                    )

                    AudioMenu(engine: engine, onInteraction: onInteraction)

                    SpeedMenu(engine: engine, onInteraction: onInteraction)

                    PlayerControlButton(systemName: "arrow.up.backward.and.arrow.down.forward", size: 16, frameSize: 40) {
                        onInteraction()
                        NSApp.keyWindow?.toggleFullScreen(nil)
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
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 6)

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
    @ObservedObject var engine: MPVPlayerEngine
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
            Section("External") {
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
            }

            Divider()

            Button {
                onInteraction()
                onDisableExternalSubtitles()
            } label: {
                Label("Off", systemImage: selectedExternalSubtitle == nil ? "checkmark" : "")
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
    @ObservedObject var engine: MPVPlayerEngine
    let onInteraction: () -> Void

    var body: some View {
        Group {
            if engine.availableAudioTracks.isEmpty {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 40, height: 40)
                    .macDarkGlassCapsule(interactive: true)
            } else {
                Menu {
                    ForEach(engine.availableAudioTracks, id: \.self) { track in
                        Button {
                            onInteraction()
                            engine.selectAudioTrack(named: track)
                        } label: {
                            Label(track, systemImage: engine.selectedAudioTrack == track ? "checkmark" : "")
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
    @ObservedObject var engine: MPVPlayerEngine
    let onInteraction: () -> Void
    private let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button {
                    onInteraction()
                    engine.setPlaybackSpeed(rate)
                } label: {
                    Label(String(format: "%.2g×", rate), systemImage: abs(engine.playbackSpeed - rate) < 0.01 ? "checkmark" : "")
                }
            }
        } label: {
            Text(String(format: "%.1f×", engine.playbackSpeed))
                .font(.system(size: 13, weight: .bold))
                .frame(width: 50, height: 38)
                .macDarkGlassCapsule(interactive: true)
        }
        .menuStyle(.borderlessButton)
        .foregroundStyle(.white.opacity(0.85))
    }
}

private struct ExternalSubtitleOverlay: View {
    let cues: [SubtitleCue]
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
    @State private var pulse = false
    @State private var visible = false

    private var backdropURL: URL? {
        [launch.episodeThumbnail, launch.background, launch.poster].compactMap { $0 }.compactMap(URL.init(string:)).first
    }

    var body: some View {
        ZStack {
            Color.black

            if let backdropURL {
                CachedAsyncImage(url: backdropURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    .black.opacity(0.0),
                    .black.opacity(0.3),
                    .black.opacity(0.6),
                    .black.opacity(0.8),
                    .black.opacity(0.9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                if let logoURL = launch.logo.flatMap(URL.init) {
                    CachedAsyncImage(url: logoURL) { image in
                        image.resizable().scaledToFit()
                            .frame(width: 300, height: 180)
                            .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 4)
                    } placeholder: {
                        titleText
                    }
                    .id(launch.logo)
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(pulse ? 1.04 : 1.0)
                    .animation(.linear(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
                } else {
                    titleText
                        .opacity(visible ? 1 : 0)
                        .scaleEffect(pulse ? 1.04 : 1.0)
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
                }

                Text("Preparing playback")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            pulse = true
            withAnimation(.easeIn(duration: 0.7)) { visible = true }
        }
    }

    private var titleText: some View {
        Text(launch.title)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)
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
