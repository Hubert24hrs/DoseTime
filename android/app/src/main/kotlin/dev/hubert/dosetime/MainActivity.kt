package dev.hubert.dosetime

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.ToneGenerator
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "dosetime/alarm"
    private var player: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var toneLoop: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (isReminderIntent(intent)) setShowOverLockScreen(true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isReminderIntent(intent)) setShowOverLockScreen(true)
    }

    // Launched by a dose reminder (notification tap or full-screen alarm).
    private fun isReminderIntent(intent: Intent?): Boolean {
        val action = intent?.action ?: return false
        return action == "SELECT_NOTIFICATION" || action == "SELECT_FOREGROUND_NOTIFICATION"
    }

    // Only show over the lock screen while a dose alarm is active.
    private fun setShowOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(show)
            setTurnScreenOn(show)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startBeep" -> {
                        startBeep()
                        result.success(true)
                    }
                    "clearShownAlarms" -> {
                        // Removes alarms already on screen (stops their insistent
                        // beep) without touching the scheduled ones.
                        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
                        result.success(true)
                    }
                    "stopBeep" -> {
                        stopBeep()
                        setShowOverLockScreen(false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startBeep() {
        stopBeep()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        try {
            val afd = resources.openRawResourceFd(R.raw.dose_beep)
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mp.isLooping = true
            mp.prepare()
            mp.start()
            player = mp
        } catch (e: Exception) {
            // Fall back to a generated tone if the bundled sound can't be played.
            startToneFallback()
        }
    }

    private fun startToneFallback() {
        try {
            val tg = ToneGenerator(AudioManager.STREAM_ALARM, 100)
            toneGenerator = tg
            val loop = object : Runnable {
                override fun run() {
                    tg.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 600)
                    handler.postDelayed(this, 1500)
                }
            }
            toneLoop = loop
            handler.post(loop)
        } catch (_: Exception) {
        }
    }

    private fun stopBeep() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
        toneLoop?.let { handler.removeCallbacks(it) }
        toneLoop = null
        toneGenerator?.release()
        toneGenerator = null
    }

    override fun onDestroy() {
        stopBeep()
        super.onDestroy()
    }
}
