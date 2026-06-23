#if canImport(Libmpv)
import SwiftUI
import AppKit
import Combine
import MoonlitCore
import Libmpv

@MainActor
public class MPVPlayerEngine: ObservableObject {
    @Published private var playerView: NSView?
    private var progressTimer: Timer?
    private var positionTimer: DispatchSourceTimer?

    private var currentLaunch: PlayerLaunch?
    private var lastPlaybackSpeed: Float = 1.0
    private var pendingInitialSeekSeconds: Double?
    private var didApplyInitialSeek = false
    public private(set) var launchToken = 0
    private var didScheduleFirstFrameReveal = false
    private var launchStartedAt = CACurrentMediaTime()
    private var didReachReadyToPlay = false
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var lastStallPosition: Double = 0
    private var lastStallPositionTime: TimeInterval = 0
    private var wasUserPaused = false

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

    public let positionPublisher = PassthroughSubject<Double, Never>()
    public let bufferedPositionPublisher = PassthroughSubject<Double, Never>()

    private var mpv: OpaquePointer?
    private var metalLayer: MetalLayer?
    private var displayLink: CVDisplayLink?
    private var eventQueue = DispatchQueue(label: "mpv", qos: .userInitiated)

    private var audioTrackIds: [Int64] = []
    private var subtitleTrackIds: [String: Int64] = [:]
    private var embeddedSubtitles: [SubtitleItem] = []
    private var externalSubtitles: [SubtitleItem] = []

    public init() {}

    deinit {
        guard let ctx = mpv else { return }
        mpv = nil
        mpv_terminate_destroy(ctx)
    }

    public var displayView: NSView? { playerView }

    public func launch(_ launch: PlayerLaunch) {
        cleanup()
        guard let url = URL(string: launch.sourceUrl) else { isLoading = false; return }
        currentLaunch = launch
        let fmt = formatLabel(for: launch)
        pendingInitialSeekSeconds = (fmt == "mkv" || fmt == "webm" || fmt == "avi")
            ? nil
            : launch.initialPositionMs.map { $0 / 1000 }.flatMap { $0 > 0 ? $0 : nil }
        didApplyInitialSeek = false
        isLoading = true; isPlaying = false; isEnded = false
        launchStartedAt = CACurrentMediaTime()
        didReachReadyToPlay = false

        if !isLikelyHLS(launch) {
            let headers = launch.sourceHeaders ?? [:]
            Task.detached { await self.preflightPing(url: url, headers: headers) }
        }

        setupPlayer(with: url)
        setupLifecycle()
        loadSubtitles(from: launch.subtitles ?? [])
        startProgressTimer()
        print("[Moonlit][MPV] launch.done host=\(url.host ?? "nil") format=\(fmt)")
        NSLog("[Moonlit][MPV] url=%@", url.absoluteString)
        NSLog("[Moonlit][MPV] headerKeys=%@", (launch.sourceHeaders ?? [:]).keys.sorted().joined(separator: ","))
        scheduleOpenTimeout(for: launchToken, launch: launch, isHLS: isLikelyHLS(launch))
    }

    public func loadURL(_ urlString: String, headers: [String: String] = [:]) {
        guard let mpv else { return }
        didEncounterError = false
        isLoading = true
        isPlaying = false
        isEnded = false
        hasRenderedFrame = false
        didReachReadyToPlay = false
        didScheduleFirstFrameReveal = false
        lastStallPosition = 0
        lastStallPositionTime = 0
        applyRequestHeaders(headers)
        let rawUrl = urlString
        command("loadfile", args: [rawUrl, "replace"])
        print("[Moonlit][MPV] reload.done url=\(rawUrl)")
    }

    private func applyRequestHeaders(_ headers: [String: String]) {
        guard let mpv else { return }
        if headers.isEmpty {
            checkError(mpv_set_property_string(mpv, "http-header-fields", ""))
            return
        }
        let serialized = headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { key, value in
                let escaped = value
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: ",", with: "\\,")
                return "\(key): \(escaped)"
            }
            .joined(separator: ",")
        checkError("http-header-fields", mpv_set_property_string(mpv, "http-header-fields", serialized))
    }

    public func play() {
        setFlag("pause", false)
        isPlaying = true; isEnded = false; wasUserPaused = false
        print("[Moonlit][MPV] play")
    }

    public func pause() {
        setFlag("pause", true)
        isPlaying = false; wasUserPaused = true
        print("[Moonlit][MPV] pause")
    }

    public func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    public func seek(to seconds: Double) {
        command("seek", args: [String(seconds), "absolute"])
        currentPosition = seconds
    }

    public func seekBy(_ seconds: Double) {
        seek(to: min(max(currentPosition + seconds, 0), duration))
    }

    public func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed; lastPlaybackSpeed = speed
        var s = Double(speed)
        mpv_set_property(mpv, "speed", MPV_FORMAT_DOUBLE, &s)
    }

    public func skipForward() { seekBy(30) }
    public func skipBack() { seekBy(-15) }
    public func skipForward15() { seekBy(15) }
    public func skipBack15() { seekBy(-15) }

    public func toggleMute() {
        isMuted.toggle()
        setFlag("mute", isMuted)
    }

    public func setVideoFill(_ fill: Bool) {
        isFillingVideo = fill
        setFlag("keepaspect", !fill)
    }

    public func selectAudioTrack(named trackName: String) {
        guard let idx = availableAudioTracks.firstIndex(of: trackName), idx < audioTrackIds.count else { return }
        var aid = audioTrackIds[idx]
        mpv_set_property(mpv, "aid", MPV_FORMAT_INT64, &aid)
        selectedAudioTrack = trackName
    }

    public func loadSubtitles(from subtitles: [SubtitleItem]) {
        externalSubtitles = subtitles
        rebuildSubtitleList()
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

        guard let subtitle else {
            setStringProperty("sid", "no")
            return
        }

        if let sid = subtitleTrackIds[subtitle.id] {
            var id = sid
            mpv_set_property(mpv, "sid", MPV_FORMAT_INT64, &id)
            return
        }

        setStringProperty("sid", "no")
        guard let url = URL(string: subtitle.url) else { return }
        let token = launchToken
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
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
            await persistProgress(launch: launch, positionSeconds: position, durationSeconds: total, completed: false)
        }
        cleanup()
    }

    public func refreshAudioTracks() {
        refreshTracks()
    }

    // MARK: - mpv Setup

    private func setupPlayer(with url: URL) {
        mpv = mpv_create()
        guard let mpv else { return }

        checkError("vo", mpv_set_option_string(mpv, "vo", "gpu-next"))
        checkError("gpu-api", mpv_set_option_string(mpv, "gpu-api", "vulkan"))
        checkError("gpu-context", mpv_set_option_string(mpv, "gpu-context", "moltenvk"))

        checkError("vulkan-swap-mode", mpv_set_option_string(mpv, "vulkan-swap-mode", "fifo"))
        checkError("vulkan-queue-count", mpv_set_option_string(mpv, "vulkan-queue-count", "1"))
        checkError("vulkan-async-compute", mpv_set_option_string(mpv, "vulkan-async-compute", "no"))
        checkError("vulkan-async-transfer", mpv_set_option_string(mpv, "vulkan-async-transfer", "no"))

        checkError("hwdec", mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
        checkError("target-colorspace-hint", mpv_set_option_string(mpv, "target-colorspace-hint", "yes"))
        checkError("tone-mapping", mpv_set_option_string(mpv, "tone-mapping", "auto"))
        checkError("hdr-compute-peak", mpv_set_option_string(mpv, "hdr-compute-peak", "yes"))
        checkError("ao", mpv_set_option_string(mpv, "ao", "avfoundation,audiounit,"))
        checkError("audio-fallback-to-null", mpv_set_option_string(mpv, "audio-fallback-to-null", "yes"))
        checkError("audio-channels", mpv_set_option_string(mpv, "audio-channels", "auto"))
        checkError("keep-open", mpv_set_option_string(mpv, "keep-open", "yes"))
        checkError("video-rotate", mpv_set_option_string(mpv, "video-rotate", "no"))
        checkError("subs-match-os", mpv_set_option_string(mpv, "subs-match-os-language", "yes"))
        checkError("subs-fallback", mpv_set_option_string(mpv, "subs-fallback", "yes"))
        checkError("log", mpv_request_log_messages(mpv, "warn"))

        checkError("network-timeout", mpv_set_option_string(mpv, "network-timeout", "15"))

        checkError("cache-secs", mpv_set_option_string(mpv, "cache-secs", "30"))
        checkError("cache-pause", mpv_set_option_string(mpv, "cache-pause", "yes"))

        checkError("cache", mpv_set_option_string(mpv, "cache", "yes"))
        checkError("force-seekable", mpv_set_option_string(mpv, "force-seekable", "yes"))
        checkError("demuxer-lavf-o", mpv_set_option_string(mpv, "demuxer-lavf-o",
            "probesize=32768,analyzeduration=1000000,timeout=15000000,protocol_whitelist=file,http,https,tcp,tls,crypto,httpproxy"))

        let sourceHeaders = currentLaunch?.sourceHeaders ?? [:]
        let sanitized = sourceHeaders.filter { key, value in
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && key.caseInsensitiveCompare("Range") != .orderedSame
        }
        if !sanitized.isEmpty {
            let serialized = sanitized
                .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
                .map { key, value in
                    let escaped = value
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: ",", with: "\\,")
                    return "\(key): \(escaped)"
                }
                .joined(separator: ",")
            checkError("http-header-fields", mpv_set_option_string(mpv, "http-header-fields", serialized))
        }

        let container = MPVContainerView(frame: NSRect(x: 0, y: 0, width: 1920, height: 1080))
        container.autoresizingMask = [.width, .height]
        let layer = container.metalLayer
        self.metalLayer = layer
        self.playerView = container

        var metalLayerPtr = Unmanaged.passUnretained(layer).toOpaque()
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &metalLayerPtr))

        let initResult = mpv_initialize(mpv)
        checkError(initResult)
        NSLog("[Moonlit][MPV] initialize result=%d (0=ok, <0=failed)", initResult)

        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "paused-for-cache", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "track-list/count", MPV_FORMAT_INT64)

        mpv_set_wakeup_callback(mpv, { ctx in
            let client = Unmanaged<MPVPlayerEngine>.fromOpaque(ctx!).takeUnretainedValue()
            client.readEvents()
        }, Unmanaged.passUnretained(self).toOpaque())

        let rawUrl = url.absoluteString
        var cargs = (
            strdup("loadfile"),
            strdup(rawUrl),
            strdup("replace"),
            nil
        ) as (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?)
        var argv: [UnsafePointer<CChar>?] = [
            UnsafePointer(cargs.0),
            UnsafePointer(cargs.1),
            UnsafePointer(cargs.2),
            nil
        ]
        let asyncResult = mpv_command_async(mpv, 0, &argv)
        if asyncResult < 0 {
            let msg = String(cString: mpv_error_string(asyncResult))
            print("[Moonlit][MPV] loadfile async failed: \(asyncResult) \(msg)")
        }
        defer {
            free(cargs.0)
            free(cargs.1)
            free(cargs.2)
        }

        startPositionTimer()
    }

    private func startPositionTimer() {
        positionTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: eventQueue)
        timer.schedule(deadline: .now() + 0.25, repeating: 0.25)
        timer.setEventHandler { [weak self] in
            guard let self, let mpv = self.mpv else { return }
            let pos = self.getDouble("time-pos")
            let dur = self.getDouble("duration")
            let finPos = pos.isFinite ? pos : nil
            let finDur = dur.isFinite ? dur : nil
            guard let currentPos = finPos, let currentDur = finDur else { return }
            DispatchQueue.main.async {
                if abs(currentPos - self.currentPosition) > 0.1 {
                    self.currentPosition = currentPos
                    self.positionPublisher.send(currentPos)
                }
                if currentDur > 0, currentDur != self.duration {
                    self.duration = currentDur
                }
                if self.isPlaying, currentPos > 0 {
                    if abs(currentPos - self.lastStallPosition) > 0.1 {
                        self.lastStallPosition = currentPos
                        self.lastStallPositionTime = CACurrentMediaTime()
                    } else if self.lastStallPositionTime > 0,
                              CACurrentMediaTime() - self.lastStallPositionTime > 10 {
                        NSLog("[Moonlit][MPV] stall.detected position=%.2f", currentPos)
                        self.isLoading = false
                        self.isPlaying = false
                        self.didEncounterError = true
                    }
                }
            }
        }
        timer.resume()
        positionTimer = timer
    }

    // MARK: - mpv Event Loop

    private func readEvents() {
        eventQueue.async { [weak self] in
            guard let self, let mpv = self.mpv else { return }
            while self.mpv != nil {
                let event = mpv_wait_event(mpv, 0)
                if let event, event.pointee.event_id == MPV_EVENT_NONE { break }
                if let event { self.handleEvent(event) }
            }
        }
    }

    private func handleEvent(_ event: UnsafePointer<mpv_event>) {
        let eventID = event.pointee.event_id
        switch eventID {
        case MPV_EVENT_PROPERTY_CHANGE:
            let data = OpaquePointer(event.pointee.data)
            if let prop = UnsafePointer<mpv_event_property>(data)?.pointee {
                let name = String(cString: prop.name)
                switch name {
                case "pause", "paused-for-cache", "eof-reached":
                    let flag = (prop.data?.load(as: Int32.self) ?? 0) != 0
                    DispatchQueue.main.async { [weak self] in self?.applyFlag(name, flag) }
                case "track-list/count":
                    DispatchQueue.main.async { [weak self] in self?.refreshTracks() }
                default:
                    break
                }
            }
        case MPV_EVENT_FILE_LOADED:
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.didReachReadyToPlay = true
                self.isLoading = false
                self.refreshTracks()
                if !self.hasRenderedFrame, !self.didScheduleFirstFrameReveal {
                    self.didScheduleFirstFrameReveal = true
                    let token = self.launchToken
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(for: .milliseconds(350))
                        guard let self, self.launchToken == token, !self.hasRenderedFrame else { return }
                        self.hasRenderedFrame = true
                    }
                }
            }
        case MPV_EVENT_END_FILE:
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let reason = event.pointee.data?.load(as: mpv_end_file_reason.self) ?? MPV_END_FILE_REASON_EOF
                if reason == MPV_END_FILE_REASON_EOF {
                    if self.currentPosition < 2, self.duration > 0, self.duration < 5 {
                        NSLog("[Moonlit][MPV] short eof position=%.2f duration=%.2f", self.currentPosition, self.duration)
                        self.isLoading = false
                        self.isPlaying = false
                        self.didEncounterError = true
                    } else {
                        self.isEnded = true
                        self.isPlaying = false
                        self.isLoading = false
                    }
                } else if reason != MPV_END_FILE_REASON_STOP {
                    self.isLoading = false
                    self.isPlaying = false
                    self.didEncounterError = true
                }
            }
        case MPV_EVENT_SHUTDOWN:
            if let ctx = mpv {
                mpv = nil
                mpv_terminate_destroy(ctx)
            }
        case MPV_EVENT_LOG_MESSAGE:
            let msg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event.pointee.data))
            if let msg {
                let prefix = String(cString: msg.pointee.prefix)
                let level = String(cString: msg.pointee.level)
                let text = String(cString: msg.pointee.text).trimmingCharacters(in: .whitespacesAndNewlines)
                NSLog("[mpv][%@][%@] %@", prefix, level, text)
            }
        default:
            break
        }
    }

    private func applyFlag(_ name: String, _ value: Bool) {
        switch name {
        case "pause":
            isPlaying = !value
        case "paused-for-cache":
            if hasRenderedFrame { isLoading = value }
        default:
            break
        }
    }

    // MARK: - mpv Commands

    private func getDouble(_ name: String) -> Double {
        guard let mpv else { return 0 }
        var data = Double()
        mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
        return data
    }

    private func setFlag(_ name: String, _ flag: Bool) {
        guard let mpv else { return }
        var data: Int = flag ? 1 : 0
        mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
    }

    private func command(_ command: String, args: [String?] = []) {
        guard let mpv else { return }
        var cargs = ([command] + args + [nil]).map { $0.flatMap { UnsafePointer<CChar>(strdup($0)) } }
        defer { cargs.forEach { if let p = $0 { free(UnsafeMutablePointer(mutating: p)) } } }
        mpv_command(mpv, &cargs)
    }

    private func getString(_ name: String) -> String? {
        guard let mpv else { return nil }
        guard let cstr = mpv_get_property_string(mpv, name) else { return nil }
        defer { mpv_free(cstr) }
        return String(cString: cstr)
    }

    private func getInt(_ name: String) -> Int {
        guard let mpv else { return 0 }
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_INT64, &data)
        return Int(data)
    }

    private func getFlag(_ name: String) -> Bool {
        guard let mpv else { return false }
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
        return data != 0
    }

    private func setStringProperty(_ name: String, _ value: String) {
        guard let mpv else { return }
        mpv_set_property_string(mpv, name, value)
    }

    private func rebuildSubtitleList() {
        availableSubtitles = embeddedSubtitles + externalSubtitles
    }

    private func trackLabel(title: String, lang: String, index: Int, kind: String) -> String {
        if !title.isEmpty { return title }
        if !lang.isEmpty {
            return (Locale.current.localizedString(forLanguageCode: lang) ?? lang).capitalized
        }
        return "\(kind) \(index + 1)"
    }

    public func refreshTracks() {
        eventQueue.async { [weak self] in
            guard let self, self.mpv != nil else { return }
            let count = self.getInt("track-list/count")

            var audioLabels: [String] = []
            var audioIds: [Int64] = []
            var selectedAudioLabel: String?
            var subs: [SubtitleItem] = []
            var subIds: [String: Int64] = [:]
            var selectedEmbeddedSub: SubtitleItem?

            for i in 0..<max(count, 0) {
                let type = self.getString("track-list/\(i)/type") ?? ""
                let id = Int64(self.getInt("track-list/\(i)/id"))
                let title = (self.getString("track-list/\(i)/title") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let lang = (self.getString("track-list/\(i)/lang") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let selected = self.getFlag("track-list/\(i)/selected")

                if type == "audio" {
                    let label = self.trackLabel(title: title, lang: lang, index: audioLabels.count, kind: "Audio")
                    audioLabels.append(label)
                    audioIds.append(id)
                    if selected { selectedAudioLabel = label }
                } else if type == "sub" {
                    let item = SubtitleItem(
                        id: "mpv-embedded-\(id)",
                        url: "mpv-embedded:\(id)",
                        lang: lang.isEmpty ? "und" : lang,
                        name: title.isEmpty ? self.trackLabel(title: "", lang: lang, index: subs.count, kind: "Subtitle") : title
                    )
                    subs.append(item)
                    subIds[item.id] = id
                    if selected { selectedEmbeddedSub = item }
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.audioTrackIds = audioIds
                self.availableAudioTracks = audioLabels
                if let selectedAudioLabel {
                    self.selectedAudioTrack = selectedAudioLabel
                } else if self.selectedAudioTrack == nil {
                    self.selectedAudioTrack = audioLabels.first
                }
                self.embeddedSubtitles = subs
                self.subtitleTrackIds = subIds
                self.rebuildSubtitleList()
                if self.selectedSubtitle == nil, let selectedEmbeddedSub {
                    self.selectedSubtitle = selectedEmbeddedSub
                }
            }
        }
    }

    private func checkError(_ status: CInt) {
        if status < 0 {
            let msg = String(cString: mpv_error_string(status))
            print("[Moonlit][MPV] error: \(status) \(msg)")
        }
    }

    private func checkError(_ opt: String, _ status: CInt) {
        if status < 0 {
            let msg = String(cString: mpv_error_string(status))
            print("[Moonlit][MPV] option [\(opt)] fail: \(status) \(msg)")
        }
    }

    // MARK: - Internal

    private func isLikelyHLS(_ launch: PlayerLaunch) -> Bool {
        let contentType = launch.sourceContentType?.lowercased() ?? ""
        if contentType.contains("mpegurl") || contentType.contains("x-mpegurl") { return true }
        guard let path = URL(string: launch.sourceUrl)?.path.lowercased() else { return false }
        return path.hasSuffix(".m3u8")
    }

    private func formatLabel(for launch: PlayerLaunch) -> String {
        let contentType = launch.sourceContentType?.lowercased() ?? ""
        if contentType.contains("mpegurl") || contentType.contains("x-mpegurl") { return "hls" }
        guard let path = URL(string: launch.sourceUrl)?.path.lowercased() else { return "unknown" }
        if path.hasSuffix(".m3u8") { return "hls" }
        if path.hasSuffix(".mp4") || path.hasSuffix(".m4v") { return "mp4" }
        if path.hasSuffix(".mkv") { return "mkv" }
        if path.hasSuffix(".avi") { return "avi" }
        if path.hasSuffix(".webm") { return "webm" }
        return "unknown"
    }

    private func preflightPing(url: URL, headers: [String: String]) async {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2)
        request.httpMethod = "GET"
        request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        _ = try? await URLSession.shared.data(for: request)
    }

    private func scheduleOpenTimeout(for token: Int, launch: PlayerLaunch, isHLS: Bool) {
        guard !isHLS else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, self.launchToken == token,
                  !self.didReachReadyToPlay,
                  self.currentLaunch?.sourceUrl == launch.sourceUrl else { return }
            let cacheState = self.getDouble("cache-buffering-state")
            let demuxTime = self.getDouble("demuxer-cache-time")
            NSLog("[Moonlit][MPV] open.timeout cacheBufferingState=%.0f demuxerCacheTime=%.2f", cacheState, demuxTime)
            self.isLoading = false
            self.isPlaying = false
            self.didEncounterError = true
        }
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

    private func cleanup() {
        progressTimer?.invalidate(); progressTimer = nil
        positionTimer?.cancel(); positionTimer = nil
        teardownLifecycle()
        if let ctx = mpv {
            mpv = nil
            eventQueue.async {
                mpv_terminate_destroy(ctx)
            }
        }
        playerView = nil
        currentLaunch = nil
        pendingInitialSeekSeconds = nil
        didApplyInitialSeek = false
        didScheduleFirstFrameReveal = false
        didReachReadyToPlay = false
        launchToken += 1
        isPlaying = false; isLoading = true; isEnded = false; hasRenderedFrame = false
        didEncounterError = false
        lastStallPosition = 0; lastStallPositionTime = 0; wasUserPaused = false
        currentPosition = 0; duration = 0; lastPlaybackSpeed = 1.0
        bufferedPosition = 0
        availableSubtitles = []
        selectedSubtitle = nil
        availableAudioTracks = []
        selectedAudioTrack = nil
        loadedCues = []
    }

    private func setupLifecycle() {
        teardownLifecycle()
        var observers: [NSObjectProtocol] = []
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self, self.mpv != nil else { return }
                self.pause()
                self.setStringProperty("vid", "no")
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self, self.mpv != nil else { return }
                self.setStringProperty("vid", "auto")
                if !self.wasUserPaused { self.play() }
            }
        )
        lifecycleObservers = observers
    }

    private func teardownLifecycle() {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers = []
    }

    private func persistProgress(launch: PlayerLaunch?, positionSeconds: Double, durationSeconds: Double, completed: Bool) async {
        guard let launch, let profile = ProfileManager.shared.currentProfile,
              positionSeconds > 0 || durationSeconds > 0 else { return }
        let repo = WatchProgressRepository.shared
        await repo.updateProgress(
            profileId: profile.id, mediaId: launch.videoId,
            mediaType: launch.contentType.rawValue,
            positionSeconds: positionSeconds, durationSeconds: durationSeconds,
            completed: completed, name: launch.title,
            poster: launch.episodeThumbnail ?? launch.poster,
            parentMetaId: launch.parentMetaId, season: launch.seasonNumber,
            episode: launch.episodeNumber)
        if completed {
            await repo.markWatched(
                profileId: profile.id, mediaId: launch.videoId,
                mediaType: launch.contentType.rawValue,
                name: launch.title, poster: launch.episodeThumbnail ?? launch.poster,
                season: launch.seasonNumber, episode: launch.episodeNumber)
        }
    }
}
#endif
