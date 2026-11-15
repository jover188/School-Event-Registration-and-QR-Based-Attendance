import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/services/push_notification_service.dart';
import 'package:school_event_attendance/core/services/realtime_notification_service.dart';
import 'package:school_event_attendance/main.dart';
import 'package:school_event_attendance/screens/common/notifications_screen.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.mockHandler = null;
    ApiClient().token = null;
    ApiClient().userId = null;
    PushNotificationService().resetStateForTesting();
    RealtimeNotificationService().resetState();
  });

  tearDown(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.mockHandler = null;
    ApiClient().token = null;
    ApiClient().userId = null;
    PushNotificationService().resetStateForTesting();
    RealtimeNotificationService().resetState();
  });

  group('PushNotificationService Singleton & State Tests', () {
    test('PushNotificationService returns identical singleton instance', () {
      final instance1 = PushNotificationService();
      final instance2 = PushNotificationService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('PushNotificationService initializes with default uninitialized state', () {
      final service = PushNotificationService();
      expect(service.isInitialized, isFalse);
      expect(service.fcmToken, isNull);
      expect(service.lastRegisteredToken, isNull);
      expect(service.lastRegisteredUserId, isNull);
    });

    test('fcmToken getter reflects token and resetStateForTesting clears it', () {
      final service = PushNotificationService();
      expect(service.fcmToken, isNull);
      service.setTokenForTesting('fcm_test_device_token_xyz');
      expect(service.fcmToken, 'fcm_test_device_token_xyz');
      service.resetStateForTesting();
      expect(service.fcmToken, isNull);
      expect(service.lastRegisteredToken, isNull);
      expect(service.lastRegisteredUserId, isNull);
    });

    test('initialize() fails gracefully and does not throw when Firebase is not configured', () async {
      final service = PushNotificationService();
      // In a headless unit test without Firebase App, initialize() should catch error gracefully
      await expectLater(service.initialize(), completes);
      expect(service.isInitialized, isFalse);
    });

    test('firebaseMessagingBackgroundHandler handles message gracefully', () async {
      const message = RemoteMessage(
        messageId: 'test_msg_001',
        data: {'key': 'value'},
      );
      await expectLater(firebaseMessagingBackgroundHandler(message), completes);
    });
  });

  group('FCM Device Token Registration & Deduplication Lifecycle Tests', () {
    test('syncDeviceToken() does not call registerDeviceToken when unauthenticated', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_unauth_token_123');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      // Explicitly unauthenticated: token is null
      ApiClient().token = null;

      final success = await service.syncDeviceToken();

      expect(success, isFalse);
      expect(calls, isEmpty, reason: 'Must not make HTTP calls to register token when unauthenticated');
      expect(service.lastRegisteredToken, isNull);
      expect(service.lastRegisteredUserId, isNull);
    });

    test('syncDeviceToken() does not call registerDeviceToken when fcmToken is empty or null', () async {
      final service = PushNotificationService();
      service.setTokenForTesting(null);

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'valid_bearer_token';
      ApiClient().userId = 10;

      final success = await service.syncDeviceToken();

      expect(success, isFalse);
      expect(calls, isEmpty);
    });

    test('syncDeviceToken() registers token on backend when authenticated', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_auth_token_456');

      final calls = <String>[];
      Map<String, dynamic>? registeredBody;

      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        if (method == 'POST' && endpoint == ApiConstants.deviceTokens) {
          registeredBody = body as Map<String, dynamic>?;
          return ApiResponse(success: true, statusCode: 200);
        }
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'session_bearer_token_xyz';
      ApiClient().userId = 42;

      final success = await service.syncDeviceToken();

      expect(success, isTrue);
      expect(calls, contains('POST ${ApiConstants.deviceTokens}'));
      expect(registeredBody?['fcm_token'], 'fcm_auth_token_456');
      expect(service.lastRegisteredToken, 'fcm_auth_token_456');
      expect(service.lastRegisteredUserId, 42);
    });

    test('syncDeviceToken() skips duplicate calls when token & user ID match (deduplication)', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_dedup_token_789');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'session_token';
      ApiClient().userId = 100;

      // First sync
      final firstResult = await service.syncDeviceToken();
      expect(firstResult, isTrue);
      expect(calls.length, 1);
      expect(calls.first, 'POST ${ApiConstants.deviceTokens}');

      calls.clear();

      // Second sync with identical token & userId (should be deduplicated)
      final secondResult = await service.syncDeviceToken();
      expect(secondResult, isTrue);
      expect(calls, isEmpty, reason: 'Duplicate syncDeviceToken calls must be skipped');

      // Force sync bypasses deduplication
      final forcedResult = await service.syncDeviceToken(force: true);
      expect(forcedResult, isTrue);
      expect(calls.length, 1, reason: 'force=true must bypass deduplication check');
    });

    test('syncDeviceToken() re-registers when userId changes (account switch)', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_shared_device_token');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'user_1_token';
      ApiClient().userId = 1;

      // User 1 registers
      await service.syncDeviceToken();
      expect(calls.length, 1);
      expect(service.lastRegisteredUserId, 1);

      calls.clear();

      // User 2 logs in on the same device
      ApiClient().token = 'user_2_token';
      ApiClient().userId = 2;

      final switchResult = await service.syncDeviceToken();
      expect(switchResult, isTrue);
      expect(calls.length, 1, reason: 'Different user ID must trigger re-registration');
      expect(service.lastRegisteredUserId, 2);
    });

    test('syncDeviceToken() re-registers when FCM token is rotated', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_initial_token');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'bearer_token';
      ApiClient().userId = 55;

      // Initial registration
      await service.syncDeviceToken();
      expect(calls.length, 1);

      calls.clear();

      // Token rotation occurs
      service.setTokenForTesting('fcm_rotated_new_token');

      final rotationResult = await service.syncDeviceToken();
      expect(rotationResult, isTrue);
      expect(calls.length, 1, reason: 'Rotated FCM token must trigger re-registration');
      expect(service.lastRegisteredToken, 'fcm_rotated_new_token');
    });

    test('resetRegistrationState() clears registration cache', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_reset_token');
      service.setLastRegisteredForTesting(token: 'fcm_reset_token', userId: 77);

      expect(service.lastRegisteredToken, 'fcm_reset_token');
      expect(service.lastRegisteredUserId, 77);

      service.resetRegistrationState();

      expect(service.lastRegisteredToken, isNull);
      expect(service.lastRegisteredUserId, isNull);

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      ApiClient().token = 'bearer_token';
      ApiClient().userId = 77;

      // Now sync should proceed because cache was reset
      final result = await service.syncDeviceToken();
      expect(result, isTrue);
      expect(calls.length, 1);
    });

    test('syncDeviceToken() does not cache state if server registration fails', () async {
      final service = PushNotificationService();
      service.setTokenForTesting('fcm_failing_token');

      ApiClient.mockHandler = (method, endpoint, body) async {
        return ApiResponse(success: false, statusCode: 500, message: 'Server error');
      };

      ApiClient().token = 'bearer_token';
      ApiClient().userId = 88;

      final success = await service.syncDeviceToken();

      expect(success, isFalse);
      expect(service.lastRegisteredToken, isNull);
      expect(service.lastRegisteredUserId, isNull);
    });
  });

  group('PushNotificationService Navigation Routing Tests', () {
    testWidgets('routes to EventDetailScreen when event_id is present', (tester) async {
      final service = PushNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );
      await tester.pump();

      const message = RemoteMessage(
        messageId: 'msg_event_101',
        data: {
          'event_id': '42',
          'type': 'event_reminder_1h',
        },
      );

      service.handleNotificationTapForTesting(message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EventDetailScreen), findsOneWidget);
    });

    testWidgets('routes to NotificationsScreen when event_id is omitted or null', (tester) async {
      final service = PushNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );
      await tester.pump();

      const message = RemoteMessage(
        messageId: 'msg_announcement_202',
        data: {
          'type': 'admin_announcement',
          'title': 'School Holiday Notice',
        },
      );

      service.handleNotificationTapForTesting(message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}
