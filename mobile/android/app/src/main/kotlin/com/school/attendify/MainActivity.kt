package com.school.attendify

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.school.attendify/notifications"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure notification channel is configured
        AttendifyApplication.setupNotificationChannel(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isChannelConfigured" -> {
                    val status = checkChannelStatus()
                    result.success(status)
                }
                "playChimeSound" -> {
                    val played = playChimeSound()
                    result.success(played)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkChannelStatus(): Map<String, Any> {
        val configured: Boolean
        val hasSound: Boolean

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
            val channel = notificationManager?.getNotificationChannel(AttendifyApplication.NOTIFICATION_CHANNEL_ID)
            configured = channel != null
            hasSound = channel?.sound != null
        } else {
            configured = true
            hasSound = true
        }

        return mapOf(
            "channel_id" to AttendifyApplication.NOTIFICATION_CHANNEL_ID,
            "configured" to configured,
            "has_sound" to hasSound,
            "sound_name" to AttendifyApplication.SOUND_RESOURCE_NAME
        )
    }

    /**
     * Plays the Notification Chime 07 in foreground, respecting system ringer mode.
     * Silent or Vibrate mode suppresses audible playback.
     */
    private fun playChimeSound(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (audioManager != null && audioManager.ringerMode != AudioManager.RINGER_MODE_NORMAL) {
            // Respect device sound settings (silent/vibrate)
            return false
        }

        return try {
            val resId = resources.getIdentifier(AttendifyApplication.SOUND_RESOURCE_NAME, "raw", packageName)
            if (resId == 0) return false

            val mediaPlayer = MediaPlayer.create(applicationContext, resId) ?: return false
            mediaPlayer.setOnCompletionListener { mp ->
                mp.reset()
                mp.release()
            }
            mediaPlayer.start()
            true
        } catch (e: Exception) {
            false
        }
    }
}
