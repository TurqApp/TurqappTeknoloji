import UIKit
import AVFoundation
import CoreImage
import Flutter
import Darwin

private final class PlayerContainerView: UIView {
    weak var linkedPlayerLayer: AVPlayerLayer?
    let snapshotView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        snapshotView.contentMode = .scaleAspectFill
        snapshotView.clipsToBounds = true
        snapshotView.backgroundColor = .black
        snapshotView.isHidden = true
        addSubview(snapshotView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        linkedPlayerLayer?.frame = bounds
        snapshotView.frame = bounds
    }
}

class HLSPlayerView: NSObject, FlutterPlatformView {

    // MARK: - Properties
    private var _view: PlayerContainerView
    private let viewId: Int64
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var eventSink: FlutterEventSink?
    private var timeObserver: Any?
    private var isLooping: Bool = false
    private var isAutoPlay: Bool = true
    private var didRequestInitialPlay: Bool = false
    private var autoplayRequestWorkItem: DispatchWorkItem?
    private var lastAutoplayRequestAt: CFTimeInterval = 0
    private var lastExplicitPlayAt: CFTimeInterval = 0
    private var lastExplicitPlayUrl: String?
    private var lastExplicitPauseAt: CFTimeInterval = 0
    private var lastExplicitPauseUrl: String?
    private var lastRecoveryPlayAt: CFTimeInterval = 0
    private var lastEmittedPlayAt: CFTimeInterval = 0
    private var lastEmittedPlayUrl: String?
    private var lastObservedTimeControlStatus: AVPlayer.TimeControlStatus?
    private var didStabilizeVisualLayer: Bool = false
    private var didRenderFirstFrame: Bool = false
    private var currentUrl: String?
    private let ciContext = CIContext(options: nil)
    private var bufferingEventsCount: Int = 0
    private var playbackStallCount: Int = 0
    private let playbackHealthMonitor: PlaybackHealthMonitor
    private var playbackHealthProbe: AVPlayerPlaybackProbe?
    private var playbackWatchdog: PlaybackWatchdog?
    private var wasMutedBeforeBackground: Bool = false
    private var volumeBeforeBackground: Float = 1.0
    private var preferResumePoster: Bool = false
    private var preferStableStartupBuffer: Bool = false
    private var lastNativeVisualPhase: String?
    private var lastNativeVisualPhaseAtEpochMs: Int64 = 0

    private func log(_ message: String) {
        print("[HLSPlayerView] \(message)")
    }

    // MARK: - Observers
    private var statusObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var playerLayerReadyObserver: NSKeyValueObservation?

    // MARK: - Notification Observers
    private var didPlayToEndTimeObserver: NSObjectProtocol?
    private var failedToPlayToEndTimeObserver: NSObjectProtocol?
    private var playbackStalledObserver: NSObjectProtocol?

    // MARK: - Lifecycle
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        eventChannel: FlutterEventChannel
    ) {
        _view = PlayerContainerView(frame: frame)
        self.viewId = viewId
        playbackHealthMonitor = PlaybackHealthMonitor(
            tag: "AVPlaybackHealth[\(viewId)]"
        )
        _view.backgroundColor = .black
        _view.isOpaque = true

        super.init()

        playbackHealthMonitor.stateListener = { monitor in
            PlaybackHealthStore.shared.update(
                monitor: monitor,
                errors: monitor.getErrors(),
                snapshot: monitor.snapshot()
            )
        }
        PlaybackHealthStore.shared.installDebugLabelIfNeeded()

        // Setup event channel
        eventChannel.setStreamHandler(self)

        // Parse arguments
        if let params = args as? [String: Any] {
            if params["url"] as? String != nil {
                isAutoPlay = params["autoPlay"] as? Bool ?? true
                isLooping = params["loop"] as? Bool ?? false
                preferResumePoster = params["preferResumePoster"] as? Bool ?? false
                preferStableStartupBuffer = params["preferStableStartupBuffer"] as? Bool ?? false
            }
        }

        // Setup app lifecycle observers
        setupLifecycleObservers()
    }

    deinit {
        cleanup()
        didRequestInitialPlay = false
        didStabilizeVisualLayer = false
        didRenderFirstFrame = false
    }

    func view() -> UIView {
        return _view
    }

    // MARK: - Video Loading
    func loadVideo(
        url: String,
        autoPlay: Bool? = nil,
        loop: Bool? = nil,
        preferResumePoster: Bool? = nil
    ) {
        if let autoPlay = autoPlay {
            isAutoPlay = autoPlay
        }
        if let loop = loop {
            isLooping = loop
        }
        if let preferResumePoster = preferResumePoster {
            self.preferResumePoster = preferResumePoster
        }
        log("loadVideo url=\(url)")
        guard let videoURL = URL(string: url) else {
            log("invalidUrl url=\(url)")
            sendEvent(["event": "error", "message": "Invalid URL"])
            return
        }

        let shouldPreserveSnapshot = currentUrl == url && currentUrl != nil
        if !shouldPreserveSnapshot {
            clearFrameSnapshot()
        }
        cleanup(preserveFrameSnapshot: shouldPreserveSnapshot)
        if shouldPreserveSnapshot && !_view.snapshotView.isHidden {
            recordNativeVisualPhase(
                phase: shouldUseResumePosterPhase() ? "resume_poster" : "poster",
                source: "load_cached_resume"
            )
        }
        didRequestInitialPlay = false
        lastExplicitPlayAt = 0
        lastExplicitPlayUrl = nil
        lastExplicitPauseAt = 0
        lastExplicitPauseUrl = nil
        lastRecoveryPlayAt = 0
        lastEmittedPlayAt = 0
        lastEmittedPlayUrl = nil
        lastObservedTimeControlStatus = nil
        didStabilizeVisualLayer = false
        didRenderFirstFrame = false
        bufferingEventsCount = 0
        playbackStallCount = 0
        currentUrl = url

        // Create AVURLAsset for HLS
        // A7: AVURLAssetPreferPreciseDurationAndTimingKey kaldırıldı — HLS'de tüm içeriği
        // taratıp süreyi kesin hesaplar, TTFF'i ciddi yavaşlatır. HLS için gereksiz.
        let asset = AVURLAsset(url: videoURL, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [:]
        ])

        // Create player item
        playerItem = AVPlayerItem(asset: asset)
        setupVideoOutput()

        // Configure player item for optimal HLS playback
        if #available(iOS 10.0, *) {
            playerItem?.preferredForwardBufferDuration = preferStableStartupBuffer ? 10.0 : 6.0
        }

        // Create player
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = preferStableStartupBuffer

        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.backgroundColor = UIColor.black.cgColor
        playerLayer?.needsDisplayOnBoundsChange = true
        playerLayer?.frame = _view.bounds

        if let playerLayer = playerLayer {
            _view.layer.addSublayer(playerLayer)
            _view.linkedPlayerLayer = playerLayer
        }

        setupPlayerLayerObservers()

        refreshPlayerLayer()

        // Setup observers
        setupPlayerObservers()
        configurePlaybackHealth()

    }

    // MARK: - Player Controls
    func play() {
        log("play url=\(currentUrl ?? "-")")
        let now = CACurrentMediaTime()
        let normalizedUrl = currentUrl ?? ""
        if !normalizedUrl.isEmpty,
           lastExplicitPlayUrl == normalizedUrl,
           now - lastExplicitPlayAt < 0.35 {
            log("playDeduped url=\(normalizedUrl)")
            return
        }
        lastExplicitPlayAt = now
        lastExplicitPlayUrl = normalizedUrl
        PlaybackHealthStore.shared.activate(
            monitor: playbackHealthMonitor,
            snapshot: playbackHealthMonitor.snapshot()
        )
        didRequestInitialPlay = true
        lastAutoplayRequestAt = now
        autoplayRequestWorkItem?.cancel()
        autoplayRequestWorkItem = nil
        playbackWatchdog?.start()
        playbackHealthMonitor.onPlaybackRequested()
        player?.play()
        scheduleVisualLayerStabilization(forceReattach: false)
    }

    func pause() {
        let now = CACurrentMediaTime()
        let normalizedUrl = currentUrl ?? ""
        if !normalizedUrl.isEmpty,
           lastExplicitPauseUrl == normalizedUrl,
           now - lastExplicitPauseAt < 0.35 {
            log("pauseDeduped url=\(normalizedUrl)")
            return
        }
        lastExplicitPauseAt = now
        lastExplicitPauseUrl = normalizedUrl
        log("pause url=\(currentUrl ?? "-")")
        captureCurrentFrameSnapshot(showOverlay: shouldShowResumePosterOnPause())
        playbackWatchdog?.stop()
        player?.pause()
        playbackHealthMonitor.onPlaybackPaused()
        PlaybackHealthStore.shared.clear(monitor: playbackHealthMonitor)
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                self?.sendEvent(["event": "seekCompleted", "position": seconds])
            }
        }
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func setVolume(_ volume: Double) {
        let normalizedVolume = Float(max(0.0, min(1.0, volume)))
        player?.volume = normalizedVolume
        player?.isMuted = normalizedVolume <= 0.0001
    }

    func setLoop(_ loop: Bool) {
        isLooping = loop
    }

    func setAutoplayIntent(_ autoPlay: Bool) {
        isAutoPlay = autoPlay
        if !autoPlay {
            autoplayRequestWorkItem?.cancel()
            return
        }
        didRequestInitialPlay = false
        requestAutoplayIfNeeded(force: true)
    }

    func getCurrentTime() -> Double {
        return player?.currentTime().seconds ?? 0.0
    }

    func getDuration() -> Double {
        return playerItem?.duration.seconds ?? 0.0
    }

    func isMuted() -> Bool {
        return player?.isMuted ?? false
    }

    func isPlaying() -> Bool {
        if #available(iOS 10.0, *) {
            return player?.timeControlStatus == .playing
        } else {
            return player?.rate ?? 0 > 0
        }
    }

    func isBuffering() -> Bool {
        if #available(iOS 10.0, *) {
            if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                return true
            }
        }
        return playerItem?.isPlaybackBufferEmpty ?? false
    }

    func getPlaybackDiagnostics() -> [String: Any] {
        let position = player?.currentTime().seconds ?? 0.0
        let duration = playerItem?.duration.seconds ?? 0.0
        let accessEvent = playerItem?.accessLog()?.events.last
        let observedBitrateKbps = (accessEvent?.observedBitrate ?? 0.0) / 1000.0
        let indicatedBitrateKbps = (accessEvent?.indicatedBitrate ?? 0.0) / 1000.0
        let switchBitrateKbps = (accessEvent?.switchBitrate ?? 0.0) / 1000.0
        return [
            "platform": "ios",
            "playerExists": player != nil,
            "currentUrl": currentUrl ?? "",
            "isPlaying": isPlaying(),
            "isBuffering": isBuffering(),
            "isMuted": player?.isMuted ?? false,
            "volume": Double(player?.volume ?? 0),
            "position": position.isFinite ? position : 0.0,
            "duration": duration.isFinite ? duration : 0.0,
            "didRenderFirstFrame": didRenderFirstFrame,
            "bufferingEvents": bufferingEventsCount,
            "playbackStalls": playbackStallCount,
            "observedBitrateKbps": observedBitrateKbps,
            "indicatedBitrateKbps": indicatedBitrateKbps,
            "switchBitrateKbps": switchBitrateKbps,
        ]
    }

    func getProcessDiagnostics() -> [String: Any] {
        return [
            "platform": "ios",
            "residentMemoryMb": Self.currentResidentMemoryMb(),
            "thermalState": Self.thermalStateName(),
            "playerExists": player != nil,
        ]
    }

    // MARK: - Network & Buffer Control

    /// Oynatmayı durdur ve network/decoder kaynaklarını serbest bırak.
    /// Player instance hayatta kalır, tekrar loadVideo ile yüklenebilir.
    func stopPlayback(showOverlay: Bool = true) {
        if showOverlay {
            captureCurrentFrameSnapshot(showOverlay: true)
        } else {
            clearFrameSnapshot()
        }

        // Time observer kaldır
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // KVO observer'ları kaldır
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        timeControlStatusObserver?.invalidate()
        statusObserver = nil
        playbackBufferEmptyObserver = nil
        playbackLikelyToKeepUpObserver = nil
        timeControlStatusObserver = nil

        // Notification observer'ları kaldır
        if let observer = didPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndTimeObserver = nil
        }
        if let observer = failedToPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            failedToPlayToEndTimeObserver = nil
        }
        if let observer = playbackStalledObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackStalledObserver = nil
        }

        // Network + decoder serbest bırak, player shell hayatta kalsın
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem = nil

        sendEvent(["event": "stopped"])
    }

    /// Forward buffer süresini dinamik ayarla (saniye cinsinden).
    func setPreferredBufferDuration(_ duration: Double) {
        if #available(iOS 10.0, *) {
            playerItem?.preferredForwardBufferDuration = duration
        }
    }

    // MARK: - Observers Setup
    private func setupPlayerObservers() {
        guard let playerItem = playerItem else { return }

        // Status observer
        statusObserver = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.log("readyToPlay url=\(self?.currentUrl ?? "-") duration=\(item.duration.seconds)")
                    self?.refreshPlayerLayer(forceReattach: false)
                    self?.requestAutoplayIfNeeded(force: false)
                    self?.sendEvent([
                        "event": "ready",
                        "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0
                    ])
                case .failed:
                    let errorMessage = item.error?.localizedDescription ?? "Unknown playback error"
                    self?.log("failed url=\(self?.currentUrl ?? "-") error=\(errorMessage)")
                    self?.sendEvent(["event": "error", "message": errorMessage])
                case .unknown:
                    self?.log("statusUnknown url=\(self?.currentUrl ?? "-")")
                    break
                @unknown default:
                    break
                }
            }
        }

        // Buffer observers
        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty {
                self?.bufferingEventsCount += 1
                self?.log("bufferEmpty url=\(self?.currentUrl ?? "-")")
                self?.sendEvent(["event": "buffering", "isBuffering": true])
            }
        }

        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                self?.log("likelyToKeepUp url=\(self?.currentUrl ?? "-")")
                self?.requestRecoveryAutoplayIfNeeded(source: "likelyToKeepUp")
                self?.sendEvent(["event": "buffering", "isBuffering": false])
            }
        }

        // Time control status observer (iOS 10+)
        if #available(iOS 10.0, *) {
            timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                DispatchQueue.main.async {
                    let status = player.timeControlStatus
                    if self?.lastObservedTimeControlStatus == status {
                        return
                    }
                    self?.lastObservedTimeControlStatus = status
                    switch status {
                case .playing:
                        self?.log("timeControlStatus=playing url=\(self?.currentUrl ?? "-")")
                        if self?.didRenderFirstFrame == false {
                            self?.scheduleVisualLayerStabilization(forceReattach: false)
                        }
                        self?.emitPlayEventIfNeeded()
                    case .paused:
                        self?.log("timeControlStatus=paused url=\(self?.currentUrl ?? "-")")
                        self?.sendEvent(["event": "pause"])
                    case .waitingToPlayAtSpecifiedRate:
                        self?.log("timeControlStatus=waiting url=\(self?.currentUrl ?? "-")")
                        self?.sendEvent(["event": "buffering", "isBuffering": true])
                    @unknown default:
                        break
                    }
                }
            }
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = self.playerItem?.duration else { return }

            let currentTime = time.seconds
            let totalDuration = duration.seconds

            if currentTime >= 0.0 &&
                currentTime < 1.2 &&
                !self.didRenderFirstFrame &&
                !self.didStabilizeVisualLayer {
                self.scheduleVisualLayerStabilization(forceReattach: false)
            }

            if currentTime.isFinite && totalDuration.isFinite {
                self.sendEvent([
                    "event": "timeUpdate",
                    "position": currentTime,
                    "duration": totalDuration
                ])
            }
        }

        // Notification observers
        didPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnded()
        }

        failedToPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.log("failedToPlayToEnd url=\(self?.currentUrl ?? "-") error=\(error?.localizedDescription ?? "unknown")")
            self?.sendEvent(["event": "error", "message": error?.localizedDescription ?? "Failed to play to end"])
        }

        playbackStalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.log("playbackStalled url=\(self?.currentUrl ?? "-")")
            self?.playbackStallCount += 1
            self?.requestRecoveryAutoplayIfNeeded(source: "playbackStalled")
            self?.sendEvent(["event": "buffering", "isBuffering": true])
        }
    }

    private func requestAutoplayIfNeeded(force: Bool) {
        guard (isAutoPlay || force), let player = player else { return }
        if didRequestInitialPlay && !force { return }
        let now = CACurrentMediaTime()
        if now - lastAutoplayRequestAt < 0.25 {
            return
        }
        PlaybackHealthStore.shared.activate(
            monitor: playbackHealthMonitor,
            snapshot: playbackHealthMonitor.snapshot()
        )
        didRequestInitialPlay = true
        lastAutoplayRequestAt = now
        autoplayRequestWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let player = self.player else { return }
            self.autoplayRequestWorkItem = nil
            if #available(iOS 10.0, *) {
                switch player.timeControlStatus {
                case .playing, .waitingToPlayAtSpecifiedRate:
                    self.refreshPlayerLayer()
                    return
                case .paused:
                    break
                @unknown default:
                    break
                }
            } else if player.rate > 0 {
                self.refreshPlayerLayer()
                return
            }
            self.playbackHealthMonitor.onPlaybackRequested()
            self.refreshPlayerLayer()
            if #available(iOS 10.0, *) {
                player.playImmediately(atRate: 1.0)
            } else {
                player.play()
            }
        }
        autoplayRequestWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + (force ? 0.0 : 0.05),
            execute: workItem
        )
    }

    private func requestRecoveryAutoplayIfNeeded(source: String) {
        guard let player = player else { return }
        let normalizedUrl = currentUrl ?? ""
        let hasExplicitPlayIntent =
            !normalizedUrl.isEmpty &&
            lastExplicitPlayUrl == normalizedUrl &&
            !(lastExplicitPauseUrl == normalizedUrl && lastExplicitPauseAt >= lastExplicitPlayAt)
        guard isAutoPlay || hasExplicitPlayIntent || didRequestInitialPlay else {
            log("recoveryPlaySkipped source=\(source) reason=no_play_intent url=\(currentUrl ?? "-")")
            return
        }
        let now = CACurrentMediaTime()
        if now - lastRecoveryPlayAt < 1.2 {
            log("recoveryPlaySkipped source=\(source) url=\(currentUrl ?? "-")")
            return
        }
        if #available(iOS 10.0, *) {
            if player.timeControlStatus == .playing {
                return
            }
        } else if player.rate > 0 {
            return
        }
        lastRecoveryPlayAt = now
        didRequestInitialPlay = false
        requestAutoplayIfNeeded(force: true)
    }

    private func emitPlayEventIfNeeded() {
        let now = CACurrentMediaTime()
        let normalizedUrl = currentUrl ?? ""
        if !normalizedUrl.isEmpty,
           lastEmittedPlayUrl == normalizedUrl,
           now - lastEmittedPlayAt < 0.35 {
            log("playEventDeduped url=\(normalizedUrl)")
            return
        }
        lastEmittedPlayAt = now
        lastEmittedPlayUrl = normalizedUrl
        sendEvent(["event": "play"])
    }

    private func handlePlaybackEnded() {
        playbackHealthMonitor.onPlaybackCompleted()
        sendEvent(["event": "completed"])

        if isLooping {
            player?.seek(to: .zero)
            player?.play()
        }
    }

    // MARK: - Lifecycle Observers
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appWillResignActive() {
        forceBackgroundSilence()
    }

    @objc private func appDidEnterBackground() {
        playbackHealthMonitor.onAppDidEnterBackground()
        forceBackgroundSilence()
    }

    @objc private func appWillEnterForeground() {
        playbackHealthMonitor.onAppWillEnterForeground()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
        } catch {
            log("Audio session reactivate failed: \(error)")
        }

        player?.isMuted = wasMutedBeforeBackground
        player?.volume = volumeBeforeBackground
    }

    private func forceBackgroundSilence() {
        wasMutedBeforeBackground = player?.isMuted ?? false
        volumeBeforeBackground = player?.volume ?? 1.0

        player?.pause()
        player?.isMuted = true
        player?.volume = 0
        player?.rate = 0
        playbackHealthMonitor.onPlaybackPaused()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            log("Audio session deactivate failed: \(error)")
        }
    }

    // MARK: - Layout
    func layoutSubviews() {
        playerLayer?.frame = _view.bounds
    }

    private func refreshPlayerLayer(forceReattach: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let playerLayer = self.playerLayer {
                playerLayer.player = self.player
                playerLayer.isHidden = false
                playerLayer.frame = self._view.bounds
                let needsAttach = playerLayer.superlayer == nil || playerLayer.superlayer !== self._view.layer
                if needsAttach {
                    if playerLayer.superlayer != nil {
                        playerLayer.removeFromSuperlayer()
                    }
                    self._view.layer.addSublayer(playerLayer)
                }
                self._view.linkedPlayerLayer = playerLayer
                self.playbackHealthProbe?.attachPlayerLayer(playerLayer, didAttach: needsAttach)
            }
            if forceReattach || !self.didRenderFirstFrame {
                self._view.setNeedsLayout()
                self._view.layoutIfNeeded()
                self.playerLayer?.setNeedsDisplay()
                self._view.layer.setNeedsDisplay()
            }
            CATransaction.commit()
        }
    }

    private func setupPlayerLayerObservers() {
        playerLayerReadyObserver?.invalidate()
        playerLayerReadyObserver = playerLayer?.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard layer.isReadyForDisplay, !self.didRenderFirstFrame else { return }
                self.didRenderFirstFrame = true
                self.log("firstFrame url=\(self.currentUrl ?? "-")")
                self.playbackHealthMonitor.onFirstFrameRendered()
                self.playbackHealthMonitor.onFrameRendered()
                self.hideFrameSnapshot()
                self.recordNativeVisualPhase(
                    phase: "video_play",
                    source: "first_frame"
                )
                self.sendEvent(["event": "firstFrame"])
            }
        }
    }

    private func configurePlaybackHealth() {
        playbackHealthMonitor.resetForNewPlaybackSession()
        playbackHealthProbe?.invalidate()
        playbackWatchdog?.stop()
        playbackHealthProbe = AVPlayerPlaybackProbe(
            player: player,
            playerItem: playerItem,
            monitor: playbackHealthMonitor,
            tag: "AVPlayerPlaybackProbe[\(viewId)]"
        )
        if let playerLayer {
            playbackHealthProbe?.attachPlayerLayer(playerLayer)
        }
        playbackWatchdog = PlaybackWatchdog(
            playerProvider: { [weak self] in self?.player },
            playerLayerProvider: { [weak self] in self?.playerLayer },
            monitor: playbackHealthMonitor,
            tag: "AVPlayerPlaybackWatchdog[\(viewId)]"
        )
    }

    private func setupVideoOutput() {
        videoOutput = nil
        guard let playerItem = playerItem else { return }
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ])
        playerItem.add(output)
        videoOutput = output
    }

    private func captureCurrentFrameSnapshot(showOverlay: Bool) {
        guard let image = currentFrameSnapshot() else { return }
        _view.snapshotView.image = image
        if showOverlay {
            _view.snapshotView.isHidden = false
            recordNativeVisualPhase(
                phase: shouldUseResumePosterPhase() ? "resume_poster" : "poster",
                source: "snapshot_capture"
            )
        }
    }

    private func currentFrameSnapshot() -> UIImage? {
        guard let output = videoOutput else { return nil }

        let candidateTimes: [CMTime] = [
            player?.currentTime() ?? .invalid,
            output.itemTime(forHostTime: CACurrentMediaTime()),
        ]

        for time in candidateTimes where time.isValid && !time.isIndefinite {
            var displayTime = CMTime.invalid
            if let pixelBuffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: &displayTime) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }

        return nil
    }

    private func clearFrameSnapshot() {
        _view.snapshotView.image = nil
        _view.snapshotView.isHidden = true
        clearNativeVisualPhase()
    }

    private func hideFrameSnapshot() {
        _view.snapshotView.isHidden = true
        clearNativeVisualPhase()
    }

    private func shouldUseResumePosterPhase() -> Bool {
        let position = player?.currentTime().seconds ?? 0.0
        return preferResumePoster && position.isFinite && position > 0.05
    }

    private func shouldShowResumePosterOnPause() -> Bool {
        shouldUseResumePosterPhase()
    }

    private func clearNativeVisualPhase() {
        lastNativeVisualPhase = nil
        lastNativeVisualPhaseAtEpochMs = 0
    }

    private func recordNativeVisualPhase(
        phase: String,
        source: String
    ) {
        let now = Int64(Date().timeIntervalSince1970 * 1000.0)
        let previousPhase = lastNativeVisualPhase
        if previousPhase == phase {
            return
        }
        let previousDurationMs: Int64 = lastNativeVisualPhaseAtEpochMs > 0
            ? now - lastNativeVisualPhaseAtEpochMs
            : -1
        lastNativeVisualPhase = phase
        lastNativeVisualPhaseAtEpochMs = now
        let payload: [String: Any] = [
            "event": "visualPhase",
            "phase": phase,
            "source": source,
            "previousPhase": previousPhase ?? "",
            "previousDurationMs": previousDurationMs,
            "phaseStartedAtEpochMs": now,
            "overlayVisible": !_view.snapshotView.isHidden,
            "didRenderFirstFrame": didRenderFirstFrame,
            "preferResumePoster": preferResumePoster,
            "url": currentUrl ?? "",
        ]
        log("visualPhase phase=\(phase) source=\(source) overlayVisible=\(!_view.snapshotView.isHidden) url=\(currentUrl ?? "-")")
        sendEvent(payload)
    }

    private func scheduleVisualLayerStabilization(forceReattach: Bool) {
        guard !didStabilizeVisualLayer else { return }
        didStabilizeVisualLayer = true
        let delays: [Double] = [0.0, 0.08, 0.22]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                if self.didRenderFirstFrame && delay > 0 && !forceReattach {
                    return
                }
                self.refreshPlayerLayer(forceReattach: forceReattach)
            }
        }
    }

    // MARK: - Cleanup
    private func cleanup(preserveFrameSnapshot: Bool = false) {
        if preserveFrameSnapshot {
            captureCurrentFrameSnapshot(showOverlay: true)
        }

        // Remove time observer
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // Remove KVO observers
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        timeControlStatusObserver?.invalidate()

        statusObserver = nil
        playbackBufferEmptyObserver = nil
        playbackLikelyToKeepUpObserver = nil
        timeControlStatusObserver = nil
        playerLayerReadyObserver?.invalidate()
        playerLayerReadyObserver = nil

        // Remove notification observers
        if let observer = didPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndTimeObserver = nil
        }

        if let observer = failedToPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            failedToPlayToEndTimeObserver = nil
        }

        if let observer = playbackStalledObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackStalledObserver = nil
        }

        // Remove app lifecycle observers
        NotificationCenter.default.removeObserver(self)

        // Stop player
        autoplayRequestWorkItem?.cancel()
        autoplayRequestWorkItem = nil
        lastAutoplayRequestAt = 0
        lastObservedTimeControlStatus = nil
        lastExplicitPauseAt = 0
        lastExplicitPauseUrl = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playbackWatchdog?.stop()
        playbackWatchdog = nil
        playbackHealthProbe?.invalidate()
        playbackHealthProbe = nil
        playbackHealthMonitor.onPlayerLayerDetached()

        // Remove layer
        playerLayer?.removeFromSuperlayer()

        // Nullify references
        videoOutput = nil
        playerLayer = nil
        playerItem = nil
        player = nil
        didRenderFirstFrame = false
        if !preserveFrameSnapshot {
            currentUrl = nil
        }
        PlaybackHealthStore.shared.clear(monitor: playbackHealthMonitor)
    }

    func dispose() {
        cleanup()
        eventSink = nil
    }

    // MARK: - Event Handling
    private func sendEvent(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }

    private static func thermalStateName() -> String {
        if #available(iOS 11.0, *) {
            switch ProcessInfo.processInfo.thermalState {
            case .nominal: return "nominal"
            case .fair: return "fair"
            case .serious: return "serious"
            case .critical: return "critical"
            @unknown default: return "unknown"
            }
        }
        return "unsupported"
    }

    private static func currentResidentMemoryMb() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0.0 }
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }
}

// MARK: - FlutterStreamHandler
extension HLSPlayerView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        refreshPlayerLayer()
        // Listener geç bağlandıysa mevcut durumu replay et.
        if let item = playerItem, item.status == .readyToPlay {
            sendEvent([
                "event": "ready",
                "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0
            ])
        }
        if didRenderFirstFrame || playerLayer?.isReadyForDisplay == true {
            didRenderFirstFrame = true
            sendEvent(["event": "firstFrame"])
        }
        if isPlaying() {
            sendEvent(["event": "play"])
        } else if playerItem?.isPlaybackLikelyToKeepUp == false {
            sendEvent(["event": "buffering", "isBuffering": true])
        }
        let pos = getCurrentTime()
        let dur = getDuration()
        if dur.isFinite && dur > 0 {
            sendEvent([
                "event": "timeUpdate",
                "position": max(0.0, pos),
                "duration": dur
            ])
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
