package com.turqapp.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ExoPlayerFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>

        val eventChannel = EventChannel(
            messenger,
            "turqapp.hls_player/events_$viewId"
        )

        val playerView = ExoPlayerView(
            context = context,
            viewId = viewId.toLong(),
            args = creationParams,
            eventChannel = eventChannel
        )

        ExoPlayerPlugin.instance?.registerView(viewId.toLong(), playerView)

        return playerView
    }
}
