package com.turqapp.app

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.turqapp.app.qa.PlaybackHealthStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val DEEP_LINK_CHANNEL = "turqapp.deep_link/method"
        private const val DEEP_LINK_EVENTS = "turqapp.deep_link/events"
        private const val NETWORK_STATE_CHANNEL = "turqapp.network_state/method"
    }

    private var initialDeepLink: String? = null
    private var pendingDeepLink: String? = null
    private var deepLinkEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlaybackHealthStore.installStatusLabel(this)
        ExoPlayerPlugin.registerWith(flutterEngine, applicationContext)
        configureDeepLinkBridge(flutterEngine)
        configureNetworkStateBridge(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        PlaybackHealthStore.installStatusLabel(this)
        PlaybackHealthStore.dispatchAppForegrounded(applicationContext)
        ExoPlayerPlugin.instance?.handleAppForegrounded()
    }

    override fun onPause() {
        ExoPlayerPlugin.instance?.handleAppBackgrounded()
        PlaybackHealthStore.dispatchAppBackgrounded(applicationContext)
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchDeepLink(intent)
    }

    private fun configureDeepLinkBridge(flutterEngine: FlutterEngine) {
        initialDeepLink = extractDeepLink(intent)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, DEEP_LINK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        val link = initialDeepLink ?: pendingDeepLink
                        initialDeepLink = null
                        pendingDeepLink = null
                        result.success(link)
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(messenger, DEEP_LINK_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    deepLinkEventSink = events
                    val pending = pendingDeepLink
                    if (!pending.isNullOrBlank()) {
                        events?.success(pending)
                        pendingDeepLink = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    deepLinkEventSink = null
                }
            })
    }

    private fun configureNetworkStateBridge(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, NETWORK_STATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDefaultTransport" -> result.success(getDefaultTransport())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getDefaultTransport(): String {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return "none"
        val activeNetwork = connectivityManager.activeNetwork ?: return "none"
        val capabilities =
            connectivityManager.getNetworkCapabilities(activeNetwork) ?: return "none"
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> "wifi"
            else -> "none"
        }
    }

    private fun dispatchDeepLink(intent: Intent?) {
        val link = extractDeepLink(intent) ?: return
        val sink = deepLinkEventSink
        if (sink != null) {
            sink.success(link)
            return
        }
        pendingDeepLink = link
    }

    private fun extractDeepLink(intent: Intent?): String? {
        val link = intent?.dataString?.trim() ?: return null
        if (link.isEmpty()) return null
        return link
    }
}
