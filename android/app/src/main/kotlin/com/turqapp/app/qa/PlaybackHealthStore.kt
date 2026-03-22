package com.turqapp.app.qa

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import com.turqapp.app.R
import org.json.JSONArray
import org.json.JSONObject

/**
 * Shared, test-readable playback health state.
 *
 * Instrumentation can read:
 * - hidden TextView with id playbackHealthStatusLabel
 * - persisted snapshot via readSnapshot(...)
 */
object PlaybackHealthStore {
    private const val prefsName = "playback_health_store"
    private const val keyActive = "active"
    private const val keySnapshot = "snapshot"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var activeMonitor: PlaybackHealthMonitor? = null

    @Volatile
    private var currentErrors: List<String> = emptyList()

    @Volatile
    private var statusString: String = "OK"

    @Volatile
    private var lastSnapshot: Map<String, Any> = defaultSnapshot(active = false)

    @Volatile
    private var statusLabel: TextView? = null

    data class Snapshot(
        val active: Boolean,
        val firstFrameRendered: Boolean,
        val errors: List<String>,
        val status: String,
        val snapshot: Map<String, Any>,
        val raw: String,
    )

    fun register(context: Context, monitor: PlaybackHealthMonitor) {
        activeMonitor = monitor
        publish(context, monitor, monitor.snapshot())
    }

    fun publish(context: Context, monitor: PlaybackHealthMonitor) {
        publish(context, monitor, monitor.snapshot())
    }

    fun publish(context: Context, monitor: PlaybackHealthMonitor, snapshot: Map<String, Any>) {
        activeMonitor = monitor
        update(context, monitor.getErrors(), snapshot, active = true)
    }

    fun clear(context: Context, monitor: PlaybackHealthMonitor? = null) {
        if (monitor == null || activeMonitor === monitor) {
            activeMonitor = null
        }
        update(
            context = context,
            errors = emptyList(),
            snapshot = defaultSnapshot(active = false),
            active = false,
        )
    }

    fun update(context: Context, errors: List<String>) {
        update(context, errors, lastSnapshot, active = activeMonitor != null)
    }

    fun currentStatus(): String = statusString

    fun currentErrors(): List<String> = currentErrors

    fun snapshot(): Map<String, Any> = lastSnapshot

    fun requireActiveMonitor(): PlaybackHealthMonitor {
        return requireNotNull(activeMonitor) {
            "No active PlaybackHealthMonitor registered."
        }
    }

    fun installStatusLabel(activity: Activity) {
        mainHandler.post {
            val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return@post
            val existing = root.findViewById<TextView?>(R.id.playbackHealthStatusLabel)
            if (existing != null) {
                statusLabel = existing
                syncLabel(existing, statusString)
                return@post
            }

            val label = TextView(activity).apply {
                id = R.id.playbackHealthStatusLabel
                text = statusString
                contentDescription = statusString
                setTextColor(Color.TRANSPARENT)
                setBackgroundColor(Color.TRANSPARENT)
                alpha = 0.02f
                isClickable = false
                isFocusable = false
                importantForAccessibility = TextView.IMPORTANT_FOR_ACCESSIBILITY_YES
                layoutParams = FrameLayout.LayoutParams(1, 1)
            }
            root.addView(label)
            statusLabel = label
            syncLabel(label, statusString)
        }
    }

    fun dispatchAppBackgrounded(context: Context) {
        activeMonitor?.onAppBackgrounded()
        activeMonitor?.let { publish(context, it, it.snapshot()) }
    }

    fun dispatchAppForegrounded(context: Context) {
        activeMonitor?.onAppForegrounded()
        activeMonitor?.let { publish(context, it, it.snapshot()) }
    }

    fun readSnapshot(context: Context): Snapshot? {
        val prefs = context.applicationContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(keyActive, false)) return null
        val raw = prefs.getString(keySnapshot, null) ?: return null
        val json = JSONObject(raw)
        val errorsJson = json.optJSONArray("errors") ?: JSONArray()
        val errors = buildList {
            for (index in 0 until errorsJson.length()) {
                add(errorsJson.optString(index))
            }
        }
        val snapshotJson = json.optJSONObject("snapshot")
        val snapshot = buildMap<String, Any> {
            if (snapshotJson != null) {
                val keys = snapshotJson.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    put(key, snapshotJson.opt(key) ?: continue)
                }
            }
        }
        return Snapshot(
            active = json.optBoolean("active", false),
            firstFrameRendered = json.optBoolean("firstFrameRendered", false),
            errors = errors,
            status = json.optString("status", "OK"),
            snapshot = snapshot,
            raw = raw,
        )
    }

    private fun update(
        context: Context,
        errors: List<String>,
        snapshot: Map<String, Any>,
        active: Boolean,
    ) {
        currentErrors = errors.distinct()
        statusString = if (currentErrors.isEmpty()) "OK" else currentErrors.joinToString("|")

        val merged = LinkedHashMap<String, Any>()
        merged.putAll(snapshot)
        merged["supported"] = true
        merged["active"] = active
        merged["errors"] = currentErrors
        merged["status"] = statusString
        merged["firstFrameRendered"] = snapshot["hasRenderedFirstFrame"] as? Boolean ?: false
        lastSnapshot = merged

        val json = JSONObject().apply {
            put("active", active)
            put("firstFrameRendered", merged["firstFrameRendered"] as? Boolean ?: false)
            put("status", statusString)
            put("errors", JSONArray(currentErrors))
            put("snapshot", toJsonObject(merged))
        }

        context.applicationContext
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(keyActive, active)
            .putString(keySnapshot, json.toString())
            .apply()

        mainHandler.post {
            statusLabel?.let { syncLabel(it, statusString) }
        }
    }

    private fun syncLabel(label: TextView, status: String) {
        label.text = status
        label.contentDescription = status
        label.accessibilityLiveRegion = TextView.ACCESSIBILITY_LIVE_REGION_POLITE
    }

    private fun toJsonObject(map: Map<String, Any>): JSONObject {
        val json = JSONObject()
        map.forEach { (key, value) ->
            json.put(key, toJsonValue(value))
        }
        return json
    }

    private fun toJsonValue(value: Any?): Any {
        return when (value) {
            null -> JSONObject.NULL
            is JSONObject -> value
            is JSONArray -> value
            is Map<*, *> -> {
                val json = JSONObject()
                value.forEach { (entryKey, entryValue) ->
                    if (entryKey != null) {
                        json.put(entryKey.toString(), toJsonValue(entryValue))
                    }
                }
                json
            }
            is Iterable<*> -> JSONArray().apply {
                value.forEach { put(toJsonValue(it)) }
            }
            is Array<*> -> JSONArray().apply {
                value.forEach { put(toJsonValue(it)) }
            }
            is Number, is Boolean, is String -> value
            else -> value.toString()
        }
    }

    private fun defaultSnapshot(active: Boolean): Map<String, Any> {
        return mapOf(
            "supported" to true,
            "active" to active,
            "hasRenderedFirstFrame" to false,
            "errors" to emptyList<String>(),
            "status" to "OK",
        )
    }
}
