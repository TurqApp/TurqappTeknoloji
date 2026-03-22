package com.turqapp.app.qa

import android.content.Context

object ExoPlayerSmokeRegistry {
    data class Snapshot(
        val active: Boolean,
        val firstFrameRendered: Boolean,
        val errors: List<String>,
        val status: String,
        val snapshot: Map<String, Any>,
        val raw: String,
    )

    fun register(context: Context, monitor: PlaybackHealthMonitor) {
        PlaybackHealthStore.register(context, monitor)
    }

    fun publish(context: Context, monitor: PlaybackHealthMonitor) {
        PlaybackHealthStore.publish(context, monitor)
    }

    fun publish(context: Context, monitor: PlaybackHealthMonitor, snapshot: Map<String, Any>) {
        PlaybackHealthStore.publish(context, monitor, snapshot)
    }

    fun clear(context: Context, monitor: PlaybackHealthMonitor) {
        PlaybackHealthStore.clear(context, monitor)
    }

    fun requireActiveMonitor(): PlaybackHealthMonitor {
        return PlaybackHealthStore.requireActiveMonitor()
    }

    fun readSnapshot(context: Context): Snapshot? {
        val snapshot = PlaybackHealthStore.readSnapshot(context) ?: return null
        return Snapshot(
            active = snapshot.active,
            firstFrameRendered = snapshot.firstFrameRendered,
            errors = snapshot.errors,
            status = snapshot.status,
            snapshot = snapshot.snapshot,
            raw = snapshot.raw,
        )
    }
}
