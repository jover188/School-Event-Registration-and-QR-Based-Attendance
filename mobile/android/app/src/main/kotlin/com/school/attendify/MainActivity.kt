package com.school.attendify

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.school.attendify/notifications"
        const val NOTIFICATION_CHANNEL_ID = "attendify_important_v1"
        const val NOTIFICATION_CHANNEL_NAME = "Important Announcements & Events"
        const val NOTIFICATION_CHANNEL_DESC = "Audible notifications with Notification Chime 07"
        const val SOUND_RESOURCE_NAME = "sfxmint_ready_chime_07"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup notification channel upon engine init
        setupNotificationChannel()

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

    /**
     * Safely creates or migrates the Android Notification Channel with custom sound.
     * Android does not permit changing an existing channel's sound after creation,
     * so we verify existing channel attributes and recreate if previously misconfigured.
     */
    private fun setupNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

            val soundUri = Uri.parse(
                "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/$SOUND_RESOURCE_NAME"
            )

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val existingChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
            if (existingChannel != null) {
                // If channel exists but has no sound or was created with low importance, delete and recreate
                if (existingChannel.sound == null || existingChannel.importance < NotificationManager.IMPORTANCE_HIGH) {
                    notificationManager.deleteNotificationChannel(NOTIFICATION_CHANNEL_ID)
                }
            }

            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = NOTIFICATION_CHANNEL_DESC
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun checkChannelStatus(): Map<String, Any> {
        val configured: Boolean
        val hasSound: Boolean

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val channel = notificationManager?.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
            configured = channel != null
            hasSound = channel?.sound != null
        } else {
            configured = true
            hasSound = true
        }

        return mapOf(
            "channel_id" to NOTIFICATION_CHANNEL_ID,
            "configured" to configured,
            "has_sound" to hasSound,
            "sound_name" to SOUND_RESOURCE_NAME
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
            val resId = resources.getIdentifier(SOUND_RESOURCE_NAME, "raw", packageName)
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
