import AVFoundation
import Foundation
import QuartzCore

final class PlaybackWatchdog {
    private let playerProvider: () -> AVPlayer?
    private let playerLayerProvider: () -> AVPlayerLayer?
    private let monitor: PlaybackHealthMonitor
    private let interval: TimeInterval
    private let tag: String

    private var timer: DispatchSourceTimer?
    private var lastObservedTime: Double = 0
    private var lastAdvancedAt: CFTimeInterval = 0

    init(
        playerProvider: @escaping () -> AVPlayer?,
        playerLayerProvider: @escaping () -> AVPlayerLayer?,
        monitor: PlaybackHealthMonitor,
        interval: TimeInterval = 0.25,
        tag: String = "PlaybackWatchdog"
    ) {
        self.playerProvider = playerProvider
        self.playerLayerProvider = playerLayerProvider
        self.monitor = monitor
        self.interval = interval
        self.tag = tag
    }

    func start() {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.timer = timer
        timer.resume()
        log("start")
    }

    func stop() {
        timer?.cancel()
        timer = nil
        log("stop")
    }

    private func tick() {
        guard let player = playerProvider() else { return }
        let layer = playerLayerProvider()
        let currentTime = player.currentTime().seconds
        let timestamp = CACurrentMediaTime()
        let advanced = currentTime.isFinite && currentTime > lastObservedTime + 0.04

        if advanced {
            lastObservedTime = currentTime
            lastAdvancedAt = timestamp
            monitor.onTimeProgress(currentTime)
        }

        monitor.detectTimeoutAnomalies(referenceTime: timestamp)

        let layerReady = layer?.isReadyForDisplay ?? false
        let playerIsPlaying: Bool
        if #available(iOS 10.0, *) {
            playerIsPlaying = player.timeControlStatus == .playing
        } else {
            playerIsPlaying = player.rate > 0
        }

        let staleFrame = monitor.shouldFlagVideoFreeze(referenceTime: timestamp)
        let likelyAudioOnly =
            playerIsPlaying &&
            (advanced || timestamp - lastAdvancedAt < 1.0) &&
            staleFrame &&
            !monitor.isBuffering &&
            (!layerReady || currentTime > 0.1)

        if staleFrame && (playerIsPlaying || currentTime > 0.1 || monitor.isPlaybackExpected) {
            monitor.detectVideoFreezeIfNeeded(referenceTime: timestamp)
        }

        if likelyAudioOnly {
            monitor.onAudioMissing()
            monitor.detectVideoFreezeIfNeeded(referenceTime: timestamp)
        }

        if monitor.awaitingFullscreenRecovery &&
            monitor.fullscreenTransitionStartedAt > 0 &&
            timestamp - monitor.fullscreenTransitionStartedAt > 1.5 &&
            monitor.isPlaybackExpected &&
            (!playerIsPlaying || !monitor.hasFreshFrame(since: monitor.fullscreenTransitionStartedAt)) {
            monitor.onFullscreenInterruption()
        }

        if monitor.awaitingBackgroundRecovery &&
            monitor.appWillEnterForegroundAt > 0 &&
            timestamp - monitor.appWillEnterForegroundAt > 1.5 &&
            monitor.isPlaybackExpected &&
            (!playerIsPlaying || !monitor.hasFreshFrame(since: monitor.appWillEnterForegroundAt)) {
            monitor.onBackgroundResumeFailure()
        }
    }

    private func log(_ message: String) {
        print("[\(tag)] \(message)")
    }
}
