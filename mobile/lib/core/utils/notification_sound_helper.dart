import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_player_stub.dart' if (dart.library.html) 'audio_player_web.dart';

/// Manages audible alerts for Attendify notifications using Notification Chime 07.
///
/// Ensures:
/// 1. Only intended sound-eligible categories trigger the chime (announcements, reminders, cancellations).
/// 2. Deduplication prevents repeated chime playback for the same notification ID.
/// 3. Native Android audio respects device ringer mode (silent/vibrate).
/// 4. Flutter Web audio respects browser autoplay restrictions.
class NotificationSoundHelper {
  static const MethodChannel _channel = MethodChannel('com.school.attendify/notifications');

  /// Official sound identifier configured in Android raw resources and backend metadata.
  static const String expectedSoundName = 'sfxmint_ready_chime_07';

  /// Notification types approved for audible chime playback.
  static const Set<String> soundEnabledTypes = {
    'new_event_published',
    'admin_announcement',
    'admin_announcements',
    'event_reminder_24h',
    'event_reminder_1h',
    'event_cancellation',
  };

  /// Set of notification IDs whose sounds have already been played during this app session.
  static final Set<int> _playedNotificationIds = <int>{};

  /// Determines if a notification is sound-enabled and triggers the chime if not already played.
  static Future<bool> playIfSoundEnabled({
    required int? notificationId,
    required String? soundName,
    String? notificationType,
  }) async {
    final bool isEligible = soundName == expectedSoundName ||
        (notificationType != null && soundEnabledTypes.contains(notificationType));

    if (!isEligible) {
      return false;
    }

    // Avoid duplicate sounds for the same notification
    if (notificationId != null) {
      if (_playedNotificationIds.contains(notificationId)) {
        return false;
      }
      _playedNotificationIds.add(notificationId);
    }

    if (kIsWeb) {
      playWebAudio('assets/sounds/sfxmint_ready_chime_07.mp3');
      return true;
    }

    try {
      final bool? played = await _channel.invokeMethod<bool>('playChimeSound');
      return played ?? false;
    } catch (e) {
      debugPrint('NotificationSoundHelper playChimeSound error: $e');
      return false;
    }
  }

  /// Verifies whether the Android notification channel has been configured.
  static Future<Map<String, dynamic>?> checkAndroidChannel() async {
    if (kIsWeb) return null;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('isChannelConfigured');
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Reset deduplication tracking (useful for testing).
  @visibleForTesting
  static void resetPlayedIds() {
    _playedNotificationIds.clear();
  }
}
