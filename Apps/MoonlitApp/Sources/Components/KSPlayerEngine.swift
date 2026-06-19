import SwiftUI
import UIKit
import Combine
import QuartzCore
import MoonlitCore
import KSPlayer
import AVFoundation

@MainActor
public class KSPlayerEngine: ObservableObject {
    private let coordinator = KSVideoPlayer.Coordinator()
    @Published private var playerView: UIView?
    private var progressTimer: Timer?
    #if DEBUG
    private var diagnosticsTimer: Timer?
    #endif
    private var currentLaunch: PlayerLaunch?
    private var lastPlaybackSpeed: Float = 1.0
    private var pendingInitialSeekSeconds: Double?
    private var didApplyInitialSeek = false
    private var launchToken = 0
    private var didScheduleFirstFrameReveal = false
    private var lastAVSyncLogTime = CACurrentMediaTime()
    private var lastDroppedVideoFrameCount = UInt32(0)
    private var lastDroppedVideoPacketCount = UInt32(0)
    private var lastRetriedUrl: String?
    private var videoStallTicks = 0

    @Published public var isPlaying = false
    @Published public var isLoading = true
    @Published public var isEnded = false
    @Published public var hasRenderedFrame = false
    public private(set) var currentPosition: Double = 0
    @Published public var duration: Double = 0
    public private(set) var bufferedPosition: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var availableSubtitles: [SubtitleItem] = []
    @Published public var selectedSubtitle: SubtitleItem?
    @Published public var availableAudioTracks: [String] = []
    @Published public var selectedAudioTrack: String?
    @Published public var isMuted = false
    @Published public var loadedCues: [SubtitleCue] = []
    @Published public var isFillingVideo = false
    @Published public var didEncounterError = false

    public let positionPublisher = PassthroughSubject<Double, Never>()
    public let bufferedPositionPublisher = PassthroughSubject<Double, Never>()

    public init() {}

    public var displayView: UIView? { playerView }

    public func launch(_ launch: PlayerLaunch) {
        cleanup()
        guard let url = URL(string: launch.sourceUrl) else { isLoading = false; return }
        PlayerPerformanceDiagnostics.shared.event(
            "ks.launch host=\(url.host ?? "nil") hls=\(isLikelyHLS(launch)) subtitles=\(launch.subtitles?.count ?? 0)"
        )
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

        let options = MoonlitKSOptions()
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
                self.logEngineDiagnostics(reason: "readyToPlay")
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
            PlayerPerformanceDiagnostics.shared.mark("ks.onPlay")
            self.logAVSyncIfNeeded()
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
                    // Reveal the player layer now that a real frame has had time to decode.
                    UIView.animate(withDuration: 0.2) { self.playerView?.alpha = 1 }
                }
            }
            // Only publish position changes that are meaningfully different (>0.25s)
            // to avoid triggering SwiftUI re-renders on every decoder callback
            if abs(current - self.currentPosition) > 0.25 {
                self.setCurrentPosition(current)
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
                self.setCurrentPosition(initialSeek)
            }
        }
        coordinator.onFinish = { [weak self] _, error in
            guard let self else { return }
            self.isEnded = error == nil
            self.isPlaying = false
            self.isLoading = false
            Task { await self.persistProgress(completed: error == nil) }
            if let error {
                print("[Moonlit] KSPlayer finished with error: \(error)")
            }
        }
        coordinator.onBufferChanged = { [weak self] _, _ in
            guard let self else { return }
            PlayerPerformanceDiagnostics.shared.mark("ks.buffer")
            self.setBufferedPosition(self.duration)
        }

        loadSubtitles(from: launch.subtitles ?? [])

        // Option A: pre-flight ping warms up debrid/proxy servers before KSPlayer connects.
        // StremThru and similar proxies need 500–2000ms to locate the file in the debrid
        // cache and open a CDN connection. Without this, video bitrate starts near-zero
        // while audio plays at full speed → AV drift → frame drops. For HLS the playlist
        // fetch is the warm-up; for direct/debrid streams we fire a Range:0-1 request.
        let capturedToken = launchToken
        let shouldPing = !isLikelyHLS(launch)
        Task { @MainActor [weak self] in
            guard let self, self.launchToken == capturedToken else { return }
            if shouldPing {
                await self.preflightPing(url: url, headers: headers)
                guard self.launchToken == capturedToken else { return }
            }
            let view = self.coordinator.makeView(url: url, options: options)
            view.translatesAutoresizingMaskIntoConstraints = false
            // Hide until the first real frame is decoded so stale frames from a previous
            // stream cannot bleed through the loading overlay.
            view.alpha = 0
            self.playerView = view
            self.startProgressTimer()
            self.startDiagnosticsTimer()
        }
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
        setCurrentPosition(seconds)
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
        let token = launchToken
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            // Parse off the main actor — SubtitleCue.parse is a synchronous full-file
            // parse (regex per cue) that would otherwise block the main thread and
            // starve the throttled position updates at startup.
            let cues: [SubtitleCue] = await Task.detached(priority: .utility) {
                guard let content = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1) else { return [] }
                return SubtitleCue.parse(content)
            }.value
            await MainActor.run {
                guard self.launchToken == token else { return }
                self.loadedCues = cues
            }
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
        PlayerPerformanceDiagnostics.shared.event("ks.cleanup position=\(String(format: "%.2f", currentPosition)) duration=\(String(format: "%.2f", duration))")
        progressTimer?.invalidate(); progressTimer = nil
        #if DEBUG
        diagnosticsTimer?.invalidate(); diagnosticsTimer = nil
        #endif
        coordinator.resetPlayer()
        playerView = nil
        currentLaunch = nil
        pendingInitialSeekSeconds = nil
        didApplyInitialSeek = false
        didScheduleFirstFrameReveal = false
        lastAVSyncLogTime = CACurrentMediaTime()
        lastDroppedVideoFrameCount = 0
        lastDroppedVideoPacketCount = 0
        videoStallTicks = 0
        launchToken += 1
        isPlaying = false; isLoading = true; isEnded = false; hasRenderedFrame = false
        didEncounterError = false
        setCurrentPosition(0); duration = 0; lastPlaybackSpeed = 1.0
        setBufferedPosition(0)
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

    private func startDiagnosticsTimer() {
        #if DEBUG
        diagnosticsTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                PlayerPerformanceDiagnostics.shared.event(
                    "diagnostics.timer playing=\(self.isPlaying) loading=\(self.isLoading) frame=\(self.hasRenderedFrame) position=\(String(format: "%.2f", self.currentPosition)) duration=\(String(format: "%.2f", self.duration))"
                )
                self.logAVSyncIfNeeded()
            }
        }
        diagnosticsTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        #endif
    }

    private func setCurrentPosition(_ position: Double) {
        currentPosition = position
        positionPublisher.send(position)
    }

    private func setBufferedPosition(_ position: Double) {
        bufferedPosition = position
        bufferedPositionPublisher.send(position)
    }

    private func logAVSyncIfNeeded() {
        let now = CACurrentMediaTime()
        guard now - lastAVSyncLogTime >= 1,
              let dynamicInfo = coordinator.playerLayer?.player.dynamicInfo else { return }
        lastAVSyncLogTime = now

        let frameDelta = dynamicInfo.droppedVideoFrameCount - lastDroppedVideoFrameCount
        let packetDelta = dynamicInfo.droppedVideoPacketCount - lastDroppedVideoPacketCount
        lastDroppedVideoFrameCount = dynamicInfo.droppedVideoFrameCount
        lastDroppedVideoPacketCount = dynamicInfo.droppedVideoPacketCount

        PlayerPerformanceDiagnostics.shared.logAVSync(
            backend: activeBackendName(),
            displayFPS: dynamicInfo.displayFPS,
            syncDiff: dynamicInfo.audioVideoSyncDiff,
            droppedFrames: dynamicInfo.droppedVideoFrameCount,
            droppedPackets: dynamicInfo.droppedVideoPacketCount,
            droppedFramesDelta: frameDelta,
            droppedPacketsDelta: packetDelta,
            videoBitrate: dynamicInfo.videoBitrate,
            audioBitrate: dynamicInfo.audioBitrate
        )

        // Option B: stall detection. If audio is flowing but video bitrate stays near-zero
        // in the first 10s, the proxy wasn't ready when the pre-flight ping returned.
        // Auto-retry once — the second attempt hits a warm proxy and plays cleanly.
        if isPlaying && currentPosition < 10
            && dynamicInfo.audioBitrate > 50_000
            && dynamicInfo.videoBitrate < 50_000 {
            videoStallTicks += 1
            if videoStallTicks >= 3, let launch = currentLaunch, launch.sourceUrl != lastRetriedUrl {
                lastRetriedUrl = launch.sourceUrl
                videoStallTicks = 0
                PlayerPerformanceDiagnostics.shared.event(
                    "stall.retry host=\(URL(string: launch.sourceUrl)?.host ?? "nil") vbr=\(dynamicInfo.videoBitrate) audio=\(dynamicInfo.audioBitrate)"
                )
                self.launch(launch)
            }
        } else {
            videoStallTicks = 0
        }
    }

    private func preflightPing(url: URL, headers: [String: String]) async {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2)
        request.httpMethod = "GET"
        request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        _ = try? await URLSession.shared.data(for: request)
        PlayerPerformanceDiagnostics.shared.event("preflight.done host=\(url.host ?? "nil")")
    }

    /// The KSPlayer backend actually driving playback: `KSAVPlayer` (Apple AVPlayer) or
    /// `KSMEPlayer` (FFmpeg). KSPlayer tries `firstPlayerType` and falls back to
    /// `secondPlayerType` when the container/codec is unsupported (e.g. MKV on AVPlayer),
    /// so this can differ from the requested preference.
    private func activeBackendName() -> String {
        guard let player = coordinator.playerLayer?.player else { return "none" }
        return String(describing: type(of: player))
    }

    /// One-shot snapshot of the resolved engine + the actual video track (codec, profile,
    /// bit depth, frame rate, dimensions, rotation). This is the evidence that tells us
    /// whether a stream is on FFmpeg (KSMEPlayer) and what codec it is — which decides
    /// whether the FPS problem is decoder pacing vs. something tunable.
    private func logEngineDiagnostics(reason: String) {
        guard let player = coordinator.playerLayer?.player else { return }
        let backend = String(describing: type(of: player))
        let videoTracks = player.tracks(mediaType: .video)
        let video = videoTracks.first(where: { $0.isEnabled }) ?? videoTracks.first

        var codec = "nil"
        var subType = "nil"
        var dims = "nil"
        var bitDepth = "?"
        var fps = "?"
        var rotation = "0"
        if let video {
            codec = video.description.replacingOccurrences(of: " ", with: "_")
            bitDepth = String(video.bitDepth)
            fps = String(format: "%.3f", video.nominalFrameRate)
            rotation = String(video.rotation)
            if let formatDescription = video.formatDescription {
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                dims = "\(dimensions.width)x\(dimensions.height)"
                subType = fourCharCodeString(CMFormatDescriptionGetMediaSubType(formatDescription))
            }
        }

        PlayerPerformanceDiagnostics.shared.event(
            "player.engine backend=\(backend) reason=\(reason) " +
            "codec=\(codec) subType=\(subType) dims=\(dims) bitDepth=\(bitDepth) " +
            "fps=\(fps) rotation=\(rotation)"
        )
    }

    private func fourCharCodeString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        let string = String(bytes: bytes, encoding: .ascii)?
            .trimmingCharacters(in: CharacterSet(charactersIn: " \0")) ?? ""
        return string.isEmpty ? String(code) : string
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

// MARK: - MoonlitKSOptions

/// KSPlayer's default `videoClockSync` drops frames at `-4/fps` (~160ms at 25fps).
/// The KSMEPlayer decode output queue holds ~3 frames, creating a persistent
/// ~120ms PTS lag. This pushes the AV-sync diff into the drop zone (~−240ms peak),
/// causing a regular oscillation that drops ~20% of frames even on trivially
/// decodable streams. Raising the threshold to `-8/fps` (320ms) stops the
/// oscillation; genuine decoder overload (> 1s behind) still triggers recovery.
private final class MoonlitKSOptions: KSOptions {
    private var syncDelayCount = 0

    override func videoClockSync(
        main: KSClock,
        nextVideoTime: TimeInterval,
        fps: Double,
        frameCount: Int
    ) -> (Double, ClockProcessType) {
        // KSClock.getTime() is internal; replicate its logic using public fields:
        // time.seconds + CACurrentMediaTime() - lastMediaTime
        let clockTime = main.time.seconds + CACurrentMediaTime() - main.lastMediaTime
        let desire = clockTime - videoDelay
        let diff = nextVideoTime - desire
        // KSPlayer defaults to -4/fps (~160ms at 25fps). The KSMEPlayer decode queue
        // holds ~3 frames creating a persistent ~120ms PTS lag, pushing diffs to ~-240ms
        // and causing ~20% oscillating drop rate. -8/fps (320ms) stops the oscillation;
        // genuine overload (>1s behind) still triggers recovery.
        if diff >= 1 / fps / 2 {
            syncDelayCount = 0
            return (diff, .remain)
        } else if diff < -8 / fps {
            syncDelayCount += 1
            if diff < -1 {
                return (diff, syncDelayCount % 10 == 0 ? .dropGOPPacket : .next)
            }
            return (diff, syncDelayCount % 4 == 0 ? .dropNextFrame : .next)
        } else {
            syncDelayCount = 0
            return (diff, .next)
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

public struct SubtitleCueIndex: Sendable {
    private struct IndexedCue: Sendable {
        let cue: SubtitleCue
        let originalIndex: Int
    }

    private let cuesByStart: [IndexedCue]
    private let maxEndThroughIndex: [TimeInterval]

    public init(cues: [SubtitleCue]) {
        let sorted = cues.enumerated()
            .map { IndexedCue(cue: $0.element, originalIndex: $0.offset) }
            .sorted {
                if $0.cue.start == $1.cue.start {
                    return $0.originalIndex < $1.originalIndex
                }
                return $0.cue.start < $1.cue.start
            }
        self.cuesByStart = sorted

        var runningMax: TimeInterval = 0
        self.maxEndThroughIndex = sorted.map { item in
            runningMax = max(runningMax, item.cue.end)
            return runningMax
        }
    }

    public func activeCues(at position: TimeInterval) -> [SubtitleCue] {
        guard !cuesByStart.isEmpty else { return [] }

        var low = 0
        var high = cuesByStart.count
        while low < high {
            let mid = (low + high) / 2
            if cuesByStart[mid].cue.start <= position {
                low = mid + 1
            } else {
                high = mid
            }
        }

        var active: [IndexedCue] = []
        var index = low - 1
        while index >= 0 {
            guard maxEndThroughIndex[index] > position else { break }
            let item = cuesByStart[index]
            if position < item.cue.end {
                active.append(item)
            }
            index -= 1
        }

        return active
            .sorted {
                if $0.cue.start == $1.cue.start {
                    return $0.originalIndex < $1.originalIndex
                }
                return $0.cue.start < $1.cue.start
            }
            .map(\.cue)
    }
}
