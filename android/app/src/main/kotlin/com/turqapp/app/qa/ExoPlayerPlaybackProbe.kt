package com.turqapp.app.qa

import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener

/**
 * Media3 ExoPlayer -> PlaybackHealthMonitor bridge.
 *
 * Kullanım:
 * - visible feed cell bind olurken oluştur
 * - player'a listener + analytics listener olarak bağla
 * - autoplay başlatırken onAutoplayRequested() çağır
 * - fullscreen transition öncesi/sonrası ilgili hook'ları çağır
 */
class ExoPlayerPlaybackProbe(
    private val player: ExoPlayer,
    private val monitor: PlaybackHealthMonitor,
    private val tag: String = "ExoPlayerPlaybackProbe",
) : Player.Listener, AnalyticsListener {

    private val watchdog = PlaybackWatchdog(
        playerProvider = { player },
        monitor = monitor,
        tag = "$tag/watchdog",
    )

    private var selectedBitrateKbps: Long = 0L
    private var selectedResolution: String = "-"
    private var rebufferCount = 0

    fun attach() {
        player.addListener(this)
        player.addAnalyticsListener(this)
        watchdog.start()
        Log.d(tag, "attach")
    }

    fun detach() {
        watchdog.stop()
        player.removeListener(this)
        player.removeAnalyticsListener(this)
        Log.d(tag, "detach")
    }

    fun onAutoplayRequested() {
        monitor.onPlaybackRequested()
        Log.d(tag, "autoplayRequested")
    }

    fun onSurfaceAttached() {
        monitor.onSurfaceAttached()
    }

    fun onSurfaceDetached() {
        monitor.onSurfaceDetached()
    }

    fun onFullscreenTransitionStarted() {
        monitor.onFullscreenTransitionStarted()
    }

    fun onFullscreenTransitionEnded() {
        monitor.onFullscreenTransitionEnded()
    }

    fun onAppBackgrounded() {
        monitor.onAppBackgrounded()
    }

    fun onAppForegrounded() {
        monitor.onAppForegrounded()
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        when (playbackState) {
            Player.STATE_READY -> {
                monitor.onBufferingEnded()
                monitor.onPlayerReady()
                Log.d(
                    tag,
                    "state=READY position=${player.currentPosition} bitrate=${selectedBitrateKbps}kbps res=$selectedResolution"
                )
            }
            Player.STATE_BUFFERING -> {
                rebufferCount += 1
                monitor.onBufferingStarted()
                Log.w(tag, "state=BUFFERING count=$rebufferCount")
            }
            Player.STATE_ENDED -> {
                monitor.onPlaybackPaused()
                Log.d(tag, "state=ENDED position=${player.currentPosition}")
            }
            Player.STATE_IDLE -> {
                monitor.onPlaybackPaused()
                Log.d(tag, "state=IDLE")
            }
        }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        val bufferingWhileAutoplaying =
            player.playWhenReady && player.playbackState == Player.STATE_BUFFERING
        if (isPlaying) {
            monitor.onPlaybackStarted()
        } else if (!bufferingWhileAutoplaying) {
            monitor.onPlaybackPaused()
        }
        Log.d(
            tag,
            "isPlaying=$isPlaying playWhenReady=${player.playWhenReady} state=${player.playbackState}"
        )
        if (player.playWhenReady && !isPlaying && player.playbackState == Player.STATE_READY) {
            monitor.onPlaybackNotStarted()
        }
    }

    override fun onRenderedFirstFrame() {
        monitor.onFirstFrameRendered()
        monitor.onFrameRendered()
        Log.d(
            tag,
            "firstFrameRendered position=${player.currentPosition} bitrate=${selectedBitrateKbps}kbps res=$selectedResolution"
        )
    }

    override fun onDroppedVideoFrames(
        eventTime: AnalyticsListener.EventTime,
        droppedFrames: Int,
        elapsedMs: Long,
    ) {
        monitor.onDroppedFrames(droppedFrames)
        Log.w(tag, "droppedFrames=$droppedFrames total=${monitor.snapshot()["droppedFramesTotal"]}")
    }

    override fun onAudioUnderrun(
        eventTime: AnalyticsListener.EventTime,
        bufferSize: Int,
        bufferSizeMs: Long,
        elapsedSinceLastFeedMs: Long,
    ) {
        monitor.onAudioMissing()
        Log.e(
            tag,
            "audioUnderrun bufferSize=$bufferSize bufferSizeMs=$bufferSizeMs elapsedSinceLastFeedMs=$elapsedSinceLastFeedMs"
        )
    }

    override fun onTracksChanged(
        eventTime: AnalyticsListener.EventTime,
        tracks: Tracks,
    ) {
        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_VIDEO) continue
            for (index in 0 until group.length) {
                if (!group.isTrackSelected(index)) continue
                val format = group.getTrackFormat(index)
                selectedBitrateKbps = (format.bitrate / 1000L).coerceAtLeast(0L)
                selectedResolution = "${format.width}x${format.height}"
                Log.d(
                    tag,
                    "videoTrackSelected bitrate=${selectedBitrateKbps}kbps res=$selectedResolution"
                )
                return
            }
        }
    }

    override fun onBandwidthEstimate(
        eventTime: AnalyticsListener.EventTime,
        totalLoadTimeMs: Int,
        totalBytesLoaded: Long,
        bitrateEstimate: Long,
    ) {
        Log.d(
            tag,
            "bandwidthEstimate=${bitrateEstimate / 1000L}kbps totalBytesLoaded=$totalBytesLoaded"
        )
    }

    fun hasErrors(): Boolean = monitor.hasErrors()

    fun getErrors(): List<String> = monitor.getErrors()

    fun debugSnapshot(): Map<String, Any> = monitor.snapshot() + mapOf(
        "selectedBitrateKbps" to selectedBitrateKbps,
        "selectedResolution" to selectedResolution,
        "rebufferCount" to rebufferCount,
        "playerState" to player.playbackState,
        "playWhenReady" to player.playWhenReady,
        "currentPositionMs" to player.currentPosition,
    )
}
