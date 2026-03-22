import AVFoundation
import UIKit

final class AVPlayerPlaybackProbe: NSObject {
    private weak var player: AVPlayer?
    private weak var playerItem: AVPlayerItem?
    private weak var playerLayer: AVPlayerLayer?
    private let monitor: PlaybackHealthMonitor
    private let tag: String

    private var timeControlObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private var bufferEmptyObserver: NSKeyValueObservation?
    private var likelyToKeepUpObserver: NSKeyValueObservation?
    private var layerReadyObserver: NSKeyValueObservation?
    private var timeObserverToken: Any?

    private var playbackStalledObserver: NSObjectProtocol?
    private var accessLogObserver: NSObjectProtocol?
    private var failedToPlayObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    init(
        player: AVPlayer?,
        playerItem: AVPlayerItem?,
        monitor: PlaybackHealthMonitor,
        tag: String = "AVPlayerPlaybackProbe"
    ) {
        self.player = player
        self.playerItem = playerItem
        self.monitor = monitor
        self.tag = tag
        super.init()
        attachObservers()
    }

    func attachPlayerLayer(_ layer: AVPlayerLayer?) {
        guard let layer else { return }
        playerLayer = layer
        monitor.onPlayerLayerAttached()
        layerReadyObserver?.invalidate()
        layerReadyObserver = layer.observe(\.isReadyForDisplay, options: [.new, .initial]) { [weak self] layer, _ in
            guard let self else { return }
            if layer.isReadyForDisplay {
                self.monitor.onFirstFrameRendered()
                self.monitor.onFrameRendered()
                self.log("layerReadyForDisplay")
            }
        }
    }

    func onPlaybackRequested() {
        monitor.onPlaybackRequested()
    }

    func onFullscreenTransitionStarted() {
        monitor.onFullscreenTransitionStarted()
    }

    func onFullscreenTransitionEnded() {
        monitor.onFullscreenTransitionEnded()
    }

    func onAppDidEnterBackground() {
        monitor.onAppDidEnterBackground()
    }

    func onAppWillEnterForeground() {
        monitor.onAppWillEnterForeground()
    }

    func detachPlayerLayer() {
        monitor.onPlayerLayerDetached()
        layerReadyObserver?.invalidate()
        layerReadyObserver = nil
        playerLayer = nil
    }

    func invalidate() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        timeControlObserver?.invalidate()
        rateObserver?.invalidate()
        itemStatusObserver?.invalidate()
        bufferEmptyObserver?.invalidate()
        likelyToKeepUpObserver?.invalidate()
        layerReadyObserver?.invalidate()

        if let observer = playbackStalledObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = accessLogObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = failedToPlayObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playbackStalledObserver = nil
        accessLogObserver = nil
        failedToPlayObserver = nil
        backgroundObserver = nil
        foregroundObserver = nil
        detachPlayerLayer()
    }

    private func attachObservers() {
        guard let player else { return }

        if #available(iOS 10.0, *) {
            timeControlObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
                guard let self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.monitor.onPlaybackStarted()
                    self.monitor.onBufferingEnded()
                    self.maybeRecordVisibleFrame()
                    self.log("timeControlStatus=playing")
                case .paused:
                    self.monitor.onPlaybackPaused()
                    self.log("timeControlStatus=paused")
                case .waitingToPlayAtSpecifiedRate:
                    self.monitor.onBufferingStarted()
                    self.log("timeControlStatus=waiting")
                @unknown default:
                    break
                }
            }
        }

        rateObserver = player.observe(\.rate, options: [.new, .initial]) { [weak self] player, _ in
            guard let self else { return }
            if player.rate > 0 {
                self.monitor.onPlaybackStarted()
                self.maybeRecordVisibleFrame()
                self.log("rate=\(player.rate)")
            } else if #available(iOS 10.0, *) {
                // timeControlStatus observer already owns the paused signal on iOS 10+.
            } else {
                self.monitor.onPlaybackPaused()
            }
        }

        if let item = playerItem {
            itemStatusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self else { return }
                if item.status == .readyToPlay {
                    self.monitor.onPlayerReady()
                    self.maybeRecordVisibleFrame()
                    self.log("itemReady")
                }
            }

            bufferEmptyObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new, .initial]) { [weak self] item, _ in
                guard let self else { return }
                if item.isPlaybackBufferEmpty {
                    self.monitor.onBufferingStarted()
                    self.log("bufferEmpty")
                }
            }

            likelyToKeepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .initial]) { [weak self] item, _ in
                guard let self else { return }
                if item.isPlaybackLikelyToKeepUp {
                    self.monitor.onBufferingEnded()
                    self.maybeRecordVisibleFrame()
                    self.log("likelyToKeepUp")
                }
            }

            playbackStalledObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemPlaybackStalled,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.monitor.onStallDetected()
                self?.monitor.onBufferingStarted()
                self?.log("playbackStalled")
            }

            accessLogObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemNewAccessLogEntry,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                let event = item.accessLog()?.events.last
                let summary = [
                    "observed=\((event?.observedBitrate ?? 0) / 1000)kbps",
                    "indicated=\((event?.indicatedBitrate ?? 0) / 1000)kbps",
                    "switch=\((event?.switchBitrate ?? 0) / 1000)kbps",
                    "stalls=\(event?.numberOfStalls ?? 0)",
                    "segments=\(event?.segmentsDownloadedDuration ?? 0)"
                ].joined(separator: " ")
                self.monitor.onAccessLogUpdate(summary: summary)
                self.log("accessLog \(summary)")
            }

            failedToPlayObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] notification in
                self?.monitor.onPlaybackNotStarted()
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self?.log("failedToPlayToEnd \(error?.localizedDescription ?? "unknown")")
            }
        }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            if seconds.isFinite && seconds >= 0 {
                self.monitor.onTimeProgress(seconds)
                self.maybeRecordVisibleFrame(currentSeconds: seconds)
            }
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onAppDidEnterBackground()
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onAppWillEnterForeground()
        }
    }

    private func maybeRecordVisibleFrame(currentSeconds: Double? = nil) {
        guard let player else { return }
        let seconds = currentSeconds ?? player.currentTime().seconds
        let itemReady = playerItem?.status == .readyToPlay
        let layerReady = playerLayer?.isReadyForDisplay ?? false
        let isActuallyPlaying: Bool
        if #available(iOS 10.0, *) {
            isActuallyPlaying = player.timeControlStatus == .playing
        } else {
            isActuallyPlaying = player.rate > 0
        }

        guard itemReady else { return }
        if isActuallyPlaying && (seconds > 0 || layerReady) {
            monitor.onFirstFrameRendered()
            monitor.onFrameRendered()
        }
    }

    private func log(_ message: String) {
        print("[\(tag)] \(message)")
    }
}
