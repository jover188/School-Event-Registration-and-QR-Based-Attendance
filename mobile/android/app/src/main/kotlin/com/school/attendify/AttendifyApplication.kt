package com.school.attendify

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import io.flutter.app.FlutterApplication

class AttendifyApplication : FlutterApplication() {

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "attendify_important_v1"
        const val NOTIFICATION_CHANNEL_NAME = "Important Announcements & Events"
        const val NOTIFICATION_CHANNEL_DESC = "Audible notifications with Notification Chime 07"
        const val SOUND_RESOURCE_NAME = "sfxmint_ready_chime_07"

        /**
         * Safely creates or migrates the Android Notification Channel with custom sound and high importance.
         * Runs on application process startup, ensuring the channel exists even when the application
         * is launched directly into background/service mode by incoming FCM push messages.
         */
        fun setupNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return

                val resId = context.resources.getIdentifier(SOUND_RESOURCE_NAME, "raw", context.packageName)
                val soundUri = if (resId != 0) {
                    Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/$resId")
                } else {
                    Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/raw/$SOUND_RESOURCE_NAME")
                }

                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()

                val existingChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
                val soundMatches = existingChannel?.sound?.toString()?.let {
                    it.contains(SOUND_RESOURCE_NAME) || (resId != 0 && it.contains("$resId"))
                } ?: false

                if (existingChannel != null && (existingChannel.importance < NotificationManager.IMPORTANCE_HIGH || !soundMatches)) {
                    notificationManager.deleteNotificationChannel(NOTIFICATION_CHANNEL_ID)
                }

                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = NOTIFICATION_CHANNEL_DESC
                    setSound(soundUri, audioAttributes)
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 250, 250, 250)
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }

                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        setupNotificationChannel(this)
    }
}
