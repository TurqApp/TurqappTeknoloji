package com.turqapp.app.qa

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.media3.common.Player

/**
 * Hafif position/frame watchdog.
 *
 * Kritik kural:
 * - playback position artıyor
 * - ama yeni frame callback'i gelmiyor
 * => VIDEO_FREEZE
 *
 * UI state'e güvenmez, player truth ve frame timestamp'ini karşılaştırır.
 */
class PlaybackWatchdog(
    private val playerProvider: () -> Player?,
    private val monitor: PlaybackHealthMonitor,
    private val tag: String = "PlaybackWatchdog",
    private val tickMs: Long = 250L,
    private val freezeNoFrameWindowMs: Long = 1_000L,
    private val audioMissingWindowMs: Long = 1_500L,
) {

    private val handler = Handler(Looper.getMainLooper())
    private var running = false
    private var lastObservedPositionMs = 0L
    private var lastAdvancedAt = 0L

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
        lastAdvancedAt = 0L
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
            lastAdvancedAt = now
        }

        val lastFrameRenderedAt = monitor.lastFrameRenderedAt
        val frameSilentTooLong =
            lastFrameRenderedAt > 0L && now - lastFrameRenderedAt > freezeNoFrameWindowMs
        val progressedWithoutFrame =
            advanced && monitor.firstFrameRendered && frameSilentTooLong

        if (progressedWithoutFrame) {
            Log.e(
                tag,
                "freezeDetected positionMs=$positionMs lastFrameRenderedAt=$lastFrameRenderedAt"
            )
            monitor.onVideoFreeze()
        }

        val playbackExpected = player.playWhenReady
        val startedTooLate =
            playbackExpected &&
                monitor.playbackRequestedAt > 0L &&
                !monitor.firstFrameRendered &&
                now - monitor.playbackRequestedAt > audioMissingWindowMs

        if (startedTooLate) {
            monitor.onPlaybackNotStarted()
        }

        val likelyAudioOnly =
            player.isPlaying &&
                monitor.firstFrameRendered &&
                lastAdvancedAt > 0L &&
                now - lastAdvancedAt < freezeNoFrameWindowMs &&
                frameSilentTooLong

        if (likelyAudioOnly) {
            monitor.onAudioMissing()
            monitor.onVideoFreeze()
        }

        if (monitor.isFullscreenTransitionOpen &&
            playbackExpected &&
            !player.isPlaying &&
            player.playbackState == Player.STATE_READY
        ) {
            monitor.onFullscreenInterruption()
        }

        lastObservedPositionMs = positionMs
    }
}
