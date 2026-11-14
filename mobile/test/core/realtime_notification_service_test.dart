import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/services/realtime_notification_service.dart';
import 'package:school_event_attendance/core/utils/notification_sound_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel notificationChannel =
      MethodChannel('com.school.attendify/notifications');
  final List<MethodCall> methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    SharedPreferences.setMockInitialValues({
      'auth_bearer_token': 'mock_student_token_123',
    });
    NotificationSoundHelper.resetPlayedIds();
    RealtimeNotificationService().resetState();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, (MethodCall methodCall) async {
      methodCalls.add(methodCall);
      if (methodCall.method == 'playChimeSound') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, null);
    ApiClient.mockHandler = null;
    RealtimeNotificationService().stop();
  });

  group('RealtimeNotificationService Tests', () {
    test('initial sync establishes high watermark without playing sound', () async {
      final service = RealtimeNotificationService();

      ApiClient.mockHandler = (method, endpoint, body) async {
        if (endpoint.contains(ApiConstants.notifications)) {
          return ApiResponse(
            success: true,
            statusCode: 200,
            data: [
              {
                'id': 50,
                'title': 'Existing Announcement',
                'message': 'Old broadcast',
                'notification_type': 'admin_announcement',
                'is_read': false,
                'payload': {'sound': 'sfxmint_ready_chime_07'},
              },
            ],
            rawBody: {'unread_count': 1},
          );
        }
        return ApiResponse(success: false, statusCode: 404);
      };

      // Perform initial sync
      await service.syncNotifications(isInitial: true);

      // Verify unread count set to 1
      expect(service.unreadCount.value, 1);

      // Sound should NOT play on initial historical sync
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 0);
    });

    test('incremental sync triggers sound and emits stream event for incoming broadcast',
        () async {
      final service = RealtimeNotificationService();
      service.resetState(lastKnownId: 50, initialUnreadCount: 1);

      ApiClient.mockHandler = (method, endpoint, body) async {
        if (endpoint.contains('after_id=50')) {
          return ApiResponse(
            success: true,
            statusCode: 200,
            data: [
              {
                'id': 51,
                'title': 'New Urgent Broadcast',
                'message': 'Classes dismissed early today.',
                'notification_type': 'admin_announcement',
                'is_read': false,
                'payload': {'sound': 'sfxmint_ready_chime_07'},
              },
            ],
            rawBody: {'unread_count': 2},
          );
        }
        return ApiResponse(success: false, statusCode: 404);
      };

      Map<String, dynamic>? receivedNotification;
      final sub = service.onNotificationReceived.listen((notif) {
        receivedNotification = notif;
      });

      // Run incremental sync
      await service.syncNotifications();
      await Future<void>.delayed(Duration.zero);

      expect(receivedNotification, isNotNull);
      expect(receivedNotification?['id'], 51);
      expect(receivedNotification?['title'], 'New Urgent Broadcast');

      // Verify sound played for new arrival
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);

      // Verify reactive unread count updated to 2
      expect(service.unreadCount.value, 2);

      await sub.cancel();
    });

    test('incremental sync prevents duplicate chime sound for same notification', () async {
      final service = RealtimeNotificationService();
      service.resetState(lastKnownId: 50, initialUnreadCount: 1);

      ApiClient.mockHandler = (method, endpoint, body) async {
        return ApiResponse(
          success: true,
          statusCode: 200,
          data: [
            {
              'id': 52,
              'title': 'Cancellation Alert',
              'message': 'Event cancelled.',
              'notification_type': 'event_cancellation',
              'is_read': false,
              'payload': {'sound': 'sfxmint_ready_chime_07'},
            },
          ],
          rawBody: {'unread_count': 2},
        );
      };

      // First sync plays sound
      await service.syncNotifications();
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);

      // Re-running sync for same notification must not replay sound
      await service.syncNotifications();
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);
    });

    test('updateUnreadCount updates ValueNotifier immediately', () {
      final service = RealtimeNotificationService();
      service.updateUnreadCount(5);
      expect(service.unreadCount.value, 5);

      service.updateUnreadCount(0);
      expect(service.unreadCount.value, 0);
    });
  });
}
