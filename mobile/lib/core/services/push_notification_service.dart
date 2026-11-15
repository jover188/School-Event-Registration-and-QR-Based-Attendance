import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../screens/common/notifications_screen.dart';
import '../../screens/student/event_detail_screen.dart';
import '../network/api_client.dart';
import '../utils/notification_sound_helper.dart';
import 'realtime_notification_service.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
///
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter's isolate
/// execution engine can invoke it even when the UI is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handled automatically by Android system notification tray when 'notification' payload is included.
  debugPrint('FCM background message received: ${message.messageId}');
}

/// Push notification coordinator for Attendify using Firebase Cloud Messaging.
///
/// Features:
/// 1. Graceful initialization: Does not crash if `google-services.json` is missing or Firebase is unconfigured.
/// 2. Device token registration: Automatically delivers FCM device token to Attendify backend via [RealtimeNotificationService].
/// 3. Token refresh tracking: Updates device token mapping when rotated by FCM.
/// 4. Foreground chime & sync: Triggers [NotificationSoundHelper] chime and updates notification streams/badges when messages arrive in foreground.
/// 5. Tap navigation: Automatically routes event notifications to [EventDetailScreen] and announcements to [NotificationsScreen].
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  String? _lastRegisteredToken;
  String? get lastRegisteredToken => _lastRegisteredToken;

  int? _lastRegisteredUserId;
  int? get lastRegisteredUserId => _lastRegisteredUserId;

  /// Initialize Firebase and configure FCM messaging listeners.
  ///
  /// Safely catches missing configuration or initialization errors so app
  /// startup continues seamlessly in development/testing without `google-services.json`.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      debugPrint('Firebase not initialized or pending google-services.json: $e');
      return;
    }

    try {
      // 1. Register top-level background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request user notification permissions
      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM notification permission status: ${settings.authorizationStatus}');

      // 3. Retrieve and cache initial FCM device token
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        debugPrint('FCM Device Token retrieved: $token');
        if (ApiClient().token != null && ApiClient().token!.isNotEmpty) {
          await syncDeviceToken();
        }
      }

      // 4. Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
        debugPrint('FCM Device Token refreshed: $newToken');
        _fcmToken = newToken;
        await syncDeviceToken();
      });

      // 5. Handle incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message received: ${message.messageId}');
        final Map<String, dynamic> data = message.data;
        final RemoteNotification? notification = message.notification;

        int? notifId;
        if (data['id'] != null) {
          notifId = int.tryParse(data['id'].toString());
        } else if (data['notification_id'] != null) {
          notifId = int.tryParse(data['notification_id'].toString());
        }

        final soundName = data['sound']?.toString() ?? notification?.android?.sound;
        final notifType = data['notification_type']?.toString() ?? data['type']?.toString();

        // Play chime sound if notification is eligible
        NotificationSoundHelper.playIfSoundEnabled(
          notificationId: notifId,
          soundName: soundName,
          notificationType: notifType,
        );

        // Synchronize notification inbox stream and unread badge
        RealtimeNotificationService().syncNotifications();
      });

      // 6. Handle notification click from background state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 7. Handle notification click from terminated cold-start state
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleNotificationTap(message);
        }
      });
    } catch (e) {
      debugPrint('Error configuring FirebaseMessaging listeners: $e');
    }
  }

  /// Route user to the appropriate screen based on payload contents.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM notification tapped: ${message.data}');

    void performNavigation() {
      final navState = navigatorKey.currentState;
      if (navState == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => performNavigation());
        return;
      }

      final rawEventId = message.data['event_id'];
      int? eventId;
      if (rawEventId != null) {
        eventId = int.tryParse(rawEventId.toString());
      }

      if (eventId != null && eventId > 0) {
        navState.push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: eventId),
          ),
        );
      } else {
        navState.push(
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        );
      }
    }

    final navState = navigatorKey.currentState;
    if (navState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => performNavigation());
    } else {
      performNavigation();
    }
  }

  /// Synchronize FCM device token with the Attendify backend.
  ///
  /// Guarantees:
  /// - Only attempts registration when authenticated ([ApiClient.token] is non-empty).
  /// - Deduplicates calls when token and [userId] have already been registered and [force] is false.
  /// - Returns true on success or when successfully skipped due to deduplication.
  Future<bool> syncDeviceToken({bool force = false}) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      try {
        _fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Device Token retrieved on sync: $_fcmToken');
      } catch (e) {
        debugPrint('Error retrieving FCM token on sync: $e');
      }
    }

    if (_fcmToken == null || _fcmToken!.isEmpty) {
      return false;
    }

    String? token = ApiClient().token;
    if (token == null || token.isEmpty) {
      token = await ApiClient().getToken();
    }
    if (token == null || token.isEmpty) {
      return false;
    }

    final userId = await ApiClient().getUserId();

    if (!force && _lastRegisteredToken == _fcmToken && _lastRegisteredUserId == userId) {
      return true;
    }

    final success = await RealtimeNotificationService().registerDeviceToken(_fcmToken!);
    if (success) {
      _lastRegisteredToken = _fcmToken;
      _lastRegisteredUserId = userId;
    }
    return success;
  }

  /// Resets the device token registration cache.
  ///
  /// Called upon user logout or session termination so that the next user
  /// logging in on this device will unconditionally register their FCM token.
  void resetRegistrationState() {
    _lastRegisteredToken = null;
    _lastRegisteredUserId = null;
  }

  @visibleForTesting
  void handleNotificationTapForTesting(RemoteMessage message) => _handleNotificationTap(message);

  @visibleForTesting
  void setTokenForTesting(String? token) {
    _fcmToken = token;
  }

  @visibleForTesting
  void setLastRegisteredForTesting({String? token, int? userId}) {
    _lastRegisteredToken = token;
    _lastRegisteredUserId = userId;
  }

  @visibleForTesting
  void resetStateForTesting() {
    _isInitialized = false;
    _fcmToken = null;
    _lastRegisteredToken = null;
    _lastRegisteredUserId = null;
  }
}
