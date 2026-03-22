package com.turqapp.app.qa

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.media3.common.Player

/**
 * Lightweight watchdog that compares playback progression with visible frame activity.
 */
class PlaybackWatchdog(
    private val playerProvider: () -> Player?,
    private val monitor: PlaybackHealthMonitor,
    private val tag: String = "PlaybackWatchdog",
    private val tickMs: Long = 250L,
    private val freezeNoFrameWindowMs: Long = 1_000L,
    private val startTimeoutMs: Long = 1_500L,
) {

    private val handler = Handler(Looper.getMainLooper())
    private var running = false
    private var lastObservedPositionMs = 0L
    private var lastProgressedAt = 0L

    private val tick = object : Runnable {
        override fun run() {
            if (!running) return

            val player = playerProvider()
            if (player != null) {
                evaluatePlayer(player)
            } else {
                monitor.evaluatePassiveTimeouts()
            }

            handler.postDelayed(this, tickMs)
        }
    }

    fun start() {
        if (running) return
        running = true
        lastObservedPositionMs = 0L
        lastProgressedAt = 0L
        handler.post(tick)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(tick)
    }

    private fun evaluatePlayer(player: Player) {
        val now = SystemClock.elapsedRealtime()
        val positionMs = player.currentPosition.coerceAtLeast(0L)
        monitor.onPositionUpdate(positionMs)
        monitor.evaluatePassiveTimeouts()

        val advanced = positionMs > lastObservedPositionMs + 40L
        if (advanced) {
            lastProgressedAt = now
        }

        val staleFrame = monitor.shouldFlagVideoFreeze(now)
        val progressedWithoutFreshFrame =
            advanced &&
                staleFrame &&
                monitor.hasRenderedFirstFrame &&
                now - monitor.lastFrameRenderedAt > freezeNoFrameWindowMs

        if (progressedWithoutFreshFrame) {
            Log.e(
                tag,
                "freezeDetected positionMs=$positionMs lastFrameRenderedAt=${monitor.lastFrameRenderedAt}"
            )
            monitor.onVideoFreeze()
        }

        val playbackExpected = monitor.isPlaybackExpected || player.playWhenReady
        val startedTooLate =
            playbackExpected &&
                !monitor.hasRenderedFirstFrame &&
                monitor.playbackRequestedAt > 0L &&
                now - monitor.playbackRequestedAt > startTimeoutMs

        if (startedTooLate) {
            monitor.onPlaybackNotStarted()
        }

        val likelyAudioOnly =
            (player.isPlaying || playbackExpected) &&
                (advanced || now - lastProgressedAt < freezeNoFrameWindowMs) &&
                staleFrame &&
                !monitor.isBuffering

        if (likelyAudioOnly) {
            monitor.onAudioMissing()
            monitor.onVideoFreeze()
        }

        if (monitor.awaitingFullscreenRecovery &&
            playbackExpected &&
            monitor.fullscreenTransitionStartedAt > 0L &&
            now - monitor.fullscreenTransitionStartedAt > startTimeoutMs &&
            (!player.isPlaying || !monitor.hasFreshFrameSince(monitor.fullscreenTransitionStartedAt))
        ) {
            monitor.onFullscreenInterruption()
        }

        if (monitor.awaitingBackgroundRecovery &&
            monitor.appForegroundedAt > 0L &&
            now - monitor.appForegroundedAt > startTimeoutMs &&
            playbackExpected &&
            (!player.isPlaying || !monitor.hasFreshFrameSince(monitor.appForegroundedAt))
        ) {
            monitor.onBackgroundResumeFailure()
        }

        lastObservedPositionMs = positionMs
    }
}
