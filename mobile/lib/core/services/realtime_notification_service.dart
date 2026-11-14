import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../utils/notification_sound_helper.dart';
import '../widgets/app_toast.dart';

/// Real-Time Notification Coordinator for Attendify.
///
/// Features:
/// 1. Lifecycle-aware polling (checks every 4 seconds in foreground, pauses when backgrounded).
/// 2. Instant broadcast notification delivery to active screens without requiring manual refresh.
/// 3. Immediate sound trigger for sound-eligible notifications using [NotificationSoundHelper].
/// 4. Sound deduplication preventing repeat chimes for identical notification IDs.
/// 5. Global [unreadCount] ValueNotifier reacting instantly across all dashboard bells.
/// 6. In-app banner alert via [AppToast] for immediate foreground visual confirmation.
class RealtimeNotificationService with WidgetsBindingObserver {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  /// Reactive unread notification counter for app-wide UI badges.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Broadcast stream emitting incoming notifications as they arrive in real-time.
  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationReceived => _notificationStream.stream;

  Timer? _pollTimer;
  int _lastKnownId = 0;
  bool _isInitialized = false;
  bool _isSyncing = false;
  Duration pollInterval = const Duration(seconds: 4);

  /// Visible for testing to reset state between test cases.
  @visibleForTesting
  void resetState({int lastKnownId = 0, int initialUnreadCount = 0}) {
    _pollTimer?.cancel();
    _lastKnownId = lastKnownId;
    unreadCount.value = initialUnreadCount;
    _isSyncing = false;
    _isInitialized = false;
  }

  /// Initialize real-time notification synchronization upon app launch or login.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    syncNotifications(isInitial: true);
  }

  void _startTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => syncNotifications());
  }

  void _stopTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      syncNotifications();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopTimer();
    }
  }

  /// Synchronize notifications with the backend.
  /// On initial load, seeds the latest notification ID and initial unread count.
  /// On subsequent checks, queries for newly created notifications arriving after [_lastKnownId].
  Future<void> syncNotifications({bool isInitial = false}) async {
    if (_isSyncing) return;

    final token = await ApiClient().getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    _isSyncing = true;
    try {
      if (_lastKnownId == 0) {
        // Initial sync: fetch latest page to establish the high-watermark ID
        final response = await ApiClient().get('${ApiConstants.notifications}?per_page=10');
        if (response.success && response.data is List) {
          final List list = response.data as List;
          int maxId = 0;
          for (final item in list) {
            if (item is Map) {
              final id = (item['id'] as num?)?.toInt() ?? 0;
              if (id > maxId) maxId = id;
            }
          }
          _lastKnownId = maxId;

          final count = (response.rawBody?['unread_count'] as num?)?.toInt();
          if (count != null) {
            unreadCount.value = count;
          }
        }
      } else {
        // Incremental sync: only ask for notifications newer than _lastKnownId
        final response = await ApiClient().get(
          '${ApiConstants.notifications}?after_id=$_lastKnownId&per_page=10',
        );

        if (response.success && response.data is List) {
          final List list = response.data as List;
          final List<Map<String, dynamic>> newItems = [];

          for (final item in list) {
            if (item is Map) {
              newItems.add(Map<String, dynamic>.from(item));
            }
          }

          if (newItems.isNotEmpty) {
            // Sort ascending so notifications are processed chronologically
            newItems.sort((a, b) =>
                ((a['id'] as num?)?.toInt() ?? 0).compareTo((b['id'] as num?)?.toInt() ?? 0));

            for (final item in newItems) {
              final int notifId = (item['id'] as num?)?.toInt() ?? 0;
              if (notifId > _lastKnownId) {
                _lastKnownId = notifId;
              }

              // Extract sound details
              final type = item['notification_type'] as String?;
              final payload = item['payload'];
              String? sound;
              if (payload is Map) {
                sound = payload['sound'] as String?;
              } else if (payload is String && payload.isNotEmpty) {
                try {
                  final decoded = jsonDecode(payload);
                  if (decoded is Map) sound = decoded['sound'] as String?;
                } catch (_) {}
              }

              // 1. Play notification sound immediately upon arrival
              NotificationSoundHelper.playIfSoundEnabled(
                notificationId: notifId,
                soundName: sound,
                notificationType: type,
              );

              // 2. Emit to active listeners (e.g. NotificationsScreen)
              _notificationStream.add(item);

              // 3. Show in-app banner toast if app context is available
              _showForegroundToast(item);
            }

            // Update reactive unread count
            final serverUnread = (response.rawBody?['unread_count'] as num?)?.toInt();
            if (serverUnread != null) {
              unreadCount.value = serverUnread;
            } else {
              unreadCount.value += newItems.length;
            }
          } else {
            // If server returned unread_count even with no new items, keep in sync
            final serverUnread = (response.rawBody?['unread_count'] as num?)?.toInt();
            if (serverUnread != null && serverUnread != unreadCount.value) {
              unreadCount.value = serverUnread;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('RealtimeNotificationService sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Show a non-intrusive in-app banner toast when an announcement arrives in foreground.
  void _showForegroundToast(Map<String, dynamic> notification) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final title = notification['title']?.toString() ?? 'New Announcement';
      final message = notification['message']?.toString() ?? '';
      final snippet = message.length > 80 ? '${message.substring(0, 80)}…' : message;

      AppToast.info(context, '$title: $snippet');
    } catch (_) {
      // Gracefully ignore toast errors during test execution or transitions
    }
  }

  /// Manually update unread count (e.g. after marking notifications read in NotificationsScreen).
  void updateUnreadCount(int count) {
    unreadCount.value = max(0, count);
  }

  /// Register FCM Device Token with the backend.
  Future<bool> registerDeviceToken(String fcmToken, [String platform = 'android']) async {
    try {
      final response = await ApiClient().post(ApiConstants.deviceTokens, {
        'fcm_token': fcmToken,
        'platform': platform,
      });
      return response.success;
    } catch (e) {
      debugPrint('Error registering device token: $e');
      return false;
    }
  }

  /// Deregister FCM Device Token upon user logout.
  Future<bool> deregisterDeviceToken(String fcmToken) async {
    try {
      final response = await ApiClient().delete(ApiConstants.deviceTokens, body: {
        'fcm_token': fcmToken,
      });
      return response.success;
    } catch (e) {
      debugPrint('Error deregistering device token: $e');
      return false;
    }
  }

  /// Stop polling and tear down state upon logout.
  void stop() {
    _stopTimer();
    _lastKnownId = 0;
    unreadCount.value = 0;
    _isInitialized = false;
  }
}
