package com.turqapp.app.qa

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.Espresso.pressBack
import androidx.test.espresso.ViewAssertion
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.action.ViewActions.swipeUp
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import com.turqapp.app.MainActivity
import com.turqapp.app.R
import org.hamcrest.MatcherAssert.assertThat
import org.hamcrest.Matchers.`is`
import org.hamcrest.Matchers.not
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.atomic.AtomicReference

@RunWith(AndroidJUnit4::class)
@LargeTest
class ExoPlayerCrashAnrMatrixTest {
    @get:Rule
    val scenarioRule = ActivityScenarioRule(MainActivity::class.java)

    private val device: UiDevice by lazy {
        UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
    }

    @Test
    fun feedPlaybackResilienceMatrix_staysResponsiveAndHealthy() {
        waitForView(R.id.playbackHealthStatusLabel, timeoutMs = 10_000L)
        onView(withId(R.id.feedTab)).perform(click())
        waitForView(R.id.feedRecyclerView, timeoutMs = 10_000L)

        repeat(3) { cycle ->
            waitForHealthyFirstFrame(timeoutMs = 3_000L)
            assertNoCriticalPlaybackErrors(stage = "cycle_${cycle}_initial")

            repeat(3) {
                onView(withId(R.id.feedRecyclerView)).perform(swipeUp())
                SystemClock.sleep(220L)
            }

            onView(withId(R.id.fullscreenButton)).perform(click())
            SystemClock.sleep(1_200L)
            assertNoCriticalPlaybackErrors(stage = "cycle_${cycle}_fullscreen")
            pressBack()
            SystemClock.sleep(500L)

            device.pressHome()
            SystemClock.sleep(800L)
            relaunchApp()
            waitForHealthyFirstFrame(timeoutMs = 3_500L)
            assertNoCriticalPlaybackErrors(stage = "cycle_${cycle}_resume")

            try {
                device.setOrientationLeft()
                SystemClock.sleep(500L)
                assertNoCriticalPlaybackErrors(stage = "cycle_${cycle}_rotate_left")
            } finally {
                device.setOrientationNatural()
            }
            SystemClock.sleep(600L)
            waitForHealthyFirstFrame(timeoutMs = 3_000L)
            assertAppResponsive(stage = "cycle_${cycle}_final")
        }
    }

    private fun assertAppResponsive(stage: String) {
        val label = readPlaybackStatusLabel()
        assertThat("Playback label missing at $stage", label, not(`is`("MISSING")))
    }

    private fun waitForHealthyFirstFrame(timeoutMs: Long) {
        val deadline = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < deadline) {
            val snapshot = PlaybackHealthStore.readSnapshot(appContext())
            val status = readPlaybackStatusLabel()
            if (snapshot?.firstFrameRendered == true && !containsCriticalError(status)) {
                return
            }
            SystemClock.sleep(120L)
        }
        throw AssertionError(
            "Playback did not recover in time. " +
                "status=${readPlaybackStatusLabel()} snapshot=${PlaybackHealthStore.readSnapshot(appContext())?.raw}"
        )
    }

    private fun assertNoCriticalPlaybackErrors(stage: String) {
        val status = readPlaybackStatusLabel()
        if (containsCriticalError(status)) {
            throw AssertionError("Critical playback error at $stage: $status")
        }
    }

    private fun containsCriticalError(status: String): Boolean {
        val critical = listOf(
            "FIRST_FRAME_TIMEOUT",
            "READY_WITHOUT_FRAME",
            "VIDEO_FREEZE",
            "PLAYBACK_NOT_STARTED",
            "FULLSCREEN_INTERRUPTION",
            "BACKGROUND_RESUME_FAILURE",
            "EXCESSIVE_REBUFFERING",
            "EXCESSIVE_DROPPED_FRAMES",
        )
        return critical.any(status::contains)
    }

    private fun readPlaybackStatusLabel(): String {
        val value = AtomicReference("MISSING")
        onView(withId(R.id.playbackHealthStatusLabel)).check(
            ViewAssertion { view, noViewFoundException ->
                if (noViewFoundException != null) throw noViewFoundException
                value.set((view as TextView).text?.toString().orEmpty())
            }
        )
        return value.get()
    }

    private fun waitForView(viewId: Int, timeoutMs: Long) {
        val deadline = SystemClock.elapsedRealtime() + timeoutMs
        var lastError: Throwable? = null
        while (SystemClock.elapsedRealtime() < deadline) {
            try {
                onView(withId(viewId)).check { _, noViewFoundException ->
                    if (noViewFoundException != null) throw noViewFoundException
                }
                return
            } catch (error: Throwable) {
                lastError = error
                SystemClock.sleep(150L)
            }
        }
        throw AssertionError("View id=$viewId not found within $timeoutMs ms", lastError)
    }

    private fun relaunchApp() {
        val context = appContext()
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            ?: throw AssertionError("Launch intent not found for ${context.packageName}")
        context.startActivity(launchIntent)
        waitForView(R.id.playbackHealthStatusLabel, timeoutMs = 10_000L)
    }

    private fun appContext(): Context = ApplicationProvider.getApplicationContext()
}
