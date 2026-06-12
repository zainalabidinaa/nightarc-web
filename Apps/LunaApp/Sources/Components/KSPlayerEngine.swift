import SwiftUI
import UIKit
import LunaCore
import KSPlayer
import AVFoundation

@MainActor
public class KSPlayerEngine: ObservableObject {
    private let coordinator = KSVideoPlayer.Coordinator()
    @Published private var playerView: UIView?
    private var progressTimer: Timer?
    private var currentLaunch: PlayerLaunch?
    private var lastPlaybackSpeed: Float = 1.0
    private var pendingInitialSeekSeconds: Double?
    private var didApplyInitialSeek = false
    private var launchToken = 0
    private var didScheduleFirstFrameReveal = false

    @Published public var isPlaying = false
    @Published public var isLoading = true
    @Published public var isEnded = false
    @Published public var hasRenderedFrame = false
    @Published public var currentPosition: Double = 0
    @Published public var duration: Double = 0
    @Published public var bufferedPosition: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var availableSubtitles: [SubtitleItem] = []
    @Published public var selectedSubtitle: SubtitleItem?
    @Published public var availableAudioTracks: [String] = []
    @Published public var selectedAudioTrack: String?
    @Published public var isMuted = false
    @Published public var loadedCues: [SubtitleCue] = []
    @Published public var isFillingVideo = false
    @Published public var didEncounterError = false

    public init() {}

    public var displayView: UIView? { playerView }

    public func launch(_ launch: PlayerLaunch) {
        cleanup()
        guard let url = URL(string: launch.sourceUrl) else { isLoading = false; return }
        StreamPlaybackDiagnostics.logLaunch(launch)
        currentLaunch = launch
        pendingInitialSeekSeconds = launch.initialPositionMs.map { $0 / 1000 }.flatMap { $0 > 0 ? $0 : nil }
        didApplyInitialSeek = false
        isLoading = true; isPlaying = false; isEnded = false

        var headers: [String: String] = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        ]
        if let sourceHeaders = launch.sourceHeaders {
            headers.merge(sourceHeaders) { _, new in new }
        }

        let options = KSOptions()
        options.appendHeader(headers)
        // Keep startup snappy; higher values can delay the first playable frame.
        options.preferredForwardBufferDuration = 2
        options.isSecondOpen = true
        options.hardwareDecode = true
        if isLikelyHLS(launch) {
            options.maxBufferDuration = 12
        }

        coordinator.onStateChanged = { [weak self] _, state in
            guard let self else { return }
            self.isPlaying = state.isPlaying
            self.isEnded = state == .playedToTheEnd
            if state == .readyToPlay {
                self.refreshAudioTracks()
            }
            // Only show buffering spinner after first frame has rendered
            // (before that the loading backdrop handles the visual state)
            if self.hasRenderedFrame {
                self.isLoading = state == .buffering
            }
            if state == .error {
                self.isLoading = false
                self.isPlaying = false
                self.didEncounterError = true
            }
        }
        coordinator.onPlay = { [weak self] current, total in
            guard let self else { return }
            // Delay revealing the video layer to give the video decoder time to render
            // its first frame. Without this, audio starts (triggering onPlay) before the
            // video track has decoded, leaving the player UIView showing solid black.
            if !self.hasRenderedFrame, !self.didScheduleFirstFrameReveal {
                self.didScheduleFirstFrameReveal = true
                let token = self.launchToken
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(350))
                    guard let self, self.launchToken == token, !self.hasRenderedFrame else { return }
                    self.hasRenderedFrame = true
                    self.isLoading = false
                    self.refreshAudioTracks()
                }
            }
            // Only publish position changes that are meaningfully different (>0.25s)
            // to avoid triggering SwiftUI re-renders on every decoder callback
            if abs(current - self.currentPosition) > 0.25 {
                self.currentPosition = current
            }
            if total > 0, !total.isNaN, !total.isInfinite, total != self.duration {
                self.duration = total
            }
            if !self.didApplyInitialSeek,
               let initialSeek = self.pendingInitialSeekSeconds,
               initialSeek > 0,
               total <= 0 || initialSeek < total {
                self.didApplyInitialSeek = true
                self.pendingInitialSeekSeconds = nil
                self.coordinator.seek(time: initialSeek)
                self.currentPosition = initialSeek
            }
        }
        coordinator.onFinish = { [weak self] _, error in
            guard let self else { return }
            self.isEnded = error == nil
            self.isPlaying = false
            self.isLoading = false
            Task { await self.persistProgress(completed: error == nil) }
            if let error {
                print("[Luna] KSPlayer finished with error: \(error)")
            }
        }
        coordinator.onBufferChanged = { [weak self] _, _ in
            guard let self else { return }
            self.bufferedPosition = self.duration
        }

        let view = coordinator.makeView(url: url, options: options)
        view.translatesAutoresizingMaskIntoConstraints = false
        playerView = view

        loadSubtitles(from: launch.subtitles ?? [])
        startProgressTimer()
    }

    public func play() {
        coordinator.playerLayer?.play()
        coordinator.playbackRate = lastPlaybackSpeed
        isPlaying = true; isEnded = false
    }

    public func pause() { coordinator.playerLayer?.pause(); isPlaying = false }
    public func togglePlayPause() { if isPlaying { pause() } else { play() } }

    public func seek(to seconds: Double) {
        coordinator.seek(time: seconds)
        currentPosition = seconds
    }

    public func seekBy(_ seconds: Double) { seek(to: min(max(currentPosition + seconds, 0), duration)) }

    public func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed; lastPlaybackSpeed = speed
        coordinator.playbackRate = speed
    }

    public func skipForward() { seekBy(30) }
    public func skipBack() { seekBy(-15) }
    public func skipForward15() { seekBy(15) }
    public func skipBack15() { seekBy(-15) }
    public func toggleMute() { isMuted.toggle(); coordinator.isMuted = isMuted }

    public func setVideoFill(_ fill: Bool) {
        isFillingVideo = fill
        coordinator.playerLayer?.player.contentMode = fill ? .scaleAspectFill : .scaleAspectFit
    }

    public func selectAudioTrack(named trackName: String) {
        guard let tracks = coordinator.playerLayer?.player.tracks(mediaType: .audio),
              let track = tracks.first(where: { displayName(for: $0) == trackName }) else { return }
        coordinator.playerLayer?.player.select(track: track)
        selectedAudioTrack = displayName(for: track)
        refreshAudioTracks()
    }

    public func loadSubtitles(from subtitles: [SubtitleItem]) {
        availableSubtitles = subtitles
        if selectedSubtitle == nil, let first = subtitles.first {
            setSubtitle(first)
        }
    }

    public func cycleSubtitle() {
        guard !availableSubtitles.isEmpty else { return }
        if let current = selectedSubtitle,
           let idx = availableSubtitles.firstIndex(where: { $0.id == current.id }) {
            selectedSubtitle = availableSubtitles[(idx + 1) % availableSubtitles.count]
        } else { selectedSubtitle = availableSubtitles.first }
    }

    public func setSubtitle(_ subtitle: SubtitleItem?) {
        selectedSubtitle = subtitle
        loadedCues = []
        guard let subtitle, let url = URL(string: subtitle.url) else { return }
        Task { @MainActor in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return }
            loadedCues = SubtitleCue.parse(content)
        }
    }
    public func stop() {
        let launch = currentLaunch
        let position = currentPosition
        let total = duration
        Task { @MainActor in
            await persistProgress(
                launch: launch,
                positionSeconds: position,
                durationSeconds: total,
                completed: false
            )
        }
        cleanup()
    }

    private func cleanup() {
        progressTimer?.invalidate(); progressTimer = nil
        coordinator.resetPlayer()
        playerView = nil
        currentLaunch = nil
        pendingInitialSeekSeconds = nil
        didApplyInitialSeek = false
        didScheduleFirstFrameReveal = false
        launchToken += 1
        isPlaying = false; isLoading = true; isEnded = false; hasRenderedFrame = false
        didEncounterError = false
        currentPosition = 0; duration = 0; lastPlaybackSpeed = 1.0
        bufferedPosition = 0
        availableSubtitles = []
        selectedSubtitle = nil
        availableAudioTracks = []
        selectedAudioTrack = nil
        loadedCues = []
    }

    public func refreshAudioTracks() {
        let tracks = coordinator.playerLayer?.player.tracks(mediaType: .audio) ?? []
        availableAudioTracks = tracks.map(displayName(for:))
        if let selected = tracks.first(where: { $0.isEnabled }) {
            selectedAudioTrack = displayName(for: selected)
        } else if selectedAudioTrack == nil {
            selectedAudioTrack = availableAudioTracks.first
        }
    }

    private func displayName(for track: MediaPlayerTrack) -> String {
        let language = track.languageCode.flatMap {
            Locale.current.localizedString(forLanguageCode: $0)?.capitalized
        }
        let base = language ?? (track.name.isEmpty ? "Audio \(track.trackID)" : track.name)
        if track.bitRate > 0 {
            return "\(base) · \(Int(track.bitRate / 1000)) kbps"
        }
        return base
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let launch = self.currentLaunch,
                      let profile = ProfileManager.shared.currentProfile else { return }
                await WatchProgressRepository.shared.updateProgress(
                    profileId: profile.id, mediaId: launch.videoId,
                    mediaType: launch.contentType.rawValue,
                    positionSeconds: self.currentPosition, durationSeconds: self.duration,
                    completed: false, name: launch.title, poster: launch.episodeThumbnail ?? launch.poster,
                    parentMetaId: launch.parentMetaId, season: launch.seasonNumber,
                    episode: launch.episodeNumber)
            }
        }
    }

    private func isLikelyHLS(_ launch: PlayerLaunch) -> Bool {
        let contentType = launch.sourceContentType?.lowercased() ?? ""
        if contentType.contains("mpegurl") || contentType.contains("x-mpegurl") {
            return true
        }
        guard let path = URL(string: launch.sourceUrl)?.path.lowercased() else { return false }
        return path.hasSuffix(".m3u8")
    }

    private func persistProgress(completed: Bool) async {
        await persistProgress(
            launch: currentLaunch,
            positionSeconds: currentPosition,
            durationSeconds: duration,
            completed: completed
        )
    }

    private func persistProgress(
        launch: PlayerLaunch?,
        positionSeconds: Double,
        durationSeconds: Double,
        completed: Bool
    ) async {
        guard let launch,
              let profile = ProfileManager.shared.currentProfile,
              positionSeconds > 0 || durationSeconds > 0 else { return }
        let repo = WatchProgressRepository.shared
        await repo.updateProgress(
            profileId: profile.id,
            mediaId: launch.videoId,
            mediaType: launch.contentType.rawValue,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            completed: completed,
            name: launch.title,
            poster: launch.episodeThumbnail ?? launch.poster,
            parentMetaId: launch.parentMetaId,
            season: launch.seasonNumber,
            episode: launch.episodeNumber
        )
        if completed {
            await repo.markWatched(
                profileId: profile.id,
                mediaId: launch.videoId,
                mediaType: launch.contentType.rawValue,
                name: launch.title,
                poster: launch.episodeThumbnail ?? launch.poster,
                season: launch.seasonNumber,
                episode: launch.episodeNumber
            )
        }
    }
}

// MARK: - SubtitleCue

public struct SubtitleCue: Sendable {
    public let start: TimeInterval
    public let end: TimeInterval
    public let text: String

    public static func parse(_ content: String) -> [SubtitleCue] {
        var cues: [SubtitleCue] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.contains("-->") {
                let arrowParts = line.components(separatedBy: "-->")
                if arrowParts.count >= 2,
                   let start = parseVTTTime(arrowParts[0].trimmingCharacters(in: .whitespaces)),
                   let end = parseVTTTime(arrowParts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? "") {
                    i += 1
                    var textLines: [String] = []
                    while i < lines.count {
                        let t = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        if t.isEmpty || t.contains("-->") { break }
                        // Skip pure-number SRT sequence lines
                        if t.allSatisfy({ $0.isNumber }) { i += 1; continue }
                        textLines.append(stripTags(t))
                        i += 1
                    }
                    let text = textLines.filter { !$0.isEmpty }.joined(separator: "\n")
                    if !text.isEmpty { cues.append(SubtitleCue(start: start, end: end, text: text)) }
                    continue
                }
            }
            i += 1
        }
        return cues
    }

    private static func parseVTTTime(_ s: String) -> TimeInterval? {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        let parts = normalized.components(separatedBy: ":")
        switch parts.count {
        case 3:
            guard let h = Double(parts[0]), let m = Double(parts[1]), let sec = Double(parts[2]) else { return nil }
            return h * 3600 + m * 60 + sec
        case 2:
            guard let m = Double(parts[0]), let sec = Double(parts[1]) else { return nil }
            return m * 60 + sec
        default: return nil
        }
    }

    private static func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
