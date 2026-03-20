package com.turqapp.app

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import androidx.media3.common.AudioAttributes
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView

class ExoPlayerView(
    private val context: Context,
    private val viewId: Long,
    private val args: Map<String, Any>?,
    private val eventChannel: EventChannel
) : PlatformView, EventChannel.StreamHandler {

    private val forceFullscreen = args?.get("forceFullscreen") as? Boolean ?: false
    private val container = object : FrameLayout(context) {
        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            if (forceFullscreen) {
                val root = rootView
                val targetWidth = if (root.width > 0) root.width else MeasureSpec.getSize(widthMeasureSpec)
                val targetHeight = if (root.height > 0) root.height else MeasureSpec.getSize(heightMeasureSpec)
                super.onMeasure(
                    MeasureSpec.makeMeasureSpec(targetWidth, MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(targetHeight, MeasureSpec.EXACTLY)
                )
                return
            }
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }
    private val playerView: PlayerView
    private var player: ExoPlayer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isLooping = false
    private val handler = Handler(Looper.getMainLooper())
    private var positionRunnable: Runnable? = null
    private var preferredMaxBufferMs: Long = 10000
    private var currentUrl: String? = null
    private var isSoftHeld = false
    private var heldVolume: Float = 1f
    private var didRenderFirstFrame = false
    private var isPlayerReady = false
    private var hasVideoSize = false
    private var hasStableSurfaceLayout = false
    private var pendingRevealRunnable: Runnable? = null
    private var lastSurfaceWidth = 0
    private var lastSurfaceHeight = 0
    private var stableSurfacePasses = 0
    private var isBufferingDispatched = false

    init {
        val layoutRes = R.layout.turq_texture_player_view
        playerView = (LayoutInflater.from(context)
            .inflate(layoutRes, container, false) as PlayerView).apply {
            useController = false
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            setShutterBackgroundColor(if (forceFullscreen) Color.BLACK else Color.TRANSPARENT)
            setBackgroundColor(if (forceFullscreen) Color.BLACK else Color.TRANSPARENT)
            setKeepContentOnPlayerReset(true)
            alpha = if (forceFullscreen) 0f else 1f
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        container.addView(playerView)
        playerView.videoSurfaceView?.addOnLayoutChangeListener { _, left, top, right, bottom, _, _, _, _ ->
            val width = (right - left).coerceAtLeast(0)
            val height = (bottom - top).coerceAtLeast(0)
            if (width == 0 || height == 0) {
                stableSurfacePasses = 0
                hasStableSurfaceLayout = false
                return@addOnLayoutChangeListener
            }

            if (width == lastSurfaceWidth && height == lastSurfaceHeight) {
                stableSurfacePasses += 1
            } else {
                lastSurfaceWidth = width
                lastSurfaceHeight = height
                stableSurfacePasses = 1
                hasStableSurfaceLayout = false
            }

            if (stableSurfacePasses >= 2) {
                hasStableSurfaceLayout = true
                scheduleSurfaceReveal()
            }
        }
        container.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                player?.let { existing ->
                    if (playerView.player !== existing) {
                        playerView.player = existing
                    }
                }
            }

            override fun onViewDetachedFromWindow(v: View) {
                // Scroll sırasında geçici detach durumunda sadece pause et.
                // playerView.player = null yapmak son frame'i düşürüp siyah ekran üretir.
                softHold()
            }
        })
        eventChannel.setStreamHandler(this)

        val url = args?.get("url") as? String
        if (url != null) {
            val autoPlay = args?.get("autoPlay") as? Boolean ?: true
            isLooping = args?.get("loop") as? Boolean ?: false
            loadVideo(url, autoPlay, isLooping)
        }
    }

    fun loadVideo(url: String, autoPlay: Boolean = true, loop: Boolean = false) {
        isLooping = loop
        val existing = player

        // Aynı URL tekrar istenirse player'ı yeniden kurma.
        if (existing != null && currentUrl == url) {
            existing.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
            if (autoPlay) {
                play()
            } else {
                softHold()
            }
            return
        }

        val activePlayer = if (existing == null) {
            // iOS tarafindaki stability-first davranisa yaklasmak icin Android
            // buffer profili biraz daha genis tutulur. Bu, TTFF'i azicik
            // uzatabilir ama scroll gecislerinde siyah ekran/rebuffer oranini
            // gozle gorulur sekilde azaltir.
            val targetBufferMs = preferredMaxBufferMs.coerceIn(4500, 16000).toInt()
            val minBufferMs = (targetBufferMs * 0.8).toInt().coerceAtLeast(3200)
            val playbackBufferMs = (minBufferMs * 0.24).toInt().coerceIn(900, 1800)
            val rebufferPlaybackMs =
                (minBufferMs * 0.55).toInt().coerceIn(1600, 3200)
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    minBufferMs,
                    targetBufferMs,
                    playbackBufferMs,
                    rebufferPlaybackMs
                )
                .build()

            ExoPlayer.Builder(context)
                .setLoadControl(loadControl)
                .build()
                .apply {
                    setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING)
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                        .build()
                    // Audio focus'u native katmanda zorla alma.
                    // Feed/SinglePost geçişinde focus churn sesi sıfırlayabiliyor.
                    setAudioAttributes(audioAttributes, false)
                }
        } else {
            existing
        }

        activePlayer.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        activePlayer.playWhenReady = autoPlay
        isSoftHeld = false
        didRenderFirstFrame = false
        isPlayerReady = false
        hasVideoSize = false
        hasStableSurfaceLayout = false
        lastSurfaceWidth = 0
        lastSurfaceHeight = 0
        stableSurfacePasses = 0
        isBufferingDispatched = false
        resetSurfaceVisibility()

        if (existing == null) {
            activePlayer.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_READY -> {
                        if (isBufferingDispatched) {
                            isBufferingDispatched = false
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                        }
                        isPlayerReady = true
                        scheduleSurfaceReveal()
                        sendEvent(mapOf(
                            "event" to "ready",
                            "duration" to (activePlayer.duration / 1000.0)
                        ))
                        startPositionUpdates()
                    }
                    Player.STATE_ENDED -> {
                        if (isBufferingDispatched) {
                            isBufferingDispatched = false
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                        }
                        sendEvent(mapOf("event" to "completed"))
                        stopPositionUpdates()
                    }
                    Player.STATE_BUFFERING -> {
                        if (!isBufferingDispatched) {
                            isBufferingDispatched = true
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to true))
                        }
                    }
                    Player.STATE_IDLE -> {}
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isPlaying) {
                    if (isBufferingDispatched) {
                        isBufferingDispatched = false
                        sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                    }
                    sendEvent(mapOf("event" to "play"))
                    startPositionUpdates()
                } else {
                    val state = activePlayer.playbackState
                    if (state != Player.STATE_ENDED && state != Player.STATE_BUFFERING) {
                        sendEvent(mapOf("event" to "pause"))
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                revealSurface()
                sendEvent(mapOf(
                    "event" to "error",
                    "message" to (error.message ?: "Unknown playback error")
                ))
                stopPositionUpdates()
            }

            override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
                hasVideoSize = videoSize.width > 0 && videoSize.height > 0
                scheduleSurfaceReveal()
            }

            override fun onRenderedFirstFrame() {
                didRenderFirstFrame = true
                scheduleSurfaceReveal()
                sendEvent(mapOf("event" to "firstFrame"))
            }
            })
        }

        val mediaItem = MediaItem.fromUri(url)
        activePlayer.clearMediaItems()

        // HLS URL'leri için HlsMediaSource kullan (ABR desteği)
        if (url.contains(".m3u8") || url.contains("/hls/")) {
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setConnectTimeoutMs(6000)
                .setReadTimeoutMs(9000)
                .setDefaultRequestProperties(mapOf(
                    "X-Turq-App" to "turqapp-mobile",
                ))
            val hlsSource = HlsMediaSource.Factory(httpDataSourceFactory)
                .setAllowChunklessPreparation(true)
                .createMediaSource(mediaItem)
            activePlayer.setMediaSource(hlsSource)
        } else {
            activePlayer.setMediaItem(mediaItem)
        }
        activePlayer.prepare()

        playerView.player = activePlayer
        player = activePlayer
        currentUrl = url
    }

    fun play() {
        player?.let { p ->
            if (isSoftHeld) {
                p.volume = heldVolume
                isSoftHeld = false
            }
            p.play()
        }
    }

    fun pause() {
        isSoftHeld = false
        player?.pause()
    }

    fun softHold() {
        player?.let { p ->
            if (!isSoftHeld) {
                heldVolume = p.volume
            }
            p.playWhenReady = false
            p.volume = 0f
            isSoftHeld = true
        }
    }

    fun seek(seconds: Double) {
        val posMs = (seconds * 1000).toLong()
        player?.seekTo(posMs)
        sendEvent(mapOf(
            "event" to "seekCompleted",
            "position" to seconds
        ))
    }

    fun setMuted(muted: Boolean) {
        val target = if (muted) 0f else 1f
        player?.volume = target
        if (!isSoftHeld) heldVolume = target
    }

    fun setVolume(volume: Float) {
        val target = volume.coerceIn(0f, 1f)
        player?.volume = target
        if (!isSoftHeld) heldVolume = target
    }

    fun setLoop(loop: Boolean) {
        isLooping = loop
        player?.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
    }

    fun getCurrentTime(): Double {
        return (player?.currentPosition ?: 0L) / 1000.0
    }

    fun getDuration(): Double {
        val dur = player?.duration ?: C.TIME_UNSET
        return if (dur == C.TIME_UNSET) 0.0 else dur / 1000.0
    }

    fun isMuted(): Boolean {
        return (player?.volume ?: 1f) == 0f
    }

    fun isPlaying(): Boolean {
        return player?.isPlaying ?: false
    }

    /// Oynatmayı durdur, network/decoder kaynaklarını serbest bırak.
    /// Player view hayatta kalır, tekrar loadVideo ile yüklenebilir.
    fun stopPlayback() {
        stopPositionUpdates()
        player?.stop()
        player?.clearMediaItems()
        sendEvent(mapOf("event" to "stopped"))
    }

    /// Bir sonraki loadVideo çağrısında kullanılacak max buffer süresini ayarla (ms).
    fun setPreferredBufferDuration(durationMs: Long) {
        preferredMaxBufferMs = durationMs
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        positionRunnable = object : Runnable {
            override fun run() {
                player?.let { p ->
                    if (p.isPlaying) {
                        sendEvent(mapOf(
                            "event" to "timeUpdate",
                            "position" to (p.currentPosition / 1000.0),
                            "duration" to (if (p.duration == C.TIME_UNSET) 0.0 else p.duration / 1000.0)
                        ))
                        handler.postDelayed(this, 500)
                        return
                    }
                }
                stopPositionUpdates()
            }
        }
        handler.postDelayed(positionRunnable!!, 500)
    }

    private fun stopPositionUpdates() {
        positionRunnable?.let { handler.removeCallbacks(it) }
        positionRunnable = null
    }

    private fun sendEvent(data: Map<String, Any>) {
        handler.post {
            eventSink?.success(data)
        }
    }

    private fun resetSurfaceVisibility() {
        handler.post {
            pendingRevealRunnable?.let(handler::removeCallbacks)
            pendingRevealRunnable = null
            playerView.animate().cancel()
            playerView.alpha = 0f
        }
    }

    private fun scheduleSurfaceReveal() {
        if (!forceFullscreen) {
            val canReveal = didRenderFirstFrame ||
                (isPlayerReady && hasVideoSize && hasStableSurfaceLayout)
            if (!canReveal) return
            handler.post {
                pendingRevealRunnable?.let(handler::removeCallbacks)
                val revealRunnable = Runnable {
                    pendingRevealRunnable = null
                    revealSurface(immediate = !didRenderFirstFrame)
                }
                pendingRevealRunnable = revealRunnable
                val revealDelayMs = if (didRenderFirstFrame) 24L else 72L
                handler.postDelayed(revealRunnable, revealDelayMs)
            }
            return
        }
        if (!hasVideoSize || (!didRenderFirstFrame && !isPlayerReady)) {
            return
        }
        handler.post {
            pendingRevealRunnable?.let(handler::removeCallbacks)
            val revealRunnable = Runnable {
                pendingRevealRunnable = null
                revealSurface()
            }
            pendingRevealRunnable = revealRunnable
            // Stabil yüzey yakalanırsa hızlı aç; gelmezse READY fallback ile beyaz ekranı bırakma.
            val revealDelayMs = if (hasStableSurfaceLayout) 32L else 120L
            handler.postDelayed(revealRunnable, revealDelayMs)
        }
    }

    private fun revealSurface(immediate: Boolean = false) {
        handler.post {
            pendingRevealRunnable = null
            if (playerView.alpha < 1f) {
                if (immediate) {
                    playerView.animate().cancel()
                    playerView.alpha = 1f
                } else {
                    playerView.animate()
                        .alpha(1f)
                        .setDuration(90)
                        .start()
                }
            }
        }
    }

    private fun releasePlayer(fully: Boolean) {
        stopPositionUpdates()
        player?.pause()
        resetSurfaceVisibility()
        if (fully) {
            player?.release()
            player = null
            currentUrl = null
            isSoftHeld = false
        }
    }

    // PlatformView
    override fun getView(): View = container

    override fun dispose() {
        releasePlayer(fully = true)
        eventSink = null
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Listener geç bağlandıysa mevcut state'i replay et.
        player?.let { p ->
            if (p.playbackState == Player.STATE_READY) {
                sendEvent(
                    mapOf(
                        "event" to "ready",
                        "duration" to (if (p.duration == C.TIME_UNSET) 0.0 else p.duration / 1000.0)
                    )
                )
            }
            if (didRenderFirstFrame) {
                sendEvent(mapOf("event" to "firstFrame"))
            }
            if (p.isPlaying) {
                sendEvent(mapOf("event" to "play"))
                startPositionUpdates()
            } else if (p.playbackState == Player.STATE_BUFFERING) {
                sendEvent(mapOf("event" to "buffering", "isBuffering" to true))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
